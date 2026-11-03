#!/usr/bin/env python3
"""JasperGold on compile+easy-TB-pass generated RTL, then vs enhanced TB.

Does not run JG on compile-fail or easy-TB-fail files (no useful netlist).
Reuses ComplexVCoder rows that already have cdc_errors filled.
"""

from __future__ import annotations

import json
import os
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from evaluate_pass_at_n import JG_BIN, run_jasper  # noqa: E402

OUT = ROOT / "experiments/jasper_vs_enhanced_generated.json"
XRUN_BIN = "/eda/cadence/XCELIUM2603/tools.lnx86/inca/bin/64bit"


def utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    if not path.is_file():
        return None
    return json.loads(path.read_text())


def collect_functional_pass() -> list[dict]:
    rows = []
    cvc = load_json(
        ROOT / "experiments/complexvcoder-3prompt-10attempt-v1/all_generated_eval_summary.json"
    ) or []
    for item in cvc:
        if not (item.get("compile_ok") and item.get("simulate_ok")):
            continue
        rows.append(
            {
                "source": "complexvcoder-3prompt",
                "circuit": item["circuit"],
                "prompt": item.get("prompt_type", "unknown"),
                "attempt": item.get("attempt", "unknown"),
                "rtl": item["rtl"],
                "cached_cdc_errors": item.get("cdc_errors"),
                "cached_rdc_errors": item.get("rdc_errors"),
            }
        )
    rtl = load_json(
        ROOT / "experiments/rtlcoder-deepseek-3prompt-10attempt-v1/all_generated_eval_summary.json"
    ) or []
    for item in rtl:
        if not (item.get("compile_ok") and item.get("simulate_ok")):
            continue
        rows.append(
            {
                "source": "rtlcoder-deepseek-3prompt",
                "circuit": item["circuit"],
                "prompt": item.get("prompt_type", "unknown"),
                "attempt": item.get("attempt", "unknown"),
                "rtl": item["rtl"],
            }
        )
    for path, default_src in (
        (
            ROOT / "experiments/multi-llm-observable-v1/openrouter/icarus_observable_summary.json",
            None,
        ),
        (
            ROOT / "experiments/multi-llm-3prompt-v1/openrouter/icarus_3prompt_summary.json",
            None,
        ),
    ):
        data = load_json(path) or []
        for item in data:
            if not (item.get("compile_ok") and item.get("simulate_ok")):
                continue
            rows.append(
                {
                    "source": item.get("model") or default_src,
                    "circuit": item["circuit"],
                    "prompt": item.get("prompt_type", "unknown"),
                    "attempt": item.get("attempt", "unknown"),
                    "rtl": item["rtl"],
                }
            )
    return rows


def load_enhanced() -> dict:
    """Map (source, circuit, prompt, attempt) -> PASS/FAIL/SKIP."""
    out = {}
    files = [
        ROOT / "enhanced_cdc_tb/results/functional_generated.json",
        ROOT / "enhanced_cdc_tb/results/rtlcoder_functional_generated.json",
        ROOT / "enhanced_cdc_tb/results/openrouter_3prompt_functional.json",
    ]
    for path in files:
        data = load_json(path)
        if not data:
            continue
        for r in data.get("results", []):
            key = (
                r.get("source"),
                r.get("circuit"),
                str(r.get("prompt")),
                str(r.get("attempt")),
            )
            out[key] = {
                "status": r.get("status"),
                "note": r.get("note"),
            }
    return out


def identity(row: dict) -> tuple:
    return (row["source"], row["circuit"], str(row["prompt"]), str(row["attempt"]))


def tag_for(rtl: Path) -> Path:
    att = rtl.parent.parent
    try:
        return att.relative_to(ROOT / "experiments")
    except ValueError:
        return att.relative_to(ROOT)


def main() -> int:
    os.environ["PATH"] = f"{XRUN_BIN}:{JG_BIN}:{os.environ.get('PATH', '')}"
    os.environ["DS"] = str(ROOT)
    resume = "--resume" in sys.argv
    rows = collect_functional_pass()
    seen = {}
    results = []
    if resume and OUT.exists():
        payload = json.loads(OUT.read_text())
        results = payload.get("results", [])
        seen = {identity(r): r for r in results}
        rows = [row for row in rows if identity(row) not in seen]
    print(
        f"Pending Jasper: {len(rows)}; already scored: {len(seen)} "
        f"(easy-TB-pass generated only)",
        flush=True,
    )
    enh = load_enhanced()
    for index, row in enumerate(rows, 1):
        rtl = ROOT / row["rtl"]
        rec = {
            "source": row["source"],
            "circuit": row["circuit"],
            "prompt": row["prompt"],
            "attempt": row["attempt"],
            "rtl": row["rtl"],
            "enhanced": enh.get(identity(row)),
        }
        cached = row.get("cached_cdc_errors")
        if cached is not None and "--force" not in sys.argv:
            rec.update(
                {
                    "jg_source": "cached_cvc_eval",
                    "cdc_errors": cached,
                    "rdc_errors": row.get("cached_rdc_errors"),
                    "cdc_clean": cached == 0
                    and (row.get("cached_rdc_errors") in (0, None)),
                    "jg_returncode": 0,
                }
            )
        elif not rtl.is_file():
            rec.update({"error": "missing rtl", "cdc_clean": False})
        else:
            try:
                jg = run_jasper(rtl, row["circuit"], tag_for(rtl))
                rec.update(jg)
                rec["jg_source"] = "run"
            except Exception as exc:
                rec.update({"error": str(exc), "cdc_clean": False, "jg_source": "error"})
        results.append(rec)
        compare = summarize(results)
        OUT.write_text(
            json.dumps(
                {
                    "updated_utc": utc(),
                    "note": (
                        "JG only on compile+easy-TB pass. cdc_clean is structural "
                        "zero CDC/RDC in Jasper, NOT metastability-safe."
                    ),
                    "compare": compare,
                    "results": results,
                },
                indent=2,
            )
            + "\n"
        )
        print(
            f"{index}/{len(rows)} {row['source']}/{row['circuit']}/"
            f"{row['prompt']}/{row['attempt']} "
            f"jg_cdc={rec.get('cdc_errors')} rdc={rec.get('rdc_errors')} "
            f"cdc_clean={rec.get('cdc_clean')} enh={rec.get('enhanced')}",
            flush=True,
        )
    print("DONE", json.dumps(summarize(results)), flush=True)
    print(OUT, flush=True)
    return 0


def summarize(results: list[dict]) -> dict:
    by = defaultdict(lambda: Counter())
    conf = Counter()
    for r in results:
        src = r["source"]
        jg_ok = bool(r.get("cdc_clean"))
        enh = (r.get("enhanced") or {}).get("status")
        by[src]["n"] += 1
        if r.get("cdc_errors") is not None:
            by[src]["jg_ran"] += 1
        if jg_ok:
            by[src]["jg_clean"] += 1
        if enh == "PASS":
            by[src]["enh_pass"] += 1
        if enh == "FAIL":
            by[src]["enh_fail"] += 1
        if r.get("cdc_errors") is not None and enh in {"PASS", "FAIL"}:
            key = f"jg_clean={jg_ok}/enh={enh}"
            conf[key] += 1
            by[src][key] += 1
    return {"by_source": {k: dict(v) for k, v in by.items()}, "confusion": dict(conf)}


if __name__ == "__main__":
    raise SystemExit(main())
