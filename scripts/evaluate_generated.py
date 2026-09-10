#!/usr/bin/env python3
"""Compile-check generated RTL candidates against the benchmark testbenches."""

import argparse
import json
import os
import re
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def manifest_text(circuit: str) -> str:
    man = ROOT / "benchmarks" / circuit / "manifest.yaml"
    if not man.exists():
        raise KeyError(f"no benchmark manifest for {circuit}")
    return man.read_text()


def manifest_scalar(circuit: str, key: str) -> str:
    match = re.search(rf"^{re.escape(key)}:\s*(\S+)", manifest_text(circuit), re.M)
    if not match:
        raise KeyError(f"{circuit}: manifest has no {key}")
    return match.group(1)


def manifest_list(circuit: str, key: str) -> list[str]:
    text = manifest_text(circuit)
    match = re.search(
        rf"^{re.escape(key)}:\s*\n((?:[ \t]+-[^\n]*\n?)+)", text, re.M
    )
    if not match:
        raise KeyError(f"{circuit}: manifest has no {key}")
    return re.findall(r"^[ \t]+-\s*(\S+)", match.group(1), re.M)


def top_rtl_for(circuit: str) -> Path:
    """Return the fixed RTL file that defines the requested top module."""
    bench = ROOT / "benchmarks" / circuit
    top = manifest_scalar(circuit, "top_module")
    definition = re.compile(rf"^\s*module\s+{re.escape(top)}\b", re.M)
    matches = [
        bench / rel
        for rel in manifest_list(circuit, "rtl_fixed")
        if definition.search((bench / rel).read_text(errors="replace"))
    ]
    if len(matches) != 1:
        raise RuntimeError(
            f"{circuit}: expected one fixed RTL file defining {top}, found {matches}"
        )
    return matches[0]


def evaluation_sim_script(
    rtl: Path, circuit: str, work: Path, *, compile_only: bool
) -> tuple[Path, Path]:
    """Derive the benchmark's xrun script with the generated top substituted."""
    bench = ROOT / "benchmarks" / circuit
    source = bench / manifest_scalar(circuit, "simulation")
    top_rtl = top_rtl_for(circuit)
    text = source.read_text()
    text, root_count = re.subn(
        r'(?m)^ROOT=.*$',
        f'ROOT="{ROOT}"',
        text,
        count=1,
    )
    if root_count != 1:
        raise RuntimeError(f"{circuit}: simulation script has no unique ROOT")
    relative_top = top_rtl.relative_to(bench).as_posix()
    candidate_forms = (
        f'"$BENCH/{relative_top}"',
        f'"${{BENCH}}/{relative_top}"',
        str(top_rtl),
    )
    replacement = f'"{rtl.resolve()}"'
    for old in candidate_forms:
        if old in text:
            text = text.replace(old, replacement)
            break
    else:
        raise RuntimeError(
            f"{circuit}: simulation script does not reference {relative_top}"
        )

    log = work / ("compile.log" if compile_only else "sim.log")
    timeout = work / "timeout.tcl"
    timeout.write_text("run 50us\nexit\n")
    text = text.replace(
        'xrun "${XRUN_MODE[@]}"',
        f'xrun "${{XRUN_MODE[@]}}" -l "{log}" -input "{timeout}"',
        1,
    )
    if "-xmlibdirname" not in text:
        raise RuntimeError(f"{circuit}: simulation script has no -xmlibdirname")
    text = re.sub(
        r'(-xmlibdirname\s+)(?:"[^"]*"|\\\n\s*"[^"]*")',
        rf'\1"{work / "xcelium"}"',
        text,
        count=1,
    )
    runner = work / "run.sh"
    runner.write_text(text)
    runner.chmod(0o700)
    return runner, log


def evaluate(rtl: Path, circuit: str, out_dir: Path) -> dict:
    work = ROOT / "build" / "eval" / out_dir.relative_to(ROOT / "experiments")
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True)
    runner, log = evaluation_sim_script(rtl, circuit, work, compile_only=True)
    completed = subprocess.run(
        [str(runner)],
        cwd=ROOT,
        env={**os.environ, "COMPILE_ONLY": "1"},
        capture_output=True,
        text=True,
    )
    log_text = log.read_text(errors="replace") if log.exists() else completed.stdout + completed.stderr
    compile_ok = completed.returncode == 0 and not re.search(
        r"\b(?:xmvlog|xmelab): \*[EF],", log_text
    )
    result = {
        "circuit": circuit,
        "benchmark_status": manifest_scalar(circuit, "status"),
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
