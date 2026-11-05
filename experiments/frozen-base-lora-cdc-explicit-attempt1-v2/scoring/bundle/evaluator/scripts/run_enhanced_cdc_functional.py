#!/usr/bin/env python3
"""Run enhanced CDC TBs only on generated RTL that compiled and passed sim."""

from __future__ import annotations

import json
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "enhanced_cdc_tb"))
from run_enhanced import enhanced_tb, run_one  # noqa: E402

CVC = ROOT / "experiments/complexvcoder-3prompt-10attempt-v1/all_generated_eval_summary.json"
ICARUS = ROOT / "experiments/multi-llm-observable-v1/openrouter/icarus_observable_summary.json"
OUT = ROOT / "enhanced_cdc_tb/results/functional_generated.json"


def collect() -> list[dict]:
    rows = []
    cvc = json.loads(CVC.read_text())
    for item in cvc:
        if not (item.get("compile_ok") and item.get("simulate_ok")):
            continue
        rtl = ROOT / item["rtl"]
        if not rtl.is_file():
            continue
        rows.append(
            {
                "source": "complexvcoder-3prompt",
                "circuit": item["circuit"],
                "prompt": item.get("prompt_type", "unknown"),
                "attempt": item.get("attempt", "unknown"),
                "rtl": rtl,
            }
        )
    icarus = json.loads(ICARUS.read_text())
    for item in icarus:
        if not (item.get("compile_ok") and item.get("simulate_ok")):
            continue
        rtl = ROOT / item["rtl"]
        if not rtl.is_file():
            continue
        rows.append(
            {
                "source": item["model"],
                "circuit": item["circuit"],
                "prompt": item.get("prompt_type", "observable"),
                "attempt": item.get("attempt", "unknown"),
                "rtl": rtl,
            }
        )
    return rows


def identity(row: dict) -> tuple:
    return (row["source"], row["circuit"], row["prompt"], row["attempt"])


def main() -> int:
    limit = 0
    resume = "--resume" in sys.argv
    if "--limit" in sys.argv:
        limit = int(sys.argv[sys.argv.index("--limit") + 1])

    rows = collect()
    seen = set()
    results = []
    if resume and OUT.exists():
        payload = json.loads(OUT.read_text())
        results = payload.get("results", [])
        seen = {
            (r["source"], r["circuit"], r["prompt"], r["attempt"]) for r in results
        }
        rows = [row for row in rows if identity(row) not in seen]
    if limit:
        rows = rows[:limit]

    print(
        f"Pending enhanced CDC TB runs: {len(rows)}; already scored: {len(seen)}",
        flush=True,
    )
    for index, row in enumerate(rows, 1):
        if not enhanced_tb(row["circuit"]):
            result = {"status": "SKIP", "note": "no enhanced TB"}
        else:
            try:
                result = run_one(row)
            except Exception as exc:
                result = {"status": "FAIL", "note": f"runner error: {exc}"}
        printable = {
            **row,
            "rtl": str(Path(row["rtl"]).relative_to(ROOT)),
            **result,
        }
        results.append(printable)
        OUT.parent.mkdir(parents=True, exist_ok=True)
        OUT.write_text(
            json.dumps(
                {
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "n": len(results),
                    "results": results,
                },
                indent=2,
            )
            + "\n"
        )
        print(
            f"{index}/{len(rows)} {row['source']}/{row['circuit']}/"
            f"{row['prompt']}/{row['attempt']}: {result['status']} "
            f"{result.get('note', '')}",
            flush=True,
        )

    counts = Counter(r["status"] for r in results)
    by = defaultdict(Counter)
    for r in results:
        by[r["circuit"]][r["status"]] += 1
    print(f"DONE {dict(counts)} summary={OUT}", flush=True)
    for circuit in sorted(by):
        print(f"  {circuit}: {dict(by[circuit])}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
