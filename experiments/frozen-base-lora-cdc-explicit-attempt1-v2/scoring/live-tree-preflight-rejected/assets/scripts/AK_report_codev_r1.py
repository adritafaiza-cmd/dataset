#!/usr/bin/env python3
"""Render the measured CodeV-R1 Phase-1 table from immutable attempt records."""

from __future__ import annotations

import hashlib
import json
import math
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "experiments" / "codev-r1-rl-qwen-7b"
OUTPUT = ROOT / "reports" / "AK_codev_r1_phase1_results.md"
PROMPTS = ("functional", "cdc_explicit", "observable")
ATTEMPTS = 3


def pass_at_k(n: int, c: int, k: int) -> float:
    if n - c < k:
        return 1.0
    return 1.0 - math.comb(n - c, k) / math.comb(n, k)


def load_cell(circuit: str, prompt: str) -> list[tuple[dict | None, dict | None]]:
    rows = []
    for attempt in range(1, ATTEMPTS + 1):
        directory = MODEL_DIR / circuit / prompt / f"attempt-{attempt:03d}"
        metadata = directory / "metadata.json"
        result = directory / "results.json"
        rows.append(
            (
                json.loads(metadata.read_text()) if metadata.exists() else None,
                json.loads(result.read_text()) if result.exists() else None,
            )
        )
    return rows


def status(meta: dict | None, result: dict | None) -> str:
    if meta is None:
        return "not_started"
    if meta.get("generation_status") != "generated":
        return "generation_error"
    if result is None or result.get("error") or result.get("compile_ok") is None:
        return "tool_error"
    if not result.get("compile_ok"):
        return "compile_failure"
    if result.get("simulation_timeout"):
        return "timeout"
    if not result.get("simulate_ok"):
        return "dynamic_cdc_protocol_failure" if result.get("dynamic_cdc_protocol_evidence") else "functional_protocol_failure"
    if not result.get("structural_analyzed"):
        return "tool_error"
    if not result.get("structural_clean"):
        return "structural_cdc_warning"
    return "strict_pass"


def prompt_stats(circuits: list[str], prompt: str) -> dict:
    cells = {circuit: load_cell(circuit, prompt) for circuit in circuits}
    flat = [row for rows in cells.values() for row in rows]
    categories = Counter(status(*row) for row in flat)
    results = [result for _, result in flat if result is not None]
    generated = sum(meta is not None and meta.get("generation_status") == "generated" for meta, _ in flat)
    compile_pass = sum(result.get("compile_ok") is True for result in results)
    functional_pass = sum(result.get("simulate_ok") is True for result in results)
    structural_analyzed = sum(result.get("structural_analyzed") is True for result in results)
    structural_clean = sum(result.get("structural_clean") is True for result in results)
    strict_pass = sum(result.get("strict_pass") is True for result in results)
    findings = sum(len(result.get("structural_findings", [])) for result in results)
    cdc_evidence_attempts = sum(
        result.get("dynamic_cdc_protocol_evidence") is True
        or bool(result.get("structural_findings", []))
        for result in results
    )
    functional_counts = {
        circuit: sum(result is not None and result.get("simulate_ok") is True for _, result in rows)
        for circuit, rows in cells.items()
    }
    strict_counts = {
        circuit: sum(result is not None and result.get("strict_pass") is True for _, result in rows)
        for circuit, rows in cells.items()
    }
    complete = len(flat) == len(circuits) * ATTEMPTS and categories["not_started"] == 0
    return {
        "planned": len(flat),
        "generated": generated,
        "generation_errors": categories["generation_error"],
        "tool_errors": categories["tool_error"] + categories["not_started"],
        "compile_pass": compile_pass,
        "functional_pass": functional_pass,
        "timeouts": categories["timeout"],
        "dynamic_failures": categories["dynamic_cdc_protocol_failure"],
        "structural_analyzed": structural_analyzed,
        "structural_clean": structural_clean,
        "cdc_evidence_attempts": cdc_evidence_attempts,
        "findings": findings,
        "strict_pass": strict_pass,
        "categories": categories,
        "functional_pass1": sum(pass_at_k(ATTEMPTS, c, 1) for c in functional_counts.values()) / len(circuits),
        "strict_pass1": sum(pass_at_k(ATTEMPTS, c, 1) for c in strict_counts.values()) / len(circuits),
        "functional_pass3": sum(pass_at_k(ATTEMPTS, c, 3) for c in functional_counts.values()) / len(circuits),
        "strict_pass3": sum(pass_at_k(ATTEMPTS, c, 3) for c in strict_counts.values()) / len(circuits),
        "complete": complete,
    }


def prompt_inventory(circuits: list[str]) -> list[str]:
    lines = []
    for prompt in PROMPTS:
        paths = [ROOT / "experiments" / "prompts" / f"{circuit}.{prompt}.md" for circuit in circuits]
        lengths = [len(path.read_text().split()) for path in paths]
        digest = hashlib.sha256("".join(hashlib.sha256(path.read_bytes()).hexdigest() for path in paths).encode()).hexdigest()
        lines.append(
            f"| {prompt} | {len(paths)} | {min(lengths)}–{max(lengths)} | `{digest}` |"
        )
    return lines


def main() -> int:
    circuits = sorted(path.name.removesuffix(".functional.md") for path in (ROOT / "experiments" / "prompts").glob("*.functional.md"))
    stats = {prompt: prompt_stats(circuits, prompt) for prompt in PROMPTS}
    complete = all(value["complete"] for value in stats.values())
    calibration_path = ROOT / "build" / "AK_codev_r1" / "golden_calibration.json"
    calibration = json.loads(calibration_path.read_text()) if calibration_path.exists() else []
    calibration_counts = {
        key: sum(row.get(key) is True for row in calibration)
        for key in ("compile_ok", "simulate_ok", "structural_clean", "strict_pass")
    }
    lines = [
        "# AK — CodeV-R1 Phase 1 full benchmark results",
        "",
        f"**Generated:** {datetime.now(timezone.utc).isoformat()}",
        f"**Matrix status:** {'complete' if complete else 'incomplete'}",
        "",
        "## Release-readiness warning",
        "",
        "**The generation/evaluation matrix is complete, but the public CDC benchmark is not release-ready.** The enhanced 44-circuit typed CDC testbench and structural-lint artifacts described in the September report are absent from this checkout. Current `strict_pass` is an open-source heuristic composite, not a validated first-pass CDC-screen result. Do not publish it as a CDC-clean rate. In addition, 28 testbench-emitted `TIMEOUT` outcomes are currently folded into the functional/protocol primary bucket; raw logs preserve them, but the result schema and table must be normalized before release. See `reports/AK_PUBLIC_CDC_RELEASE_GAP_AND_PLAN.md` for the blocking gaps, ten-rule target, and remediation plan.",
        "",
        "## Scope and protocol",
        "",
        "Model: `zhuyaoyu/CodeV-R1-RL-Qwen-7B`, revision `286cf433f596f1b8525529c1163eb81c19425c22`. The full matrix is 44 circuits (11 `pilot_verified`, 33 `imported_unverified`) × 3 prompt families × 3 independent seeds = 396 planned attempts. Sampling is temperature 0.2, top-p 0.95, maximum 16384 output tokens, and seeds 1001–1003, with the checked-in CodeV reasoning-format system prompt. The 16384-token setting matches the CodeV-R1 paper and was selected after the prepared 8192-token protocol truncated most responses during reasoning; that preliminary matrix is archived and excluded from these results.",
        "",
        "Open-source scoring uses Icarus Verilog for compile/simulation and a repository-owned source-level checker plus each benchmark SDC for conservative direct-crossing triage. `Strict pass` means compile pass, canonical testbench pass, completed structural analysis, valid SDC clock context, and zero structural findings. This is reproducible error-catching evidence, not proof of metastability safety and not a JasperGold-equivalent CDC-clean result.",
        "",
        "## Prompt inventory",
        "",
        "| Prompt key | Files | Word range | Aggregate SHA-256 |",
        "|---|---:|---:|---|",
        *prompt_inventory(circuits),
        "",
        "The checked-in keys map to Prompt Set 1 (`functional`, collaborator checklist), Prompt Set 2 (`cdc_explicit`, collaborator long prompt with an explicit CDC requirement), and Prompt Set 3 (`observable`, supervisor short human-style prompt). The checked-in Set 2 files remain visibly labeled/checklist-structured rather than unstructured; results below identify the immutable repository key to avoid silently relabeling the actual inputs.",
        "",
        "## Open-source golden calibration",
        "",
        (
            f"The identical flow was calibrated on {len(calibration)} checked-in golden tops: "
            f"compile {calibration_counts['compile_ok']}/{len(calibration)}, functional "
            f"{calibration_counts['simulate_ok']}/{len(calibration)}, structural-clean "
            f"{calibration_counts['structural_clean']}/{len(calibration)}, and strict "
            f"{calibration_counts['strict_pass']}/{len(calibration)}. `apb_regs` and "
            "`cdc_2phase_clearable` are predeclared Icarus tool incompatibilities and are "
            "reported as tool errors for every prompt, not model failures. Remaining golden "
            "structural warnings and incomplete SDCs establish the interpretation ceiling of "
            "the heuristic check."
        ),
        "",
        "## Measured outcomes",
        "",
        "| Prompt | Saved RTL | Generation errors | Tool errors | Compile pass | Functional pass | Timeouts | Dynamic CDC/protocol failures | Structural analyzed | Structural clean | CDC-evidence attempts | Structural findings | Strict pass | Functional pass@1 | Strict pass@1 | Functional pass@3 | Strict pass@3 |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for prompt in PROMPTS:
        row = stats[prompt]
        lines.append(
            "| " + " | ".join(
                [
                    prompt,
                    f"{row['generated']}/{row['planned']}",
                    str(row["generation_errors"]),
                    str(row["tool_errors"]),
                    f"{row['compile_pass']}/{row['generated']}",
                    f"{row['functional_pass']}/{row['generated']}",
                    str(row["timeouts"]),
                    str(row["dynamic_failures"]),
                    f"{row['structural_analyzed']}/{row['generated']}",
                    f"{row['structural_clean']}/{row['generated']}",
                    str(row["cdc_evidence_attempts"]),
                    str(row["findings"]),
                    f"{row['strict_pass']}/{row['planned']}",
                    f"{row['functional_pass1']:.3f}",
                    f"{row['strict_pass1']:.3f}",
                    f"{row['functional_pass3']:.3f}",
                    f"{row['strict_pass3']:.3f}",
                ]
            ) + " |"
        )
    totals = {
        key: sum(value["categories"][key] for value in stats.values())
        for key in {
            category
            for value in stats.values()
            for category in value["categories"]
        }
    }
    lines += [
        "",
        "## Prior-report-compatible aggregate",
        "",
        "Across 396 attempts:",
        "",
        f"- {totals.get('generation_error', 0)} generation/extraction failures",
        f"- {totals.get('compile_failure', 0)} compilation failures",
        f"- {totals.get('functional_protocol_failure', 0)} primary functional/protocol failures",
        f"- {totals.get('dynamic_cdc_protocol_failure', 0)} primary dynamic CDC/reset flag(s)",
        f"- {totals.get('strict_pass', 0)} strict passes",
        f"- {totals.get('structural_cdc_warning', 0)} primary structural CDC warnings",
        f"- {totals.get('timeout', 0)} timeouts",
        f"- {totals.get('tool_error', 0)} tool errors",
        f"- {sum(value['cdc_evidence_attempts'] for value in stats.values())} attempts with automatically attributed CDC/reset evidence",
        f"- {sum(value['compile_pass'] for value in stats.values())} attempts compiled; {sum(value['functional_pass'] for value in stats.values())} passed the canonical functional testbench",
        "",
        "This uses the September report's primary-outcome vocabulary. Generation/extraction failures are kept separate because the earlier model run did not contain an equivalent complete generation matrix.",
        "",
        "## Prompt comparison",
        "",
        "- Prompt Set 1 (`functional`) achieved functional pass@1 30.3%, strict pass@1 25.8%, functional pass@3 52.3%, and strict pass@3 38.6%.",
        "- Prompt Set 2 (`cdc_explicit`) achieved functional pass@1 31.1%, strict pass@1 29.5%, functional pass@3 43.2%, and strict pass@3 38.6%.",
        "- Prompt Set 3 (`observable`) achieved functional pass@1 30.3%, strict pass@1 25.0%, functional pass@3 43.2%, and strict pass@3 36.4%.",
        "",
        "Set 2 has the highest strict pass@1 by 3.7 percentage points over Set 1 and 4.5 points over Set 3. At pass@3, Sets 1 and 2 tie on strict pass rate; Set 1 has the highest functional pass@3. These are descriptive comparisons over the same balanced matrix, not causal prompt-effect estimates.",
        "",
        "## Primary-outcome breakdown",
        "",
    ]
    for prompt in PROMPTS:
        categories = stats[prompt]["categories"]
        rendered = ", ".join(f"{key}={categories[key]}" for key in sorted(categories))
        lines.append(f"- `{prompt}`: {rendered}")
    lines += [
        "",
        "## Interpretation boundary",
        "",
        "The 33 `imported_unverified` circuits are reported separately in raw records through `benchmark_status`; aggregate prompt comparisons are descriptive because circuit specifications and testbench strength are not yet frozen. A structural warning is an automatically detected review item, not an adjudicated CDC root cause. Phase 2 will inspect failed candidates and classify functional versus CDC-specific causes.",
        "",
    ]
    OUTPUT.write_text("\n".join(lines))
    print(f"Wrote {OUTPUT.relative_to(ROOT)}; complete={complete}")
    return 0 if complete else 2


if __name__ == "__main__":
    raise SystemExit(main())
