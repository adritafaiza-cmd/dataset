#!/usr/bin/env python3
"""Llama compile-repair agent for the CDC RTL pilot.

This is a different condition from the frozen one-shot baseline in
experiments/llama-3.3-70b-instruct/. It keeps every failed round and
does not edit generated RTL by hand.

For each circuit × prompt, generate, compile with xrun -elaborate, and
if compile fails send the compiler errors back until compile passes or
--max-rounds is reached.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from evaluate_generated import TB, evaluate  # noqa: E402
from generate_openrouter import extract_verilog  # noqa: E402

PROMPT_DIR = ROOT / "experiments" / "prompts"
CIRCUITS = ["cdc_2phase", "async_fifo", "apbxclk"]
PROMPT_TYPES = ["functional", "cdc_explicit"]
DEFAULT_MODEL = "meta-llama/llama-3.3-70b-instruct"
XRUN_BIN = "/eda/cadence/XCELIUM2603/tools.lnx86/inca/bin/64bit"


def extract_errors(log_text: str, limit: int = 3500) -> str:
    lines = []
    for line in log_text.splitlines():
        if re.search(r"\*(E|F),", line) or "errors:" in line.lower():
            lines.append(line)
    text = "\n".join(lines) if lines else log_text[-limit:]
    return text[-limit:]


def chat(api_key: str, model: str, messages: list[dict], max_tokens: int, timeout: int) -> tuple[dict, str, float]:
    payload = {
        "model": model,
        "temperature": 0.2,
        "top_p": 0.95,
        "max_tokens": max_tokens,
        "messages": messages,
    }
    tmp = Path("/tmp/llama_compile_agent_request.json")
    tmp.write_text(json.dumps(payload) + "\n")
    started = time.time()
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
            "X-Title: CDC RTL compile agent",
            "--data-binary",
            f"@{tmp}",
            "-w",
            "\n%{http_code}",
        ],
        capture_output=True,
        text=True,
    )
    elapsed = time.time() - started
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or "curl failed")
    body, _, status_text = completed.stdout.rpartition("\n")
    status = int(status_text or "0")
    if status != 200:
        raise RuntimeError(f"OpenRouter HTTP {status}: {body[:500]}")
    data = json.loads(body)
    content = data["choices"][0]["message"]["content"]
    return data, content, elapsed


def ensure_xrun() -> None:
    env = os.environ.copy()
    env["PATH"] = XRUN_BIN + ":" + env.get("PATH", "")
    os.environ["PATH"] = env["PATH"]
    if shutil.which("xrun") is None:
        raise RuntimeError("xrun not found; Cadence Xcelium is required")


def run_job(
    circuit: str,
    prompt_type: str,
    api_key: str,
    model: str,
    max_rounds: int,
    max_tokens: int,
    timeout: int,
) -> dict:
    spec = (PROMPT_DIR / f"{circuit}.{prompt_type}.md").read_text()
    model_tag = model.split("/")[-1] + "-compile-agent"
    job_dir = ROOT / "experiments" / model_tag / circuit / prompt_type
    job_dir.mkdir(parents=True, exist_ok=True)

    existing = sorted(job_dir.glob("round-*"))
    for rnd in existing:
        results = rnd / "results.json"
        if results.exists() and json.loads(results.read_text()).get("compile_ok"):
            print(f"SKIP {circuit}/{prompt_type} already compiled in {rnd.name}")
            return json.loads(results.read_text())

    start_round = len(existing) + 1
    messages = [{"role": "user", "content": spec}]
    last_rtl = None
    last_errors = None
    if existing:
        last = existing[-1]
        rtl_path = last / "generated" / f"{circuit}.v"
        resp = last / "response.txt"
        if resp.exists():
            messages.append({"role": "assistant", "content": resp.read_text()})
        if rtl_path.exists() and (last / "results.json").exists():
            last_rtl = rtl_path.read_text()
            last_errors = json.loads((last / "results.json").read_text()).get("error_excerpt", "")
            messages.append(
                {
                    "role": "user",
                    "content": repair_message(last_rtl, last_errors),
                }
            )

    for round_idx in range(start_round, max_rounds + 1):
        out_dir = job_dir / f"round-{round_idx:03d}"
        if out_dir.exists() and not (out_dir / "results.json").exists():
            shutil.rmtree(out_dir)
        if out_dir.exists():
            continue
        out_dir.mkdir()
        (out_dir / "generated").mkdir()
        (out_dir / "prompt.md").write_text(spec)
        print(f"===== {circuit}/{prompt_type} round {round_idx}/{max_rounds} =====", flush=True)
        data, content, elapsed = chat(api_key, model, messages, max_tokens, timeout)
        (out_dir / "response.json").write_text(json.dumps(data) + "\n")
        (out_dir / "response.txt").write_text(content if content.endswith("\n") else content + "\n")
        rtl_text = extract_verilog(content)
        rtl_path = out_dir / "generated" / f"{circuit}.v"
        rtl_path.write_text(rtl_text)
        (out_dir / "request.json").write_text(json.dumps({"round": round_idx, "n_messages": len(messages)}) + "\n")

        result = evaluate(rtl_path, circuit, out_dir)
        log_path = ROOT / result["log"] if result.get("log") else None
        log_text = log_path.read_text(errors="replace") if log_path and log_path.exists() else ""
        result["error_excerpt"] = extract_errors(log_text)
        result["round"] = round_idx
        result["elapsed_s"] = round(elapsed, 3)
        result["agent"] = "llama-compile-repair"
        result["model"] = data.get("model", model)
        (out_dir / "results.json").write_text(json.dumps(result, indent=2) + "\n")
        (out_dir / "metadata.json").write_text(
            json.dumps(
                {
                    "provider": "openrouter",
                    "model": data.get("model", model),
                    "requested_model": model,
                    "condition": "compile-repair-agent",
                    "not_one_shot_baseline": True,
                    "circuit": circuit,
                    "prompt_type": prompt_type,
                    "round": round_idx,
                    "compile_ok": result["compile_ok"],
                    "elapsed_s": round(elapsed, 3),
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                },
                indent=2,
            )
            + "\n"
        )
        status = "COMPILE PASS" if result["compile_ok"] else "COMPILE FAIL"
        print(f"{status} {out_dir.relative_to(ROOT)}", flush=True)
        if result["compile_ok"]:
            return result

        messages.append({"role": "assistant", "content": content})
        messages.append({"role": "user", "content": repair_message(rtl_text, result["error_excerpt"])})

    return {"circuit": circuit, "prompt_type": prompt_type, "compile_ok": False, "rounds": max_rounds}


def repair_message(rtl: str, errors: str) -> str:
    return (
        "The previous Verilog failed Xcelium compile/elaborate against the official "
        "testbench. Keep the same module name and port list. Return one complete "
        "corrected source file only. No testbench, no markdown explanation.\n\n"
        "Compiler errors:\n"
        f"{errors}\n\n"
        "Previous file:\n"
        f"{rtl}\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--max-rounds", type=int, default=8)
    parser.add_argument("--max-tokens", type=int, default=8192)
    parser.add_argument("--timeout", type=int, default=180)
    parser.add_argument("--circuit", choices=CIRCUITS)
    parser.add_argument("--prompt-type", choices=PROMPT_TYPES)
    args = parser.parse_args()

    api_key = os.environ.get("OPENROUTER_API_KEY")
    if not api_key:
        print("ERROR: set OPENROUTER_API_KEY first.", file=sys.stderr)
        return 1

    ensure_xrun()
    jobs = (
        [(args.circuit, args.prompt_type)]
        if args.circuit and args.prompt_type
        else [(c, p) for c in CIRCUITS for p in PROMPT_TYPES]
    )
    summary = []
    for circuit, prompt_type in jobs:
        try:
            result = run_job(
                circuit,
                prompt_type,
                api_key,
                args.model,
                args.max_rounds,
                args.max_tokens,
                args.timeout,
            )
            summary.append(
                {
                    "circuit": circuit,
                    "prompt_type": prompt_type,
                    "compile_ok": bool(result.get("compile_ok")),
                    "round": result.get("round"),
                    "rtl": result.get("rtl"),
                }
            )
        except Exception as exc:
            print(f"ERROR {circuit}/{prompt_type}: {exc}", file=sys.stderr)
            summary.append(
                {
                    "circuit": circuit,
                    "prompt_type": prompt_type,
                    "compile_ok": False,
                    "error": str(exc)[:300],
                }
            )
            return 1

    out = ROOT / "experiments" / (args.model.split("/")[-1] + "-compile-agent") / "agent_summary.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(summary, indent=2) + "\n")
    passed = sum(1 for row in summary if row.get("compile_ok"))
    print(f"Agent compile success: {passed}/{len(summary)} jobs. {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
