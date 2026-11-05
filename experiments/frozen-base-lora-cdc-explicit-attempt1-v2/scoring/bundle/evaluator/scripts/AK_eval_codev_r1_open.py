#!/usr/bin/env python3
"""Open-source compile, simulation, and SDC-informed CDC checks for CodeV-R1.

This evaluator intentionally does not claim metastability proof.  It runs the
checked-in benchmark testbench with Icarus Verilog, confirms that the checked-in
SDC describes every manifest clock, and applies a conservative source-level
check for direct register-to-register crossings that lack a visible second
destination-domain stage.
"""

from __future__ import annotations

import argparse
import json
import re
import shlex
import subprocess
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from eval_all_generated import iter_generated  # noqa: E402
from evaluate_generated import (  # noqa: E402
    manifest_list,
    manifest_scalar,
    top_rtl_for,
)

MODEL_DIR = ROOT / "experiments" / "codev-r1-rl-qwen-7b"
PASS_RE = re.compile(r"(?:ALL TESTS PASSED|TESTS PASSED|TEST PASSED)", re.I)
FAIL_RE = re.compile(
    r"(?:TESTS? FAILED|ASSERT(?:ION)? FAIL|CDC/RESET VIOLATION|"
    r"PROTOCOL VIOLATION|\bTIMEOUT\b|\bFATAL\b)",
    re.I,
)
DYNAMIC_RE = re.compile(
    r"(?:ASSERT(?:ION)? FAIL|CDC/RESET VIOLATION|PROTOCOL VIOLATION)", re.I
)
OPEN_SOURCE_UNSUPPORTED = {
    "apb_regs": "Icarus 13 cannot elaborate the checked-in interface/type-parameter testbench stack",
    "cdc_2phase_clearable": "Icarus 13 cannot parse required vendor common_cells type parameters",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def manifest_clocks(circuit: str) -> list[str]:
    return manifest_list(circuit, "clocks")


def simulation_arguments(circuit: str, candidate: Path) -> tuple[str, list[str], list[Path]]:
    """Translate the simple checked-in xrun command to Icarus arguments."""
    bench = ROOT / "benchmarks" / circuit
    script = bench / manifest_scalar(circuit, "simulation")
    text = script.read_text().replace("\\\n", " ")
    command = re.search(r"(?m)^xrun\s+(.+)$", text)
    if not command:
        raise RuntimeError(f"{circuit}: simulation script has no xrun command")
    expanded = command.group(1).replace('"${XRUN_MODE[@]}"', "").replace("${XRUN_MODE[@]}", "")
    expanded = expanded.replace("$ROOT", str(ROOT)).replace("${ROOT}", str(ROOT))
    expanded = expanded.replace("$BENCH", str(bench)).replace("${BENCH}", str(bench))
    tokens = shlex.split(expanded)
    top = manifest_scalar(circuit, "testbench_top")
    include_dirs: list[str] = []
    defines: list[str] = []
    sources: list[Path] = []
    index = 0
    while index < len(tokens):
        token = tokens[index]
        if token in {"-64bit", "-sv"}:
            index += 1
        elif token in {"-timescale", "-top", "-xmlibdirname"}:
            if token == "-top":
                top = tokens[index + 1]
            index += 2
        elif token == "-incdir":
            include_dirs.append(tokens[index + 1])
            index += 2
        elif token == "-define":
            defines.append(tokens[index + 1])
            index += 2
        elif token.startswith("-"):
            raise RuntimeError(f"{circuit}: unsupported xrun option {token!r}")
        else:
            sources.append(Path(token).resolve())
            index += 1

    fixed_top = top_rtl_for(circuit).resolve()
    replaced = [candidate.resolve() if source == fixed_top else source for source in sources]
    if fixed_top not in sources:
        raise RuntimeError(f"{circuit}: fixed top {fixed_top} absent from simulation command")
    args = ["-g2012", "-Wall", "-s", top]
    args += [value for directory in include_dirs for value in ("-I", directory)]
    args += [value for define in defines for value in ("-D", define)]
    return top, args, replaced


def sdc_context(circuit: str) -> dict:
    bench = ROOT / "benchmarks" / circuit
    sdc = bench / manifest_scalar(circuit, "constraints")
    text = sdc.read_text(errors="replace")
    clocks = manifest_clocks(circuit)
    constrained = {
        port
        for port in re.findall(r"create_clock\b[^\n]*?get_ports\s+(?:\{([^}]+)\}|([^\]\s]+))", text)
        for port in port
        if port
    }
    missing = [clock for clock in clocks if clock not in constrained]
    async_declared = len(clocks) < 2 or bool(
        re.search(r"set_clock_groups\s+-asynchronous", text, re.I)
        or re.search(r"set_false_path", text, re.I)
    )
    return {
        "file": str(sdc.relative_to(ROOT)),
        "manifest_clocks": clocks,
        "constrained_clocks": sorted(constrained),
        "missing_clocks": missing,
        "asynchronous_relationship_declared": async_declared,
        "ok": not missing and async_declared,
    }


def run_command(command: list[str], *, timeout: int, cwd: Path) -> tuple[int | None, str, bool]:
    try:
        completed = subprocess.run(
            command, cwd=cwd, capture_output=True, text=True, timeout=timeout
        )
        return completed.returncode, completed.stdout + completed.stderr, False
    except subprocess.TimeoutExpired as exc:
        output = (exc.stdout or "") + (exc.stderr or "")
        if isinstance(output, bytes):
            output = output.decode(errors="replace")
        return None, output, True


def source_crossing_findings(candidate: Path, circuit: str) -> list[dict]:
    """Find obvious unsynchronized crossings within the generated top module.

    This deliberately reports only direct nonblocking-assignment relationships;
    it is a triage rule, not a complete CDC engine.
    """
    text = re.sub(r"/\*.*?\*/|//[^\n]*", "", candidate.read_text(errors="replace"), flags=re.S)
    top = manifest_scalar(circuit, "top_module")
    module_match = re.search(rf"\bmodule\s+{re.escape(top)}\b(.*?)\bendmodule\b", text, re.S)
    if not module_match:
        return [{"rule_id": "AK_CDC_TOP_NOT_PARSED", "top_module": top}]
    module_text = module_match.group(1)
    clocks = manifest_clocks(circuit)
    starts = list(re.finditer(r"\balways(?:_ff)?\s*@\s*\(([^)]*)\)", module_text, re.S))
    blocks: list[dict] = []
    for index, start in enumerate(starts):
        sensitivity = start.group(1)
        clock = next((name for name in clocks if re.search(rf"\b{re.escape(name)}\b", sensitivity)), None)
        if clock is None:
            continue
        end = starts[index + 1].start() if index + 1 < len(starts) else len(module_text)
        body = module_text[start.end() : end]
        assignments = [
            (match.group(1), match.group(2), match.start())
            for match in re.finditer(r"\b([A-Za-z_]\w*)(?:\s*\[[^]]+\])?\s*<=\s*([^;]+);", body)
        ]
        blocks.append({"clock": clock, "body": body, "assignments": assignments})

    assigned_domains: dict[str, set[str]] = defaultdict(set)
    for block in blocks:
        for lhs, _rhs, _offset in block["assignments"]:
            assigned_domains[lhs].add(block["clock"])

    findings: list[dict] = []
    for signal, domains in sorted(assigned_domains.items()):
        if len(domains) > 1:
            findings.append(
                {
                    "rule_id": "AK_CDC_MULTI_DOMAIN_DRIVER",
                    "signal": signal,
                    "clock_domains": sorted(domains),
                }
            )

    seen: set[tuple[str, str, str, str]] = set()
    for block in blocks:
        destination_clock = block["clock"]
        for lhs, rhs, offset in block["assignments"]:
            rhs_ids = set(re.findall(r"\b[A-Za-z_]\w*\b", rhs))
            for source in sorted(rhs_ids):
                source_domains = assigned_domains.get(source, set())
                for source_clock in sorted(source_domains - {destination_clock}):
                    # Treat a visible second destination-domain assignment as a
                    # conventional scalar synchronizer chain.  Bypasses and
                    # multi-bit coherency still require later human review.
                    second_stage = any(
                        next_lhs != lhs
                        and lhs in set(re.findall(r"\b[A-Za-z_]\w*\b", next_rhs))
                        for next_lhs, next_rhs, _ in block["assignments"]
                    )
                    if second_stage:
                        continue
                    key = (source, source_clock, lhs, destination_clock)
                    if key in seen:
                        continue
                    seen.add(key)
                    findings.append(
                        {
                            "rule_id": "AK_CDC_DIRECT_REG_CROSSING",
                            "source_signal": source,
                            "source_clock": source_clock,
                            "destination_signal": lhs,
                            "destination_clock": destination_clock,
                            "source_offset": offset,
                        }
                    )
    return findings


def structural_check(
    circuit: str,
    candidate: Path,
    top: str,
    compile_args: list[str],
    sources: list[Path],
    work: Path,
    timeout: int,
) -> dict:
    findings = source_crossing_findings(candidate, circuit)
    context = sdc_context(circuit)
    return {
        "structural_analyzed": True,
        "structural_returncode": 0,
        "structural_timeout": False,
        "structural_findings": findings,
        "structural_clean": not findings and context["ok"],
        "sdc_context": context,
        "structural_log": None,
    }


def evaluate_one(circuit: str, prompt: str, attempt: str, rtl: Path, timeout: int) -> dict:
    attempt_dir = rtl.parent.parent
    work = ROOT / "build" / "AK_codev_r1" / circuit / prompt / attempt
    work.mkdir(parents=True, exist_ok=True)
    if circuit in OPEN_SOURCE_UNSUPPORTED:
        return {
            "evaluator": "AK_open_source_v1",
            "circuit": circuit,
            "benchmark_status": manifest_scalar(circuit, "status"),
            "prompt_type": prompt,
            "attempt": attempt,
            "rtl": str(rtl.relative_to(ROOT)),
            "compile_ok": None,
            "simulate_ok": None,
            "strict_pass": False,
            "error": OPEN_SOURCE_UNSUPPORTED[circuit],
            "timestamp": utc_now(),
        }
    top, compile_args, sources = simulation_arguments(circuit, rtl)
    simulation = work / "simulation.vvp"
    compile_command = ["iverilog", *compile_args, "-o", str(simulation), *map(str, sources)]
    compile_rc, compile_log, compile_timeout = run_command(
        compile_command, timeout=timeout, cwd=work
    )
    (work / "compile.log").write_text(compile_log)
    compile_ok = compile_rc == 0 and simulation.exists()
    result: dict = {
        "evaluator": "AK_open_source_v1",
        "circuit": circuit,
        "benchmark_status": manifest_scalar(circuit, "status"),
        "prompt_type": prompt,
        "attempt": attempt,
        "rtl": str(rtl.relative_to(ROOT)),
        "compile_ok": compile_ok,
        "compile_returncode": compile_rc,
        "compile_timeout": compile_timeout,
        "compile_log": str((work / "compile.log").relative_to(ROOT)),
        "simulate_ok": None,
        "simulation_timeout": False,
        "dynamic_cdc_protocol_evidence": False,
        "timestamp": utc_now(),
    }
    if not compile_ok:
        return result

    sim_rc, sim_log, sim_timeout = run_command(
        ["vvp", str(simulation)], timeout=timeout, cwd=work
    )
    (work / "simulation.log").write_text(sim_log)
    result.update(
        simulate_ok=(sim_rc == 0 and bool(PASS_RE.search(sim_log)) and not FAIL_RE.search(sim_log)),
        simulation_returncode=sim_rc,
        simulation_timeout=sim_timeout,
        dynamic_cdc_protocol_evidence=bool(DYNAMIC_RE.search(sim_log)),
        simulation_log=str((work / "simulation.log").relative_to(ROOT)),
    )
    structural = structural_check(
        circuit, rtl, top, compile_args, sources, work, timeout
    )
    result.update(structural)
    result["strict_pass"] = bool(result["simulate_ok"] and result["structural_clean"])
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model-dir", default=str(MODEL_DIR.relative_to(ROOT)))
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--timeout", type=int, default=60)
    parser.add_argument("--calibrate-golden", action="store_true")
    args = parser.parse_args()
    if args.calibrate_golden:
        rows = []
        for manifest in sorted((ROOT / "benchmarks").glob("*/manifest.yaml")):
            circuit = manifest.parent.name
            try:
                result = evaluate_one(
                    circuit, "_golden", "attempt-000", top_rtl_for(circuit), args.timeout
                )
            except Exception as exc:
                result = {
                    "circuit": circuit,
                    "compile_ok": None,
                    "simulate_ok": None,
                    "strict_pass": False,
                    "error": f"{type(exc).__name__}: {exc}",
                    "timestamp": utc_now(),
                }
            rows.append(result)
            print(
                f"GOLDEN {circuit} compile={result.get('compile_ok')} "
                f"functional={result.get('simulate_ok')} strict={result.get('strict_pass')} "
                f"{result.get('error', '')}",
                flush=True,
            )
        destination = ROOT / "build" / "AK_codev_r1" / "golden_calibration.json"
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(json.dumps(rows, indent=2) + "\n")
        print(f"Wrote {destination.relative_to(ROOT)} ({len(rows)} records)")
        return 0
    model_dir = ROOT / args.model_dir
    items = list(iter_generated(model_dir))
    if args.limit:
        items = items[: args.limit]
    summary = model_dir / "AK_open_source_eval_summary.json"
    rows = []
    for index, (circuit, prompt, attempt, rtl) in enumerate(items, 1):
        try:
            result = evaluate_one(circuit, prompt, attempt, rtl, args.timeout)
        except Exception as exc:  # preserve every candidate and continue the matrix
            result = {
                "evaluator": "AK_open_source_v1",
                "circuit": circuit,
                "prompt_type": prompt,
                "attempt": attempt,
                "rtl": str(rtl.relative_to(ROOT)),
                "compile_ok": None,
                "simulate_ok": None,
                "strict_pass": False,
                "error": f"{type(exc).__name__}: {exc}",
                "timestamp": utc_now(),
            }
        (rtl.parent.parent / "results.json").write_text(json.dumps(result, indent=2) + "\n")
        rows.append(result)
        summary.write_text(json.dumps(rows, indent=2) + "\n")
        print(
            f"{index}/{len(items)} {circuit}/{prompt}/{attempt} "
            f"compile={result.get('compile_ok')} functional={result.get('simulate_ok')} "
            f"structural={result.get('structural_clean')} strict={result.get('strict_pass')} "
            f"{result.get('error', '')}",
            flush=True,
        )
    print(f"Wrote {summary.relative_to(ROOT)} ({len(rows)} records)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
