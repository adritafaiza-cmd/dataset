#!/usr/bin/env python3
"""Generate direct Qwen RTL candidates from frozen prompts, without repair."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import fcntl
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import platform
import re
import subprocess
import time
import uuid

MODEL = str(Path(__file__).resolve().parents[1] / "models/Qwen3.5-9B")
REVISION = json.loads((Path(MODEL) / "provenance.json").read_text())["revision"]
TYPES = ("functional", "cdc_explicit", "observable")
SETTINGS = dict(do_sample=True, temperature=0.2, top_p=0.95, top_k=0,
                max_new_tokens=8192, num_beams=1, num_return_sequences=1,
                repetition_penalty=1.0, use_cache=True)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def command(argv):
    result = subprocess.run(argv, capture_output=True, text=True, timeout=30)
    return {"returncode": result.returncode, "stdout": result.stdout, "stderr": result.stderr}


def extract_rtl(response):
    # Only remove Markdown fence wrappers. Preserve malformed/truncated RTL,
    # multiple modules and raw unfenced output; never add or repair source text.
    blocks = re.findall(r"^```(?:verilog|systemverilog|sv|v)?[ \t]*\r?\n(.*?)^```[ \t]*$",
                        response, flags=re.M | re.S | re.I)
    if blocks:
        return "\n".join(blocks), "all_supported_fenced_blocks"
    return response, "verbatim_response"


def complete(path, identity):
    marker = path / "complete.json"
    if not marker.exists():
        return False
    record = json.loads(marker.read_text())
    if record.get("identity") != identity:
        raise RuntimeError(f"Completed attempt has a different configuration: {path}")
    expected = {"prompt.md", "request.txt", "response.txt", "response.json", "metadata.json",
                f"generated/{identity['circuit']}.sv"}
    hashes = record.get("sha256", {})
    return set(hashes) == expected and all(
        (path / name).is_file() and sha((path / name).read_bytes()) == digest
        for name, digest in hashes.items())


def plan(repo, output, selected=None, attempts=10):
    prompt_dir = repo / "experiments/prompts"
    circuits = sorted({p.name.removesuffix(f".{kind}.md")
                       for kind in TYPES for p in prompt_dir.glob(f"*.{kind}.md")})
    if selected is not None:
        unknown = set(selected) - set(circuits)
        if unknown:
            raise ValueError(f"Unknown circuits: {sorted(unknown)}")
        circuits = selected
    if not circuits:
        raise RuntimeError(f"No frozen prompts in {prompt_dir}")
    jobs = []
    for circuit in circuits:
        for kind in TYPES:
            source = prompt_dir / f"{circuit}.{kind}.md"
            prompt = source.read_bytes()  # Missing counterpart is a hard error.
            if not prompt.strip():
                raise RuntimeError(f"Empty prompt: {source}")
            prompt.decode("utf-8")
            for seed in range(1, attempts + 1):
                identity = dict(model=MODEL, revision=REVISION, precision="bfloat16",
                                circuit=circuit, prompt_type=kind, seed=seed,
                                prompt_sha256=sha(prompt), settings=SETTINGS,
                                script_sha256=sha(Path(__file__).read_bytes()),
                                prompt_profile="pinned_tokenizer_chat_template_thinking_disabled")
                path = output / circuit / kind / f"attempt-{seed:03d}"
                jobs.append((source, prompt, path, identity))
    return circuits, jobs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path, default=Path("experiments/qwen-direct"))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--rank", type=int, default=0)
    parser.add_argument("--world-size", type=int, default=1)
    parser.add_argument("--smoke", action="store_true")
    parser.add_argument("--circuits", nargs="+")
    parser.add_argument("--attempts", type=int, default=1)
    args = parser.parse_args()
    if args.attempts < 1:
        parser.error("--attempts must be positive")
    repo = args.repo.resolve()
    output = args.output if args.output.is_absolute() else repo / args.output
    circuits, jobs = plan(repo, output, args.circuits, args.attempts)
    if not 0 <= args.rank < args.world_size:
        parser.error("rank must be within world-size")
    jobs = [job for index, job in enumerate(jobs) if (index // args.attempts) % args.world_size == args.rank]
    if args.smoke:
        jobs = jobs[:1]
    pending = [job for job in jobs if not complete(job[2], job[3])]
    print(f"{len(circuits)} circuits x {len(TYPES)} prompt types x {args.attempts} seeds = {len(jobs)} attempts; "
          f"{len(jobs)-len(pending)} completed, {len(pending)} pending", flush=True)
    if args.dry_run or not pending:
        return
    output.mkdir(parents=True, exist_ok=True)
    with (output / f".generation-rank-{args.rank}.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        run(repo, output, jobs)


def run(repo, output, jobs):
    os.environ.setdefault("CUBLAS_WORKSPACE_CONFIG", ":4096:8")
    import torch
    import transformers
    from transformers import Qwen3_5ForConditionalGeneration, AutoTokenizer, GenerationConfig, set_seed

    if not torch.cuda.is_available() or torch.cuda.device_count() != 1:
        raise RuntimeError("Exactly one visible NVIDIA GPU is required")
    torch.use_deterministic_algorithms(True)
    torch.backends.cuda.matmul.allow_tf32 = False
    torch.backends.cudnn.allow_tf32 = False
    torch.backends.cudnn.benchmark = False
    torch.backends.cudnn.deterministic = True
    started = time.perf_counter()
    tokenizer = AutoTokenizer.from_pretrained(MODEL, revision=REVISION, trust_remote_code=False)
    if not tokenizer.chat_template:
        raise RuntimeError("Pinned tokenizer has no chat template")
    model = Qwen3_5ForConditionalGeneration.from_pretrained(
        MODEL, revision=REVISION, dtype=torch.bfloat16, device_map={"": 0},
        attn_implementation="sdpa", trust_remote_code=False).eval()
    if any(p.device.type != "cuda" or p.dtype != torch.bfloat16 for p in model.parameters()):
        raise RuntimeError("All model parameters must be BF16 on the allocated GPU")
    torch.cuda.synchronize()
    load_seconds = time.perf_counter() - started
    eos = model.generation_config.eos_token_id
    if eos is None:
        raise RuntimeError("Pinned model does not specify EOS")
    eos_ids = eos if isinstance(eos, list) else [eos]
    generation = GenerationConfig(**SETTINGS, eos_token_id=eos,
                                  pad_token_id=tokenizer.pad_token_id or eos_ids[0],
                                  bos_token_id=model.generation_config.bos_token_id)
    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
    run_dir = output / "runs" / run_id
    run_dir.mkdir(parents=True)
    props = torch.cuda.get_device_properties(0)
    environment = dict(
        run_id=run_id, timestamp_utc=datetime.now(timezone.utc).isoformat(),
        hostname=platform.node(), python=platform.python_version(), platform=platform.platform(),
        torch=torch.__version__, transformers=transformers.__version__, cuda=torch.version.cuda,
        cudnn=torch.backends.cudnn.version(), gpu_name=props.name,
        gpu_memory_bytes=props.total_memory, gpu_compute_capability=list(torch.cuda.get_device_capability(0)),
        nvidia_smi=command(["nvidia-smi"]), model_load_seconds=load_seconds,
        git_head=command(["git", "-C", str(repo), "rev-parse", "HEAD"]),
        git_status=command(["git", "-C", str(repo), "status", "--porcelain"]),
        packages=sorted(f"{d.metadata['Name']}=={d.version}" for d in importlib.metadata.distributions()),
        slurm={k: v for k, v in os.environ.items() if k.startswith("SLURM_")},
        cuda_visible_devices=os.environ.get("CUDA_VISIBLE_DEVICES"),
        deterministic_algorithms=True, attention_implementation="sdpa",
        generation_config=generation.to_dict(), chat_template=tokenizer.chat_template)
    write_json(run_dir / "environment.json", environment)
    # Validate all input lengths before generating anything; never truncate prompts.
    requests = {}
    for source, prompt, _, _ in jobs:
        if source in requests:
            continue
        request = tokenizer.apply_chat_template(
            [{"role": "user", "content": prompt.decode("utf-8")}],
            tokenize=False, add_generation_prompt=True, enable_thinking=False)
        encoded = tokenizer(request, add_special_tokens=False, return_tensors="pt", truncation=False)
        count = encoded.input_ids.shape[1]
        if count + SETTINGS["max_new_tokens"] > model.config.text_config.max_position_embeddings:
            raise RuntimeError(f"Prompt plus generation exceeds context: {source} ({count} tokens)")
        requests[source] = request, encoded
    for source, prompt, target, identity in jobs:
        if complete(target, identity):
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            target.rename(target.with_name(target.name + ".incomplete-" + uuid.uuid4().hex))
        target.mkdir()
        (target / "generated").mkdir()
        (target / "prompt.md").write_bytes(prompt)
        request, encoded = requests[source]
        (target / "request.txt").write_text(request, encoding="utf-8")
        inputs = {key: value.to("cuda:0") for key, value in encoded.items()}
        set_seed(identity["seed"])
        torch.cuda.reset_peak_memory_stats()
        torch.cuda.synchronize()
        start = time.perf_counter()
        print(f"Generating {identity['circuit']}/{identity['prompt_type']}/seed-{identity['seed']}", flush=True)
        with torch.inference_mode():
            sequence = model.generate(**inputs, generation_config=generation)
        torch.cuda.synchronize()
        elapsed = time.perf_counter() - start
        token_ids = sequence[0, inputs["input_ids"].shape[1]:].tolist()
        response = tokenizer.decode(token_ids, skip_special_tokens=False, clean_up_tokenization_spaces=False)
        # Remove only a terminal model EOS token from the extraction input.
        ended = bool(token_ids and token_ids[-1] in eos_ids)
        content = tokenizer.decode(token_ids[:-1] if ended else token_ids,
                                   skip_special_tokens=False, clean_up_tokenization_spaces=False)
        rtl, extraction = extract_rtl(content)
        (target / "response.txt").write_text(response, encoding="utf-8")
        write_json(target / "response.json", dict(token_ids=token_ids, text=response))
        (target / "generated" / f"{identity['circuit']}.sv").write_text(rtl, encoding="utf-8")
        write_json(target / "metadata.json", dict(
            **identity, run_id=run_id, environment_file=str((run_dir / "environment.json").relative_to(output)),
            timestamp_utc=datetime.now(timezone.utc).isoformat(), runtime_seconds=elapsed,
            prompt_file=str(source.relative_to(repo)), request_sha256=sha(request.encode()),
            input_tokens=inputs["input_ids"].shape[1], output_tokens=len(token_ids),
            termination_reason="eos" if ended else "max_new_tokens", extraction=extraction,
            gpu_name=props.name, peak_gpu_memory_bytes=torch.cuda.max_memory_allocated(),
            evaluation_status="not_evaluated", repaired=False))
        hashes = {str(p.relative_to(target)): sha(p.read_bytes())
                  for p in target.rglob("*") if p.is_file()}
        temporary = target / "complete.json.tmp"
        write_json(temporary, dict(identity=identity, sha256=hashes))
        temporary.replace(target / "complete.json")  # Atomic completion marker, written last.
        print(f"Saved {target} ({elapsed:.2f}s, {len(token_ids)} tokens)", flush=True)
    write_json(run_dir / "summary.json", dict(total=len(jobs), completed=sum(
        complete(path, identity) for _, _, path, identity in jobs),
        timestamp_utc=datetime.now(timezone.utc).isoformat()))


if __name__ == "__main__":
    main()
