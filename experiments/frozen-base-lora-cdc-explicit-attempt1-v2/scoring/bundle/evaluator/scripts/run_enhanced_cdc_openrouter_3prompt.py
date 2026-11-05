#!/usr/bin/env python3
"""Enhanced CDC TB on OpenRouter 3-prompt files that passed Icarus compile+sim."""

from __future__ import annotations

import json
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "enhanced_cdc_tb"))
from run_enhanced import enhanced_tb, run_one  # noqa: E402

SUMMARY = ROOT / "experiments/multi-llm-3prompt-v1/openrouter/icarus_3prompt_summary.json"
OUT = ROOT / "enhanced_cdc_tb/results/openrouter_3prompt_functional.json"


def collect() -> list[dict]:
    rows = []
    if not SUMMARY.is_file():
        return rows
    for item in json.loads(SUMMARY.read_text()):
        if not (item.get("compile_ok") and item.get("simulate_ok")):
            continue
        rtl = ROOT / item["rtl"]
        if not rtl.is_file():
            continue
        rows.append(
            {
                "source": item.get("model", "openrouter-3prompt"),
                "circuit": item["circuit"],
                "prompt": item.get("prompt_type", "unknown"),
                "attempt": item.get("attempt", "unknown"),
                "rtl": rtl,
            }
        )
    return rows


def identity(row: dict) -> tuple:
    return (row["source"], row["circuit"], row["prompt"], row["attempt"])


def main() -> int:
    resume = "--resume" in sys.argv
    rows = collect()
    seen = set()
    results = []
    if resume and OUT.exists():
        payload = json.loads(OUT.read_text())
        results = payload.get("results", [])
        seen = {identity(r) for r in results}
        rows = [row for row in rows if identity(row) not in seen]
    print(
        f"Pending OpenRouter-3prompt enhanced TB: {len(rows)}; already scored: {len(seen)}",
        flush=True,
    )
    if not rows and not results:
        print(f"No compile+sim PASS rows yet. Need {SUMMARY}", flush=True)
        return 1
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
        counts = Counter(r.get("status") for r in results)
        by = defaultdict(lambda: Counter())
        for r in results:
            by[r["source"]][r.get("status")] += 1
        OUT.write_text(
            json.dumps(
                {
                    "updated_utc": datetime.now(timezone.utc).isoformat(),
                    "counts": dict(counts),
                    "by_source": {k: dict(v) for k, v in by.items()},
                    "results": results,
                },
                indent=2,
            )
            + "\n"
        )
        print(
            f"{index}/{len(rows)} {row['source']}/{row['circuit']}/"
            f"{row['prompt']}/{row['attempt']}: {printable.get('status')} "
            f"{printable.get('note', '')}",
            flush=True,
        )
    print(f"DONE {dict(Counter(r.get('status') for r in results))} {OUT}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
