#!/usr/bin/env python3
"""Run enhanced procedural-Verilog TBs on golden or generated RTL."""

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
TB_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(ROOT / "cdc_tb_checks"))

from evaluate_generated import (  # noqa: E402
    evaluation_sim_script,
    manifest_scalar,
    top_rtl_for,
)
from lint_cdc import lint_text  # noqa: E402

MODELS = {
    "complexvcoder": ROOT / "complexvcoder",
    "qwen-32b": ROOT / "experiments/qwen-2.5-coder-32b-instruct",
    "llama-70b-openrouter": ROOT
    / "experiments/multi-llm-passk/openrouter/meta-llama__llama-3.3-70b-instruct",
    "gpt-5.6-sol": ROOT
    / "experiments/multi-llm-passk/openai/gpt-5.6-sol",
}


def simulation_top(circuit: str) -> str:
    script = ROOT / "benchmarks" / circuit / manifest_scalar(circuit, "simulation")
    match = re.search(r"(?:^|\s)-top\s+([A-Za-z_]\w*)", script.read_text(), re.M)
    if not match:
        raise RuntimeError(f"{circuit}: cannot find -top in {script}")
    return match.group(1)


def canonical_tb(circuit: str) -> Path:
    bench = ROOT / "benchmarks" / circuit
    script = bench / manifest_scalar(circuit, "simulation")
    top = simulation_top(circuit)
    candidates = [
        bench / rel
        for rel in re.findall(r'"\$BENCH/(tb/[^"\n]+\.(?:v|sv))"', script.read_text())
    ]
    definition = re.compile(rf"^\s*module\s+{re.escape(top)}\b", re.M)
    matches = [
        path
        for path in candidates
        if path.exists() and definition.search(path.read_text(errors="replace"))
    ]
    if len(matches) != 1:
        raise RuntimeError(
            f"{circuit}: expected one canonical TB defining {top}, found {matches}"
        )
    return matches[0]


def enhanced_tb(circuit: str) -> Path | None:
    accepted = {
        f"{circuit}_tb",
        f"{circuit}_enhanced_tb",
        f"{circuit}_smoke_tb",
        f"{circuit}_assert",
    }
    matches = [
        path
        for suffix in ("*.v", "*.sv")
        for path in TB_ROOT.glob(f"*/{suffix}")
        if path.stem in accepted
    ]
    if len(matches) > 1:
        raise RuntimeError(f"{circuit}: multiple enhanced TBs found: {matches}")
    return matches[0] if matches else None


def enhanced_top(path: Path) -> str:
    match = re.search(
        r"^\s*module\s+([A-Za-z_]\w*)\b",
        path.read_text(errors="replace"),
        re.M,
    )
    if not match:
        raise RuntimeError(f"{path}: no module declaration")
    return match.group(1)


def generated_rows(model: str, model_dir: Path):
    for rtl in sorted(model_dir.glob("*/*/attempt-*/generated/*.v")):
        parts = rtl.relative_to(model_dir).parts
        if len(parts) < 5:
            continue
        circuit, prompt, attempt = parts[:3]
        yield {
            "source": model,
            "circuit": circuit,
            "prompt": prompt,
            "attempt": attempt,
            "rtl": rtl,
        }


def golden_rows():
    for manifest in sorted((ROOT / "benchmarks").glob("*/manifest.yaml")):
        circuit = manifest.parent.name
        if enhanced_tb(circuit):
            yield {
                "source": "golden",
                "circuit": circuit,
                "prompt": "reference",
                "attempt": "fixed",
                "rtl": top_rtl_for(circuit),
            }


def runtime_text(text: str) -> str:
    return "\n".join(
        line
        for line in text.splitlines()
        if "$display" not in line and "$finish" not in line
    )


def run_one(row: dict) -> dict:
    circuit = row["circuit"]
    rtl = Path(row["rtl"])
    tb = enhanced_tb(circuit)
    if not tb:
        return {"status": "SKIP", "note": "no enhanced TB"}

    lint_hits = lint_text(rtl.read_text(errors="replace"), str(rtl))
    work = (
        ROOT
        / "build/enhanced_cdc_tb"
        / row["source"]
        / circuit
        / row["prompt"]
        / row["attempt"]
    )
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True)
    runner, log = evaluation_sim_script(rtl, circuit, work, compile_only=False)

    original = canonical_tb(circuit)
    rel = original.relative_to(ROOT / "benchmarks" / circuit).as_posix()
    text = runner.read_text()
    old = f'"$BENCH/{rel}"'
    if old not in text:
        raise RuntimeError(f"{circuit}: runner does not contain {old}")
    text = text.replace(old, f'"{tb.resolve()}"', 1)
    canonical_top = simulation_top(circuit)
    text, top_count = re.subn(
        rf"(-top\s+){re.escape(canonical_top)}\b",
        rf"\1{enhanced_top(tb)}",
        text,
        count=1,
    )
    if top_count != 1:
        raise RuntimeError(f"{circuit}: could not replace simulation top")
    runner.write_text(text)

    try:
        completed = subprocess.run(
            [str(runner)],
            cwd=ROOT,
            env={**os.environ, "CDC_CHECKS": "0"},
            capture_output=True,
            text=True,
            timeout=180,
        )
        log_text = (
            log.read_text(errors="replace")
            if log.exists()
            else completed.stdout + completed.stderr
        )
    except subprocess.TimeoutExpired:
        return {
            "status": "FAIL",
            "note": "xrun timeout 180s",
            "lint_ok": not lint_hits,
            "lint_hits": lint_hits,
        }

    runtime = runtime_text(log_text)
    compile_error = bool(re.search(r"\b(?:xmvlog|xmelab): \*[EF],", log_text))
    violation = re.search(
        r"^.*(?:CDC(?:/RESET)? VIOLATION|PROTOCOL VIOLATION|"
        r"TESTS FAILED|TIMEOUT|ENHANCED FAIL).*$",
        runtime,
        re.M,
    )
    pass_line = re.search(
        r"^.*(?:ALL TESTS PASSED|ENHANCED PASS).*$", runtime, re.M
    )
    if compile_error:
        status, note = "FAIL", "compile fail"
    elif violation:
        status, note = "FAIL", violation.group(0).strip()[:200]
    elif completed.returncode != 0:
        status, note = "FAIL", f"xrun return code {completed.returncode}"
    elif pass_line:
        status, note = "PASS", pass_line.group(0).strip()[:200]
    else:
        status, note = "FAIL", "no pass marker"
    return {
        "status": status,
        "note": note,
        "lint_ok": not lint_hits,
        "lint_hits": lint_hits,
        "log": str(log.relative_to(ROOT)) if log.exists() else None,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        choices=["golden", "all", *MODELS],
        default="golden",
        help="RTL source to test",
    )
    parser.add_argument("--circuit", action="append", help="repeat to select circuits")
    parser.add_argument("--limit", type=int, default=0)
    args = parser.parse_args()

    rows = []
    if args.source in {"golden", "all"}:
        rows.extend(golden_rows())
    if args.source != "golden":
        selected = MODELS.items() if args.source == "all" else [(args.source, MODELS[args.source])]
        for model, directory in selected:
            rows.extend(generated_rows(model, directory))
    if args.circuit:
        wanted = set(args.circuit)
        rows = [row for row in rows if row["circuit"] in wanted]
    if args.limit:
        rows = rows[: args.limit]

    print(f"Running {len(rows)} enhanced TB evaluations", flush=True)
    results = []
    for index, row in enumerate(rows, 1):
        printable = {**row, "rtl": str(Path(row["rtl"]).relative_to(ROOT))}
        try:
            result = run_one(row)
        except Exception as exc:
            result = {"status": "FAIL", "note": f"runner error: {exc}"}
        printable.update(result)
        results.append(printable)
        print(
            f"{index}/{len(rows)} {row['source']} {row['circuit']}/"
            f"{row['prompt']}/{row['attempt']} {result['status']} "
            f"{result['note']}",
            flush=True,
        )

    totals = defaultdict(lambda: {"n": 0, "pass": 0, "fail": 0, "skip": 0})
    for result in results:
        cell = totals[result["source"]]
        cell["n"] += 1
        cell[result["status"].lower()] += 1
    payload = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "source": args.source,
        "n": len(results),
        "totals": dict(totals),
        "results": results,
    }
    out = TB_ROOT / "results"
    out.mkdir(parents=True, exist_ok=True)
    path = out / f"{args.source}.json"
    path.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"Wrote {path}")
    return 0 if all(r["status"] != "FAIL" for r in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
