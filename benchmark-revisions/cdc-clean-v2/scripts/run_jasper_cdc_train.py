#!/usr/bin/env python3
"""Structural Jasper on the 37 audited training modules.

Clocks and input resets come from each module's structural.json.
This is a teacher check. It does not edit RTL and does not write a training prompt.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "training" / "cdc-external-v1"
TRAIN = ROOT / "training" / "cdc-lora-v1" / "train.jsonl"
OUT = ROOT / "build" / "jasper" / "cdc-train-v1"
JG = "/eda/cadence/JASPER/bin/jg"
MODULE_RE = re.compile(r"^\s*module\s+(\w+)", re.M)
ACTIVE_LOW = re.compile(r"(?:_n|rstn|resetn)$", re.I)


def modules_in(text: str) -> set[str]:
    return set(MODULE_RE.findall(text))


def stage_rtl(path: Path, directory: Path, work: Path) -> Path:
    """Copy RTL for Jasper. Training files stay unchanged.

    This Jasper build rejects `input logic` after `default_nettype none`.
    The staged copy removes only that directive.
    """
    staged = work / "rtl" / path.relative_to(directory)
    staged.parent.mkdir(parents=True, exist_ok=True)
    text = path.read_text(errors="replace")
    text = re.sub(r"(?m)^`default_nettype\s+none\s*$", "`default_nettype wire", text)
    staged.write_text(text)
    return staged


def rtl_and_incdirs(directory: Path, work: Path) -> tuple[list[Path], list[Path]]:
    source = directory / "source.sv"
    files = [stage_rtl(source, directory, work)]
    seen = modules_in(source.read_text(errors="replace"))
    deps = directory / "deps"
    extra_dirs = {files[0].parent}
    if deps.is_dir():
        for path in sorted(deps.rglob("*")):
            if not path.is_file():
                continue
            if path.suffix in {".svh", ".vh"}:
                staged = stage_rtl(path, directory, work)
                extra_dirs.add(staged.parent)
                continue
            if path.suffix not in {".sv", ".v"}:
                continue
            found = modules_in(path.read_text(errors="replace"))
            if found & seen:
                continue
            staged = stage_rtl(path, directory, work)
            files.append(staged)
            extra_dirs.add(staged.parent)
            seen |= found
    return files, sorted(extra_dirs)


def write_setup(name: str) -> Path:
    directory = DATA / name
    structural = json.loads((directory / "structural.json").read_text())
    ports = {item["name"]: item.get("direction") for item in structural.get("ports", [])}
    clocks = [clock for clock in structural.get("clocks", []) if ports.get(clock) == "input"]
    resets = [reset for reset in structural.get("resets", []) if ports.get(reset) == "input"]
    if not clocks:
        raise RuntimeError(f"{name} has no input clock in structural.json")
    work = OUT / name
    work.mkdir(parents=True, exist_ok=True)
    files, incdirs = rtl_and_incdirs(directory, work)
    sdc = work / "clocks.sdc"
    groups = ""
    if len(clocks) > 1:
        groups = "set_clock_groups -asynchronous \\\n" + " \\\n".join(
            f"    -group {{{clock}}}" for clock in clocks
        )
    sdc.write_text(
        "".join(f"create_clock -name {clock} -period 10.000 [get_ports {clock}]\n" for clock in clocks)
        + groups
        + "\n"
    )
    resets_tcl = "\n".join(
        f"config_rtlds -reset -async {reset} -polarity {'low' if ACTIVE_LOW.search(reset) else 'high'}"
        for reset in resets
    )
    incdir = " ".join(f"+incdir+{path}" for path in incdirs)
    file_list = " \\\n    ".join(str(path) for path in files)
    tcl = work / "run.tcl"
    tcl.write_text(f"""set RPT_DIR {work}
file mkdir $RPT_DIR
clear -all
analyze -sv12 {incdir} \\
    {file_list}
elaborate -top {name}
read_sdc {sdc}
check_cdc -init
{chr(10).join(f"clock {clock}" for clock in clocks)}
{resets_tcl}
check_cdc -extract
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\\[cdc_train\\] {name} done"
""")
    return tcl


def main() -> None:
    names = [json.loads(line)["module"] for line in TRAIN.read_text().splitlines() if line.strip()]
    env = os.environ.copy()
    env["PATH"] = "/eda/cadence/JASPER/bin:" + env.get("PATH", "")
    summary = []
    for index, name in enumerate(names, start=1):
        tcl = write_setup(name)
        log = OUT / name / "jasper.log"
        print(f"{index}/{len(names)} {name}", flush=True)
        work = OUT / name
        completed = subprocess.run(
            [JG, "-batch", "-proj", str(work / "jgproject"), str(tcl)],
            cwd=work,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=180,
        )
        log.write_text(completed.stdout)
        report = OUT / name / "cdc_report.rpt"
        summary.append({
            "module": name,
            "returncode": completed.returncode,
            "report": report.is_file(),
            "log_tail": "\n".join(completed.stdout.splitlines()[-8:]),
        })
        (OUT / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print("JASPER_TRAIN_DONE", len(summary), flush=True)


if __name__ == "__main__":
    main()
