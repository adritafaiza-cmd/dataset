#!/usr/bin/env python3
"""Repair existing Qwen2.5-Coder-32B RTL with bounded tool feedback.

ComplexVCoder uses Qwen2.5-Coder-7B through a graph intermediate. This script
does not run that pipeline. It starts from the direct Qwen2.5-Coder-32B
Verilog and asks the same model to repair it.

Three feedback settings fill the three repair-table rows:

  compile      compiler errors only
  functional   compiler errors, then the functional testbench log
  cdc          compiler errors, functional log, then enhanced CDC/reset log

A circuit-prompt pair passes @10 when any of its 10 attempts passes. An
attempt that already passes is kept and does not call the API. Each failing
attempt gets at most --max-rounds repair calls.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(ROOT / "enhanced_cdc_tb"))

from comparison_set import FIXED_16  # noqa: E402
from evaluate_generated import evaluate  # noqa: E402
from evaluate_pass_at_n import XRUN_BIN, simulate  # noqa: E402
from generate_openrouter import extract_verilog  # noqa: E402
from run_enhanced import run_one as enhanced_evaluate  # noqa: E402

LICENSE_ERROR = re.compile(
    r"Unable to check out|checkout license|License check failed|\*F,NOLIC",
    re.I,
)
MODEL = "qwen/qwen-2.5-coder-32b-instruct"
PROMPTS = ("functional", "cdc_explicit", "observable")
MODES = ("compile", "functional", "cdc")
QWEN_TAG = "qwen__qwen-2.5-coder-32b-instruct"
SOURCES = (
    (
        ROOT
        / "experiments/qwen25-16fix-3prompt-10attempt-v1/openrouter"
        / QWEN_TAG,
        FIXED_16,
    ),
    (
        ROOT / "experiments/multi-llm-3prompt-v1/openrouter" / QWEN_TAG,
        None,
    ),
    (
        ROOT / "experiments/multi-llm-observable-v1/openrouter" / QWEN_TAG,
        None,
    ),
)


def utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def circuits() -> list[str]:
    return sorted(
        p.name
        for p in (ROOT / "benchmarks").iterdir()
        if (p / "manifest.yaml").is_file()
        and (ROOT / "experiments/prompts" / f"{p.name}.functional.md").is_file()
    )


def discover(selected: set[str] | None) -> list[dict]:
    rows = []
    seen = set()
    for tree, allowed in SOURCES:
        if not tree.is_dir():
            continue
        for rtl in sorted(tree.rglob("generated/*.v")) + sorted(tree.rglob("generated/*.sv")):
            parts = rtl.relative_to(tree).parts
            if len(parts) < 4:
                continue
            circuit, prompt, attempt = parts[:3]
            if prompt not in PROMPTS or not re.fullmatch(r"attempt-\d{3}", attempt):
                continue
            if allowed is not None and circuit not in allowed:
                continue
            if allowed is None and circuit in FIXED_16:
                continue
            if selected is not None and circuit not in selected:
                continue
            key = (circuit, prompt, attempt)
            if key in seen:
                continue
            seen.add(key)
            rows.append(
                {
                    "circuit": circuit,
                    "prompt": prompt,
                    "attempt": attempt,
                    "rtl": rtl,
                }
            )
    return rows


def excerpt(text: str, limit: int = 2500) -> str:
    lines = [
        line
        for line in text.splitlines()
        if re.search(r"\*(E|F),|error|fail|violation|timeout", line, re.I)
    ]
    body = "\n".join(lines) if lines else text
    return body[-limit:]


def chat(api_key: str, messages: list[dict], max_tokens: int, timeout: int) -> tuple[dict, str]:
    payload = {
        "model": MODEL,
        "temperature": 0.2,
        "top_p": 0.95,
        "max_tokens": max_tokens,
        "messages": messages,
    }
    with tempfile.NamedTemporaryFile(prefix="qwen25-repair-", suffix=".json", delete=False) as handle:
        handle.write(json.dumps(payload).encode())
        tmp = Path(handle.name)
    completed = subprocess.run(
        [
            "curl",
            "-sS",
            "-X",
            "POST",
            "https://openrouter.ai/api/v1/chat/completions",
            "--connect-timeout",
            "15",
            "--max-time",
            str(timeout),
            "-H",
            f"Authorization: Bearer {api_key}",
            "-H",
            "Content-Type: application/json",
            "-H",
            "HTTP-Referer: https://github.com/adritafaiza-cmd/dataset",
            "-H",
            "X-Title: Qwen CDC repair",
            "--data-binary",
            f"@{tmp}",
            "-w",
            "\n%{http_code}",
        ],
        capture_output=True,
        text=True,
    )
    tmp.unlink(missing_ok=True)
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or "curl failed")
    body, _, status_text = completed.stdout.rpartition("\n")
    status = int(status_text or "0")
    if status != 200:
        raise RuntimeError(f"OpenRouter HTTP {status}: {body[:500]}")
    data = json.loads(body)
    return data, data["choices"][0]["message"]["content"]


def repair_message(mode: str, feedback: str) -> str:
    scope = {
        "compile": "The compiler errors are the only failure log.",
        "functional": "The compiler and functional testbench logs are the failure logs.",
        "cdc": "The compiler, functional testbench, and CDC assertion logs are the failure logs.",
    }[mode]
    return (
        "Repair the Verilog below. Keep the same module name and port list. "
        "Do not remove a clock-domain crossing to silence an error. "
        "Return one complete Verilog file only, with no Markdown and no explanation.\n\n"
        f"{scope}\n\n"
        f"Failure log:\n{feedback}\n"
    )


def score_once(rtl: Path, circuit: str, prompt: str, attempt: str, out_dir: Path, mode: str) -> dict:
    compiled = evaluate(rtl, circuit, out_dir)
    record = {
        "compile_ok": compiled.get("compile_ok") is True,
        "compile_log": compiled.get("log"),
        "functional_ok": False,
        "cdc_ok": False,
        "feedback": "",
    }
    if not record["compile_ok"]:
        log = ROOT / compiled["log"] if compiled.get("log") else None
        text = log.read_text(errors="replace") if log and log.is_file() else ""
        record["feedback"] = excerpt(text)
        return record

    if mode == "compile":
        functional = simulate(rtl, circuit, out_dir)
        record["functional_ok"] = functional.get("simulate_ok") is True
        record["functional_note"] = functional.get("sim_note")
        if record["functional_ok"]:
            record.update(score_cdc(rtl, circuit, prompt, attempt, out_dir))
        return record

    functional = simulate(rtl, circuit, out_dir)
    record["functional_ok"] = functional.get("simulate_ok") is True
    record["functional_note"] = functional.get("sim_note")
    if not record["functional_ok"]:
        log = ROOT / functional["sim_log"] if functional.get("sim_log") else None
        text = log.read_text(errors="replace") if log and log.is_file() else ""
        record["feedback"] = excerpt(text or functional.get("sim_note") or "")
        return record

    record.update(score_cdc(rtl, circuit, prompt, attempt, out_dir))
    if mode == "cdc" and not record["cdc_ok"]:
        record["feedback"] = record.get("cdc_note") or "CDC assertion failed"
    return record


def score_cdc(rtl: Path, circuit: str, prompt: str, attempt: str, out_dir: Path) -> dict:
    try:
        result = enhanced_evaluate(
            {
                "source": f"qwen25-repair-{out_dir.parent.name}",
                "circuit": circuit,
                "prompt": prompt,
                "attempt": attempt,
                "rtl": rtl.resolve(),
            }
        )
    except Exception as exc:
        return {"cdc_ok": False, "cdc_note": f"{type(exc).__name__}: {exc}"[:300]}
    (out_dir / "enhanced.json").write_text(json.dumps(result, indent=2) + "\n")
    return {
        "cdc_ok": result.get("status") == "PASS",
        "cdc_note": result.get("note"),
    }


def score(rtl: Path, circuit: str, prompt: str, attempt: str, out_dir: Path, mode: str) -> dict:
    record = score_once(rtl, circuit, prompt, attempt, out_dir, mode)
    for delay in (20, 40, 60):
        if not LICENSE_ERROR.search(record.get("feedback") or ""):
            return record
        time.sleep(delay)
        record = score_once(rtl, circuit, prompt, attempt, out_dir, mode)
    return record


def passed(mode: str, record: dict) -> bool:
    if mode == "compile":
        return record.get("compile_ok") is True
    if mode == "functional":
        return record.get("functional_ok") is True
    return record.get("cdc_ok") is True


def pass_at_10(rows: list[dict], field: str) -> float:
    groups: dict[tuple[str, str], list[bool]] = {}
    for row in rows:
        groups.setdefault((row["circuit"], row["prompt"]), []).append(row.get(field) is True)
    if not groups:
        return 0.0
    return sum(any(values) for values in groups.values()) / len(groups)


def save_summary(path: Path, mode: str, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "updated": utc(),
        "model": MODEL,
        "mode": mode,
        "n": len(rows),
        "groups": len({(r["circuit"], r["prompt"]) for r in rows}),
        "compile_at_10": round(pass_at_10(rows, "compile_ok"), 4),
        "functional_at_10": round(pass_at_10(rows, "functional_ok"), 4),
        "cdc_at_10": round(pass_at_10(rows, "cdc_ok"), 4),
        "results": rows,
    }
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(payload, indent=2) + "\n")
    tmp.replace(path)


def run_attempt(item: dict, mode: str, api_key: str, max_rounds: int, max_tokens: int, timeout: int) -> dict:
    circuit, prompt, attempt = item["circuit"], item["prompt"], item["attempt"]
    job = ROOT / "experiments/qwen25-repair" / mode / circuit / prompt / attempt
    final = job / "final.json"
    if final.is_file():
        return json.loads(final.read_text())

    spec = (ROOT / "experiments/prompts" / f"{circuit}.{prompt}.md").read_text()
    rtl_path = item["rtl"]
    messages = [{"role": "user", "content": spec}]
    record = {
        "circuit": circuit,
        "prompt": prompt,
        "attempt": attempt,
        "start_rtl": str(rtl_path.relative_to(ROOT)),
        "mode": mode,
    }
    for round_idx in range(0, max_rounds + 1):
        out_dir = job / f"round-{round_idx:03d}"
        saved = out_dir / "repair.json"
        if saved.is_file():
            scored = json.loads(saved.read_text())
            source = ROOT / scored["rtl"]
        else:
            out_dir.mkdir(parents=True, exist_ok=True)
            if round_idx == 0:
                source = rtl_path
            else:
                data, content = chat(api_key, messages, max_tokens, timeout)
                (out_dir / "response.json").write_text(json.dumps(data) + "\n")
                (out_dir / "response.txt").write_text(content if content.endswith("\n") else content + "\n")
                source = out_dir / "generated" / rtl_path.name
                source.parent.mkdir(exist_ok=True)
                source.write_text(extract_verilog(content))
            scored = score(source, circuit, prompt, attempt, out_dir, mode)
        scored.update(record)
        scored["round"] = round_idx
        scored["rtl"] = str(source.relative_to(ROOT))
        (out_dir / "repair.json").write_text(json.dumps(scored, indent=2) + "\n")
        record = scored
        if passed(mode, scored) or round_idx == max_rounds:
            break
        messages.append({"role": "assistant", "content": source.read_text()})
        messages.append({"role": "user", "content": repair_message(mode, scored.get("feedback", ""))})
    final.write_text(json.dumps(record, indent=2) + "\n")
    return record


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=MODES, required=True)
    parser.add_argument("--circuit", action="append", choices=circuits())
    parser.add_argument("--max-rounds", type=int, default=3)
    parser.add_argument("--max-tokens", type=int, default=8192)
    parser.add_argument("--timeout", type=int, default=240)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--jobs", type=int, default=4, help="attempts to repair at once")
    args = parser.parse_args()
    if args.max_rounds < 0:
        parser.error("--max-rounds must be >= 0")
    if args.jobs < 1:
        parser.error("--jobs must be >= 1")

    api_key = os.environ.get("OPENROUTER_API_KEY", "")
    if not api_key:
        print("ERROR: set OPENROUTER_API_KEY before running.", file=sys.stderr)
        return 1
    os.environ["PATH"] = XRUN_BIN + ":" + os.environ.get("PATH", "")
    if shutil.which("xrun") is None:
        print("ERROR: xrun not found. Run this on ecs05.", file=sys.stderr)
        return 1

    selected = set(args.circuit) if args.circuit else None
    items = discover(selected)
    if args.limit:
        items = items[: args.limit]
    summary_path = ROOT / "experiments/qwen25-repair" / f"{args.mode}_summary.json"
    done = []
    if summary_path.is_file():
        done = json.loads(summary_path.read_text()).get("results") or []
    done_keys = {(r["circuit"], r["prompt"], r["attempt"]) for r in done}
    pending = [item for item in items if (item["circuit"], item["prompt"], item["attempt"]) not in done_keys]
    print(
        f"MODE={args.mode} JOBS={args.jobs} TOTAL={len(items)} done={len(done_keys)} pending={len(pending)}",
        flush=True,
    )
    lock = threading.Lock()
    finished = 0
    auth_failed = False

    def one(item: dict) -> dict:
        nonlocal finished, auth_failed
        started = time.time()
        try:
            record = run_attempt(
                item, args.mode, api_key, args.max_rounds, args.max_tokens, args.timeout
            )
        except Exception as exc:
            record = {
                "circuit": item["circuit"],
                "prompt": item["prompt"],
                "attempt": item["attempt"],
                "compile_ok": False,
                "functional_ok": False,
                "cdc_ok": False,
                "error": f"{type(exc).__name__}: {exc}"[:500],
            }
            text = str(exc)
            if "401" in text or "402" in text or "curl failed" in text:
                auth_failed = True
                reason = "401" if "401" in text else "402" if "402" in text else "curl failed"
                print(f"STOP: OpenRouter request stopped ({reason}).", file=sys.stderr)
                return {}
        with lock:
            done.append(record)
            save_summary(summary_path, args.mode, done)
            finished += 1
            index = finished
        print(
            f"{index}/{len(pending)} {item['circuit']} {item['prompt']}/{item['attempt']} "
            f"C={record.get('compile_ok')} F={record.get('functional_ok')} "
            f"CDC={record.get('cdc_ok')} round={record.get('round')} "
            f"{time.time() - started:.0f}s {record.get('error', '')}",
            flush=True,
        )
        return record

    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = [pool.submit(one, item) for item in pending]
        for future in futures:
            future.result()
            if auth_failed:
                for pending_future in futures:
                    pending_future.cancel()
                print("STOP: OpenRouter rejected the request. Unfinished attempts were not recorded.", file=sys.stderr)
                return 1
    print(f"SUMMARY {summary_path}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
