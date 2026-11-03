#!/usr/bin/env python3
"""Generate Qwen2.5 RTL for the 16 repaired circuits.

This is a fresh, resumable post-repair generation set:
16 circuits x 3 prompts x 10 attempts = 480 candidates.
Generation only; evaluation is performed separately.
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from comparison_set import FIXED_16  # noqa: E402
from run_multi_llm_passk import model_tag, write_generation  # noqa: E402

MODEL = "qwen/qwen-2.5-coder-32b-instruct"
PROMPTS = ("functional", "cdc_explicit", "observable")
DEFAULT_OUT = ROOT / "experiments/qwen25-16fix-3prompt-10attempt-v1"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--circuit",
        action="append",
        choices=sorted(FIXED_16),
        help="Generate only this circuit; may be repeated. Default: all 16.",
    )
    parser.add_argument(
        "--prompt",
        action="append",
        choices=PROMPTS,
        help="Generate only this prompt; may be repeated. Default: all three.",
    )
    parser.add_argument("--attempts", type=int, default=10)
    parser.add_argument("--temperature", type=float, default=0.2)
    parser.add_argument("--top-p", type=float, default=0.95)
    parser.add_argument("--max-tokens", type=int, default=8192)
    parser.add_argument("--api-timeout", type=int, default=240)
    parser.add_argument("--output-root", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()

    if not 1 <= args.attempts <= 10:
        parser.error("--attempts must be between 1 and 10")

    api_key = os.environ.get("OPENROUTER_API_KEY", "")
    if not api_key:
        print("ERROR: set OPENROUTER_API_KEY before running.", file=sys.stderr)
        return 1

    circuits = sorted(args.circuit or FIXED_16)
    prompts = args.prompt or list(PROMPTS)
    provider_root = args.output_root / "openrouter" / model_tag(MODEL)

    generated = skipped = failed = 0
    total = len(circuits) * len(prompts) * args.attempts
    index = 0
    for circuit in circuits:
        for prompt in prompts:
            prompt_path = ROOT / "experiments/prompts" / f"{circuit}.{prompt}.md"
            if not prompt_path.is_file():
                raise FileNotFoundError(prompt_path)
            for attempt in range(1, args.attempts + 1):
                index += 1
                attempt_dir = (
                    provider_root
                    / circuit
                    / prompt
                    / f"attempt-{attempt:03d}"
                )
                existing = (
                    list((attempt_dir / "generated").glob("*.v"))
                    + list((attempt_dir / "generated").glob("*.sv"))
                    if attempt_dir.is_dir()
                    else []
                )
                if existing:
                    skipped += 1
                    print(
                        f"{index}/{total} SKIP {circuit}/{prompt}/{attempt:03d}",
                        flush=True,
                    )
                    continue
                if attempt_dir.exists():
                    shutil.rmtree(attempt_dir)
                print(
                    f"{index}/{total} GENERATE {circuit}/{prompt}/{attempt:03d}",
                    flush=True,
                )
                try:
                    write_generation(
                        attempt_dir=attempt_dir,
                        circuit=circuit,
                        prompt_type=prompt,
                        prompt_path=prompt_path,
                        provider="openrouter",
                        model=MODEL,
                        attempt=attempt,
                        temperature=args.temperature,
                        top_p=args.top_p,
                        max_tokens=args.max_tokens,
                        timeout=args.api_timeout,
                        api_key=api_key,
                    )
                    generated += 1
                except Exception as exc:
                    failed += 1
                    print(f"API ERROR: {exc}", file=sys.stderr, flush=True)
                    if "401" in str(exc) or "Missing Authentication" in str(exc):
                        print("STOP: OpenRouter authentication failed.", file=sys.stderr)
                        return 1

    print(
        f"DONE total={total} generated={generated} skipped={skipped} failed={failed}",
        flush=True,
    )
    return 0 if failed == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
