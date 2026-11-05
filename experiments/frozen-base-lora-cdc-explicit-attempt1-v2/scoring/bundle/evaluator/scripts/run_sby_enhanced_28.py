#!/usr/bin/env python3
"""SymbiYosys and enhanced Icarus TB for the 28 golden circuits and their generated RTL."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(ROOT / "enhanced_cdc_tb"))

from comparison_set import FIXED_16  # noqa: E402
from evaluate_icarus_observable import (  # noqa: E402
    FAIL_RE,
    PASS_RE,
    run,
    simulation_arguments,
)
from evaluate_symbiyosys_eligible import (  # noqa: E402
    DEFAULT_SBY,
    evaluate as sby_eval,
    parse_sby,
)
from run_enhanced import enhanced_tb, enhanced_top  # noqa: E402
from evaluate_generated import top_rtl_for  # noqa: E402

FENCE = re.compile(r"^\s*```[a-zA-Z0-9_-]*\s*\n|\n```\s*$", re.M)
TREES = [
    ("complexvcoder", ROOT / "experiments/complexvcoder-3prompt-10attempt-v1"),
    ("rtlcoder", ROOT / "experiments/rtlcoder-deepseek-3prompt-10attempt-v1"),
    ("qwen35", ROOT / "experiments/qwen35-3prompt-10attempt-v1"),
    ("llama", ROOT / "experiments/llama-16fix-3prompt-10attempt-v1"),
    ("llama", ROOT / "experiments/multi-llm-3prompt-v1/openrouter/meta-llama__llama-3.3-70b-instruct"),
    ("llama", ROOT / "experiments/multi-llm-observable-v1/openrouter/meta-llama__llama-3.3-70b-instruct"),
    ("qwen25", ROOT / "experiments/multi-llm-3prompt-v1/openrouter/qwen__qwen-2.5-coder-32b-instruct"),
    ("qwen25", ROOT / "experiments/multi-llm-observable-v1/openrouter/qwen__qwen-2.5-coder-32b-instruct"),
]


def all_circuits() -> list[str]:
    return sorted(
        p.name
        for p in (ROOT / "benchmarks").iterdir()
        if (p / "manifest.yaml").is_file()
    )


def generated(wanted: set[str]) -> list[dict]:
    rows = []
    for model, tree in TREES:
        if not tree.is_dir():
            continue
        files = list(tree.rglob("generated/*.v")) + list(tree.rglob("generated/*.sv"))
        for rtl in files:
            if "archive" in rtl.parts:
                continue
            parts = rtl.relative_to(tree).parts
            circuit = next((part for part in parts if part in wanted), None)
            if circuit is None:
                continue
            idx = parts.index(circuit)
            if idx + 2 >= len(parts):
                continue
            prompt, attempt = parts[idx + 1], parts[idx + 2]
            if prompt not in {"functional", "cdc_explicit", "observable"}:
                continue
            rows.append(
                {
                    "model": model,
                    "circuit": circuit,
                    "prompt": prompt,
                    "attempt": attempt,
                    "rtl": rtl,
                }
            )
    return rows


def strip_copy(rtl: Path, work: Path) -> Path:
    text = rtl.read_text(errors="replace")
    stripped = FENCE.sub("", text).strip() + "\n"
    if stripped == text:
        return rtl
    work.mkdir(parents=True, exist_ok=True)
    dest = work / rtl.name
    dest.write_text(stripped)
    return dest


def run_sby(rows: list[dict], wanted: list[str]) -> None:
    out = ROOT / "experiments/sby_28.json"
    done = json.loads(out.read_text())["results"] if out.is_file() else []
    seen = {(r["model"], r["circuit"], r.get("prompt_type"), r["attempt"]) for r in done}
    contracts = {}
    for circuit in wanted:
        sby = ROOT / "formal" / circuit / "golden.sby"
        if sby.is_file():
            contracts[circuit] = parse_sby(sby)
    pending = [
        r
        for r in rows
        if r["circuit"] in contracts
        and (r["model"], r["circuit"], r["prompt"], r["attempt"]) not in seen
    ]
    print(f"SBY circuits={len(contracts)} pending={len(pending)} done={len(done)}", flush=True)
    for i, row in enumerate(pending, 1):
        work = ROOT / "build/sby28" / row["model"] / row["circuit"] / row["prompt"] / row["attempt"]
        source = strip_copy(row["rtl"], work)
        result = sby_eval(
            DEFAULT_SBY,
            row["model"],
            row["circuit"],
            row["prompt"],
            row["attempt"],
            source,
            contracts[row["circuit"]],
            90,
        )
        result["rtl"] = str(row["rtl"].relative_to(ROOT))
        done.append(result)
        out.write_text(json.dumps({"n": len(done), "results": done}) + "\n")
        print(
            f"SBY {i}/{len(pending)} {row['model']} {row['circuit']} {row['prompt']}/{row['attempt']} "
            f"{result['formal_status']}",
            flush=True,
        )
    print("SBY DONE", flush=True)


def run_enhanced(rows: list[dict]) -> None:
    out = ROOT / "experiments/enhanced_icarus_28.json"
    done = json.loads(out.read_text())["results"] if out.is_file() else []
    seen = {(r["model"], r["circuit"], r["prompt"], r["attempt"]) for r in done}
    pending = [r for r in rows if (r["model"], r["circuit"], r["prompt"], r["attempt"]) not in seen]
    print(f"ENH pending={len(pending)} done={len(done)}", flush=True)
    for i, row in enumerate(pending, 1):
        tb = enhanced_tb(row["circuit"])
        rec = {
            "model": row["model"],
            "circuit": row["circuit"],
            "prompt": row["prompt"],
            "attempt": row["attempt"],
            "rtl": str(row["rtl"].relative_to(ROOT)),
        }
        if tb is None:
            rec.update(compile_ok=None, simulate_ok=None, error="no enhanced TB")
        else:
            work = (
                ROOT
                / "build/enhanced-icarus-28"
                / row["model"]
                / row["circuit"]
                / row["prompt"]
                / row["attempt"]
            )
            work.mkdir(parents=True, exist_ok=True)
            source = strip_copy(row["rtl"], work)
            try:
                args, sources = simulation_arguments(row["circuit"], source)
                from evaluate_icarus_observable import UNSUPPORTED
                from run_enhanced import canonical_tb

                if row["circuit"] in UNSUPPORTED:
                    raise RuntimeError(UNSUPPORTED[row["circuit"]])
                canonical = canonical_tb(row["circuit"]).resolve()
                sources = [tb.resolve() if s == canonical else s for s in sources]
                if tb.resolve() not in sources:
                    sources.append(tb.resolve())
                top = enhanced_top(tb)
                args = [top if a == args[args.index("-s") + 1] else a for a in args]
                exe = work / "sim.vvp"
                rc, log, to = run(["iverilog", *args, "-o", str(exe), *map(str, sources)], 90, work)
                (work / "compile.log").write_text(log)
                rec["compile_ok"] = rc == 0 and exe.exists() and not to
                rec["simulate_ok"] = False
                if rec["compile_ok"]:
                    rc, log, to = run(["vvp", str(exe)], 90, work)
                    (work / "sim.log").write_text(log)
                    rec["simulate_ok"] = (
                        rc == 0 and not to and bool(PASS_RE.search(log)) and not FAIL_RE.search(log)
                    )
            except Exception as exc:
                rec.update(compile_ok=None, simulate_ok=None, error=f"{type(exc).__name__}: {exc}")
        done.append(rec)
        out.write_text(json.dumps({"n": len(done), "results": done}) + "\n")
        if i % 20 == 0 or i == 1:
            print(
                f"ENH {i}/{len(pending)} {row['model']} {row['circuit']} "
                f"compile={rec.get('compile_ok')} pass={rec.get('simulate_ok')}",
                flush=True,
            )
    print("ENH DONE", flush=True)


def main() -> int:
    which = sys.argv[1] if len(sys.argv) > 1 else "both"
    wanted = all_circuits()
    print(f"CKTS={len(wanted)} qwen25_only={sorted(FIXED_16)}", flush=True)
    rows = [{"model": "golden", "circuit": c, "prompt": "golden", "attempt": "fixed", "rtl": top_rtl_for(c)} for c in wanted]
    rows.extend(generated(set(wanted)))
    print(f"ROWS={len(rows)}", flush=True)
    if which in {"sby", "both"}:
        run_sby(rows, wanted)
    if which in {"enh", "both"}:
        run_enhanced(rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
