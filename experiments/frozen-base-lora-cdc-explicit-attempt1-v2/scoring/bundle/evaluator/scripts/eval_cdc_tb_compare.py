#!/usr/bin/env python3
"""Run CDC TB checks (lint + embedded Verilog monitors) on golden/generated RTL.

Sources: golden, complexvcoder, qwen-32b, llama openrouter, gpt-5.6-sol.
Writes cdc_tb_checks/compare/cdc_tb_compare.json and a markdown table.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "cdc_tb_checks"))
sys.path.insert(0, str(ROOT / "scripts"))
from lint_cdc import lint_text  # noqa: E402
from evaluate_generated import evaluation_sim_script, top_rtl_for  # noqa: E402

DEFAULT_CIRCUITS = {"cdc_2phase", "async_fifo", "apbxclk", "afifo"}

SOURCES = {
    "golden": None,
    "complexvcoder": ROOT / "complexvcoder",
    "qwen-32b": ROOT / "experiments/qwen-2.5-coder-32b-instruct",
    "llama-70b-openrouter": ROOT
    / "experiments/multi-llm-passk/openrouter/meta-llama__llama-3.3-70b-instruct",
    "gpt-5.6-sol": ROOT / "experiments/multi-llm-passk/openai/gpt-5.6-sol",
}


def golden_rtl(circuit: str) -> Path | None:
    if not (ROOT / "benchmarks" / circuit / "manifest.yaml").exists():
        return None
    try:
        return top_rtl_for(circuit)
    except (KeyError, RuntimeError):
        return None


def iter_generated(model_dir: Path):
    for rtl in sorted(model_dir.glob("*/*/*/generated/*.v")):
        parts = rtl.relative_to(model_dir).parts
        if len(parts) < 4:
            continue
        circuit, prompt, attempt = parts[:3]
        if not re.fullmatch(r"attempt-\d{3}", attempt):
            continue
        yield circuit, prompt, attempt, rtl


def score_rtl(circuit: str, rtl: Path) -> dict:
    text = rtl.read_text(errors="replace")
    hits = lint_text(text, str(rtl.relative_to(ROOT)))
    marks = sorted(
        {
            m.group(1)
            for h in hits
            for m in [re.search(r"type ([A-Z])", h)]
            if m
        }
    )
    return {
        "circuit": circuit,
        "rtl": str(rtl.relative_to(ROOT)),
        "lint_ok": not hits,
        "lint_hits": hits,
        "marks": marks,
    }


def collect(default_only: bool) -> list[dict]:
    rows: list[dict] = []
    circuits = set()
    for src, d in SOURCES.items():
        if src == "golden":
            continue
        if not d or not d.exists():
            continue
        for circuit, prompt, attempt, rtl in iter_generated(d):
            circuits.add(circuit)
            if default_only and circuit not in DEFAULT_CIRCUITS:
                continue
            rec = score_rtl(circuit, rtl)
            rec.update({"source": src, "prompt": prompt, "attempt": attempt})
            rows.append(rec)

    for circuit in sorted(circuits | DEFAULT_CIRCUITS):
        if default_only and circuit not in DEFAULT_CIRCUITS:
            continue
        g = golden_rtl(circuit)
        if g and g.exists():
            rec = score_rtl(circuit, g)
            rec.update(
                {
                    "source": "golden",
                    "prompt": "reference",
                    "attempt": "fixed",
                }
            )
            rows.append(rec)
    return rows


def work_dir(row: dict) -> Path:
    return (
        ROOT
        / "build"
        / "cdc_tb_compare"
        / row["source"]
        / row["circuit"]
        / row["prompt"]
        / row["attempt"]
    )


def run_edited_tb(row: dict) -> dict:
    """Run the circuit's TB with its embedded Verilog CDC monitors."""
    circuit = row["circuit"]
    rtl = ROOT / row["rtl"]
    if "I" in row.get("marks", []):
        return {
            "compile_ok": False,
            "simulate_ok": False,
            "sim_note": "skip xrun: type I incomplete RTL",
            "monitor_fail": False,
        }
    source = ROOT / "benchmarks" / circuit / "sim" / "run.sh"
    if not source.exists():
        return {
            "compile_ok": None,
            "simulate_ok": None,
            "sim_note": "no sim/run.sh",
            "monitor_fail": None,
        }
    work = work_dir(row)
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True)
    runner, log = evaluation_sim_script(
        rtl, circuit, work, compile_only=False
    )
    completed = subprocess.run(
        [str(runner)],
        cwd=ROOT,
        env={**os.environ, "CDC_CHECKS": "0"},
        capture_output=True,
        text=True,
        timeout=180,
    )
    log_text = log.read_text(errors="replace") if log.exists() else (
        completed.stdout + completed.stderr
    )
    compile_ok = completed.returncode == 0 and not re.search(
        r"\b(?:xmvlog|xmelab): \*[EF],", log_text
    )
    runtime = "\n".join(
        line
        for line in log_text.splitlines()
        if "$display" not in line and "$finish" not in line
    )
    monitor_fail = bool(re.search(r"\bCDC(?:/RESET)? VIOLATION\b", runtime))
    pass_m = re.search(r"^.*\bALL TESTS PASSED\b.*$", runtime, re.M)
    fail_m = re.search(r"^.*\bTESTS FAILED\b.*$", runtime, re.M)
    if pass_m and compile_ok:
        sim_ok, note = True, "ALL TESTS PASSED"
    elif fail_m:
        sim_ok, note = False, fail_m.group(0).strip()[:160]
    elif re.search(r"\bTIMEOUT\b", runtime) or "Ran until 50 US" in runtime:
        sim_ok, note = False, "TIMEOUT"
    elif not compile_ok:
        sim_ok, note = False, "compile fail"
    else:
        sim_ok, note = False, "no sim result"
    return {
        "compile_ok": compile_ok,
        "simulate_ok": sim_ok,
        "sim_note": note,
        "monitor_fail": monitor_fail,
        "sim_log": str(log.relative_to(ROOT)) if log.exists() else None,
        "returncode": completed.returncode,
    }


def summarize(rows: list[dict]) -> dict:
    by: dict[str, dict[str, dict]] = defaultdict(
        lambda: defaultdict(
            lambda: {
                "n": 0,
                "lint_ok": 0,
                "sim_n": 0,
                "compile_ok": 0,
                "simulate_ok": 0,
                "marks": defaultdict(int),
            }
        )
    )
    for r in rows:
        cell = by[r["circuit"]][r["source"]]
        cell["n"] += 1
        if r["lint_ok"]:
            cell["lint_ok"] += 1
        if r.get("compile_ok") is not None:
            cell["sim_n"] += 1
            if r.get("compile_ok"):
                cell["compile_ok"] += 1
            if r.get("simulate_ok"):
                cell["simulate_ok"] += 1
        for m in r["marks"]:
            cell["marks"][m] += 1
    out = {}
    for circ, sources in by.items():
        out[circ] = {}
        for src, cell in sources.items():
            n = cell["n"]
            ok = cell["lint_ok"]
            sim_n = cell["sim_n"]
            out[circ][src] = {
                "n": n,
                "lint_ok": ok,
                "lint_fail": n - ok,
                "lint_pass_rate": round(ok / n, 3) if n else None,
                "sim_n": sim_n,
                "compile_ok": cell["compile_ok"],
                "simulate_ok": cell["simulate_ok"],
                "marks": dict(cell["marks"]),
            }
    return out


def markdown_table(summary: dict, sources: list[str], *, with_sim: bool) -> str:
    lines = [
        "# CDC TB comparison (edited testbench)",
        "",
        "Each cell is lint_ok/n"
        + (" and sim_ok/n for circuits with embedded Verilog monitors." if with_sim else ".")
        + " Golden must stay lint-clean. Generated: fraction the CDC lint "
        "did **not** flag.",
        "",
        "| Circuit | " + " | ".join(sources) + " |",
        "|---|" + "|".join("---" for _ in sources) + "|",
    ]
    for circ in sorted(summary):
        cells = []
        for src in sources:
            c = summary[circ].get(src)
            if not c:
                cells.append("—")
            else:
                marks = ",".join(sorted(c["marks"])) or "clean"
                cell = f"{c['lint_ok']}/{c['n']} lint ({marks})"
                if with_sim and c.get("sim_n"):
                    cell += f" · {c['simulate_ok']}/{c['sim_n']} sim"
                cells.append(cell)
        lines.append(f"| {circ} | " + " | ".join(cells) + " |")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--all-circuits",
        action="store_true",
        help="Include all circuits rather than the four quick default circuits",
    )
    parser.add_argument(
        "--sim",
        action="store_true",
        help="Run each existing TB with its embedded Verilog CDC monitors",
    )
    args = parser.parse_args()
    default_only = not args.all_circuits
    rows = collect(default_only=default_only)
    if args.sim:
        sim_rows = rows
        print(f"Running edited TB on {len(sim_rows)} RTL files", flush=True)
        for i, row in enumerate(sim_rows, 1):
            tag = f"{row['source']} {row['circuit']}/{row['prompt']}/{row['attempt']}"
            try:
                sim = run_edited_tb(row)
            except subprocess.TimeoutExpired:
                sim = {
                    "compile_ok": False,
                    "simulate_ok": False,
                    "sim_note": "xrun timeout 180s",
                    "monitor_fail": False,
                }
            except Exception as exc:  # one DUT must not abort the batch
                sim = {
                    "compile_ok": False,
                    "simulate_ok": False,
                    "sim_note": f"runner error: {exc}",
                    "monitor_fail": False,
                }
            row.update(sim)
            print(
                f"  {i}/{len(sim_rows)} {tag} lint={'ok' if row['lint_ok'] else row['marks']} "
                f"compile={row.get('compile_ok')} sim={row.get('simulate_ok')} "
                f"{row.get('sim_note')}",
                flush=True,
            )
    summary = summarize(rows)
    sources = [
        "golden",
        "complexvcoder",
        "qwen-32b",
        "llama-70b-openrouter",
        "gpt-5.6-sol",
    ]
    out_dir = ROOT / "cdc_tb_checks" / "compare"
    out_dir.mkdir(parents=True, exist_ok=True)
    payload = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "default_circuits_only": default_only,
        "sim": args.sim,
        "n_files": len(rows),
        "sources": sources,
        "summary": summary,
        "rows": rows,
    }
    (out_dir / "cdc_tb_compare.json").write_text(
        json.dumps(payload, indent=2) + "\n"
    )
    md = markdown_table(summary, sources, with_sim=args.sim)
    (out_dir / "cdc_tb_compare.md").write_text(md)
    print(md)
    print(f"Wrote {out_dir / 'cdc_tb_compare.json'} n={len(rows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
