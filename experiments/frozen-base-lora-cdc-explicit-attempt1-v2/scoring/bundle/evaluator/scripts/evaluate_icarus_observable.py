#!/usr/bin/env python3
"""Evaluate observable-prompt RTL with Icarus without replacing Xcelium results."""

from __future__ import annotations

import argparse
import json
import re
import shlex
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from evaluate_generated import manifest_scalar, top_rtl_for  # noqa: E402


PASS_RE = re.compile(r"(?:ALL TESTS PASSED|TESTS PASSED|TEST PASSED)", re.I)
FAIL_RE = re.compile(
    r"(?:TESTS? FAILED|ASSERT(?:ION)? FAIL|CDC/RESET VIOLATION|"
    r"PROTOCOL VIOLATION|\bTIMEOUT\b|\bFATAL\b)",
    re.I,
)
UNSUPPORTED = {
    "apb_regs": (
        "Icarus cannot elaborate the checked-in interface/type-parameter "
        "testbench stack"
    ),
    "cdc_2phase_clearable": (
        "Icarus cannot parse the required common_cells type parameters"
    ),
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def discover(experiment_root: Path):
    seen = set()
    for rtl in sorted(experiment_root.glob("*/*/*/attempt-???/generated/*.v")):
        parts = rtl.relative_to(experiment_root).parts
        model_dir, circuit, prompt, attempt = parts[:4]
        if prompt not in {"functional", "cdc_explicit", "observable"}:
            continue
        if not re.fullmatch(r"attempt-\d{3}", attempt):
            continue
        key = (model_dir, circuit, prompt, attempt)
        if key in seen:
            continue
        seen.add(key)
        yield model_dir, circuit, prompt, attempt, rtl


def simulation_arguments(circuit: str, candidate: Path):
    bench = ROOT / "benchmarks" / circuit
    script = bench / manifest_scalar(circuit, "simulation")
    text = script.read_text().replace("\\\n", " ")
    command = re.search(r"(?m)^xrun\s+(.+)$", text)
    if not command:
        raise RuntimeError(f"{circuit}: simulation script has no xrun command")

    variables = {"ROOT": str(ROOT), "BENCH": str(bench)}
    for name, quoted, bare in re.findall(
        r'(?m)^([A-Za-z_]\w*)=(?:"([^"]*)"|([^\s#]+))\s*$', text[: command.start()]
    ):
        value = quoted or bare
        for known_name, known_value in variables.items():
            value = value.replace(f"${{{known_name}}}", known_value)
            value = value.replace(f"${known_name}", known_value)
        if "$(" not in value and "${BASH_SOURCE" not in value:
            variables[name] = value

    expanded = command.group(1)
    expanded = expanded.replace('"${XRUN_MODE[@]}"', "").replace(
        "${XRUN_MODE[@]}", ""
    )
    for name, value in variables.items():
        expanded = expanded.replace(f"${{{name}}}", value)
        expanded = expanded.replace(f"${name}", value)
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
    if fixed_top not in sources:
        raise RuntimeError(
            f"{circuit}: fixed top {fixed_top} absent from simulation command"
        )
    sources = [
        candidate.resolve() if source == fixed_top else source for source in sources
    ]
    args = ["-g2012", "-Wall", "-s", top]
    args += [item for directory in include_dirs for item in ("-I", directory)]
    args += [item for define in defines for item in ("-D", define)]
    return args, sources


def run(command: list[str], timeout: int, cwd: Path):
    try:
        completed = subprocess.run(
            command,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
        return completed.returncode, completed.stdout + completed.stderr, False
    except subprocess.TimeoutExpired as exc:
        output = (exc.stdout or "") + (exc.stderr or "")
        if isinstance(output, bytes):
            output = output.decode(errors="replace")
        return None, output, True


def evaluate(
    model: str,
    circuit: str,
    prompt: str,
    attempt: str,
    rtl: Path,
    timeout: int,
):
    result = {
        "evaluator": "icarus_observable_v1",
        "model": model,
        "circuit": circuit,
        "benchmark_status": manifest_scalar(circuit, "status"),
        "prompt_type": prompt,
        "attempt": attempt,
        "rtl": str(rtl.relative_to(ROOT)),
        "timestamp": utc_now(),
    }
    if circuit in UNSUPPORTED:
        result.update(
            compile_ok=None,
            simulate_ok=None,
            tool_error=True,
            strict_pass=False,
            error=UNSUPPORTED[circuit],
        )
        return result

    args, sources = simulation_arguments(circuit, rtl)
    work = (
        ROOT
        / "build"
        / "icarus-observable-v1"
        / model
        / circuit
        / prompt
        / attempt
    )
    work.mkdir(parents=True, exist_ok=True)
    executable = work / "simulation.vvp"
    compile_command = [
        "iverilog",
        *args,
        "-o",
        str(executable),
        *map(str, sources),
    ]
    compile_rc, compile_log, compile_timeout = run(
        compile_command, timeout=timeout, cwd=work
    )
    compile_log_path = work / "compile.log"
    compile_log_path.write_text(compile_log)
    compile_ok = compile_rc == 0 and executable.exists()
    result.update(
        compile_ok=compile_ok,
        compile_returncode=compile_rc,
        compile_timeout=compile_timeout,
        compile_log=str(compile_log_path.relative_to(ROOT)),
        simulate_ok=None,
        simulation_timeout=False,
        strict_pass=False,
    )
    if not compile_ok:
        return result

    simulation_rc, simulation_log, simulation_timeout = run(
        ["vvp", str(executable)], timeout=timeout, cwd=work
    )
    simulation_log_path = work / "simulation.log"
    simulation_log_path.write_text(simulation_log)
    simulate_ok = (
        simulation_rc == 0
        and bool(PASS_RE.search(simulation_log))
        and not FAIL_RE.search(simulation_log)
    )
    result.update(
        simulate_ok=simulate_ok,
        simulation_returncode=simulation_rc,
        simulation_timeout=simulation_timeout,
        simulation_log=str(simulation_log_path.relative_to(ROOT)),
        strict_pass=simulate_ok,
    )
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--experiment-root",
        default="experiments/multi-llm-observable-v1/openrouter",
    )
    parser.add_argument("--timeout", type=int, default=60)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    experiment_root = (ROOT / args.experiment_root).resolve()
    items = list(discover(experiment_root))
    if args.limit:
        items = items[: args.limit]
    summary_name = (
        "icarus_3prompt_summary.json"
        if "3prompt" in str(experiment_root)
        else "icarus_observable_summary.json"
    )
    summary_path = experiment_root / summary_name
    rows = []
    for index, (model, circuit, prompt, attempt, rtl) in enumerate(items, 1):
        result_path = rtl.parent.parent / "icarus_results.json"
        if result_path.exists() and not args.force:
            result = json.loads(result_path.read_text())
            action = "SKIP"
        else:
            try:
                result = evaluate(
                    model, circuit, prompt, attempt, rtl, args.timeout
                )
            except Exception as exc:
                result = {
                    "evaluator": "icarus_observable_v1",
                    "model": model,
                    "circuit": circuit,
                    "prompt_type": prompt,
                    "attempt": attempt,
                    "rtl": str(rtl.relative_to(ROOT)),
                    "compile_ok": None,
                    "simulate_ok": None,
                    "tool_error": True,
                    "strict_pass": False,
                    "error": f"{type(exc).__name__}: {exc}",
                    "timestamp": utc_now(),
                }
            result_path.write_text(json.dumps(result, indent=2) + "\n")
            action = "RUN"
        rows.append(result)
        summary_path.write_text(json.dumps(rows, indent=2) + "\n")
        print(
            f"{index}/{len(items)} {action} {model}/{circuit}/{attempt} "
            f"compile={result.get('compile_ok')} "
            f"functional={result.get('simulate_ok')} "
            f"{result.get('error', '')}",
            flush=True,
        )

    print(
        f"DONE n={len(rows)} "
        f"compile={sum(r.get('compile_ok') is True for r in rows)} "
        f"functional={sum(r.get('simulate_ok') is True for r in rows)} "
        f"tool_error={sum(r.get('tool_error') is True for r in rows)} "
        f"summary={summary_path}",
        flush=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
