#!/usr/bin/env python3
"""Generate RTL candidates with official RTLCoder-v1.1 (CPU GGUF).

ecs05 has no GPU. This uses the authors' CPU release:
ishorn5/RTLCoder-v1.1-gguf-4bit (Mistral-v0.1, Q4_0).
Label results as RTLCoder-v1.1 4-bit GGUF, not DeepSeek-v1.1 GPU.

Uses the same prompts and attempt layout as the Llama baseline.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROMPT_DIR = ROOT / "experiments" / "prompts"
MODEL_DIR = ROOT / "models"
HF_REPO = "ishorn5/RTLCoder-v1.1-gguf-4bit"
HF_FILE = "ggml-model-q4_0.gguf"
MODEL_ID = "ishorn5/RTLCoder-v1.1"
MODEL_TAG = "rtlcoder-v1.1-gguf-4bit"
CIRCUITS = ("cdc_2phase", "async_fifo", "apbxclk")
PROMPT_TYPES = ("functional", "cdc_explicit")


def next_attempt_dir(base: Path) -> Path:
    existing = [
        int(path.name.split("-")[1])
        for path in base.glob("attempt-*")
        if path.name.split("-")[-1].isdigit()
    ]
    attempt = max(existing, default=0) + 1
    return base / f"attempt-{attempt:03d}"


def extract_verilog(text: str) -> str:
    """RTLCoder-Deepseek post-process from the official README, plus fence extraction."""
    blocks = re.findall(r"```(?:systemverilog|verilog|sv|v)?\s*(.*?)```", text, flags=re.S)
    s_full = max(blocks, key=len) if blocks else text

    if len(s_full.split("endmodulemodule", 1)) == 2:
        s = s_full.split("endmodulemodule", 1)[0] + "\nendmodule"
    elif "endmodule" in s_full:
        s = s_full.rsplit("endmodule", 1)[0] + "\nendmodule"
    else:
        s = s_full.strip()

    if s.find("top_module") != -1:
        s = s.split("top_module", 1)[0]
        if "endmodule" in s:
            s = s.rsplit("endmodule", 1)[0] + "\nendmodule"

    index = s.rfind("tb_module")
    if index == -1:
        index = s.find("testbench")
    if index != -1:
        s_tmp = s[:index]
        if "endmodule" in s_tmp:
            s = s_tmp.rsplit("endmodule", 1)[0] + "\nendmodule"

    return s.strip() + "\n"


def wrap_prompt(prompt: str) -> str:
    # Official RTLCoder-v1.1 (Mistral) demo feeds the instruction as-is.
    return prompt if prompt.endswith("\n") else prompt + "\n"


def ensure_model() -> Path:
    path = MODEL_DIR / HF_FILE
    if path.exists() and path.stat().st_size > 1_000_000:
        return path
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    from huggingface_hub import hf_hub_download

    downloaded = hf_hub_download(repo_id=HF_REPO, filename=HF_FILE, local_dir=str(MODEL_DIR))
    return Path(downloaded)


def load_llm(model_path: Path, n_ctx: int, n_threads: int, max_tokens: int, temperature: float, top_p: float):
    from llama_cpp import Llama

    return Llama(
        model_path=str(model_path),
        n_ctx=n_ctx,
        n_threads=n_threads,
        n_gpu_layers=0,
        verbose=False,
    )


def generate_one(llm, circuit: str, prompt_type: str, args) -> Path:
    prompt_path = PROMPT_DIR / f"{circuit}.{prompt_type}.md"
    prompt = prompt_path.read_text()
    wrapped = wrap_prompt(prompt)

    out_dir = next_attempt_dir(ROOT / "experiments" / MODEL_TAG / circuit / prompt_type)
    out_dir.mkdir(parents=True, exist_ok=False)
    generated_dir = out_dir / "generated"
    generated_dir.mkdir()
    shutil.copy2(prompt_path, out_dir / "prompt.md")
    (out_dir / "request.txt").write_text(wrapped)

    print(f"RTLCoder {circuit}/{prompt_type} -> {out_dir.name}", flush=True)
    started = time.time()
    result = llm(
        wrapped,
        max_tokens=args.max_tokens,
        temperature=args.temperature,
        top_p=args.top_p,
        stop=["<|EOT|>", "### Instruction:"],
    )
    elapsed = time.time() - started
    content = result["choices"][0]["text"]
    (out_dir / "response.json").write_text(json.dumps(result, indent=2) + "\n")
    (out_dir / "response.txt").write_text(content if content.endswith("\n") else content + "\n")
    (generated_dir / f"{circuit}.v").write_text(extract_verilog(content))

    usage = result.get("usage", {})
    metadata = {
        "provider": "local-gguf",
        "model": MODEL_ID,
        "quantization": "Q4_0",
        "gguf_file": HF_FILE,
        "gguf_source": f"{HF_REPO}/{HF_FILE}",
        "prompt_type": prompt_type,
        "circuit": circuit,
        "prompt_file": str(prompt_path.relative_to(ROOT)),
        "temperature": args.temperature,
        "top_p": args.top_p,
        "max_tokens": args.max_tokens,
        "n_ctx": args.n_ctx,
        "n_threads": args.n_threads,
        "elapsed_s": round(elapsed, 3),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "prompt_tokens": usage.get("prompt_tokens"),
        "completion_tokens": usage.get("completion_tokens"),
        "total_tokens": usage.get("total_tokens"),
        "note": (
            "Official CPU GGUF of RTLCoder-v1.1 (Mistral) because ecs05 has no GPU. "
            "Same prompts as the Llama 3.3 70B baseline."
        ),
    }
    (out_dir / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(f"  wrote {out_dir} in {elapsed:.1f}s", flush=True)
    return out_dir


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("circuit", nargs="?", choices=CIRCUITS)
    parser.add_argument("prompt_type", nargs="?", choices=PROMPT_TYPES)
    parser.add_argument("--all", action="store_true", help="Run all 18 pilot generations.")
    parser.add_argument("--repeats", type=int, default=1, help="Attempts per circuit/prompt in this run.")
    parser.add_argument("--temperature", type=float, default=0.2)
    parser.add_argument("--top-p", type=float, default=0.95)
    parser.add_argument("--max-tokens", type=int, default=2048)
    parser.add_argument("--n-ctx", type=int, default=4096)
    parser.add_argument("--n-threads", type=int, default=16)
    args = parser.parse_args()

    if args.all:
        jobs = []
        for circuit in CIRCUITS:
            for prompt_type in PROMPT_TYPES:
                have = len(list((ROOT / "experiments" / MODEL_TAG / circuit / prompt_type).glob("attempt-*")))
                jobs.extend([(circuit, prompt_type)] * max(0, 3 - have))
        if not jobs:
            print("All 18 RTLCoder attempts already exist.")
            return 0
    else:
        if not args.circuit or not args.prompt_type:
            parser.error("provide circuit and prompt_type, or use --all")
        jobs = [(args.circuit, args.prompt_type) for _ in range(args.repeats)]

    print(f"Downloading/loading {HF_FILE} ...", flush=True)
    model_path = ensure_model()
    llm = load_llm(model_path, args.n_ctx, args.n_threads, args.max_tokens, args.temperature, args.top_p)
    print("Model ready.", flush=True)

    for circuit, prompt_type in jobs:
        generate_one(llm, circuit, prompt_type, args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
