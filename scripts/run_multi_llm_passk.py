#!/usr/bin/env python3
"""Run a bounded multi-model RTL Pass@k experiment through an API.

For every selected model, this script sends the same frozen prompt for up to
10 independent attempts, then runs the existing benchmark flow:

    generation -> Xcelium compile -> Xcelium simulation -> JasperGold CDC/RDC

JasperGold runs only after functional simulation passes. Every candidate and
failure is preserved. This is a separate protocol from the frozen 18-attempt
baseline, Pass@20 sampling, and feedback-repair experiments.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import re
import shutil
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from evaluate_generated import evaluate  # noqa: E402
from evaluate_pass_at_n import JG_BIN, XRUN_BIN, run_jasper, simulate  # noqa: E402
from generate_openrouter import extract_verilog  # noqa: E402

CIRCUITS = ("cdc_2phase", "async_fifo", "apbxclk")
PROMPT_TYPES = ("functional", "cdc_explicit")
DEFAULT_OUT = "experiments/multi-llm-passk"
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
OPENAI_URL = "https://api.openai.com/v1/responses"


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def model_tag(model_id: str) -> str:
    """Create a stable filesystem name without conflating providers."""
    tag = re.sub(r"[^A-Za-z0-9._-]+", "__", model_id.strip())
    return tag.strip("._-") or "unnamed-model"


def pass_at_k(n: int, c: int, k: int) -> float:
    """Unbiased pass@k estimator: 1 - C(n-c,k) / C(n,k)."""
    if not 1 <= k <= n:
        raise ValueError(f"k must satisfy 1 <= k <= n; got k={k}, n={n}")
    if not 0 <= c <= n:
        raise ValueError(f"c must satisfy 0 <= c <= n; got c={c}, n={n}")
    if n - c < k:
        return 1.0
    return 1.0 - math.comb(n - c, k) / math.comb(n, k)


def pass_curve(outcomes: list[bool]) -> dict[str, object]:
    n = len(outcomes)
    c = sum(outcomes)
    return {
        "n": n,
        "c": c,
        "pass_at_k": {
            str(k): round(pass_at_k(n, c, k), 8)
            for k in range(1, n + 1)
        },
        # This is useful operationally but is not the statistical estimator.
        "observed_prefix_success": {
            str(k): any(outcomes[:k])
            for k in range(1, n + 1)
        },
    }


def ensure_environment(api_key: str, provider: str) -> None:
    if not api_key:
        env_name = "OPENAI_API_KEY" if provider == "openai" else "OPENROUTER_API_KEY"
        raise RuntimeError(f"Set {env_name} in the shell; do not put it in the repo.")
    os.environ["PATH"] = (
        XRUN_BIN + ":" + JG_BIN + ":" + os.environ.get("PATH", "")
    )
    for tool in ("xrun", "jg"):
        if shutil.which(tool) is None:
            raise RuntimeError(f"{tool} is unavailable; run this experiment on ecs05.")


def request_completion(
    *,
    api_key: str,
    provider: str,
    model: str,
    prompt: str,
    temperature: float,
    top_p: float,
    max_tokens: int,
    seed: int,
    timeout: int,
) -> tuple[dict, dict, str, float]:
    if provider == "openai":
        payload = {
            "model": model,
            "max_output_tokens": max_tokens,
            "input": prompt,
            "store": False,
        }
        url = OPENAI_URL
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }
    else:
        payload = {
            "model": model,
            "temperature": temperature,
            "top_p": top_p,
            "max_tokens": max_tokens,
            "seed": seed,
            "messages": [{"role": "user", "content": prompt}],
        }
        url = OPENROUTER_URL
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://github.com/adritafaiza-cmd/dataset",
            "X-Title": "CDC RTL multi-model Pass@k",
        }
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers=headers,
        method="POST",
    )
    started = time.monotonic()
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read().decode()
            status = response.status
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode(errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {raw[:500]}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"API request failed: {exc}") from exc
    elapsed = time.monotonic() - started
    if status != 200:
        raise RuntimeError(f"HTTP {status}: {raw[:500]}")
    data = json.loads(raw)
    if provider == "openai":
        texts = [
            part.get("text", "")
            for item in data.get("output", [])
            if item.get("type") == "message"
            for part in item.get("content", [])
            if part.get("type") == "output_text"
        ]
        content = "".join(texts)
    else:
        choices = data.get("choices") or []
        if not choices or choices[0].get("finish_reason") == "error":
            raise RuntimeError(f"Provider returned no usable completion: {raw[:500]}")
        content = choices[0].get("message", {}).get("content")
    if not content:
        raise RuntimeError("Provider returned an empty completion.")
    return payload, data, content, elapsed


def write_generation(
    *,
    attempt_dir: Path,
    circuit: str,
    prompt_type: str,
    prompt_path: Path,
    provider: str,
    model: str,
    attempt: int,
    temperature: float,
    top_p: float,
    max_tokens: int,
    timeout: int,
    api_key: str,
) -> Path:
    attempt_dir.mkdir(parents=True, exist_ok=False)
    generated_dir = attempt_dir / "generated"
    generated_dir.mkdir()
    shutil.copy2(prompt_path, attempt_dir / "prompt.md")
    prompt = prompt_path.read_text()
    prompt_sha256 = hashlib.sha256(prompt.encode()).hexdigest()

    try:
        payload, response, content, elapsed = request_completion(
            api_key=api_key,
            provider=provider,
            model=model,
            prompt=prompt,
            temperature=temperature,
            top_p=top_p,
            max_tokens=max_tokens,
            seed=attempt,
            timeout=timeout,
        )
    except Exception as exc:
        (attempt_dir / "generation_error.json").write_text(
            json.dumps(
                {
                    "provider": provider,
                    "model": model,
                    "circuit": circuit,
                    "prompt_type": prompt_type,
                    "attempt": attempt,
                    "prompt_sha256": prompt_sha256,
                    "error": str(exc),
                    "timestamp": utc_now(),
                },
                indent=2,
            )
            + "\n"
        )
        raise

    # Store the request without credentials and preserve the complete response.
    (attempt_dir / "request.json").write_text(json.dumps(payload, indent=2) + "\n")
    (attempt_dir / "response.json").write_text(json.dumps(response, indent=2) + "\n")
    (attempt_dir / "response.txt").write_text(
        content if content.endswith("\n") else content + "\n"
    )
    rtl = generated_dir / f"{circuit}.v"
    rtl.write_text(extract_verilog(content))

    usage = response.get("usage", {})
    prompt_tokens = usage.get(
        "input_tokens" if provider == "openai" else "prompt_tokens"
    )
    completion_tokens = usage.get(
        "output_tokens" if provider == "openai" else "completion_tokens"
    )
    metadata = {
        "experiment": "multi_llm_pass_at_k",
        "provider": provider,
        "requested_model": model,
        "returned_model": response.get("model"),
        "circuit": circuit,
        "prompt_type": prompt_type,
        "attempt": attempt,
        # OpenAI Responses does not expose a seed parameter. Independent API
        # calls still sample separately at the configured temperature.
        "seed": attempt if provider == "openrouter" else None,
        "prompt_file": str(prompt_path.relative_to(ROOT)),
        "prompt_sha256": prompt_sha256,
        "temperature": temperature if provider == "openrouter" else None,
        "top_p": top_p if provider == "openrouter" else None,
        "sampling_note": (
            "OpenAI GPT-5.6 does not accept temperature, top_p, or seed."
            if provider == "openai"
            else "OpenRouter sampling parameters and attempt seed were sent."
        ),
        "max_tokens": max_tokens,
        "elapsed_s": round(elapsed, 3),
        "prompt_tokens": prompt_tokens,
        "completion_tokens": completion_tokens,
        "total_tokens": usage.get("total_tokens"),
        "timestamp": utc_now(),
        "feedback": False,
    }
    (attempt_dir / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    return rtl


def evaluate_attempt(rtl: Path, circuit: str, attempt_dir: Path) -> dict:
    result = evaluate(rtl, circuit, attempt_dir)
    if not result["compile_ok"]:
        result["pipeline_stage"] = "compile_failed"
    else:
        result.update(simulate(rtl, circuit, attempt_dir))
        if not result["simulate_ok"]:
            result["pipeline_stage"] = "functional_failed"
        else:
            result.update(
                run_jasper(
                    rtl,
                    circuit,
                    attempt_dir.relative_to(ROOT / "experiments"),
                )
            )
            result["pipeline_stage"] = (
                "functional_and_jasper_passed"
                if result.get("cdc_clean")
                else "jasper_failed"
            )
    result["functional_and_jasper_clean"] = bool(
        result.get("simulate_ok") and result.get("cdc_clean")
    )
    result["evaluated_at"] = utc_now()
    (attempt_dir / "results.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


def completed_result(attempt_dir: Path) -> dict | None:
    result_path = attempt_dir / "results.json"
    if not result_path.exists():
        return None
    result = json.loads(result_path.read_text())
    required = {"compile_ok", "simulate_ok", "functional_and_jasper_clean"}
    return result if required.issubset(result) else None


def summarize_model(
    model: str,
    circuit: str,
    prompt_type: str,
    results: list[dict],
) -> dict:
    compile_outcomes = [bool(row.get("compile_ok")) for row in results]
    functional_outcomes = [bool(row.get("simulate_ok")) for row in results]
    jasper_outcomes = [
        bool(row.get("simulate_ok") and row.get("cdc_clean"))
        for row in results
    ]
    return {
        "model": model,
        "circuit": circuit,
        "prompt_type": prompt_type,
        "attempts_evaluated": len(results),
        "metrics": {
            "compile": pass_curve(compile_outcomes),
            "functional": pass_curve(functional_outcomes),
            # Jasper is gated on functional pass, as required by the protocol.
            "functional_and_jasper_clean": pass_curve(jasper_outcomes),
        },
        "attempts": results,
        "updated_at": utc_now(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--provider",
        choices=("openai", "openrouter"),
        default="openrouter",
        help="API provider used for every --model in this invocation",
    )
    parser.add_argument(
        "--model",
        action="append",
        required=True,
        help="Provider model ID; repeat this option for several LLMs",
    )
    parser.add_argument("--circuit", choices=CIRCUITS, required=True)
    parser.add_argument("--prompt-type", choices=PROMPT_TYPES, required=True)
    parser.add_argument("--attempts", type=int, default=10)
    parser.add_argument("--temperature", type=float, default=0.2)
    parser.add_argument("--top-p", type=float, default=0.95)
    parser.add_argument("--max-tokens", type=int, default=8192)
    parser.add_argument("--api-timeout", type=int, default=240)
    parser.add_argument("--output-root", default=DEFAULT_OUT)
    parser.add_argument(
        "--continue-on-api-error",
        action="store_true",
        help="Preserve the failed API attempt and continue to the next number",
    )
    args = parser.parse_args()

    if not 1 <= args.attempts <= 10:
        parser.error("--attempts must be between 1 and 10")
    api_key_env = (
        "OPENAI_API_KEY" if args.provider == "openai" else "OPENROUTER_API_KEY"
    )
    api_key = os.environ.get(api_key_env, "")
    try:
        ensure_environment(api_key, args.provider)
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    prompt_path = (
        ROOT / "experiments/prompts" / f"{args.circuit}.{args.prompt_type}.md"
    )
    prompt = prompt_path.read_text()
    prompt_sha256 = hashlib.sha256(prompt.encode()).hexdigest()
    output_root = ROOT / args.output_root
    provider_root = output_root / args.provider
    provider_root.mkdir(parents=True, exist_ok=True)
    protocol = {
        "experiment": "multi_llm_pass_at_k",
        "provider": args.provider,
        "models": args.model,
        "circuit": args.circuit,
        "prompt_type": args.prompt_type,
        "prompt_file": str(prompt_path.relative_to(ROOT)),
        "prompt_sha256": prompt_sha256,
        "attempts_per_model": args.attempts,
        "temperature": args.temperature if args.provider == "openrouter" else None,
        "top_p": args.top_p if args.provider == "openrouter" else None,
        "sampling_note": (
            "OpenAI GPT-5.6 provider defaults; temperature/top_p/seed unsupported."
            if args.provider == "openai"
            else "Configured OpenRouter temperature/top_p with attempt-number seed."
        ),
        "max_tokens": args.max_tokens,
        "feedback": False,
        "pipeline": [
            f"{args.provider} generation",
            "Xcelium compile/elaborate",
            "Xcelium functional simulation (50us cap)",
            "JasperGold CDC/RDC only after functional pass",
        ],
        "pass_at_k_definition": "1 - C(n-c,k) / C(n,k)",
        "created_at": utc_now(),
    }
    (provider_root / "protocol.json").write_text(
        json.dumps(protocol, indent=2) + "\n"
    )

    all_summaries = []
    for model in args.model:
        base = (
            provider_root
            / model_tag(model)
            / args.circuit
            / args.prompt_type
        )
        base.mkdir(parents=True, exist_ok=True)
        print(f"\n========== MODEL {model} ==========", flush=True)
        results: list[dict] = []
        for attempt in range(1, args.attempts + 1):
            attempt_dir = base / f"attempt-{attempt:03d}"
            result = completed_result(attempt_dir)
            if result is not None:
                print(f"[{attempt}/{args.attempts}] SKIP evaluated", flush=True)
                results.append(result)
                continue

            rtl = next(attempt_dir.glob("generated/*.v"), None)
            if rtl is None:
                if attempt_dir.exists():
                    backup = attempt_dir.with_name(
                        attempt_dir.name
                        + ".incomplete-"
                        + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
                    )
                    attempt_dir.rename(backup)
                    print(f"Preserved incomplete attempt: {backup}", flush=True)
                print(f"[{attempt}/{args.attempts}] GENERATE", flush=True)
                try:
                    rtl = write_generation(
                        attempt_dir=attempt_dir,
                        circuit=args.circuit,
                        prompt_type=args.prompt_type,
                        prompt_path=prompt_path,
                        provider=args.provider,
                        model=model,
                        attempt=attempt,
                        temperature=args.temperature,
                        top_p=args.top_p,
                        max_tokens=args.max_tokens,
                        timeout=args.api_timeout,
                        api_key=api_key,
                    )
                except Exception as exc:
                    print(f"  API ERROR: {exc}", file=sys.stderr, flush=True)
                    if args.continue_on_api_error:
                        continue
                    return 1

            print(f"[{attempt}/{args.attempts}] EVALUATE", flush=True)
            result = evaluate_attempt(rtl, args.circuit, attempt_dir)
            results.append(result)
            print(
                "  "
                f"compile={result.get('compile_ok')} "
                f"functional={result.get('simulate_ok')} "
                f"jasper_clean={result.get('cdc_clean')}",
                flush=True,
            )

        if not results:
            print(f"WARNING: no evaluated attempts for {model}", file=sys.stderr)
            continue
        summary = summarize_model(
            model, args.circuit, args.prompt_type, results
        )
        summary["provider"] = args.provider
        summary_path = base / "pass_at_k_summary.json"
        summary_path.write_text(json.dumps(summary, indent=2) + "\n")
        all_summaries.append(summary)
        metrics = summary["metrics"]
        print(
            f"RESULT {model}: n={len(results)} "
            f"compile={metrics['compile']['c']} "
            f"functional={metrics['functional']['c']} "
            "functional+Jasper="
            f"{metrics['functional_and_jasper_clean']['c']}",
            flush=True,
        )

    aggregate_path = (
        provider_root
        / f"{args.circuit}.{args.prompt_type}.pass_at_k_summary.json"
    )
    aggregate_path.write_text(json.dumps(all_summaries, indent=2) + "\n")
    print(f"\nWrote aggregate summary: {aggregate_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
