#!/usr/bin/env python3
"""Evaluate a Pass@N sampling experiment on ecs05.

Walks attempts in order for each circuit × prompt. Compiles with xrun,
simulates compile-pass candidates, and runs JasperGold only on the first
functionally passing file. Does not edit generated RTL.

This is not the frozen 18-attempt baseline.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from evaluate_generated import TB, evaluate  # noqa: E402

CIRCUITS = ["cdc_2phase", "async_fifo", "apbxclk"]
PROMPT_TYPES = ["functional", "cdc_explicit"]
XRUN_BIN = "/eda/cadence/XCELIUM2603/tools.lnx86/inca/bin/64bit"
JG_BIN = "/eda/cadence/JASPER/bin"
TIMEOUT_TCL = Path("/tmp/xrun_timeout.tcl")

JG_BODY = {
    "cdc_2phase": """
clear -all
analyze -sv $RTL_FILE
elaborate -top $TOP
read_sdc $SDC_FILE
check_cdc -init
clock src_clk_i
clock dst_clk_i
config_rtlds -reset -async {src_rst_ni dst_rst_ni} -polarity low
config_rtlds -port {src_rst_ni src_data_i src_valid_i src_ready_o} -clock src_clk_i
config_rtlds -port {dst_rst_ni dst_data_o dst_valid_o dst_ready_i} -clock dst_clk_i
""",
    "async_fifo": """
clear -all
analyze -sv $RTL_FILE
elaborate -bbox_a 50000 -top $TOP
read_sdc $SDC_FILE
check_cdc -init
clock wclk
clock rclk
config_rtlds -reset -async {wrst_n rrst_n} -polarity low
config_rtlds -port {winc wdata wfull awfull} -clock wclk
config_rtlds -port {rinc rdata rempty arempty} -clock rclk
""",
    "apbxclk": """
clear -all
analyze -sv $RTL_FILE
elaborate -top $TOP
read_sdc $SDC_FILE
check_cdc -init
clock S_APB_PCLK
clock M_APB_PCLK
config_rtlds -reset -async S_PRESETn -polarity low
config_rtlds -port {S_APB_PSEL S_APB_PENABLE S_APB_PREADY S_APB_PADDR S_APB_PWRITE S_APB_PWDATA S_APB_PWSTRB S_APB_PPROT S_APB_PRDATA S_APB_PSLVERR} -clock S_APB_PCLK
config_rtlds -port {M_PRESETn M_APB_PSEL M_APB_PENABLE M_APB_PREADY M_APB_PADDR M_APB_PWRITE M_APB_PWDATA M_APB_PWSTRB M_APB_PPROT M_APB_PRDATA M_APB_PSLVERR} -clock M_APB_PCLK
""",
}


def simulate(rtl: Path, circuit: str, out_dir: Path) -> dict:
    top, tb = TB[circuit]
    work = ROOT / "build" / "eval" / out_dir.relative_to(ROOT / "experiments") / "sim"
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True)
    log = work / "sim.log"
    TIMEOUT_TCL.write_text("run 50us\nexit\n")
    cmd = [
        "xrun",
        "-64bit",
        "-sv",
        "-timescale",
        "1ns/1ps",
        "-top",
        top,
        "-xmlibdirname",
        str(work / "xcelium"),
        "-l",
        str(log),
        "-input",
        str(TIMEOUT_TCL),
        str(rtl),
        str(tb),
    ]
    subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    text = log.read_text(errors="replace") if log.exists() else ""
    # Score $display / $finish output only. The apbxclk TB source itself
    # contains the string ALL TESTS PASSED, so ignore compiler source dumps.
    runtime = "\n".join(
        line
        for line in text.splitlines()
        if "$display" not in line and "$finish" not in line
    )
    pass_m = re.search(
        r"^(?:xmsim:\s*)?(?:\s*\d+(?:\.\d+)?\s+\w+\s+)?(?:CDC 2PHASE:\s*)?ALL TESTS PASSED\s*$",
        runtime,
        re.M,
    )
    fail_m = re.search(
        r"^(?:xmsim:\s*)?(?:\s*\d+(?:\.\d+)?\s+\w+\s+)?(?:CDC 2PHASE:\s*)?TESTS FAILED[^\n]*",
        runtime,
        re.M,
    )
    if pass_m:
        ok, note = True, "ALL TESTS PASSED"
    elif fail_m:
        ok, note = False, fail_m.group(0).strip()
    elif re.search(r"CDC 2PHASE: TIMEOUT", runtime) or "Ran until 50 US" in runtime:
        ok, note = False, "TIMEOUT"
    else:
        ok, note = False, "no sim result"
    return {"simulate_ok": ok, "sim_note": note, "sim_log": str(log.relative_to(ROOT))}


def parse_cdc_report(text: str) -> tuple[int, int, int]:
    cdc_e = rdc_e = 0
    section = None
    for line in text.splitlines():
        if "RDC DOMAIN" in line:
            section = "rdc"
        elif re.search(r"Section \d+:\s+CDC DOMAIN", line):
            section = "cdc"
        if section and re.search(r"RST_|CDC_|DATA_|CONV_|GRAY_|HANDSHAKE|MISSING|UNSAFE|RESET", line):
            nums = re.findall(r"\b(\d+)\b", line)
            if len(nums) >= 5:
                err = int(nums[0])
                if section == "rdc":
                    rdc_e += err
                else:
                    cdc_e += err
    err_rows = len(re.findall(r"\[\d+\]\s+Error", text))
    return cdc_e, rdc_e, err_rows


def run_jasper(rtl: Path, circuit: str, tag: Path) -> dict:
    os.environ["DS"] = str(ROOT)
    rpt = ROOT / "build/jasper/eval" / tag
    # A rerun must not accidentally score a stale report from an earlier run.
    if rpt.exists():
        shutil.rmtree(rpt)
    rpt.mkdir(parents=True)
    tcl = rpt / "run.tcl"
    tcl.write_text(
        f"set TOP      {circuit}\n"
        f"set RTL_FILE {rtl}\n"
        f"set SDC_FILE $env(DS)/benchmarks/{circuit}/constraints/{circuit}.sdc\n"
        f"set RPT_DIR  {rpt}\n"
        "file mkdir $RPT_DIR\n"
        + JG_BODY[circuit]
        + "check_cdc -extract\n"
        "check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force\n"
        "check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force\n"
        "check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force\n"
        "check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force\n"
        "check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force\n"
        f"puts {{cdc_run {circuit}}}\n"
    )
    completed = subprocess.run(
        ["jg", "-batch", str(tcl)],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    jg_log = rpt / "jasper.log"
    jg_log.write_text(completed.stdout + completed.stderr)
    report = rpt / "cdc_report.rpt"
    if completed.returncode != 0 or not report.exists():
        return {
            "jg_returncode": completed.returncode,
            "cdc_errors": None,
            "rdc_errors": None,
            "error_rows": None,
            "crossings_extracted": None,
            "jasper_zero_violations": False,
            "cdc_clean": False,
            "jasper_report": None,
            "jasper_log": str(jg_log.relative_to(ROOT)),
        }
    cdc_e, rdc_e, err_rows = parse_cdc_report(report.read_text(errors="replace"))
    crossings_report = rpt / "cdc_crossings.rpt.csv"
    if not crossings_report.exists():
        crossings_report = rpt / "cdc_crossings.rpt"
    crossing_lines = (
        [
            line
            for line in crossings_report.read_text(errors="replace").splitlines()
            if line.strip()
        ]
        if crossings_report.exists()
        else []
    )
    # Jasper emits a CSV header even when it extracts zero crossings.
    crossings_extracted = max(0, len(crossing_lines) - 1)
    zero_violations = cdc_e == 0 and rdc_e == 0 and err_rows == 0
    return {
        "jg_returncode": completed.returncode,
        "cdc_errors": cdc_e,
        "rdc_errors": rdc_e,
        "error_rows": err_rows,
        "crossings_extracted": crossings_extracted,
        "jasper_zero_violations": zero_violations,
        # Every current pilot task necessarily transfers information between
        # asynchronous domains. A zero-row report is therefore not evidence
        # of a CDC-clean implementation.
        "cdc_clean": zero_violations and crossings_extracted > 0,
        "jasper_report": str(report.relative_to(ROOT)),
        "jasper_log": str(jg_log.relative_to(ROOT)),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--model-dir",
        default="experiments/rtlcoder-deepseek-until-functional-pass",
    )
    parser.add_argument("--max-attempts", type=int, default=20)
    args = parser.parse_args()

    os.environ["PATH"] = XRUN_BIN + ":" + JG_BIN + ":" + os.environ.get("PATH", "")
    model_dir = ROOT / args.model_dir
    if not model_dir.exists():
        print(f"ERROR: {model_dir} does not exist yet. Unzip Colab outputs first.")
        return 1

    table = []
    for circuit in CIRCUITS:
        for prompt_type in PROMPT_TYPES:
            first_compile = None
            first_func = None
            cdc = "none"
            attempts = sorted(
                (
                    p
                    for p in (model_dir / circuit / prompt_type).glob("attempt-*")
                    if re.fullmatch(r"attempt-\d{3}", p.name)
                ),
                key=lambda p: int(p.name.split("-")[1]),
            )[: args.max_attempts]
            print(f"===== {circuit}/{prompt_type}  {len(attempts)} attempts =====")
            for att in attempts:
                rtl = next(att.glob("generated/*.v"), None)
                if rtl is None:
                    continue
                compile_result = evaluate(rtl, circuit, att)
                n = att.name
                if compile_result["compile_ok"] and first_compile is None:
                    first_compile = n
                if not compile_result["compile_ok"]:
                    print(f"  {n} COMPILE FAIL")
                    continue
                sim = simulate(rtl, circuit, att)
                compile_result.update(sim)
                (att / "results.json").write_text(json.dumps(compile_result, indent=2) + "\n")
                print(f"  {n} COMPILE PASS  sim={sim['sim_note']}")
                if sim["simulate_ok"]:
                    first_func = n
                    jg = run_jasper(rtl, circuit, att.relative_to(ROOT / "experiments"))
                    compile_result.update(jg)
                    (att / "results.json").write_text(json.dumps(compile_result, indent=2) + "\n")
                    cdc = "PASS" if jg.get("cdc_clean") else (
                        f"FAIL (cdc={jg.get('cdc_errors')} rdc={jg.get('rdc_errors')})"
                    )
                    print(f"  {n} FIRST FUNCTIONAL PASS  CDC {cdc}")
                    break
            table.append(
                {
                    "circuit": circuit,
                    "prompt": prompt_type,
                    "attempts_present": len(attempts),
                    "first_compile_pass": first_compile,
                    "first_functional_pass": first_func,
                    "cdc_clean": cdc,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                }
            )

    out = model_dir / "pass_at_n_summary.json"
    out.write_text(json.dumps(table, indent=2) + "\n")
    print("\nCircuit\tPrompt\tFirst compile pass\tFirst functional pass\tCDC-clean")
    for row in table:
        print(
            f"{row['circuit']}\t{row['prompt']}\t"
            f"{row['first_compile_pass'] or 'none'}\t"
            f"{row['first_functional_pass'] or 'none'}\t"
            f"{row['cdc_clean']}"
        )
    print(f"\nWrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
