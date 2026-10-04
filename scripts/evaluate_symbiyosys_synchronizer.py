#!/usr/bin/env python3
"""Run the validated synchronizer formal contract on generated RTL."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HARNESS = ROOT / "formal/synchronizer/synchronizer_formal.sv"
BUILD = ROOT / "build/formal/synchronizer"
SUMMARY = ROOT / "formal/synchronizer/generated_summary.json"
DEFAULT_SBY = Path.home() / "tools/oss-cad-suite/bin/sby"


def discover() -> list[tuple[str, str, str, Path]]:
    rows: list[tuple[str, str, str, Path]] = []
    openrouter = ROOT / "experiments/multi-llm-observable-v1/openrouter"
    for rtl in sorted(
        openrouter.glob(
            "*/synchronizer/observable/attempt-???/generated/synchronizer.v"
        )
    ):
        model, _, prompt, attempt, _, _ = rtl.relative_to(openrouter).parts
        rows.append((model, prompt, attempt, rtl))

    complex_root = ROOT / "experiments/complexvcoder-3prompt-10attempt-v1"
    for rtl in sorted(
        complex_root.glob("synchronizer/*/attempt-???/generated/synchronizer.v")
    ):
        _, prompt, attempt, _, _ = rtl.relative_to(complex_root).parts
        rows.append(("complexvcoder-3prompt", prompt, attempt, rtl))
    return rows


def safe_name(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value)


def evaluate(
    sby: Path,
    model: str,
    prompt: str,
    attempt: str,
    rtl: Path,
    timeout: int,
) -> dict:
    identity = f"{model}/{prompt}/{attempt}"
    digest = hashlib.sha256(identity.encode()).hexdigest()[:10]
    work = BUILD / safe_name(model) / prompt / attempt
    config_dir = BUILD / "configs"
    config_dir.mkdir(parents=True, exist_ok=True)
    config = config_dir / f"{safe_name(model)}-{prompt}-{attempt}-{digest}.sby"
    config.write_text(
        f"""[options]
mode prove
depth 20

[engines]
smtbmc boolector

[script]
read -formal -sv {rtl.name} {HARNESS.name}
prep -top synchronizer_formal

[files]
{rtl.resolve()}
{HARNESS.resolve()}
"""
    )
    started = datetime.now(timezone.utc).isoformat()
    env = {
        **os.environ,
        "PATH": f"{sby.parent}:{os.environ.get('PATH', '')}",
    }
    try:
        completed = subprocess.run(
            [str(sby), "-f", "-d", str(work), str(config)],
            cwd=ROOT,
            env=env,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
        status_path = work / "status"
        raw_status = (
            status_path.read_text().strip()
            if status_path.exists()
            else ("ERROR" if completed.returncode else "UNKNOWN")
        )
        status = raw_status.split()[0]
        timed_out = False
        driver_log = completed.stdout + completed.stderr
    except subprocess.TimeoutExpired as exc:
        status = "TIMEOUT"
        timed_out = True
        output = (exc.stdout or "") + (exc.stderr or "")
        driver_log = output.decode(errors="replace") if isinstance(output, bytes) else output
    work.mkdir(parents=True, exist_ok=True)
    (work / "driver.log").write_text(driver_log)
    return {
        "evaluator": "symbiyosys_synchronizer_v1",
        "model": model,
        "circuit": "synchronizer",
        "prompt_type": prompt,
        "attempt": attempt,
        "rtl": str(rtl.relative_to(ROOT)),
        "status": status,
        "proved": status == "PASS",
        "counterexample": status == "FAIL",
        "timeout": timed_out,
        "depth": 20,
        "engine": "smtbmc boolector",
        "started_utc": started,
        "work_dir": str(work.relative_to(ROOT)),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sby", type=Path, default=DEFAULT_SBY)
    parser.add_argument("--timeout", type=int, default=60)
    parser.add_argument("--limit", type=int, default=0)
    args = parser.parse_args()
    if not args.sby.is_file():
        raise SystemExit(f"SymbiYosys not found: {args.sby}")

    items = discover()
    if args.limit:
        items = items[: args.limit]
    rows = []
    for index, (model, prompt, attempt, rtl) in enumerate(items, 1):
        result = evaluate(args.sby, model, prompt, attempt, rtl, args.timeout)
        rows.append(result)
        SUMMARY.write_text(json.dumps(rows, indent=2) + "\n")
        print(
            f"{index}/{len(items)} {model}/{prompt}/{attempt}: "
            f"{result['status']}",
            flush=True,
        )

    counts = {
        status: sum(row["status"] == status for row in rows)
        for status in ("PASS", "FAIL", "ERROR", "TIMEOUT", "UNKNOWN")
    }
    print(f"DONE {counts} summary={SUMMARY}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
