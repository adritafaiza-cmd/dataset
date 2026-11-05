#!/usr/bin/env python3
"""Functional testbench for the 44 golden circuits and generated RTL, using Icarus."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from evaluate_icarus_observable import evaluate  # noqa: E402
from evaluate_generated import top_rtl_for  # noqa: E402

OUT = ROOT / "experiments/icarus_benchmark.json"
FENCE = re.compile(r"^\s*```[a-zA-Z0-9_-]*\s*\n|\n```\s*$", re.M)

ROOTS = [
    ROOT / "experiments/complexvcoder-3prompt-10attempt-v1",
    ROOT / "experiments/rtlcoder-deepseek-3prompt-10attempt-v1",
    ROOT / "experiments/qwen35-3prompt-10attempt-v1",
    ROOT / "experiments/llama-16fix-3prompt-10attempt-v1",
    ROOT / "experiments/multi-llm-3prompt-v1/openrouter",
    ROOT / "experiments/multi-llm-observable-v1/openrouter",
]


def circuits() -> set[str]:
    return {
        p.name
        for p in (ROOT / "benchmarks").iterdir()
        if (p / "manifest.yaml").is_file()
    }


def rows() -> list[dict]:
    known = circuits()
    out = []
    for ckt in sorted(known):
        rtl = top_rtl_for(ckt)
        out.append(
            {
                "model": "golden",
                "circuit": ckt,
                "prompt": "golden",
                "attempt": "fixed",
                "rtl": rtl,
            }
        )
    for exp in ROOTS:
        if not exp.is_dir():
            continue
        files = list(exp.rglob("generated/*.v")) + list(exp.rglob("generated/*.sv"))
        for rtl in sorted(files):
            if "archive" in rtl.parts:
                continue
            parts = rtl.relative_to(exp).parts
            circuit = next((part for part in parts if part in known), None)
            if circuit is None:
                continue
            idx = parts.index(circuit)
            if idx + 2 >= len(parts):
                continue
            prompt, attempt = parts[idx + 1], parts[idx + 2]
            model = parts[idx - 1] if idx > 0 else exp.name
            if prompt not in {"functional", "cdc_explicit", "observable"}:
                continue
            out.append(
                {
                    "model": model,
                    "circuit": circuit,
                    "prompt": prompt,
                    "attempt": attempt,
                    "rtl": rtl,
                }
            )
    return out


def compile_source(rtl: Path, work: Path) -> Path:
    text = rtl.read_text(errors="replace")
    stripped = FENCE.sub("", text).strip() + "\n"
    if stripped == text:
        return rtl
    dest = work / rtl.name
    dest.write_text(stripped)
    return dest


def main() -> int:
    items = rows()
    done = []
    if OUT.is_file():
        prev = json.loads(OUT.read_text())
        done = prev.get("results") or []
    seen = {
        (r["model"], r["circuit"], r.get("prompt") or r.get("prompt_type"), r["attempt"])
        for r in done
    }
    pending = [
        r
        for r in items
        if (r["model"], r["circuit"], r["prompt"], r["attempt"]) not in seen
    ]
    print(f"TOTAL={len(items)} done={len(done)} pending={len(pending)}", flush=True)
    for i, row in enumerate(pending, 1):
        work = (
            ROOT
            / "build/icarus-benchmark"
            / row["model"]
            / row["circuit"]
            / row["prompt"]
            / row["attempt"]
        )
        work.mkdir(parents=True, exist_ok=True)
        source = compile_source(row["rtl"], work)
        try:
            result = evaluate(
                row["model"],
                row["circuit"],
                row["prompt"],
                row["attempt"],
                source,
                90,
            )
        except Exception as exc:
            result = {
                "model": row["model"],
                "circuit": row["circuit"],
                "prompt_type": row["prompt"],
                "attempt": row["attempt"],
                "compile_ok": None,
                "simulate_ok": None,
                "tool_error": True,
                "strict_pass": False,
                "error": f"{type(exc).__name__}: {exc}",
            }
        result["rtl"] = str(row["rtl"].relative_to(ROOT))
        result["model"] = row["model"]
        done.append(result)
        OUT.write_text(json.dumps({"n": len(done), "results": done}, indent=2) + "\n")
        print(
            f"{i}/{len(pending)} {row['model']} {row['circuit']} {row['prompt']}/{row['attempt']} "
            f"compile={result.get('compile_ok')} functional={result.get('simulate_ok')} "
            f"{result.get('error', '')}",
            flush=True,
        )
    print(
        f"DONE n={len(done)} "
        f"compile={sum(r.get('compile_ok') is True for r in done)} "
        f"functional={sum(r.get('simulate_ok') is True for r in done)}",
        flush=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
