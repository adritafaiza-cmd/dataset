#!/usr/bin/env python3
"""Run generated RTL through ordered Xcelium, SBY, and enhanced-TB gates.

Gate order:
  1. Xcelium compile
  2. canonical functional TB (only after compile)
  3. circuit-specific SymbiYosys proof (only after functional pass)
  4. fixed enhanced TB (only after formal proof)

The generated RTL is never edited.  Whether the corresponding golden contract
proved is recorded with every formal result so an unvalidated baseline cannot
be mistaken for a comparable score.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections.abc import Iterator
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(ROOT / "enhanced_cdc_tb"))

from evaluate_generated import evaluate as xcelium_compile  # noqa: E402
from evaluate_pass_at_n import simulate as xcelium_functional  # noqa: E402
from comparison_set import FIXED_16  # noqa: E402
from evaluate_symbiyosys_eligible import (  # noqa: E402
    DEFAULT_SBY,
    evaluate as sby_evaluate,
    parse_sby,
)
from run_enhanced import run_one as enhanced_evaluate  # noqa: E402

OUT = ROOT / "experiments/generated_gate_pipeline.json"
WORK = ROOT / "experiments/generated-gate-pipeline"
LOG = ROOT / "logs/generated-gate-pipeline.log"
FENCE = re.compile(r"^\s*```[a-zA-Z0-9_-]*\s*\n|\n```\s*$", re.M)

TREES = [
    ("ComplexVCoder", ROOT / "experiments/complexvcoder-3prompt-10attempt-v1"),
    ("RTLCoder", ROOT / "experiments/rtlcoder-deepseek-3prompt-10attempt-v1"),
    ("Qwen 3.5", ROOT / "experiments/qwen35-3prompt-10attempt-v1"),
    ("Llama", ROOT / "experiments/llama-16fix-3prompt-10attempt-v1"),
    (
        "Llama",
        ROOT
        / "experiments/multi-llm-3prompt-v1/openrouter"
        / "meta-llama__llama-3.3-70b-instruct",
    ),
    (
        "Llama",
        ROOT
        / "experiments/multi-llm-observable-v1/openrouter"
        / "meta-llama__llama-3.3-70b-instruct",
    ),
    (
        "Qwen 2.5",
        ROOT
        / "experiments/multi-llm-3prompt-v1/openrouter"
        / "qwen__qwen-2.5-coder-32b-instruct",
    ),
    (
        "Qwen 2.5",
        ROOT
        / "experiments/multi-llm-observable-v1/openrouter"
        / "qwen__qwen-2.5-coder-32b-instruct",
    ),
    (
        "Qwen 2.5",
        ROOT
        / "experiments/qwen25-16fix-3prompt-10attempt-v1/openrouter"
        / "qwen__qwen-2.5-coder-32b-instruct",
    ),
    ("Qwen 3.8", ROOT / "experiments/qwen38-27b-3prompt-10attempt-v1"),
]


def utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def known_circuits() -> set[str]:
    return {
        p.name
        for p in (ROOT / "benchmarks").iterdir()
        if (p / "manifest.yaml").is_file()
    }


def discover() -> Iterator[dict]:
    known = known_circuits()
    seen: set[Path] = set()
    for model, tree in TREES:
        if not tree.is_dir():
            continue
        files = sorted(list(tree.rglob("generated/*.v")) + list(tree.rglob("generated/*.sv")))
        for rtl in files:
            resolved = rtl.resolve()
            if resolved in seen or "archive" in rtl.parts:
                continue
            seen.add(resolved)
            parts = rtl.relative_to(tree).parts
            circuit = next((part for part in parts if part in known), None)
            if circuit is None:
                continue
            index = parts.index(circuit)
            if index + 2 >= len(parts):
                continue
            prompt, attempt = parts[index + 1 : index + 3]
            if prompt not in {"functional", "cdc_explicit", "observable"}:
                continue
            if not re.fullmatch(r"attempt-\d{3}", attempt):
                continue
            yield {
                "model": model,
                "circuit": circuit,
                "prompt": prompt,
                "attempt": attempt,
                "rtl": rtl,
            }


def identity(row: dict) -> tuple[str, str, str, str]:
    return row["model"], row["circuit"], row["prompt"], row["attempt"]


def normalized_source(rtl: Path, out_dir: Path) -> tuple[Path, bool]:
    """Remove outer Markdown fences without editing the generated artifact."""
    text = rtl.read_text(errors="replace")
    normalized = FENCE.sub("", text).strip() + "\n"
    if normalized == text:
        return rtl, False
    normalized_dir = out_dir / "normalized"
    normalized_dir.mkdir(parents=True, exist_ok=True)
    source = normalized_dir / rtl.name
    source.write_text(normalized)
    return source, True


def load_golden_contract_status() -> dict[str, bool]:
    path = ROOT / "experiments/sby_golden_validated.json"
    payload = json.loads(path.read_text())
    return {
        row["circuit"]: row.get("formal_status") == "FORMAL_PROVED"
        for row in payload["results"]
    }


def save(rows: list[dict], out: Path) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    tmp = out.with_suffix(".json.tmp")
    tmp.write_text(
        json.dumps({"updated": utc(), "n": len(rows), "results": rows}, indent=2)
        + "\n"
    )
    tmp.replace(out)


def golden_contract_passed(circuit: str) -> bool:
    return (ROOT / "formal" / circuit / "golden_prove" / "PASS").is_file()


def run_candidate(
    item: dict,
    contracts: dict[str, dict],
    golden_proved: dict[str, bool],
    *,
    independent: bool = False,
) -> dict:
    model = item["model"]
    circuit = item["circuit"]
    prompt = item["prompt"]
    attempt = item["attempt"]
    rtl: Path = item["rtl"]
    safe_model = re.sub(r"[^A-Za-z0-9_.-]+", "_", model)
    out_dir = WORK / safe_model / circuit / prompt / attempt
    out_dir.mkdir(parents=True, exist_ok=True)
    source, normalized = normalized_source(rtl, out_dir)

    record = {
        "model": model,
        "circuit": circuit,
        "prompt": prompt,
        "attempt": attempt,
        "rtl": str(rtl.relative_to(ROOT)),
        "normalized_markdown_fence": normalized,
        "compile_ok": False,
        "functional_ok": None,
        "formal_status": "NOT_RUN_COMPILE_FAILED",
        "formal_baseline_proved": golden_proved.get(circuit, False),
        "enhanced_status": "NOT_RUN_FORMAL_NOT_PROVED",
        "started": utc(),
    }
    try:
        compiled = xcelium_compile(source, circuit, out_dir)
        record["compile_ok"] = compiled.get("compile_ok") is True
        record["compile_log"] = compiled.get("log")
        if not record["compile_ok"] and not independent:
            return record

        if record["compile_ok"]:
            functional = xcelium_functional(source, circuit, out_dir)
            record["functional_ok"] = functional.get("simulate_ok") is True
            record["functional_note"] = functional.get("sim_note")
            record["functional_log"] = functional.get("sim_log")
            if independent and not record["functional_ok"]:
                record["enhanced_status"] = "NOT_RUN_FUNCTIONAL_FAILED"
        elif independent:
            record["functional_ok"] = False
            record["enhanced_status"] = "NOT_RUN_COMPILE_FAILED"
        if not independent and not record["functional_ok"]:
            record["formal_status"] = "NOT_RUN_FUNCTIONAL_FAILED"
            return record

        if independent and not golden_contract_passed(circuit):
            record["formal_status"] = "FORMAL_UNSUPPORTED"
            record["formal_baseline_proved"] = False
        elif independent or record["functional_ok"]:
            formal = sby_evaluate(
                DEFAULT_SBY,
                model,
                circuit,
                prompt,
                attempt,
                source,
                contracts[circuit],
                300,
            )
            record["formal_status"] = formal["formal_status"]
            record["formal_work_dir"] = formal.get("work_dir")
        if not independent and record["formal_status"] != "FORMAL_PROVED":
            return record
        if independent and not (record["compile_ok"] and record["functional_ok"]):
            return record

        enhanced = enhanced_evaluate(
            {
                "source": safe_model,
                "circuit": circuit,
                "prompt": prompt,
                "attempt": attempt,
                "rtl": source.resolve(),
            }
        )
        record["enhanced_status"] = enhanced.get("status", "ERROR")
        record["enhanced_note"] = enhanced.get("note")
        record["enhanced_log"] = enhanced.get("log")
        return record
    except Exception as exc:
        record["error"] = f"{type(exc).__name__}: {exc}"
        return record
    finally:
        record["finished"] = utc()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--only-model")
    ap.add_argument("--fixed16-only", action="store_true")
    ap.add_argument(
        "--rescore",
        action="store_true",
        help="Discard existing rows selected by the filters and evaluate them again.",
    )
    ap.add_argument(
        "--independent",
        action="store_true",
        help=(
            "Score compile, functional, formal, and enhanced as separate gates. "
            "Formal still runs when the functional testbench fails. "
            "A circuit with no golden_prove/PASS is FORMAL_UNSUPPORTED. "
            "Enhanced runs only after compile and functional both pass."
        ),
    )
    ap.add_argument("--output", type=Path)
    args = ap.parse_args()
    out = args.output if args.output is None or args.output.is_absolute() else ROOT / args.output
    if out is None:
        out = OUT
    os.environ["PATH"] = (
        "/eda/cadence/XCELIUM2603/tools.lnx86/inca/bin/64bit:"
        f"{DEFAULT_SBY.parent}:{os.environ.get('PATH', '')}"
    )
    items = list(discover())
    if args.only_model:
        items = [item for item in items if item["model"] == args.only_model]
    if args.fixed16_only:
        items = [item for item in items if item["circuit"] in FIXED_16]
    golden_proved = load_golden_contract_status()
    contracts = {
        circuit: parse_sby(ROOT / "formal" / circuit / "golden.sby")
        for circuit in golden_proved
    }
    rows: list[dict] = []
    if out.is_file():
        rows = json.loads(out.read_text()).get("results", [])
        # A prior launch skipped apb_regs because its golden contract did not
        # prove. The requested policy is to run formal after functional pass,
        # while retaining a baseline-validity flag, so rescore those rows.
        rows = [
            row
            for row in rows
            if row.get("formal_status") != "SKIP_GOLDEN_CONTRACT_NOT_PROVED"
        ]
    if args.rescore:
        selected = {identity(item) for item in items}
        rows = [row for row in rows if identity(row) not in selected]
    done = {identity(row) for row in rows if row.get("finished")}
    pending = [item for item in items if identity(item) not in done]
    print(
        f"TOTAL={len(items)} done={len(done)} pending={len(pending)} "
        f"golden_contracts={sum(golden_proved.values())}/{len(golden_proved)}",
        flush=True,
    )
    for index, item in enumerate(pending, 1):
        result = run_candidate(
            item, contracts, golden_proved, independent=args.independent
        )
        rows.append(result)
        save(rows, out)
        print(
            f"{index}/{len(pending)} {item['model']} {item['circuit']} "
            f"{item['prompt']}/{item['attempt']} "
            f"C={result['compile_ok']} F={result['functional_ok']} "
            f"SBY={result['formal_status']} ENH={result['enhanced_status']} "
            f"{result.get('error', '')}",
            flush=True,
        )
    print("DONE", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
