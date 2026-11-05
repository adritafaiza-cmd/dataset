#!/usr/bin/env python3
"""Strip chat/markdown wrappers from RTLCoder dumps to module…endmodule."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from generate_rtlcoder import extract_verilog  # noqa: E402

EXP = ROOT / "experiments/rtlcoder-deepseek-3prompt-10attempt-v1"
TOKEN_RE = re.compile(r"<\|[^|]*\|>")


def clean(text: str) -> str:
    text = TOKEN_RE.sub("", text)
    text = text.replace("```systemverilog", "```").replace("```verilog", "```")
    extracted = extract_verilog(text)
    start = None
    for match in re.finditer(r"\bmodule\s+([A-Za-z_]\w*)\s*[#(;]", extracted):
        if match.group(1) in {"is", "the", "a"}:
            continue
        start = match.start()
        break
    if start is None:
        for match in re.finditer(r"\bmodule\s+([A-Za-z_]\w*)\s*[#(;]", text):
            start = match.start()
            extracted = text
            break
    if start is None:
        return extracted.strip() + "\n"
    body = extracted[start:]
    end = body.find("endmodule")
    if end == -1:
        return body.strip() + "\n"
    return body[: end + len("endmodule")].strip() + "\n"


def main() -> int:
    files = sorted(EXP.glob("*/*/attempt-???/generated/*.sv"))
    files = [p for p in files if not p.name.endswith(".raw")]
    ok = empty = already = 0
    for path in files:
        raw_path = path.with_suffix(path.suffix + ".raw")
        if raw_path.exists():
            text = raw_path.read_text(errors="replace")
        else:
            text = path.read_text(errors="replace")
            raw_path.write_text(text)
        stripped = clean(text)
        if stripped.lstrip().startswith("module") and "endmodule" in stripped:
            already_ok = text.lstrip().startswith("module") and not text.lstrip().startswith(
                "Sure"
            )
            if already_ok and "```" not in text[:80]:
                already += 1
            else:
                ok += 1
            path.write_text(stripped)
        else:
            empty += 1
            path.write_text(stripped)
    print(
        f"cleaned={ok} already_rtl={already} no_module={empty} n={len(files)}",
        flush=True,
    )
    return 0 if empty == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
