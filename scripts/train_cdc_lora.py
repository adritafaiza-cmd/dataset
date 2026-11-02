#!/usr/bin/env python3
"""LoRA on frozen Qwen3.8-27B from the filtered external CDC pairs.

One rank. Attention and MLP only. Dev and the 44-circuit exam are not read.
"""
from __future__ import annotations

import json
import os
from pathlib import Path
import time

ROOT = Path("/scratch/ft2335/dataset-observable")
DATA = ROOT / "training" / "cdc-lora-v1"
OUT = Path(os.environ.get("CDC_LORA_OUTPUT", str(DATA)))
MODEL = ROOT / "models" / "Qwen3.8-27B"
REVISION = "1d4bf0f2ff6012fd82039f2fa52739d0dd7c60c0"

RANK = 16
ALPHA = 32
DROPOUT = 0.05
EPOCHS = 2
LR = 1e-4
GRAD_ACCUM = 8
MAX_LENGTH = 4096
SEED = 0
LEAVES = ("q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj")


def load_rows(path: Path) -> list[dict]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    if len(rows) < 12:
        raise SystemExit(f"refusing to train on {len(rows)} rows")
    return rows


def main() -> None:
    from check_cdc_audit import check
    audit = check(DATA)
    if OUT == DATA:
        raise SystemExit("Frozen audit requires a separate CDC_LORA_OUTPUT; preserve the original adapter")
    if OUT.exists() and any(OUT.iterdir()):
        raise SystemExit(f"refusing to overwrite prior retrain output: {OUT}")
    OUT.mkdir(parents=True, exist_ok=True)
    import torch
    from torch.nn import functional as F
    from peft import LoraConfig, get_peft_model
    from transformers import AutoTokenizer, Qwen3_5ForConditionalGeneration

    report = json.loads((DATA / "filter_report.json").read_text(encoding="utf-8"))
    rows = load_rows(DATA / "train.jsonl")
    if report["kept"] != len(rows):
        raise SystemExit("filter_report.json does not match train.jsonl")
    if not torch.cuda.is_available() or torch.cuda.device_count() != 1:
        raise SystemExit("exactly one visible GPU is required")
    torch.manual_seed(SEED)
    tokenizer = AutoTokenizer.from_pretrained(MODEL, revision=REVISION, trust_remote_code=False)
    if tokenizer.pad_token_id is None:
        tokenizer.pad_token = tokenizer.eos_token
    model = Qwen3_5ForConditionalGeneration.from_pretrained(
        MODEL, revision=REVISION, dtype=torch.bfloat16, device_map={"": 0},
        attn_implementation="sdpa", trust_remote_code=False)
    found = sorted({
        name.split(".")[-1]
        for name, module in model.named_modules()
        if isinstance(module, torch.nn.Linear) and name.split(".")[-1] in LEAVES
    })
    if not found:
        leaves = sorted({
            name.split(".")[-1]
            for name, module in model.named_modules()
            if isinstance(module, torch.nn.Linear)
        })
        raise SystemExit("no attention/MLP targets among " + ", ".join(leaves[:40]))
    model = get_peft_model(model, LoraConfig(
        r=RANK, lora_alpha=ALPHA, lora_dropout=DROPOUT,
        target_modules=found, bias="none", task_type="CAUSAL_LM"))
    model.print_trainable_parameters()
    if hasattr(model, "enable_input_require_grads"):
        model.enable_input_require_grads()
    model.gradient_checkpointing_enable()
    model.config.use_cache = False
    model.train()
    examples = []
    skipped = []
    for row in rows:
        messages = row["messages"]
        prompt = tokenizer.apply_chat_template(
            [messages[0]], tokenize=False, add_generation_prompt=True, enable_thinking=False)
        full = tokenizer.apply_chat_template(
            messages, tokenize=False, add_generation_prompt=False, enable_thinking=False)
        prompt_ids = tokenizer(prompt, add_special_tokens=False).input_ids
        full_ids = tokenizer(full, add_special_tokens=False).input_ids
        if full_ids[:len(prompt_ids)] != prompt_ids:
            skipped.append({"module": row.get("module"), "reason": "prompt_prefix_mismatch"})
            continue
        eos = tokenizer.eos_token_id
        if eos is not None and (not full_ids or full_ids[-1] != eos):
            full_ids = full_ids + [eos]
        if len(full_ids) > MAX_LENGTH:
            skipped.append({"module": row.get("module"), "reason": "longer_than_4096", "tokens": len(full_ids)})
            continue
        labels = [-100] * len(prompt_ids) + full_ids[len(prompt_ids):]
        if not any(label != -100 for label in labels):
            skipped.append({"module": row.get("module"), "reason": "no_assistant_tokens"})
            continue
        examples.append({
            "module": row.get("module"),
            "input_ids": full_ids,
            "labels": labels,
        })
    if skipped:
        raise SystemExit(f"frozen manifest cannot silently skip examples: {skipped}")
    if len(examples) < 12:
        raise SystemExit(f"only {len(examples)} examples fit in {MAX_LENGTH} tokens")
    (OUT / "skipped.jsonl").write_text(
        "".join(json.dumps(row) + "\n" for row in skipped), encoding="utf-8")
    optimizer = torch.optim.AdamW((p for p in model.parameters() if p.requires_grad), lr=LR)
    steps_per_epoch = (len(examples) + GRAD_ACCUM - 1) // GRAD_ACCUM
    total_steps = steps_per_epoch * EPOCHS
    print(f"examples {len(examples)} skipped {len(skipped)} steps {total_steps} targets {found}", flush=True)
    log = []
    step = 0
    optimizer.zero_grad(set_to_none=True)
    started = time.perf_counter()
    for epoch in range(EPOCHS):
        order = torch.randperm(len(examples)).tolist()
        running = 0.0
        micro = 0
        for index, example_index in enumerate(order, start=1):
            example = examples[example_index]
            batch = torch.tensor([example["input_ids"]], device="cuda")
            labels = torch.tensor([example["labels"]], device="cuda")
            outputs = model(input_ids=batch, attention_mask=torch.ones_like(batch))
            logits = outputs.logits if hasattr(outputs, "logits") else outputs[0]
            loss = F.cross_entropy(
                logits[:, :-1].reshape(-1, logits.shape[-1]).float(),
                labels[:, 1:].reshape(-1),
                ignore_index=-100)
            (loss / GRAD_ACCUM).backward()
            running += float(loss.detach())
            micro += 1
            boundary = index % GRAD_ACCUM == 0 or index == len(order)
            if boundary:
                torch.nn.utils.clip_grad_norm_((p for p in model.parameters() if p.requires_grad), 1.0)
                optimizer.step()
                optimizer.zero_grad(set_to_none=True)
                step += 1
                mean = running / micro
                record = {"epoch": epoch, "step": step, "loss": mean, "microbatches": micro,
                          "seconds": time.perf_counter() - started}
                log.append(record)
                print(f"epoch {epoch} step {step}/{total_steps} loss {mean:.4f}", flush=True)
                running = 0.0
                micro = 0
        adapter = OUT / f"adapter-epoch-{epoch}"
        model.save_pretrained(adapter)
        tokenizer.save_pretrained(adapter)
    final = OUT / "adapter"
    model.save_pretrained(final)
    tokenizer.save_pretrained(final)
    (OUT / "train_log.json").write_text(json.dumps({
        "rank": RANK, "alpha": ALPHA, "dropout": DROPOUT, "epochs": EPOCHS, "lr": LR,
        "grad_accum": GRAD_ACCUM, "max_length": MAX_LENGTH, "targets": found,
        "examples": [row["module"] for row in examples], "skipped": skipped,
        "log": log, "seconds": time.perf_counter() - started,
        "revision": REVISION,
        "audit": audit,
    }, indent=2) + "\n", encoding="utf-8")
    print("TRAIN_DONE", final, flush=True)


if __name__ == "__main__":
    os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
    main()
