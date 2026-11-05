#!/usr/bin/env python3
"""Prove generated RTL only on circuits whose golden formal contract passed."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parents[1]
FORMAL = ROOT / "formal"
BUILD = ROOT / "build/formal/eligible"
SUMMARY = FORMAL / "eligible_generated_summary.json"
COMPLEX = ROOT / "experiments/complexvcoder-3prompt-10attempt-v1"
OPENROUTER = ROOT / "experiments/multi-llm-observable-v1/openrouter"
DEFAULT_SBY = Path.home() / "tools/oss-cad-suite/bin/sby"


def eligible_circuits() -> list[str]:
    circuits = []
    for marker in sorted(FORMAL.glob("*/golden_prove/PASS")):
        circuits.append(marker.parent.parent.name)
    return circuits


def parse_sby(path: Path) -> dict:
    sections: dict[str, list[str]] = {}
    current = None
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            current = line[1:-1]
            sections.setdefault(current, [])
            continue
        if current is None:
            continue
        sections[current].append(line)

    options = {}
    for item in sections.get("options", []):
        if item.startswith("prove:"):
            key, value = item.split(":", 1)[1].strip().split(None, 1)
            options[key] = value
        elif " " in item:
            key, value = item.split(None, 1)
            options[key] = value
        else:
            options[item] = True

    files = sections.get("files", [])
    harness = None
    deps = []
    for name in files:
        raw = Path(name)
        resolved = raw.resolve() if raw.is_absolute() else (path.parent / raw).resolve()
        if raw.name.endswith("_formal.sv"):
            harness = resolved
        elif resolved.is_file():
            deps.append(resolved)
    if harness is None or not harness.is_file():
        raise RuntimeError(f"{path}: formal harness not found")

    script = " ".join(sections.get("script", []))
    match = re.search(r"prep\s+-top\s+(\S+)", script)
    if not match:
        raise RuntimeError(f"{path}: no prep -top")
    slang = "read_slang" in script
    return {
        "mode": options.get("mode", "bmc"),
        "depth": int(options.get("depth", 20)),
        "multiclock": bool(options.get("multiclock")),
        "top": match.group(1),
        "harness": harness,
        "deps": deps,
        "slang": slang,
        "engine": " ".join(sections.get("engines", ["smtbmc boolector"])),
    }


def discover(circuits: list[str], models: Optional[set] = None) -> list[tuple[str, str, str, str, Path]]:
    rows = []
    if models is None or "complexvcoder-3prompt" in models:
        for circuit in circuits:
            for rtl in sorted(COMPLEX.glob(f"{circuit}/*/attempt-???/generated/*.v")):
                prompt, attempt = rtl.relative_to(COMPLEX / circuit).parts[:2]
                if re.fullmatch(r"attempt-\d{3}", attempt):
                    rows.append(("complexvcoder-3prompt", circuit, prompt, attempt, rtl))
    if OPENROUTER.is_dir():
        for rtl in sorted(OPENROUTER.glob("*/*/*/attempt-???/generated/*.v")):
            model, circuit, prompt, attempt = rtl.relative_to(OPENROUTER).parts[:4]
            if circuit not in circuits:
                continue
            if models is not None and model not in models:
                continue
            if re.fullmatch(r"attempt-\d{3}", attempt):
                rows.append((model, circuit, prompt, attempt, rtl))
    return rows


def safe_name(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value)


def classify(status: str, returncode: int, log: str) -> str:
    if status == "PASS":
        return "FORMAL_PROVED"
    if status == "FAIL":
        return "FORMAL_COUNTEREXAMPLE"
    if status == "TIMEOUT":
        return "FORMAL_TIMEOUT"
    if "ERROR" in log or returncode not in {0, None}:
        return "FORMAL_ELAB_ERROR"
    return "FORMAL_INCONCLUSIVE"


def evaluate(sby: Path, model: str, circuit: str, prompt: str, attempt: str, rtl: Path, contract: dict, timeout: int) -> dict:
    work = BUILD / circuit / safe_name(model) / prompt / attempt
    config = work / "candidate.sby"
    work.mkdir(parents=True, exist_ok=True)
    options = [
        f"mode {contract['mode']}",
        f"depth {contract['depth']}",
    ]
    if contract["multiclock"]:
        options.append("multiclock on")
    extra_deps = [
        dep
        for dep in contract.get("deps", [])
        if dep.name != rtl.name and dep.stem != rtl.stem
    ]
    listed = [rtl.resolve(), contract["harness"], *extra_deps]
    if contract.get("slang"):
        inc = []
        for dep in extra_deps:
            parent = dep.parent
            if parent.name == "include" or (parent.parent / "include").is_dir():
                inc.append(f"-I {parent}")
        inc_s = (" " + " ".join(dict.fromkeys(inc))) if inc else ""
        names = " ".join(path.name for path in listed)
        script = f"read_slang --single-unit{inc_s} {names}\nprep -top {contract['top']}"
    else:
        names = " ".join(path.name for path in listed)
        script = f"read -formal -sv {names}\nprep -top {contract['top']}"
    file_block = "\n".join(str(path) for path in listed)
    config.write_text(
        "[options]\n"
        + "\n".join(options)
        + f"""

[engines]
{contract['engine']}

[script]
{script}

[files]
{file_block}
"""
    )
    started = datetime.now(timezone.utc).isoformat()
    env = {**os.environ, "PATH": f"{sby.parent}:{os.environ.get('PATH', '')}"}
    timed_out = False
    returncode = None
    try:
        completed = subprocess.run(
            [str(sby), "-f", "-d", str(work / "run"), str(config)],
            cwd=ROOT,
            env=env,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
        returncode = completed.returncode
        driver_log = completed.stdout + completed.stderr
        status_path = work / "run" / "status"
        raw = status_path.read_text().strip() if status_path.exists() else ("ERROR" if returncode else "UNKNOWN")
        status = raw.split()[0]
    except subprocess.TimeoutExpired as exc:
        status = "TIMEOUT"
        timed_out = True
        chunks = []
        for part in (exc.stdout, exc.stderr):
            if part is None:
                continue
            chunks.append(part.decode(errors="replace") if isinstance(part, bytes) else part)
        driver_log = "".join(chunks)
    (work / "driver.log").write_text(driver_log)
    formal_status = classify(status, returncode if not timed_out else None, driver_log)
    return {
        "evaluator": "symbiyosys_eligible_v1",
        "model": model,
        "circuit": circuit,
        "prompt_type": prompt,
        "attempt": attempt,
        "rtl": str(rtl.relative_to(ROOT)),
        "engine_status": status,
        "formal_status": formal_status,
        "proved": formal_status == "FORMAL_PROVED",
        "counterexample": formal_status == "FORMAL_COUNTEREXAMPLE",
        "timeout": timed_out,
        "depth": contract["depth"],
        "mode": contract["mode"],
        "top": contract["top"],
        "started_utc": started,
        "work_dir": str(work.relative_to(ROOT)),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sby", type=Path, default=DEFAULT_SBY)
    parser.add_argument("--timeout", type=int, default=90)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument(
        "--models",
        default="",
        help="Comma-separated model directory names. Empty = all discovered models.",
    )
    parser.add_argument(
        "--circuits",
        default="",
        help="Comma-separated circuit names. Empty = all golden-PASS circuits.",
    )
    parser.add_argument(
        "--resume",
        action="store_true",
        help="Keep existing summary rows and skip already scored identities.",
    )
    parser.add_argument(
        "--summary",
        type=Path,
        default=SUMMARY,
        help="Output JSON path.",
    )
    args = parser.parse_args()
    summary_path = args.summary if args.summary.is_absolute() else (ROOT / args.summary)
    if not args.sby.is_file():
        raise SystemExit(f"SymbiYosys not found: {args.sby}")

    circuits = eligible_circuits()
    if args.circuits:
        wanted = {item.strip() for item in args.circuits.split(",") if item.strip()}
        circuits = [c for c in circuits if c in wanted]
    contracts = {circuit: parse_sby(FORMAL / circuit / "golden.sby") for circuit in circuits}
    models = {item.strip() for item in args.models.split(",") if item.strip()} or None
    items = discover(circuits, models)
    rows = []
    seen = set()
    if args.resume and summary_path.exists():
        rows = json.loads(summary_path.read_text())
        seen = {(r["model"], r["circuit"], r["prompt_type"], r["attempt"]) for r in rows}
        items = [item for item in items if item[:4] not in seen]
    if args.limit:
        items = items[: args.limit]
    print(
        f"Eligible circuits: {len(circuits)} -> {', '.join(circuits)}",
        flush=True,
    )
    print(f"Pending candidates: {len(items)}; already scored: {len(seen)}", flush=True)

    for index, (model, circuit, prompt, attempt, rtl) in enumerate(items, 1):
        result = evaluate(
            args.sby, model, circuit, prompt, attempt, rtl, contracts[circuit], args.timeout
        )
        rows.append(result)
        summary_path.write_text(json.dumps(rows, indent=2) + "\n")
        print(
            f"{index}/{len(items)} {model}/{circuit}/{prompt}/{attempt}: "
            f"{result['formal_status']}",
            flush=True,
        )

    counts = {}
    for row in rows:
        counts[row["formal_status"]] = counts.get(row["formal_status"], 0) + 1
    print(f"DONE {counts} summary={summary_path}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
