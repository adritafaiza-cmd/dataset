#!/usr/bin/env python3
"""Download the pinned BF16 27B checkpoint for the timing pilot."""
from datetime import datetime, timezone
import json
from pathlib import Path
from huggingface_hub import snapshot_download

model = "Qwen/Qwen3.8-27B"
revision = "1d4bf0f2ff6012fd82039f2fa52739d0dd7c60c0"
output = Path(__file__).resolve().parents[1] / "models/Qwen3.8-27B"
output.mkdir(parents=True, exist_ok=True)
snapshot_download(model, revision=revision, local_dir=output, max_workers=4)
(output / "provenance.json").write_text(json.dumps(dict(
    model=model, revision=revision, timestamp_utc=datetime.now(timezone.utc).isoformat()
), indent=2) + "\n")
