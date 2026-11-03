#!/usr/bin/env python3
"""Generate one RTL candidate from an OpenRouter chat model."""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROMPT_DIR = ROOT / "experiments" / "prompts"


def next_attempt_dir(base: Path) -> Path:
    existing = [
        int(path.name.split("-")[1])
        for path in base.glob("attempt-*")
        if path.name.split("-")[-1].isdigit()
    ]
    attempt = max(existing, default=0) + 1
    return base / f"attempt-{attempt:03d}"


def extract_verilog(text: str) -> str:
    blocks = re.findall(r"```(?:systemverilog|verilog|sv|v)?\s*(.*?)```", text, flags=re.S)
    if blocks:
        return max(blocks, key=len).strip() + "\n"
    return text.strip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("circuit", choices=["cdc_2phase", "async_fifo", "apbxclk"])
    parser.add_argument("prompt_type", choices=["functional", "cdc_explicit"])
    parser.add_argument(
        "--model",
        default=os.environ.get("OPENROUTER_MODEL", "meta-llama/llama-3.3-70b-instruct"),
    )
    parser.add_argument("--temperature", type=float, default=0.2)
    parser.add_argument("--top-p", type=float, default=0.95)
    parser.add_argument("--max-tokens", type=int, default=4096)
    parser.add_argument("--timeout", type=int, default=90)
    args = parser.parse_args()

    api_key = os.environ.get("OPENROUTER_API_KEY")
    if not api_key:
        print("ERROR: set OPENROUTER_API_KEY first.", file=sys.stderr)
        return 1

    prompt_path = PROMPT_DIR / f"{args.circuit}.{args.prompt_type}.md"
    prompt = prompt_path.read_text()

    model_tag = args.model.split("/")[-1]
    out_dir = next_attempt_dir(
        ROOT / "experiments" / model_tag / args.circuit / args.prompt_type
    )
    out_dir.mkdir(parents=True, exist_ok=False)
    generated_dir = out_dir / "generated"
    generated_dir.mkdir()
    shutil.copy2(prompt_path, out_dir / "prompt.md")

    payload = {
        "model": args.model,
        "temperature": args.temperature,
        "top_p": args.top_p,
        "max_tokens": args.max_tokens,
        "messages": [{"role": "user", "content": prompt}],
    }
    payload_path = out_dir / "request.json"
    payload_path.write_text(json.dumps(payload) + "\n")

    print(
        f"Calling {args.model} for {args.circuit}/{args.prompt_type} "
        f"(timeout {args.timeout}s) ...",
        flush=True,
    )
    started = time.time()
    completed = subprocess.run(
        [
            "curl",
            "-sS",
            "-X",
            "POST",
            "https://openrouter.ai/api/v1/chat/completions",
            "--connect-timeout",
            "15",
            "--max-time",
            str(args.timeout),
            "-H",
            f"Authorization: Bearer {api_key}",
            "-H",
            "Content-Type: application/json",
            "-H",
            "HTTP-Referer: https://github.com/adritafaiza-cmd/dataset",
            "-H",
            "X-Title: CDC RTL generation pilot",
            "--data-binary",
            f"@{payload_path}",
            "-w",
            "\n%{http_code}",
        ],
        capture_output=True,
        text=True,
    )
    elapsed = time.time() - started

    if completed.returncode != 0:
        print(completed.stderr.strip() or "ERROR: curl failed", file=sys.stderr)
        print(f"Timed out or failed after {elapsed:.1f}s. Retry the same command.", file=sys.stderr)
        return 1

    body, _, status_text = completed.stdout.rpartition("\n")
    status = int(status_text or "0")
    (out_dir / "response.json").write_text(body + "\n")
    if status != 200:
        print(f"ERROR: OpenRouter returned HTTP {status}", file=sys.stderr)
        print(body, file=sys.stderr)
        return 1

    data = json.loads(body)
    content = data["choices"][0]["message"]["content"]
    (out_dir / "response.txt").write_text(content if content.endswith("\n") else content + "\n")
    (generated_dir / f"{args.circuit}.v").write_text(extract_verilog(content))

    usage = data.get("usage", {})
    metadata = {
        "provider": "openrouter",
        "model": data.get("model", args.model),
        "requested_model": args.model,
        "prompt_type": args.prompt_type,
        "circuit": args.circuit,
        "prompt_file": str(prompt_path.relative_to(ROOT)),
        "temperature": args.temperature,
        "top_p": args.top_p,
        "max_tokens": args.max_tokens,
        "http_status": status,
        "elapsed_s": round(elapsed, 3),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "prompt_tokens": usage.get("prompt_tokens"),
        "completion_tokens": usage.get("completion_tokens"),
        "total_tokens": usage.get("total_tokens"),
    }
    (out_dir / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(f"Wrote {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
