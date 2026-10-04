#!/usr/bin/env python3
"""Fail generated RTL that matches CDC anti-patterns A–H (structural).

Golden reset-synchronizer pipes are allowed. Human-repaired and GPT
ready=rst&&… patterns are not.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

RESET_PIPE_LHS = {
    "m_presetn",
    "reset_pipe",
    "s_reset_pipe",
    "s_resetn",
    "full_reset",
    "full_reset_pipe",
    "wrst_sync_ff",
    "rrst_sync_ff",
    "src_rst_sync_q",
    "dst_rst_sync_q",
    "wrst_n_sync",
    "rrst_n_sync",
}

RULES = [
    (
        "D",
        "synchronizer output bypasses final stage",
        re.compile(
            r"\bassign\s+\w*sync\w*\s*=\s*\w*(?:flipflops|sync_ff|sync_reg)\s*\[\s*0\s*\]",
            re.I,
        ),
    ),
    (
        "C",
        "binary FIFO pointer exported on crossing signal",
        re.compile(
            r"\{\s*(?:rbin|wbin)\s*,\s*(?:rptr|wptr)\s*\}\s*<=\s*"
            r"\{\s*\w*bin\w*\s*,\s*\w*bin\w*\s*\}",
            re.I,
        ),
    ),
    (
        "A",
        "reset synchronizer output directly driven by asynchronous reset",
        re.compile(
            r"\bassign\s+\w*sync_rst\w*\s*=\s*\w*async_rst\w*\s*;",
            re.I,
        ),
    ),
    (
        "B",
        "clocked domain reset body uses a foreign-domain reset",
        re.compile(
            r"always\s*@\s*\(\s*posedge\s+b_clk_i\s+or\s+negedge\s+b_rst_ni"
            r"\s*\)\s*begin[\s\S]{0,120}?\bif\s*\(\s*!\s*a_rst_ni\s*\)"
            r"|always\s*@\s*\(\s*posedge\s+a_clk_i\s+or\s+negedge\s+a_rst_ni"
            r"\s*\)\s*begin[\s\S]{0,120}?\bif\s*\(\s*!\s*b_rst_ni\s*\)",
            re.I,
        ),
    ),
    (
        "E",
        "stalled AXI payload driven from live source data",
        re.compile(
            r"\bassign\s+m_axis_tdata\s*=\s*m_axis_tready\s*\?[^:;]+:\s*s_axis_tdata",
            re.I,
        ),
    ),
    (
        "C",
        "binary pointer CDC (wptr-rptr / count=wptr)",
        re.compile(r"\b(?:wptr|wr_ptr)\s*-\s*(?:rptr|rd_ptr)\b|\bcount\s*=\s*(?:wptr|wr_ptr)\b", re.I),
    ),
    (
        "G",
        "reset AND-ed into ready (RST_PH_GLCH)",
        re.compile(r"\bsrc_ready_o\s*=\s*[^;]*\bsrc_rst_ni\s*&&", re.I),
    ),
    (
        "D",
        "combo req==ack across clocks (no 2-flop)",
        re.compile(r"\bsrc_ready_o\s*=\s*[^;]*\b(?:src_req|src_req_toggle_q)\s*==\s*\b(?:dst_ack|dst_ack_toggle_q)\b", re.I),
    ),
    (
        "E",
        "dest clock samples raw src_data_i",
        re.compile(
            r"always(?:_ff)?\s*@\s*\(\s*posedge\s+dst_clk\w*[^\)]*\)[\s\S]{0,200}?\bsrc_data_i\s*<=",
            re.I,
        ),
    ),
    (
        "C",
        "empty flag written on the write clock",
        re.compile(
            r"always(?:_ff)?\s*@\s*\(\s*posedge\s+(?:i_wclk|wclk)[\s\S]{0,300}?\b(?:o_rd_empty|rempty)\b",
            re.I,
        ),
    ),
    (
        "C",
        "full flag written on the read clock",
        re.compile(
            r"always(?:_ff)?\s*@\s*\(\s*posedge\s+(?:i_rclk|rclk)[\s\S]{0,300}?\b(?:o_wr_full|wfull)\b",
            re.I,
        ),
    ),
]

ALWAYS_ASYNC = re.compile(
    r"always(?:_ff)?\s*@\s*\(\s*posedge\s+(\w+)\s+or\s+negedge\s+(\w+)\s*\)\s*begin([\s\S]{0,1200}?)(?:end\b)",
    re.I,
)

CLK_RST_FOREIGN = [
    # (clock regex, reset regex) — reset is not native to that clock
    (re.compile(r"^(?:M_APB_PCLK|dst_clk_i|i_rclk|rclk)$", re.I), re.compile(r"S_PRESETn|src_rst_ni|i_wr_reset_n|wrst_n", re.I)),
    (re.compile(r"^(?:S_APB_PCLK|src_clk_i|i_wclk|wclk)$", re.I), re.compile(r"M_PRESETn|dst_rst_ni|i_rd_reset_n|rrst_n", re.I)),
]


def _lhs_names(block: str) -> set[str]:
    names = set()
    for m in re.finditer(r"(?:^|[,{]|\bleft\s*)\s*(\w+)\s*(?:<=|=)", block):
        names.add(m.group(1).lower())
    for m in re.finditer(r"\b(\w+)\s*<=", block):
        names.add(m.group(1).lower())
    return names


def _finding(
    text: str, path: str, offset: int, mark: str, message: str
) -> dict[str, object]:
    line = text.count("\n", 0, offset) + 1
    lines = text.splitlines()
    excerpt = lines[line - 1].strip() if 0 < line <= len(lines) else ""
    return {
        "rule_id": f"CDC-{mark}",
        "message": message,
        "file": path,
        "line": line,
        "excerpt": excerpt[:500],
        "attributable": True,
        "cdc_related": True,
    }


def lint_findings(text: str, path: str) -> list[dict[str, object]]:
    """Return structured findings while retaining ``lint_text`` compatibility."""
    findings: list[dict[str, object]] = []
    stripped = text.lstrip()
    starts_design_unit = bool(
        re.search(r"^\s*(?:module|package|interface)\b", text, re.M)
    )
    has_complete_design_unit = bool(
        re.search(r"\bendmodule\b", text)
        or (
            re.search(r"\bpackage\b", text)
            and re.search(r"\bendpackage\b", text)
        )
        or (
            re.search(r"\binterface\b", text)
            and re.search(r"\bendinterface\b", text)
        )
    )
    if stripped.startswith("```") or (
        starts_design_unit and not has_complete_design_unit
    ):
        offset = len(text) - len(stripped) if stripped.startswith("```") else 0
        findings.append(
            _finding(text, path, offset, "I", "incomplete or truncated RTL")
        )
    for mark, title, pat in RULES:
        match = pat.search(text)
        if match:
            findings.append(_finding(text, path, match.start(), mark, title))

    for m in ALWAYS_ASYNC.finditer(text):
        clk, rst, body = m.group(1), m.group(2), m.group(3)
        foreign = any(cr.search(clk) and rr.search(rst) for cr, rr in CLK_RST_FOREIGN)
        if not foreign:
            continue
        lhs = _lhs_names(body)
        if lhs and lhs <= RESET_PIPE_LHS:
            continue
        extra = sorted(lhs - RESET_PIPE_LHS)
        message = (
            f"foreign async reset always @(posedge {clk} or negedge {rst})"
            + (f" also assigns {', '.join(extra)}" if extra else "")
        )
        findings.append(_finding(text, path, m.start(), "B", message))
    return findings


def lint_text(text: str, path: str) -> list[str]:
    """Legacy string API (output intentionally unchanged)."""
    return [
        f"{finding['file']}: type {str(finding['rule_id']).removeprefix('CDC-')}: "
        f"{finding['message']}"
        for finding in lint_findings(text, path)
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--circuit", default="")
    parser.add_argument("rtl", nargs="+", type=Path)
    args = parser.parse_args()
    hits: list[str] = []
    for rtl in args.rtl:
        text = rtl.read_text(errors="replace")
        hits.extend(lint_text(text, str(rtl)))
    if hits:
        print("CDC LINT FAILED")
        for h in hits:
            print(f"  {h}")
        return 1
    print(f"CDC LINT OK ({', '.join(str(p) for p in args.rtl)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
