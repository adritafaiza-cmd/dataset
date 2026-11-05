#!/usr/bin/env python3
"""Score every generated RTL file: compile, sim, Jasper after sim pass.

Does not stop at the first functional pass. Writes results.json per attempt
and a rolling summary JSON.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from evaluate_generated import evaluate  # noqa: E402
from evaluate_pass_at_n import run_jasper, simulate  # noqa: E402

XRUN_BIN = "/eda/cadence/XCELIUM2603/tools.lnx86/inca/bin/64bit"
JG_BIN = "/eda/cadence/JASPER/bin"


def iter_generated(model_dir: Path):
    for rtl in sorted(model_dir.glob("*/*/*/generated/*.v")):
        parts = rtl.relative_to(model_dir).parts
        if len(parts) < 4:
            continue
        circuit, prompt, attempt = parts[:3]
        if not re.fullmatch(r"attempt-\d{3}", attempt):
            continue
        yield circuit, prompt, attempt, rtl


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--model-dir",
        default="experiments/multi-llm-passk/openrouter/meta-llama__llama-3.3-70b-instruct",
    )
    parser.add_argument("--limit", type=int, default=0, help="0 = all files")
    args = parser.parse_args()

    os.environ["PATH"] = f"{XRUN_BIN}:{JG_BIN}:{os.environ.get('PATH', '')}"
    os.environ["DS"] = str(ROOT)
    model_dir = ROOT / args.model_dir
    items = list(iter_generated(model_dir))
    if args.limit:
        items = items[: args.limit]

    summary_path = model_dir / "all_generated_eval_summary.json"
    rows = []
    print(
        f"Evaluating {len(items)} generated files under {model_dir}",
        flush=True,
    )
    for i, (circuit, prompt, attempt, rtl) in enumerate(items, 1):
        att = rtl.parent.parent
        tag = f"{i}/{len(items)} {circuit}/{prompt}/{attempt}"
        try:
            result = evaluate(rtl, circuit, att)
            if result["compile_ok"]:
                sim = simulate(rtl, circuit, att)
                result.update(sim)
                if sim.get("simulate_ok"):
                    jg = run_jasper(
                        rtl, circuit, att.relative_to(ROOT / "experiments")
                    )
                    result.update(jg)
            result["prompt_type"] = prompt
            result["attempt"] = attempt
            (att / "results.json").write_text(json.dumps(result, indent=2) + "\n")
        except Exception as exc:  # keep walking; one bad file must not abort
            result = {
                "circuit": circuit,
                "prompt_type": prompt,
                "attempt": attempt,
                "rtl": str(rtl.relative_to(ROOT)),
                "compile_ok": False,
                "simulate_ok": None,
                "cdc_clean": False,
                "error": str(exc),
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
            (att / "results.json").write_text(json.dumps(result, indent=2) + "\n")
        rows.append(result)
        summary_path.write_text(json.dumps(rows, indent=2) + "\n")
        c = "C" if result.get("compile_ok") else "-"
        s = "S" if result.get("simulate_ok") else "-"
        j = "J" if result.get("cdc_clean") else "-"
        extra = result.get("sim_note") or result.get("error") or ""
        print(f"{tag}  compile={c} sim={s} cdc_clean={j}  {extra}", flush=True)

    n = len(rows)
    print(
        "DONE "
        f"n={n} compile={sum(1 for r in rows if r.get('compile_ok'))} "
        f"sim={sum(1 for r in rows if r.get('simulate_ok'))} "
        f"cdc_clean={sum(1 for r in rows if r.get('cdc_clean'))} "
        f"summary={summary_path}",
        flush=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
