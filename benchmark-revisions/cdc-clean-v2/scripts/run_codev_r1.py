#!/usr/bin/env python3
"""Generate CodeV-R1 RTL through a local vLLM server and summarize the shared evaluator's results."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse

from evaluate_generated import manifest_list, manifest_scalar, top_rtl_for
from run_multi_llm_passk import pass_at_k

ROOT = Path(__file__).resolve().parents[1]
PROMPTS = ROOT / "experiments" / "prompts"
OUTPUT = ROOT / "experiments" / "codev-r1-rl-qwen-7b"
REPORT = ROOT / "reports" / "AK_codev1_benchmark.md"
MODEL = "zhuyaoyu/CodeV-R1-RL-Qwen-7B"
PROMPT_TYPES = ("functional", "cdc_explicit", "observable")
PILOT = ("cdc_2phase", "async_fifo", "apbxclk")
SYSTEM_PROMPT = (
    "You are a helpful assistant. The assistant first thinks about the reasoning process "
    "in the mind and then provides the user with the answer. The reasoning process and "
    "answer are enclosed within <think> </think> and<answer> </answer> tags, respectively, "
    "i.e., <think> reasoning process here </think><answer> answer here </answer>.  Now the "
    "user asks you to write verilog code. After thinking, when you finally reach a conclusion, "
    "enclose the final verilog code in ```verilog ``` within <answer> </answer> tags. i.e., "
    "<answer> ```verilog\n module top_module(in, out, ...) ... ``` </answer>."
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def circuits(selected: list[str] | None, all_circuits: bool) -> list[str]:
    available = sorted(p.name.removesuffix(".functional.md") for p in PROMPTS.glob("*.functional.md"))
    names = available if all_circuits else list(dict.fromkeys(selected or PILOT))
    for name in names:
        if name not in available or any(not (PROMPTS / f"{name}.{kind}.md").is_file() for kind in PROMPT_TYPES):
            raise ValueError(f"{name}: all three generation prompts are required")
    return names


def jobs(names: list[str], attempts: int):
    for name in names:
        for kind in PROMPT_TYPES:
            for attempt in range(1, attempts + 1):
                yield name, kind, attempt


def endpoint(base_url: str) -> str:
    parsed = urlparse(base_url)
    if parsed.scheme != "http" or parsed.hostname not in {"localhost", "127.0.0.1", "::1"} or parsed.path.rstrip("/") != "/v1":
        raise ValueError("--base-url must be a local http://localhost:PORT/v1 endpoint")
    return base_url.rstrip("/")


def request_json(url: str, payload: dict | None, timeout: int) -> dict:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode() if payload is not None else None,
        headers={"Content-Type": "application/json"} if payload is not None else {},
        method="POST" if payload is not None else "GET",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f"vLLM HTTP {exc.code}: {exc.read(300).decode(errors='replace')}") from exc


def extract_rtl(response: str, top: str) -> str | None:
    if "<answer>" in response:
        response = response.rsplit("<answer>", 1)[-1].split("</answer>", 1)[0]
    elif "</think>" in response:
        response = response.rsplit("</think>", 1)[-1]
    elif "<think>" in response:
        return None
    blocks = re.findall(r"```(?:verilog|systemverilog|sv|v)?\s*\n?(.*?)```", response, re.I | re.S)
    code_blocks = [block for block in blocks if re.search(r"\bmodule\s+\w+\b", block)]
    text = "\n".join(code_blocks) if any(re.search(rf"\bmodule\s+{re.escape(top)}\b", block) for block in code_blocks) else response
    start = re.search(r"\bmodule\s+\w+\b", text)
    ends = list(re.finditer(r"\bendmodule\b", text))
    if not start or not ends or not re.search(rf"\bmodule\s+{re.escape(top)}\b", text):
        return None
    return text[start.start():ends[-1].end()].strip() + "\n"


def generate_one(base_url: str, name: str, kind: str, attempt: int, args: argparse.Namespace) -> None:
    prompt_path = PROMPTS / f"{name}.{kind}.md"
    prompt = prompt_path.read_text()
    prompt_hash = hashlib.sha256(prompt.encode()).hexdigest()
    target = OUTPUT / name / kind / f"attempt-{attempt:03d}"
    if target.exists():
        meta = target / "metadata.json"
        if not meta.exists() or json.loads(meta.read_text()).get("prompt_sha256") != prompt_hash:
            raise RuntimeError(f"{target}: existing attempt has a different or unrecorded prompt; refusing to overwrite")
        print(f"SKIP {name}/{kind}/{attempt:03d}", flush=True)
        return
    target.mkdir(parents=True)
    shutil.copy2(prompt_path, target / "prompt.md")
    messages = ([{"role": "system", "content": SYSTEM_PROMPT}] if args.system_prompt == "official" else []) + [
        {"role": "user", "content": prompt}
    ]
    payload = {
        "model": MODEL, "messages": messages, "temperature": args.temperature,
        "top_p": args.top_p, "max_tokens": args.max_tokens, "seed": args.seed + attempt,
    }
    (target / "request.json").write_text(json.dumps(payload, indent=2) + "\n")
    metadata = {
        "experiment": "AK_codev1_benchmark", "model": MODEL,
        "model_revision": args.model_revision, "backend": "vllm-chat",
        "circuit": name, "benchmark_status": manifest_scalar(name, "status"),
        "prompt_type": kind, "prompt_file": str(prompt_path.relative_to(ROOT)),
        "prompt_sha256": prompt_hash, "attempt": attempt,
        "temperature": args.temperature, "top_p": args.top_p,
        "max_tokens": args.max_tokens, "seed": args.seed + attempt,
        "system_prompt": args.system_prompt, "feedback": False,
        "timestamp": utc_now(), "generation_status": "requested",
    }
    (target / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    started = time.monotonic()
    try:
        response = request_json(f"{base_url}/chat/completions", payload, args.timeout)
        (target / "response.json").write_text(json.dumps(response, indent=2) + "\n")
        if response.get("model") != MODEL:
            raise ValueError(f"server responded as {response.get('model')!r}, not {MODEL}")
        content = response["choices"][0]["message"]["content"]
        if not isinstance(content, str):
            raise ValueError("model returned no text content")
        (target / "response.txt").write_text(content if content.endswith("\n") else content + "\n")
        rtl = extract_rtl(content, manifest_scalar(name, "top_module"))
        if rtl is None:
            raise ValueError("no complete requested top module in model response")
        generated = target / "generated"
        generated.mkdir()
        (generated / f"{name}.v").write_text(rtl)
        usage = response.get("usage") or {}
        metadata.update(
            generation_status="generated", response_model=response.get("model"),
            finish_reason=response["choices"][0].get("finish_reason"),
            elapsed_s=round(time.monotonic() - started, 3),
            prompt_tokens=usage.get("prompt_tokens"),
            completion_tokens=usage.get("completion_tokens"),
        )
        print(f"GENERATED {name}/{kind}/{attempt:03d}", flush=True)
    except (OSError, RuntimeError, ValueError, KeyError, IndexError, TypeError) as exc:
        metadata.update(generation_status="failed", elapsed_s=round(time.monotonic() - started, 3))
        (target / "generation_error.json").write_text(json.dumps({"error": str(exc)}, indent=2) + "\n")
        print(f"FAILED {name}/{kind}/{attempt:03d}: {exc}", file=sys.stderr, flush=True)
        if not args.continue_on_error:
            raise
    finally:
        (target / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")


def tool_error(result: dict) -> bool:
    return bool(result.get("error")) or (result.get("returncode") in (126, 127) and not result.get("log"))


def cell(name: str, kind: str, attempts: int) -> dict:
    rows = []
    for attempt in range(1, attempts + 1):
        directory = OUTPUT / name / kind / f"attempt-{attempt:03d}"
        meta = directory / "metadata.json"
        result = directory / "results.json"
        rows.append((json.loads(meta.read_text()) if meta.exists() else None, json.loads(result.read_text()) if result.exists() else None))
    saved = sum(meta is not None and meta.get("generation_status") == "generated" for meta, _ in rows)
    infrastructure = [result for _, result in rows if result is not None and tool_error(result)]
    evaluated = [result for _, result in rows if result is not None and not tool_error(result)]
    compile_known = len(evaluated) == attempts and all(result.get("compile_ok") is not None for result in evaluated)
    functional_known = compile_known and all(not result["compile_ok"] or result.get("simulate_ok") is not None for result in evaluated)
    jasper_known = functional_known and all(
        not result.get("simulate_ok") or (result.get("jg_returncode") == 0 and result.get("cdc_errors") is not None and result.get("rdc_errors") is not None)
        for result in evaluated
    )
    checked = [result for result in evaluated if result.get("jg_returncode") == 0 and result.get("cdc_errors") is not None and result.get("rdc_errors") is not None]
    return {
        "planned": attempts, "started": sum(meta is not None for meta, _ in rows), "generated": saved,
        "generation_failures": sum(meta is not None and meta.get("generation_status") == "failed" for meta, _ in rows),
        "tool_errors": len(infrastructure), "evaluated": len(evaluated), "compile_pass": sum(result.get("compile_ok") is True for result in evaluated),
        "functional_pass": sum(result.get("simulate_ok") is True for result in evaluated),
        "timeouts": sum("TIMEOUT" in (result.get("sim_note") or "") for result in evaluated),
        "jasper_analyzed": len(checked),
        "cdc_errors": sum(result["cdc_errors"] for result in checked),
        "rdc_errors": sum(result["rdc_errors"] for result in checked),
        "clean": sum(result.get("simulate_ok") is True and result.get("cdc_clean") is True for result in checked),
        "compile_known": compile_known, "functional_known": functional_known, "jasper_known": jasper_known,
    }


def render_results(names: list[str], attempts: int) -> str:
    cells = {(name, kind): cell(name, kind, attempts) for name in names for kind in PROMPT_TYPES}
    k = min(3, attempts)
    lines = [
        f"Scope: {len(names)} circuits × 3 prompts × {attempts} attempts = {len(names) * 3 * attempts} planned generations.",
        "", f"| Prompt | Saved RTL | Generation errors | Tool errors | Compile pass | Functional pass | Timeouts | Jasper analyzed | CDC errors | RDC errors | Functional+Jasper clean | Functional pass@1 | Combined pass@1 | Functional pass@{k} | Combined pass@{k} |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for kind in PROMPT_TYPES:
        selected = [cells[name, kind] for name in names]
        planned = sum(row["planned"] for row in selected)
        scored = sum(row["evaluated"] for row in selected)
        started = sum(row["started"] for row in selected)
        generated = sum(row["generated"] for row in selected)
        checked = sum(row["jasper_analyzed"] for row in selected)
        functional = sum(row["functional_pass"] for row in selected)
        clean = sum(row["clean"] for row in selected)
        functional_known = all(row["functional_known"] for row in selected)
        jasper_known = all(row["jasper_known"] for row in selected)
        lines.append("| " + " | ".join([
            kind, f"{generated}/{planned}",
            str(sum(row["generation_failures"] for row in selected)) if started else "not run",
            str(sum(row["tool_errors"] for row in selected)) if scored or any(row["tool_errors"] for row in selected) else "not run",
            f"{sum(row['compile_pass'] for row in selected)}/{scored}" if scored else "not run",
            f"{functional}/{scored}" if functional_known else "not complete",
            str(sum(row["timeouts"] for row in selected)) if scored else "not run",
            str(checked) if scored else "not run",
            str(sum(row["cdc_errors"] for row in selected)) if checked else "not run",
            str(sum(row["rdc_errors"] for row in selected)) if checked else "not run",
            f"{clean}/{scored}" if jasper_known else "not complete",
            f"{sum(pass_at_k(attempts, row['functional_pass'], 1) for row in selected) / len(selected):.3f}" if functional_known else "N/A",
            f"{sum(pass_at_k(attempts, row['clean'], 1) for row in selected) / len(selected):.3f}" if jasper_known else "N/A",
            f"{sum(pass_at_k(attempts, row['functional_pass'], k) for row in selected) / len(selected):.3f}" if functional_known else "N/A",
            f"{sum(pass_at_k(attempts, row['clean'], k) for row in selected) / len(selected):.3f}" if jasper_known else "N/A",
        ]) + " |")
    lines += ["", "Per circuit (saved / functional / functional+Jasper clean; '—' means the stage is not fully evaluated):", "", "| Circuit | Manifest | Functional | CDC-explicit | Observable |", "|---|---|---:|---:|---:|"]
    for name in names:
        values = []
        for kind in PROMPT_TYPES:
            row = cells[name, kind]
            values.append(f"{row['generated']}/{row['functional_pass'] if row['functional_known'] else '—'}/{row['clean'] if row['jasper_known'] else '—'}")
        lines.append(f"| {name} | {manifest_scalar(name, 'status')} | " + " | ".join(values) + " |")
    lines += ["", "A dash/N/A means **unmeasured**, never zero CDC errors or a model failure. This table uses the checked-in canonical TB and the Xcelium/Jasper evaluator, not the missing September typed-TB suite."]
    return "\n".join(lines)


def update_report(names: list[str], attempts: int) -> None:
    before, separator, after = REPORT.read_text().partition("\n## Measured outcomes\n")
    if not separator:
        raise ValueError(f"{REPORT} is missing its Measured outcomes section")
    _, end, rest = after.partition("\n## Interpretation\n")
    if not end:
        raise ValueError(f"{REPORT} is missing its Interpretation section")
    REPORT.write_text(before + separator + "\n" + render_results(names, attempts) + "\n" + end + rest)
    print(f"Updated {REPORT.relative_to(ROOT)}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    for name in ("plan", "generate", "report"):
        command = subparsers.add_parser(name)
        command.add_argument("--all", action="store_true", help="Use all 44 circuits instead of the 3-circuit pilot")
        command.add_argument("--circuit", action="append", help="Choose circuit(s) instead of the pilot")
        command.add_argument("--attempts", type=int, default=3)
        if name == "generate":
            command.add_argument("--base-url", default="http://127.0.0.1:8000/v1")
            command.add_argument("--temperature", type=float, default=0.2)
            command.add_argument("--top-p", type=float, default=0.95)
            command.add_argument("--max-tokens", type=int, default=8192)
            command.add_argument("--seed", type=int, default=1000)
            command.add_argument("--timeout", type=int, default=600)
            command.add_argument("--system-prompt", choices=("official", "none"), default="official")
            command.add_argument("--model-revision", default=None, help="Revision used by the running server; unknown if omitted")
            command.add_argument("--continue-on-error", action="store_true")
    args = parser.parse_args()
    if args.all and args.circuit:
        parser.error("use --all or --circuit, not both")
    if not 1 <= args.attempts <= 20:
        parser.error("--attempts must be between 1 and 20")
    try:
        names = circuits(args.circuit, args.all)
        if args.command == "plan":
            for name in names:
                print(f"{name}: {', '.join(PROMPT_TYPES)} × {args.attempts}")
            print(f"Total: {len(names) * len(PROMPT_TYPES) * args.attempts} attempts")
        elif args.command == "report":
            update_report(names, args.attempts)
        else:
            base_url = endpoint(args.base_url)
            models = request_json(f"{base_url}/models", None, args.timeout)
            if MODEL not in {item.get("id") for item in models.get("data", [])}:
                raise ValueError(f"local server does not advertise {MODEL}; refusing to test another model")
            for name, kind, attempt in jobs(names, args.attempts):
                generate_one(base_url, name, kind, attempt, args)
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
