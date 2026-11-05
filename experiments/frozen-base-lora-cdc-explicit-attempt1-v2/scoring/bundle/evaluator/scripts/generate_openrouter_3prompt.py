#!/usr/bin/env python3
"""Generate missing functional + cdc_explicit RTL for Llama 70B and Qwen 32B.

Observable 440+440 already exists under multi-llm-observable-v1.
This writes the other two prompts into experiments/multi-llm-3prompt-v1.
Generation only — no Xcelium / Jasper. Resumable: skips existing generated/*.v.
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from run_multi_llm_passk import (  # noqa: E402
    CIRCUITS,
    model_tag,
    write_generation,
)

MODELS = (
    "meta-llama/llama-3.3-70b-instruct",
    "qwen/qwen-2.5-coder-32b-instruct",
)
PROMPTS = ("functional", "cdc_explicit")
DEFAULT_OUT = ROOT / "experiments/multi-llm-3prompt-v1"
PASSK = ROOT / "experiments/multi-llm-passk/openrouter"


def reuse_passk(dest_root: Path) -> int:
    copied = 0
    if not PASSK.is_dir():
        return 0
    for src in PASSK.glob("*/*/*/attempt-???/generated/*.v"):
        model, circuit, prompt, attempt = src.relative_to(PASSK).parts[:4]
        if prompt not in PROMPTS:
            continue
        dest = dest_root / "openrouter" / model / circuit / prompt / attempt
        if (dest / "generated" / src.name).exists():
            continue
        dest.mkdir(parents=True, exist_ok=True)
        shutil.copytree(src.parents[1], dest, dirs_exist_ok=True)
        copied += 1
    return copied


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--attempts", type=int, default=10)
    parser.add_argument("--temperature", type=float, default=0.2)
    parser.add_argument("--top-p", type=float, default=0.95)
    parser.add_argument("--max-tokens", type=int, default=8192)
    parser.add_argument("--api-timeout", type=int, default=240)
    parser.add_argument("--output-root", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--reuse-passk", action="store_true", default=True)
    parser.add_argument("--no-reuse-passk", action="store_false", dest="reuse_passk")
    args = parser.parse_args()

    api_key = os.environ.get("OPENROUTER_API_KEY", "")
    if not api_key:
        print("ERROR: set OPENROUTER_API_KEY in this shell first.", file=sys.stderr)
        print("  export OPENROUTER_API_KEY='...'", file=sys.stderr)
        print("  setenv OPENROUTER_API_KEY '...'", file=sys.stderr)
        return 1

    if args.reuse_passk:
        n = reuse_passk(args.output_root)
        print(f"Reused {n} existing passk attempts", flush=True)

    todo = 0
    done = 0
    failed = 0
    for model in MODELS:
        tag = model_tag(model)
        for circuit in CIRCUITS:
            for prompt in PROMPTS:
                prompt_path = ROOT / "experiments/prompts" / f"{circuit}.{prompt}.md"
                if not prompt_path.exists():
                    print(f"MISSING PROMPT {prompt_path}", file=sys.stderr)
                    continue
                base = args.output_root / "openrouter" / tag / circuit / prompt
                for attempt in range(1, args.attempts + 1):
                    attempt_dir = base / f"attempt-{attempt:03d}"
                    rtl = next(attempt_dir.glob("generated/*.v"), None) if attempt_dir.exists() else None
                    if rtl is not None:
                        done += 1
                        continue
                    todo += 1
                    print(
                        f"GENERATE {tag} {circuit}/{prompt} {attempt:03d}",
                        flush=True,
                    )
                    try:
                        if attempt_dir.exists():
                            shutil.rmtree(attempt_dir)
                        write_generation(
                            attempt_dir=attempt_dir,
                            circuit=circuit,
                            prompt_type=prompt,
                            prompt_path=prompt_path,
                            provider="openrouter",
                            model=model,
                            attempt=attempt,
                            temperature=args.temperature,
                            top_p=args.top_p,
                            max_tokens=args.max_tokens,
                            timeout=args.api_timeout,
                            api_key=api_key,
                        )
                        done += 1
                    except Exception as exc:
                        failed += 1
                        print(f"  API ERROR: {exc}", file=sys.stderr, flush=True)
                        if "401" in str(exc) or "Missing Authentication" in str(exc):
                            print(
                                "STOP: OpenRouter 401. Kill this job. "
                                "setenv OPENROUTER_API_KEY to the sk-or-v1- token only "
                                "(no 'pilot:' prefix, no spaces).",
                                file=sys.stderr,
                                flush=True,
                            )
                            return 1
                        continue
    print(f"DONE skipped+ok={done} failed={failed} newly_attempted={todo}")
    return 0 if failed == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
