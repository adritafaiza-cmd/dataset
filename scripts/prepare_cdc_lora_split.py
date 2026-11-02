#!/usr/bin/env python3
"""Choose the external CDC pairs for the first Qwen3.8 LoRA.

Reads /scratch training/cdc-external-v1. Writes a filtered train.jsonl.
The 44 exam circuits, their prompts, and the dev split stay out.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path("/scratch/ft2335/dataset-observable")
DATA = ROOT / "training" / "cdc-external-v1"
OUT = ROOT / "training" / "cdc-lora-v1"
MIN_KEEP = 12

EXAM = frozenset({
    "afifo", "apb_cdc", "apb_regs", "apbslave", "apbxclk", "arbiter",
    "areset_deassert_sync", "areset_sync", "async_bidir_fifo",
    "async_bidir_ramif_fifo", "async_fifo", "async_fifo_sv", "axi_dma",
    "axidma", "axil_cdc", "axis_adapter", "axis_async_fifo",
    "axis_async_fifo_adapter", "axis_fifo", "axis_register", "axis_switch",
    "axixclk", "cdc_2phase", "cdc_2phase_clearable", "cdc_4phase",
    "cdc_fifo_2phase", "cdc_fifo_gray", "cdc_fifo_gray_clearable",
    "cdc_reset_ctrlr", "data_sync", "edge_propagator", "i2c_master",
    "isochronous_4phase_handshake", "isochronous_spill_register",
    "pulse_sync", "rstgen", "spi_master_slave", "sync", "sync_multistage",
    "sync_reset", "sync_wedge", "synchronizer", "uart16550", "wbxclk",
})

DATA_MECH = frozenset({
    "level_sync", "level_synchronization", "pulse_sync", "pulse_toggle_transfer",
    "toggle_sync", "req_ack", "request_acknowledge", "gray_counter",
    "async_fifo", "dual_clock_fifo", "bundled_data", "multi_bit_handshake",
})
RESET_MECH = frozenset({
    "async_assert_sync_release_reset", "reset_sync",
})


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def as_list(value):
    if value is None:
        return []
    if isinstance(value, str):
        return [value] if value.strip() else []
    if isinstance(value, list):
        return [str(item) for item in value]
    return [str(value)]


def n_clocks(value):
    if value is None:
        return 0
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, int):
        return value
    if isinstance(value, (list, dict)):
        return len(value)
    if isinstance(value, str):
        return 1 if value.strip() else 0
    return 0


def nonempty(value):
    if value is None or value is False:
        return False
    if isinstance(value, (list, dict, str)):
        return len(value) > 0
    return True


def repo_of(module_dir: Path) -> str:
    path = module_dir / "PROVENANCE.json"
    if not path.is_file():
        return "unknown"
    raw = load_json(path)
    for key in ("repo", "repository", "repo_url", "url", "upstream"):
        if raw.get(key):
            return str(raw[key])
    return "unknown"


def elaborate_failed(module_dir: Path) -> bool:
    path = module_dir / "validation.json"
    if not path.is_file():
        return False
    raw = load_json(path)
    if raw.get("elaborate_ok") is False:
        return True
    elaborate = raw.get("elaborate")
    if isinstance(elaborate, dict) and elaborate.get("ok") is False:
        return True
    return False


def train_user_texts() -> set[str]:
    path = DATA / "train.jsonl"
    if not path.is_file():
        raise SystemExit(f"missing {path}")
    texts = set()
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            row = json.loads(line)
            messages = row["messages"]
            users = [item["content"] for item in messages if item.get("role") == "user"]
            if len(users) != 1:
                raise SystemExit("a train.jsonl row does not have exactly one user message")
            texts.add(users[0].strip())
    if not texts:
        raise SystemExit("train.jsonl has no rows")
    return texts


def decide(module_dir: Path, structural: dict, lines: int) -> tuple[str, str]:
    name = module_dir.name
    if name in EXAM:
        return "drop", "exam_module_name"
    mechs = set(as_list(structural.get("mechanism")))
    clocks = n_clocks(structural.get("clocks"))
    data = mechs & DATA_MECH
    reset = mechs & RESET_MECH
    crossing = nonempty(structural.get("crossing_signals"))
    sync = structural.get("synchronizer_present") is True
    if data and clocks >= 2 and crossing:
        return "keep", "data_cdc"
    if data and clocks >= 1 and sync and crossing and lines <= 400:
        return "keep", "one_clock_primitive"
    if reset and not data and crossing and lines <= 180:
        return "keep", "rdc_primitive"
    if not crossing:
        return "drop", "no_crossing"
    if reset and not data:
        return "drop", "large_reset_only"
    if data and clocks < 2:
        return "drop", "one_clock_not_a_small_primitive"
    return "drop", "no_data_cdc_mechanism"


def main() -> int:
    if (OUT / "audit.md").exists():
        raise SystemExit("audit.md is frozen; refusing to replace its training allowlist with heuristic filtering")
    train_texts = train_user_texts()
    OUT.mkdir(parents=True, exist_ok=True)
    kept_rows = []
    decisions = []
    seen_users = set()
    for module_dir in sorted(path for path in DATA.iterdir() if path.is_dir()):
        structural_path = module_dir / "structural.json"
        pair_path = module_dir / "pair.jsonl"
        source_path = module_dir / "source.sv"
        if not (structural_path.is_file() and pair_path.is_file() and source_path.is_file()):
            continue
        pair_lines = [line for line in pair_path.read_text(encoding="utf-8").splitlines() if line.strip()]
        if len(pair_lines) != 1:
            decisions.append({"module": module_dir.name, "action": "drop", "reason": "pair_jsonl_not_one_row"})
            continue
        pair = json.loads(pair_lines[0])
        messages = pair.get("messages") or []
        users = [item.get("content", "") for item in messages if item.get("role") == "user"]
        assistants = [item.get("content", "") for item in messages if item.get("role") == "assistant"]
        if len(users) != 1 or len(assistants) != 1 or not assistants[0].strip():
            decisions.append({"module": module_dir.name, "action": "drop", "reason": "bad_messages"})
            continue
        if users[0].strip() not in train_texts:
            decisions.append({"module": module_dir.name, "action": "skip", "reason": "not_in_train_jsonl"})
            continue
        if users[0].strip() in seen_users:
            decisions.append({"module": module_dir.name, "action": "drop", "reason": "duplicate_spec"})
            continue
        seen_users.add(users[0].strip())
        if elaborate_failed(module_dir):
            decisions.append({"module": module_dir.name, "action": "drop", "reason": "elaborate_failed"})
            continue
        source = source_path.read_text(encoding="utf-8", errors="replace")
        lines = source.count("\n") + 1
        action, reason = decide(module_dir, load_json(structural_path), lines)
        record = {
            "module": module_dir.name,
            "action": action,
            "reason": reason,
            "lines": lines,
            "repo": repo_of(module_dir),
        }
        decisions.append(record)
        if action == "keep":
            if "endmodule" not in assistants[0]:
                record["action"] = "drop"
                record["reason"] = "assistant_missing_endmodule"
                continue
            kept_rows.append({"messages": [
                {"role": "user", "content": users[0]},
                {"role": "assistant", "content": assistants[0]},
            ], "module": module_dir.name, "reason": reason, "repo": record["repo"]})

    report = {
        "train_jsonl_rows": len(train_texts),
        "modules_seen": sum(1 for row in decisions if row["action"] != "skip"),
        "kept": len(kept_rows),
        "by_reason": {},
        "kept_by_repo": {},
    }
    for row in decisions:
        report["by_reason"][row["reason"]] = report["by_reason"].get(row["reason"], 0) + 1
    for row in kept_rows:
        report["kept_by_repo"][row["repo"]] = report["kept_by_repo"].get(row["repo"], 0) + 1
    (OUT / "filter_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    (OUT / "filter_decisions.jsonl").write_text(
        "".join(json.dumps(row) + "\n" for row in decisions), encoding="utf-8")
    train_path = OUT / "train.jsonl"
    train_path.write_text(
        "".join(json.dumps({
            "messages": row["messages"],
            "module": row["module"],
            "reason": row["reason"],
        }) + "\n" for row in kept_rows),
        encoding="utf-8")
    print(json.dumps(report, indent=2))
    print(f"KEEP {len(kept_rows)}", flush=True)
    if len(kept_rows) < MIN_KEEP:
        print(f"FILTER_TOO_SMALL {len(kept_rows)} < {MIN_KEEP}", flush=True)
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main())
