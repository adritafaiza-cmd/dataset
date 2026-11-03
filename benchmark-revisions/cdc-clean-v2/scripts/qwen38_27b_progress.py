#!/usr/bin/env python3
"""Report completed, hash-verified generations and per-wave coverage."""
import hashlib
import json
from collections import Counter
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "experiments/qwen38-27b-3prompt-10attempt-v1"
waves = Counter()
prompts = set()
invalid = []
for marker in root.glob("*/*/attempt-*/complete.json"):
    record = json.loads(marker.read_text())
    identity = record["identity"]
    rtl = f"generated/{identity['circuit']}.sv"
    path = marker.parent / rtl
    if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest() != record["sha256"].get(rtl):
        invalid.append(str(marker))
        continue
    waves[identity["seed"]] += 1
    prompts.add((identity["circuit"], identity["prompt_type"]))
print(json.dumps(dict(completed=sum(waves.values()), planned=1320,
    prompt_combinations_with_results=len(prompts), planned_prompt_combinations=132,
    completed_by_seed=dict(sorted(waves.items())), invalid_markers=invalid,
    workers=[json.loads(p.read_text()) for p in sorted(root.glob("progress-rank-*.json"))]), indent=2))
