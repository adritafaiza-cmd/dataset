#!/usr/bin/env python3
"""Run the frozen 18-attempt pilot through OpenRouter.

Same prompts, temperature, and attempt count as Llama 3.3 70B.
Does not edit generated RTL.
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GENERATE = ROOT / "scripts" / "generate_openrouter.py"
CIRCUITS = ["cdc_2phase", "async_fifo", "apbxclk"]
PROMPT_TYPES = ["functional", "cdc_explicit"]
ATTEMPTS = 3


def remaining_jobs(model_tag: str) -> list[tuple[str, str]]:
    jobs: list[tuple[str, str]] = []
    base = ROOT / "experiments" / model_tag
    for circuit in CIRCUITS:
        for prompt_type in PROMPT_TYPES:
            have = len(list((base / circuit / prompt_type).glob("attempt-*")))
            jobs.extend([(circuit, prompt_type)] * max(0, ATTEMPTS - have))
    return jobs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--model",
        default="qwen/qwen2.5-32b-instruct",
        help="OpenRouter model id",
    )
    parser.add_argument("--temperature", type=float, default=0.2)
    parser.add_argument("--top-p", type=float, default=0.95)
    parser.add_argument("--max-tokens", type=int, default=8192)
    parser.add_argument("--timeout", type=int, default=180)
    args = parser.parse_args()

    if not os.environ.get("OPENROUTER_API_KEY"):
        print("ERROR: set OPENROUTER_API_KEY in this shell first.", file=sys.stderr)
        print("tcsh:  setenv OPENROUTER_API_KEY 'your-key'", file=sys.stderr)
        print("bash:  export OPENROUTER_API_KEY='your-key'", file=sys.stderr)
        return 1

    model_tag = args.model.split("/")[-1]
    jobs = remaining_jobs(model_tag)
    print(f"Model {args.model}  remaining {len(jobs)}/18")
    if not jobs:
        print("All 18 attempts already exist.")
        return 0

    for i, (circuit, prompt_type) in enumerate(jobs, 1):
        print(f"\n===== {i}/{len(jobs)} {circuit}/{prompt_type} =====", flush=True)
        cmd = [
            sys.executable,
            str(GENERATE),
            circuit,
            prompt_type,
            "--model",
            args.model,
            "--temperature",
            str(args.temperature),
            "--top-p",
            str(args.top_p),
            "--max-tokens",
            str(args.max_tokens),
            "--timeout",
            str(args.timeout),
        ]
        completed = subprocess.run(cmd, cwd=ROOT)
        if completed.returncode != 0:
            print(f"ERROR: generation failed for {circuit}/{prompt_type}", file=sys.stderr)
            return completed.returncode
    print("\nDone. Outputs in experiments/" + model_tag)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
