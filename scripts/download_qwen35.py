#!/usr/bin/env python3
"""Download an immutable official Qwen3.5 snapshot and record provenance."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
from huggingface_hub import HfApi, snapshot_download

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--model', default='Qwen/Qwen3.5-9B')
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
record = args.output / 'provenance.json'
if record.exists():
    provenance = json.loads(record.read_text())
    assert provenance['model'] == args.model
    revision = provenance['revision']
else:
    revision = HfApi().model_info(args.model).sha
    provenance = dict(model=args.model, revision=revision,
                      timestamp_utc=datetime.now(timezone.utc).isoformat())
    record.write_text(json.dumps(provenance, indent=2) + '\n')
print(f'Downloading {args.model}@{revision}', flush=True)
snapshot_download(args.model, revision=revision, local_dir=args.output,
                  max_workers=4)
print(f'Download complete: {args.output}', flush=True)
