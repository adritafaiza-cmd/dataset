#!/usr/bin/env python3
"""Run enhanced CDC TBs on generated RTL that elaborated in SymbiYosys.

Skips the functional simulation gate. Candidates are those whose formal
status is not FORMAL_ELAB_ERROR (Yosys built a netlist).
"""

from __future__ import annotations

import json
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "enhanced_cdc_tb"))
from run_enhanced import enhanced_tb, run_one  # noqa: E402

FORMAL_FILES = [
    ROOT / "formal/eligible_generated_summary.json",
    ROOT / "formal/new20_complexvcoder_summary.json",
    ROOT / "formal/new20_llama_summary.json",
    ROOT / "formal/new20_qwen_summary.json",
    ROOT / "formal/new20_rescore_svstem_summary.json",
]
OUT = ROOT / "enhanced_cdc_tb/results/formal_elab_generated.json"


def load_rows(path: Path) -> list:
    data = json.loads(path.read_text())
    if isinstance(data, dict) and "results" in data:
        return data["results"]
    return data


def collect() -> list[dict]:
    seen = {}
    for path in FORMAL_FILES:
        if not path.is_file():
            continue
        for item in load_rows(path):
            if item.get("formal_status") == "FORMAL_ELAB_ERROR":
                continue
            rtl = ROOT / item["rtl"]
            if not rtl.is_file():
                continue
            circuit = item["circuit"]
            prompt = item.get("prompt_type") or item.get("prompt") or "unknown"
            attempt = item.get("attempt", "unknown")
            model = item.get("model") or item.get("source") or "unknown"
            key = (model, circuit, prompt, attempt)
            seen[key] = {
                "source": model,
                "circuit": circuit,
                "prompt": prompt,
                "attempt": attempt,
                "rtl": rtl,
                "formal_status": item.get("formal_status"),
            }
    return [seen[key] for key in sorted(seen)]


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
        f"Pending enhanced CDC TB (formal-elab) runs: {len(rows)}; "
        f"already scored: {len(seen)}",
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
                    "gate": "symbiyosys_not_elab_error",
                    "n": len(results),
                    "results": results,
                },
                indent=2,
            )
            + "\n"
        )
        print(
            f"{index}/{len(rows)} {row['source']}/{row['circuit']}/"
            f"{row['prompt']}/{row['attempt']} "
            f"formal={row.get('formal_status')} "
            f"{result['status']} {result.get('note', '')}",
            flush=True,
        )

    counts = Counter(r["status"] for r in results)
    by = defaultdict(Counter)
    proved = Counter()
    for r in results:
        by[r["circuit"]][r["status"]] += 1
        if r.get("formal_status") == "FORMAL_PROVED":
            proved[r["status"]] += 1
    print(f"DONE {dict(counts)} summary={OUT}", flush=True)
    print(f"among FORMAL_PROVED: {dict(proved)}", flush=True)
    for circuit in sorted(by):
        print(f"  {circuit}: {dict(by[circuit])}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
