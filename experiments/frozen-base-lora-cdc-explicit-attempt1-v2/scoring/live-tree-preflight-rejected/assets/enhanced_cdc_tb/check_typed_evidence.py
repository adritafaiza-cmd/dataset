#!/usr/bin/env python3
"""Audit enhanced testbenches for machine-readable violation evidence."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
ERROR_INCREMENT = re.compile(r"\berrors\s*(?:=|<=)\s*errors\s*\+\s*1\b")
TYPED_DISPLAY = re.compile(
    r"\b(?:CDC/RESET|CDC|RESET|HANDSHAKE|SYNCHRONIZER|FIFO CDC|PROTOCOL)"
    r"\s+VIOLATION\s+\[(?:[A-Z][A-Z0-9_]*|%0s)\]\s*:"
)
UNTYPED_DISPLAY = re.compile(r"\bVIOLATION\s*:")
GENERIC_FAIL = re.compile(r'\$display\s*\(\s*"FAIL\b', re.I)


def audit(path: Path) -> list[str]:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    failures: list[str] = []
    typed_count = 0
    for index, line in enumerate(lines):
        if TYPED_DISPLAY.search(line):
            typed_count += 1
        if UNTYPED_DISPLAY.search(line):
            failures.append(f"{path}:{index + 1}: violation display lacks [RULE_ID]")
        if GENERIC_FAIL.search(line) and "timeout" not in line.lower():
            failures.append(f"{path}:{index + 1}: generic FAIL display")
        if ERROR_INCREMENT.search(line):
            nearby = "\n".join(lines[max(0, index - 8) : min(len(lines), index + 4)])
            if not TYPED_DISPLAY.search(nearby):
                failures.append(
                    f"{path}:{index + 1}: error increment lacks nearby typed evidence"
                )
    if ERROR_INCREMENT.search("\n".join(lines)) and typed_count == 0:
        failures.append(f"{path}: contains errors but no typed violation display")
    return failures


def main() -> int:
    paths = sorted((*ROOT.glob("*/*.v"), *ROOT.glob("*/*.sv")))
    failures = [failure for path in paths for failure in audit(path)]
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print(f"TYPED EVIDENCE AUDIT OK ({len(paths)} enhanced testbenches)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
