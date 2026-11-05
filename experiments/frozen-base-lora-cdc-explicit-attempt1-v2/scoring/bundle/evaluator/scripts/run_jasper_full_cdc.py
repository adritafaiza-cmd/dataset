#!/usr/bin/env python3
"""JasperGold structural + functional/protocol + metastability on ALL RTL.

Runs every golden (benchmarks/*/fixed/rtl) and every generated .v/.sv under
the four model experiment trees. Does not skip compile/easy-TB fails: those
are attempted and recorded as elab/error.

cdc_clean remains structural zero CDC/RDC. Functional/protocol is
check_cdc -protocol_check -generate/-prove. Metastability is
check_cdc -metastability -inject/-prove. That is this install's CDC app
API — not a claim of MTBF signoff.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from evaluate_generated import manifest_scalar, top_rtl_for  # noqa: E402
from comparison_set import EXPERIMENT_ROOTS, ONLY_THESE_CIRCUITS  # noqa: E402
from evaluate_pass_at_n import (  # noqa: E402
    JG_BIN,
    csv_data_rows,
    parse_cdc_report,
    sdc_declares_async_groups,
)

OUT = ROOT / "experiments/jasper_full_cdc.json"
LOG = ROOT / "logs/jasper-full-cdc.log"
WALL_SECONDS = 600
FENCE = re.compile(r"^\s*```[a-zA-Z0-9_-]*\s*\n|\n```\s*$", re.M)

EXTRA_TCL = r"""
# --- functional / protocol / metastability (do not abort structural) ---
catch {set_prove_time_limit 120s}
catch {check_cdc -protocol_check -generate -include_failed_schemes}
catch {check_cdc -protocol_check -prove}
catch {check_cdc -protocol_check -export -file $RPT_DIR/protocol_checks.sv -force}
catch {check_cdc -list schemes -file $RPT_DIR/cdc_schemes.rpt -force}
catch {check_cdc -metastability -inject -include_reset -include_protocol_check}
catch {check_cdc -metastability -prove}
catch {check_cdc -metastability -injection_status}
puts "\[cdc_full\] protocol+metastability commands finished"
"""



def utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def circuits() -> list[str]:
    return sorted(
        p.name
        for p in (ROOT / "benchmarks").iterdir()
        if (p / "manifest.yaml").is_file() and (p / "jasper").is_dir()
    )


def collect_rows(apply_circuit_filter: bool = True) -> list[dict]:
    rows: list[dict] = []
    for ckt in circuits():
        rtl = top_rtl_for(ckt)
        rows.append(
            {
                "kind": "golden",
                "source": "golden",
                "circuit": ckt,
                "prompt": "golden",
                "attempt": "fixed",
                "rtl": str(rtl.relative_to(ROOT)),
            }
        )
    known = set(circuits())
    for exp in EXPERIMENT_ROOTS:
        if not exp.is_dir():
            continue
        for rtl in sorted(list(exp.rglob("generated/*.v")) + list(exp.rglob("generated/*.sv"))):
            parts = rtl.relative_to(exp).parts
            # CVC/RTLCoder: circuit/prompt/attempt/generated/file
            # OpenRouter: model/circuit/prompt/attempt/generated/file
            if len(parts) >= 5 and parts[0] in known:
                source = exp.name
                circuit, prompt, attempt = parts[0], parts[1], parts[2]
            elif len(parts) >= 6 and parts[1] in known:
                source = parts[0]
                circuit, prompt, attempt = parts[1], parts[2], parts[3]
            else:
                continue
            allowed = ONLY_THESE_CIRCUITS.get(exp)
            if apply_circuit_filter and allowed is not None and circuit not in allowed:
                continue
            if rtl.name.endswith(".raw"):
                continue
            rows.append(
                {
                    "kind": "generated",
                    "source": source,
                    "circuit": circuit,
                    "prompt": prompt,
                    "attempt": attempt,
                    "rtl": str(rtl.relative_to(ROOT)),
                }
            )
    # de-dupe by rtl path
    seen = set()
    uniq = []
    for r in rows:
        if r["rtl"] in seen:
            continue
        seen.add(r["rtl"])
        uniq.append(r)
    return uniq


def key_of(row: dict) -> str:
    return f"{row['kind']}|{row['source']}|{row['circuit']}|{row['prompt']}|{row['attempt']}|{row['rtl']}"


def parse_log(text: str) -> dict:
    proved = len(re.findall(r"\bproved\b", text, re.I))
    cex = len(re.findall(r"\bcounterexample\b|\bcex\b", text, re.I))
    proto_err = None
    meta_err = None
    m = re.search(r"protocol_check[^\n]*error[^\n]*", text, re.I)
    if m:
        proto_err = m.group(0)[:240]
    m = re.search(r"metastability[^\n]*error[^\n]*", text, re.I)
    if m:
        meta_err = m.group(0)[:240]
    elab_fail = bool(
        re.search(r"elaborat.*fail|Cannot elaborate|error during elaboration", text, re.I)
    )
    return {
        "log_proved_mentions": proved,
        "log_cex_mentions": cex,
        "protocol_error": proto_err,
        "metastability_error": meta_err,
        "elab_fail": elab_fail,
        "protocol_export": False,
    }


def run_one(row: dict) -> dict:
    os.environ["DS"] = str(ROOT)
    os.environ["PATH"] = JG_BIN + ":" + os.environ.get("PATH", "")
    rtl = ROOT / row["rtl"]
    circuit = row["circuit"]
    tag = Path("full_cdc") / row["kind"] / row["source"] / circuit / row["prompt"] / row["attempt"]
    rpt = ROOT / "build/jasper/eval" / tag
    if rpt.exists():
        shutil.rmtree(rpt)
    rpt.mkdir(parents=True)
    rec = dict(row)
    rec["started"] = utc()
    rec["report_dir"] = str(rpt.relative_to(ROOT))
    if not rtl.is_file() or rtl.stat().st_size == 0:
        rec.update({"error": "missing_or_empty_rtl", "cdc_errors": None, "cdc_clean": False})
        rec["finished"] = utc()
        return rec
    raw_text = rtl.read_text(errors="replace")
    normalized = FENCE.sub("", raw_text).strip() + "\n"
    source_rtl = rtl
    if normalized != raw_text:
        source_rtl = rpt / rtl.name
        source_rtl.write_text(normalized)
        rec["normalized_markdown_fence"] = True
    source_tcl = ROOT / "benchmarks" / circuit / manifest_scalar(circuit, "jasper")
    text = source_tcl.read_text()
    fixed_top = top_rtl_for(circuit)
    top_name = re.escape(fixed_top.name)
    replaced, count = re.subn(
        rf"(?m)(?<!\S)\S*{top_name}(?!\S)",
        str(source_rtl.resolve()),
        text,
    )
    if count == 0:
        rec.update({"error": f"tcl does not reference {fixed_top.name}", "cdc_clean": False})
        rec["finished"] = utc()
        return rec
    replaced, count = re.subn(
        r"(?m)^set\s+RPT_DIR\s+.*$",
        f"set RPT_DIR  {rpt}",
        replaced,
        count=1,
    )
    if count != 1:
        rec.update({"error": "no unique RPT_DIR", "cdc_clean": False})
        rec["finished"] = utc()
        return rec
    if row.get("parameters"):
        switches = ""
        for name, value in sorted(row["parameters"].items()):
            if not re.fullmatch(r"[A-Za-z_]\w*", name) or not re.fullmatch(r"[0-9]+", str(value)):
                raise ValueError("Only named integer parameter overrides are supported")
            switches += f" -parameter {name} {value}"
        replaced = re.sub(r"(?m)^(elaborate[^\n]*)$", lambda m: m.group(1) + switches, replaced, count=1)
    if "protocol_check" not in replaced:
        replaced = replaced.rstrip() + "\n" + EXTRA_TCL
    tcl = rpt / "run.tcl"
    tcl.write_text(replaced)
    completed = subprocess.run(
        [
            "timeout",
            "--kill-after=30s",
            f"{WALL_SECONDS}s",
            "jg",
            "-batch",
            "-proj",
            str(rpt / "jgproject"),
            str(tcl),
        ],
        cwd=rpt,
        capture_output=True,
        text=True,
    )
    jg_log = rpt / "jasper.log"
    log_text = completed.stdout + completed.stderr
    jg_log.write_text(log_text)
    rec["jg_returncode"] = completed.returncode
    rec["jasper_log"] = str(jg_log.relative_to(ROOT))
    rec.update(parse_log(log_text))
    proto_files = list(rpt.glob("*protocol*")) + list(rpt.glob("bind_protocol*"))
    rec["protocol_export"] = any(p.is_file() and p.stat().st_size > 0 for p in proto_files)
    rec["protocol_export_bytes"] = sum(p.stat().st_size for p in proto_files if p.is_file())
    rec["protocol_ran"] = "[cdc_full]" in log_text or "protocol_check" in log_text
    rec["metastability_ran"] = "metastability" in log_text
    schemes = rpt / "cdc_schemes.rpt"
    rec["schemes_report"] = schemes.is_file()
    report = rpt / "cdc_report.rpt"
    if report.is_file():
        cdc_e, rdc_e, err_rows, waived_cdc, waived_rdc = parse_cdc_report(
            report.read_text(errors="replace")
        )
        rec["cdc_errors"] = cdc_e
        rec["rdc_errors"] = rdc_e
        rec["error_rows"] = err_rows
        rec["waived_cdc"] = waived_cdc
        rec["waived_rdc"] = waived_rdc
        n_cross = csv_data_rows(rpt / "cdc_crossings.rpt.csv")
        if n_cross == 0:
            n_cross = csv_data_rows(rpt / "cdc_crossings.rpt")
        n_pairs = csv_data_rows(rpt / "cdc_pairs.rpt.csv")
        if n_pairs == 0:
            n_pairs = csv_data_rows(rpt / "cdc_pairs.rpt")
        rec["crossings_extracted"] = n_cross
        rec["pairs_extracted"] = n_pairs
        raw_zero = cdc_e == 0 and rdc_e == 0 and err_rows == 0
        rec["raw_zero"] = raw_zero
        rec["jasper_zero_violations"] = raw_zero
        rec["async_clock_groups"] = sdc_declares_async_groups(circuit)
        structural = n_cross > 0 or n_pairs > 0 or not rec["async_clock_groups"]
        rec["cdc_clean"] = bool(
            raw_zero and (waived_cdc + waived_rdc) == 0 and structural
        )
        rec["jasper_report"] = str(report.relative_to(ROOT))
    else:
        rec["cdc_errors"] = None
        rec["rdc_errors"] = None
        rec["cdc_clean"] = False
        if completed.returncode != 0:
            rec["error"] = rec.get("error") or f"jg_rc={completed.returncode}"
    rec["finished"] = utc()
    return rec


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--resume", action="store_true")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--goldens-only", action="store_true")
    ap.add_argument(
        "--rtl-prefix",
        action="append",
        default=[],
        help="Only run rows whose RTL path starts with this prefix. Repeatable.",
    )
    ap.add_argument(
        "--all-circuits",
        action="store_true",
        help="Include circuits excluded by the comparison-set filter.",
    )
    ap.add_argument(
        "--output",
        type=Path,
        default=OUT,
        help="Result JSON path (default: experiments/jasper_full_cdc.json).",
    )
    args = ap.parse_args()
    rows = collect_rows(apply_circuit_filter=not args.all_circuits)
    if args.goldens_only:
        rows = [r for r in rows if r["kind"] == "golden"]
    if args.rtl_prefix:
        rows = [
            r for r in rows
            if any(r["rtl"].startswith(prefix) for prefix in args.rtl_prefix)
        ]
    if args.limit:
        rows = rows[: args.limit]
    output = args.output if args.output.is_absolute() else ROOT / args.output
    done_keys = set()
    results = []
    if args.resume and output.is_file():
        prev = json.loads(output.read_text())
        results = prev.get("results") or []
        done_keys = {key_of(r) for r in results if r.get("finished")}
    pending = [r for r in rows if key_of(r) not in done_keys]
    print(
        f"TOTAL={len(rows)} done={len(done_keys)} pending={len(pending)} "
        f"goldens={sum(1 for r in rows if r['kind']=='golden')} "
        f"generated={sum(1 for r in rows if r['kind']=='generated')}",
        flush=True,
    )
    for i, row in enumerate(pending, 1):
        rec = run_one(row)
        results.append(rec)
        payload = {
            "updated": utc(),
            "note": (
                "Jasper CDC app: structural check_cdc plus protocol_check "
                "generate/prove and metastability inject/prove. Not MTBF signoff."
            ),
            "n": len(results),
            "results": results,
        }
        output.parent.mkdir(parents=True, exist_ok=True)
        tmp = output.with_suffix(".json.tmp")
        tmp.write_text(json.dumps(payload, indent=2))
        tmp.replace(output)
        print(
            f"{i}/{len(pending)} {rec['kind']} {rec['source']} {rec['circuit']} "
            f"{rec['prompt']}/{rec['attempt']} "
            f"struct_cdc={rec.get('cdc_errors')} proto_export={rec.get('protocol_export')} "
            f"elab_fail={rec.get('elab_fail')} err={rec.get('error')}",
            flush=True,
        )
    print("DONE", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
