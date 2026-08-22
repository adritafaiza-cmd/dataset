#!/usr/bin/env python3
"""Compile-check generated RTL candidates against the benchmark testbenches."""

import argparse
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TB = {
    "cdc_2phase": ("cdc_2phase_tb", ROOT / "benchmarks/cdc_2phase/tb/cdc_2phase_tb.v"),
    "async_fifo": ("async_fifo_unit_test", ROOT / "benchmarks/async_fifo/tb/async_fifo_unit_test.v"),
    "apbxclk": ("apbxclk_assert", ROOT / "benchmarks/apbxclk/tb/apbxclk_tb_assert.v"),
}


def evaluate(rtl: Path, circuit: str, out_dir: Path) -> dict:
    top, tb = TB[circuit]
    work = ROOT / "build" / "eval" / out_dir.relative_to(ROOT / "experiments")
    if work.exists():
        subprocess.run(["rm", "-rf", str(work)], check=True)
    work.mkdir(parents=True)
    log = work / "xrun.log"
    cmd = [
        "xrun",
        "-64bit",
        "-sv",
        "-timescale",
        "1ns/1ps",
        "-elaborate",
        "-top",
        top,
        "-xmlibdirname",
        str(work / "xcelium"),
        "-l",
        str(log),
        str(rtl),
        str(tb),
    ]
    completed = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    log_text = log.read_text(errors="replace") if log.exists() else completed.stdout + completed.stderr
    compile_ok = completed.returncode == 0 and "errors: 0" in log_text
    result = {
        "circuit": circuit,
        "rtl": str(rtl.relative_to(ROOT)),
        "compile_ok": compile_ok,
        "returncode": completed.returncode,
        "log": str(log.relative_to(ROOT)) if log.exists() else None,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "simulate_ok": None,
        "cdc_errors": None,
        "rdc_errors": None,
    }
    (out_dir / "results.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model-dir", default="experiments/llama-3.3-70b-instruct")
    args = parser.parse_args()
    model_dir = ROOT / args.model_dir
    rows = []
    for rtl in sorted(model_dir.glob("*/*/*/generated/*.v")):
        circuit, _prompt_type, _attempt = rtl.relative_to(model_dir).parts[:3]
        out_dir = rtl.parent.parent
        result = evaluate(rtl, circuit, out_dir)
        rows.append(result)
        status = "PASS" if result["compile_ok"] else "FAIL"
        print(f"{status} {out_dir.relative_to(model_dir)}")

    summary = model_dir / "compile_summary.json"
    summary.write_text(json.dumps(rows, indent=2) + "\n")
    passed = sum(1 for row in rows if row["compile_ok"])
    print(f"Compile: {passed}/{len(rows)} passed. Summary: {summary}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
