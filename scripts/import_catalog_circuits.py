#!/usr/bin/env python3
"""Snapshot leftover CDC catalog circuits into benchmarks/."""

from __future__ import annotations

import shutil
from pathlib import Path

ROOT = Path("/home/ft2335/dataset")
CACHE = ROOT / ".cache" / "upstream"
VENDOR = ROOT / "vendor" / "common_cells"
BENCH = ROOT / "benchmarks"

PULP_SHA = "b5ec890"
APB_SHA = "4821618"
TWEAK_SHA = "9d5650d"
FIFO_SV_SHA = "fa4d3d4"
AXIS_SHA = "48ff7a7"
UART_SHA = "2b0ad80"
I2C_SHA = "a65be40"
SPI_SHA = "d2f141a"
AXI_SHA = "516bd5d"
ZIP_SHA = "2e8d3bc"


def copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def manifest(cfg: dict) -> str:
    rtl = "\n".join(f"  - original/rtl/{name}" for name in cfg["rtl_names"])
    fixed = "\n".join(f"  - fixed/rtl/{name}" for name in cfg["rtl_names"])
    clocks = "\n".join(f"  - {c}" for c in cfg["clocks"])
    resets = "\n".join(f"  - {r}" for r in cfg["resets"])
    return f"""schema_version: 1
id: {cfg["id"]}
top_module: {cfg["top"]}
source_family: {cfg["source_family"]}
upstream: {cfg["upstream"]}
upstream_commit: {cfg["upstream_commit"]}
hdl: {cfg["hdl"]}
status: imported_unverified
specification_status: draft
clocks:
{clocks}
resets:
{resets}
rtl_original:
{rtl}
rtl_fixed:
{fixed}
constraints: constraints/{cfg["id"]}.sdc
testbench: tb/{cfg["tb_file"]}
testbench_top: {cfg["tb_top"]}
simulation: sim/run.sh
note: >
  Imported from the open-source catalog with the upstream testbench where one
  exists. fixed/rtl is currently an unmodified snapshot. This circuit is not
  part of the Jasper-verified 11-circuit pilot.
"""


def specification(cfg: dict) -> str:
    return f"""# {cfg["id"]} generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
{cfg["objective"]}

## Required interface and behavior
- Implement a synthesizable `{cfg["top"]}` module compatible with the supplied testbench.
- Preserve the catalog reference behavior from `{cfg["upstream"]}`.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled and simulated with the supplied testbench.
JasperGold CDC/RDC analysis is not yet frozen for this imported circuit.
"""


def sdc(cfg: dict) -> str:
    clocks = cfg["clocks"]
    lines = [
        f"# Imported constraints for {cfg['id']}. Periods are illustrative.",
    ]
    if not clocks:
        return "\n".join(lines) + "\n"
    for i, clk in enumerate(clocks):
        period = 10.000 + i * 4.000
        lines.append(f"create_clock -name {clk} -period {period:.3f} [get_ports {clk}]")
    if len(clocks) > 1:
        groups = " \\\n    ".join(f"-group {{{c}}}" for c in clocks)
        lines.append("set_clock_groups -asynchronous \\")
        lines.append(f"    {groups}")
    return "\n".join(lines) + "\n"


def sim_script(cfg: dict) -> str:
    rtl_args = " \\\n  ".join(f'"$BENCH/fixed/rtl/{name}"' for name in cfg["rtl_names"])
    tb_args = " \\\n  ".join(f'"$BENCH/tb/{name}"' for name in cfg["tb_sim_files"])
    inc = ""
    if cfg.get("incdirs"):
        inc = "".join(f'\n  -incdir "{d}" \\' for d in cfg["incdirs"])
    extra = ""
    if cfg.get("xrun_extra"):
        extra = "".join(f"\n  {arg} \\" for arg in cfg["xrun_extra"])
    return f"""#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${{BASH_SOURCE[0]}}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/{cfg["id"]}"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${{COMPILE_ONLY:-0}}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${{XRUN_MODE[@]}}" -64bit -sv -timescale 1ns/1ps -top {cfg["tb_top"]} \\{inc}{extra}
  -xmlibdirname "$ROOT/build/sim/{cfg["id"]}" \\
  {rtl_args} \\
  {tb_args}
"""


def pass_fail_tb(name: str, body: str, timeout_ns: int = 20000) -> str:
    return f"""`timescale 1ns/1ps

module {name};
    integer errors = 0;
{body}
    initial begin
        #{timeout_ns};
        $display("{name.upper()}: TIMEOUT");
        $finish;
    end
endmodule
"""


def circuits() -> list[dict]:
    pulp_sync = VENDOR / "src" / "sync.sv"
    return [
        {
            "id": "sync",
            "top": "sync",
            "source_family": "pulp-platform",
            "upstream": "https://github.com/pulp-platform/common_cells",
            "upstream_commit": PULP_SHA,
            "hdl": "systemverilog",
            "clocks": ["clk_i"],
            "resets": ["rst_ni"],
            "objective": "Single-bit 2-flop level synchronizer.",
            "copies": [(pulp_sync, "sync.sv")],
            "rtl_names": ["sync.sv"],
            "tb_file": "sync_tb.v",
            "tb_top": "sync_tb",
            "tb_sim_files": ["sync_tb.v"],
            "tb": pass_fail_tb(
                "sync_tb",
                """
    reg clk_i = 0, rst_ni = 0, serial_i = 0;
    wire serial_o;
    always #5 clk_i = ~clk_i;

    sync #(.STAGES(2)) dut (
        .clk_i(clk_i), .rst_ni(rst_ni), .serial_i(serial_i), .serial_o(serial_o)
    );

    initial begin
        repeat (3) @(posedge clk_i);
        rst_ni = 1;
        serial_i = 1;
        repeat (3) @(posedge clk_i);
        if (serial_o !== 1'b1) begin
            $display("FAIL 2-FF did not propagate 1");
            errors = errors + 1;
        end
        serial_i = 0;
        repeat (3) @(posedge clk_i);
        if (serial_o !== 1'b0) begin
            $display("FAIL 2-FF did not propagate 0");
            errors = errors + 1;
        end
        if (errors == 0) $display("SYNC: ALL TESTS PASSED");
        else $display("SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
            ),
        },
        {
            "id": "sync_multistage",
            "top": "sync",
            "source_family": "pulp-platform",
            "upstream": "https://github.com/pulp-platform/common_cells",
            "upstream_commit": PULP_SHA,
            "hdl": "systemverilog",
            "clocks": ["clk_i"],
            "resets": ["rst_ni"],
            "objective": "Single-bit multi-stage level synchronizer (STAGES=4).",
            "copies": [(pulp_sync, "sync.sv")],
            "rtl_names": ["sync.sv"],
            "tb_file": "sync_multistage_tb.v",
            "tb_top": "sync_multistage_tb",
            "tb_sim_files": ["sync_multistage_tb.v"],
            "tb": pass_fail_tb(
                "sync_multistage_tb",
                """
    reg clk_i = 0, rst_ni = 0, serial_i = 0;
    wire serial_o;
    always #5 clk_i = ~clk_i;

    sync #(.STAGES(4)) dut (
        .clk_i(clk_i), .rst_ni(rst_ni), .serial_i(serial_i), .serial_o(serial_o)
    );

    initial begin
        repeat (3) @(posedge clk_i);
        rst_ni = 1;
        @(posedge clk_i);
        serial_i = 1;
        @(posedge clk_i);
        if (serial_o !== 1'b0) begin
            $display("FAIL output changed too early");
            errors = errors + 1;
        end
        repeat (4) @(posedge clk_i);
        if (serial_o !== 1'b1) begin
            $display("FAIL 4-stage did not propagate 1");
            errors = errors + 1;
        end
        if (errors == 0) $display("SYNC MULTISTAGE: ALL TESTS PASSED");
        else $display("SYNC MULTISTAGE: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
            ),
        },
        {
            "id": "edge_propagator",
            "top": "edge_propagator",
            "source_family": "pulp-platform",
            "upstream": "https://github.com/pulp-platform/common_cells",
            "upstream_commit": PULP_SHA,
            "hdl": "systemverilog",
            "clocks": ["clk_tx_i", "clk_rx_i"],
            "resets": ["rstn_tx_i", "rstn_rx_i"],
            "objective": "Pulse/edge propagator across asynchronous clocks.",
            "copies": [
                (VENDOR / "src" / "edge_propagator.sv", "edge_propagator.sv"),
                (VENDOR / "src" / "edge_propagator_ack.sv", "edge_propagator_ack.sv"),
                (VENDOR / "src" / "deprecated" / "pulp_sync_wedge.sv", "pulp_sync_wedge.sv"),
                (VENDOR / "src" / "deprecated" / "pulp_sync.sv", "pulp_sync.sv"),
            ],
            "rtl_names": [
                "edge_propagator.sv",
                "edge_propagator_ack.sv",
                "pulp_sync_wedge.sv",
                "pulp_sync.sv",
            ],
            "tb_file": "edge_propagator_tb.v",
            "tb_top": "edge_propagator_tb",
            "tb_sim_files": ["edge_propagator_tb.v", "pulp_clock_gating.sv"],
            "extra_tb_files": {
                "pulp_clock_gating.sv": """// Simulation model for the PULP clock-gating cell.
module pulp_clock_gating (
    input  logic clk_i,
    input  logic en_i,
    input  logic test_en_i,
    output logic clk_o
);
    assign clk_o = clk_i & (en_i | test_en_i);
endmodule
"""
            },
            "tb": pass_fail_tb(
                "edge_propagator_tb",
                """
    reg clk_tx_i = 0, clk_rx_i = 0;
    reg rstn_tx_i = 0, rstn_rx_i = 0, edge_i = 0;
    wire edge_o;
    integer seen = 0;
    always #5 clk_tx_i = ~clk_tx_i;
    always #7 clk_rx_i = ~clk_rx_i;

    edge_propagator dut (
        .clk_tx_i(clk_tx_i), .rstn_tx_i(rstn_tx_i), .edge_i(edge_i),
        .clk_rx_i(clk_rx_i), .rstn_rx_i(rstn_rx_i), .edge_o(edge_o)
    );

    always @(posedge clk_rx_i) if (rstn_rx_i && edge_o) seen = seen + 1;

    initial begin
        repeat (4) @(posedge clk_tx_i);
        rstn_tx_i = 1;
        repeat (4) @(posedge clk_rx_i);
        rstn_rx_i = 1;
        @(negedge clk_tx_i); edge_i = 1;
        @(negedge clk_tx_i); edge_i = 0;
        repeat (20) @(posedge clk_rx_i);
        if (seen == 0) begin
            $display("FAIL no pulse crossed");
            errors = errors + 1;
        end
        if (errors == 0) $display("EDGE PROPAGATOR: ALL TESTS PASSED");
        else $display("EDGE PROPAGATOR: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
            ),
        },
        {
            "id": "rstgen",
            "top": "rstgen",
            "source_family": "pulp-platform",
            "upstream": "https://github.com/pulp-platform/common_cells",
            "upstream_commit": PULP_SHA,
            "hdl": "systemverilog",
            "clocks": ["clk_i"],
            "resets": ["rst_ni"],
            "objective": "Reset release synchronizer with test-mode bypass.",
            "copies": [
                (VENDOR / "src" / "rstgen.sv", "rstgen.sv"),
                (VENDOR / "src" / "rstgen_bypass.sv", "rstgen_bypass.sv"),
            ],
            "rtl_names": ["rstgen.sv", "rstgen_bypass.sv"],
            "tb_file": "rstgen_tb.v",
            "tb_top": "rstgen_tb",
            "tb_sim_files": ["rstgen_tb.v"],
            "tb": pass_fail_tb(
                "rstgen_tb",
                """
    reg clk_i = 0, rst_ni = 0, test_mode_i = 0;
    wire rst_no, init_no;
    always #5 clk_i = ~clk_i;

    rstgen dut (
        .clk_i(clk_i), .rst_ni(rst_ni), .test_mode_i(test_mode_i),
        .rst_no(rst_no), .init_no(init_no)
    );

    initial begin
        repeat (2) @(posedge clk_i);
        if (rst_no !== 1'b0) begin
            $display("FAIL reset not asserted");
            errors = errors + 1;
        end
        repeat (3) @(posedge clk_i);
        rst_ni = 1;
        @(posedge clk_i);
        if (rst_no !== 1'b0) begin
            $display("FAIL released too early");
            errors = errors + 1;
        end
        repeat (5) @(posedge clk_i);
        if (rst_no !== 1'b1 || init_no !== 1'b1) begin
            $display("FAIL reset did not release");
            errors = errors + 1;
        end
        if (errors == 0) $display("RSTGEN: ALL TESTS PASSED");
        else $display("RSTGEN: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
            ),
        },
        {
            "id": "pulse_sync",
            "top": "pulse_sync",
            "source_family": "tweak_circuits",
            "upstream": "https://github.com/iammituraj/tweak_circuits",
            "upstream_commit": TWEAK_SHA,
            "hdl": "vhdl",
            "clocks": ["clk_a", "clk_b"],
            "resets": ["rstn_a", "rstn_b"],
            "objective": "Handshake-based pulse/toggle synchronizer for fast-to-slow events.",
            "copies": [(CACHE / "tweak_circuits" / "src" / "pulse_sync.vhd", "pulse_sync.vhd")],
            "rtl_names": ["pulse_sync.vhd"],
            "tb_file": "pulse_sync_tb.v",
            "tb_top": "pulse_sync_tb",
            "tb_sim_files": ["pulse_sync_tb.v"],
            "xrun_extra": ["-v93"],
            "tb": pass_fail_tb(
                "pulse_sync_tb",
                """
    reg clk_a = 0, clk_b = 0, rstn_a = 0, rstn_b = 0, pulseA_i = 0;
    wire pulseB_o, busy_o;
    integer seen = 0;
    always #5 clk_a = ~clk_a;
    always #11 clk_b = ~clk_b;

    pulse_sync #(.STAGES(2)) dut (
        .clk_a(clk_a), .rstn_a(rstn_a), .clk_b(clk_b), .rstn_b(rstn_b),
        .pulseA_i(pulseA_i), .pulseB_o(pulseB_o), .busy_o(busy_o)
    );

    always @(posedge clk_b) if (rstn_b && pulseB_o) seen = seen + 1;

    initial begin
        repeat (4) @(posedge clk_a); rstn_a = 1;
        repeat (4) @(posedge clk_b); rstn_b = 1;
        @(negedge clk_a); pulseA_i = 1;
        @(negedge clk_a); pulseA_i = 0;
        repeat (30) @(posedge clk_b);
        if (seen == 0) begin
            $display("FAIL no toggled pulse crossed");
            errors = errors + 1;
        end
        if (errors == 0) $display("PULSE SYNC: ALL TESTS PASSED");
        else $display("PULSE SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
            ),
        },
        {
            "id": "areset_sync",
            "top": "areset_sync",
            "source_family": "tweak_circuits",
            "upstream": "https://github.com/iammituraj/tweak_circuits",
            "upstream_commit": TWEAK_SHA,
            "hdl": "vhdl",
            "clocks": ["clk"],
            "resets": ["async_rst_i"],
            "objective": "Asynchronous reset synchronizer.",
            "copies": [(CACHE / "tweak_circuits" / "src" / "areset_sync.vhd", "areset_sync.vhd")],
            "rtl_names": ["areset_sync.vhd"],
            "tb_file": "areset_sync_tb.v",
            "tb_top": "areset_sync_tb",
            "tb_sim_files": ["areset_sync_tb.v"],
            "xrun_extra": ["-v93"],
            "tb": pass_fail_tb(
                "areset_sync_tb",
                """
    reg clk = 0, async_rst_i = 1;
    wire sync_rst_o;
    always #5 clk = ~clk;

    areset_sync #(.STAGES(2)) dut (
        .clk(clk), .async_rst_i(async_rst_i), .sync_rst_o(sync_rst_o)
    );

    initial begin
        repeat (4) @(posedge clk);
        if (sync_rst_o !== 1'b1) begin
            $display("FAIL reset not synchronized high");
            errors = errors + 1;
        end
        async_rst_i = 0;
        repeat (3) @(posedge clk);
        if (sync_rst_o !== 1'b0) begin
            $display("FAIL reset did not release");
            errors = errors + 1;
        end
        if (errors == 0) $display("ARESET SYNC: ALL TESTS PASSED");
        else $display("ARESET SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
            ),
        },
        {
            "id": "async_fifo_sv",
            "top": "async_fifo",
            "source_family": "dianluniuniu",
            "upstream": "https://github.com/dianluniuniu/async-fifo",
            "upstream_commit": FIFO_SV_SHA,
            "hdl": "systemverilog",
            "clocks": ["wclk", "rclk"],
            "resets": ["wrst_n", "rrst_n"],
            "objective": "SystemVerilog Gray-coded asynchronous FIFO.",
            "copies": [
                (CACHE / "async-fifo" / "rtl" / "async_fifo.sv", "async_fifo.sv"),
                (CACHE / "async-fifo" / "rtl" / "fifomem.sv", "fifomem.sv"),
                (CACHE / "async-fifo" / "rtl" / "rptr_empty.sv", "rptr_empty.sv"),
                (CACHE / "async-fifo" / "rtl" / "wptr_full.sv", "wptr_full.sv"),
                (CACHE / "async-fifo" / "rtl" / "sync_r2w.sv", "sync_r2w.sv"),
                (CACHE / "async-fifo" / "rtl" / "sync_w2r.sv", "sync_w2r.sv"),
            ],
            "upstream_tb": [
                (CACHE / "async-fifo" / "sim" / "async_fifo_tb.sv", "upstream/async_fifo_tb.sv")
            ],
            "rtl_names": [
                "async_fifo.sv",
                "fifomem.sv",
                "rptr_empty.sv",
                "wptr_full.sv",
                "sync_r2w.sv",
                "sync_w2r.sv",
            ],
            "tb_file": "async_fifo_sv_tb.v",
            "tb_top": "async_fifo_sv_tb",
            "tb_sim_files": ["async_fifo_sv_tb.v"],
            "tb": pass_fail_tb(
                "async_fifo_sv_tb",
                """
    reg wclk = 0, rclk = 0, wrst_n = 0, rrst_n = 0, winc = 0, rinc = 0;
    reg [7:0] wdata = 0;
    wire [7:0] rdata;
    wire wfull, rempty;
    wire [4:0] waddr, raddr;
    integer received = 0;
    always #5 wclk = ~wclk;
    always #9 rclk = ~rclk;

    async_fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) dut (
        .wclk(wclk), .wrst_n(wrst_n), .winc(winc), .wdata(wdata),
        .wfull(wfull), .waddr(waddr),
        .rclk(rclk), .rrst_n(rrst_n), .rinc(rinc), .rdata(rdata),
        .rempty(rempty), .raddr(raddr)
    );

    integer i;
    initial begin
        repeat (4) @(posedge wclk); wrst_n = 1;
        repeat (4) @(posedge rclk); rrst_n = 1;
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge wclk);
            while (wfull) @(negedge wclk);
            wdata = i[7:0];
            winc = 1;
            @(posedge wclk);
            @(negedge wclk);
            winc = 0;
        end
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge rclk);
            while (rempty) @(negedge rclk);
            rinc = 1;
            @(posedge rclk);
            if (rdata !== i[7:0]) begin
                $display("FAIL item=%0d got=%h", i, rdata);
                errors = errors + 1;
            end
            received = received + 1;
            @(negedge rclk);
            rinc = 0;
        end
        if (errors == 0) $display("ASYNC FIFO SV: ALL TESTS PASSED");
        else $display("ASYNC FIFO SV: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
                40000,
            ),
        },
    ]


AXIS_REGISTER_TB = pass_fail_tb(
    "axis_register_tb",
    """
    reg clk = 0, rst = 1;
    reg [7:0] s_data = 0;
    reg s_valid = 0, s_last = 0;
    wire s_ready;
    wire [7:0] m_data;
    wire m_valid, m_last;
    reg m_ready = 0;
    integer received = 0;
    always #5 clk = ~clk;

    axis_register #(
        .DATA_WIDTH(8), .KEEP_ENABLE(0), .LAST_ENABLE(1),
        .ID_ENABLE(0), .DEST_ENABLE(0), .USER_ENABLE(0), .REG_TYPE(2)
    ) dut (
        .clk(clk), .rst(rst),
        .s_axis_tdata(s_data), .s_axis_tkeep(1'b1), .s_axis_tvalid(s_valid),
        .s_axis_tready(s_ready), .s_axis_tlast(s_last),
        .s_axis_tid(8'b0), .s_axis_tdest(8'b0), .s_axis_tuser(1'b0),
        .m_axis_tdata(m_data), .m_axis_tkeep(), .m_axis_tvalid(m_valid),
        .m_axis_tready(m_ready), .m_axis_tlast(m_last),
        .m_axis_tid(), .m_axis_tdest(), .m_axis_tuser()
    );

    integer i;
    initial begin
        repeat (4) @(posedge clk); rst = 0; m_ready = 1;
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge clk);
            s_data = i[7:0];
            s_last = (i == 7);
            s_valid = 1;
            @(posedge clk);
            while (!s_ready) @(posedge clk);
            @(negedge clk);
            s_valid = 0; s_last = 0;
        end
        wait (received == 8);
        if (errors == 0) $display("AXIS REGISTER: ALL TESTS PASSED");
        else $display("AXIS REGISTER: TESTS FAILED (%0d)", errors);
        $finish;
    end

    always @(posedge clk) begin
        if (!rst && m_valid && m_ready) begin
            if (m_data !== received[7:0]) begin
                $display("FAIL beat=%0d got=%h", received, m_data);
                errors = errors + 1;
            end
            received = received + 1;
        end
    end
""",
)


def axis_stream_circuits() -> list[dict]:
    axis = CACHE / "verilog-axis"
    return [
        {
            "id": "axis_register",
            "top": "axis_register",
            "source_family": "verilog-axis",
            "upstream": "https://github.com/alexforencich/verilog-axis",
            "upstream_commit": AXIS_SHA,
            "hdl": "verilog-2001",
            "clocks": ["clk"],
            "resets": ["rst"],
            "objective": "AXI-Stream skid buffer / register slice.",
            "copies": [(axis / "rtl" / "axis_register.v", "axis_register.v")],
            "upstream_tb": [
                (axis / "tb" / "test_axis_register.v", "upstream/test_axis_register.v"),
                (axis / "tb" / "axis_register" / "test_axis_register.py", "upstream/test_axis_register.py"),
            ],
            "rtl_names": ["axis_register.v"],
            "tb_file": "axis_register_tb.v",
            "tb_top": "axis_register_tb",
            "tb_sim_files": ["axis_register_tb.v"],
            "tb": AXIS_REGISTER_TB,
        },
        {
            "id": "axis_fifo",
            "top": "axis_fifo",
            "source_family": "verilog-axis",
            "upstream": "https://github.com/alexforencich/verilog-axis",
            "upstream_commit": AXIS_SHA,
            "hdl": "verilog-2001",
            "clocks": ["clk"],
            "resets": ["rst"],
            "objective": "AXI-Stream elastic buffer / synchronous FIFO.",
            "copies": [(axis / "rtl" / "axis_fifo.v", "axis_fifo.v")],
            "upstream_tb": [
                (axis / "tb" / "test_axis_fifo.v", "upstream/test_axis_fifo.v"),
                (axis / "tb" / "axis_fifo" / "test_axis_fifo.py", "upstream/test_axis_fifo.py"),
            ],
            "rtl_names": ["axis_fifo.v"],
            "tb_file": "axis_fifo_tb.v",
            "tb_top": "axis_fifo_tb",
            "tb_sim_files": ["axis_fifo_tb.v"],
            "tb": AXIS_REGISTER_TB.replace("axis_register_tb", "axis_fifo_tb")
            .replace("axis_register #(", "axis_fifo #(.DEPTH(16),")
            .replace(".REG_TYPE(2)", ".USER_ENABLE(0)")
            # avoid duplicating USER_ENABLE if the template already has it
            .replace(
                """        .m_axis_tid(), .m_axis_tdest(), .m_axis_tuser()
    );""",
                """        .m_axis_tid(), .m_axis_tdest(), .m_axis_tuser(),
        .pause_req(1'b0), .pause_ack(),
        .status_depth(), .status_depth_commit(),
        .status_overflow(), .status_bad_frame(), .status_good_frame()
    );""",
            )
            .replace("AXIS REGISTER", "AXIS FIFO"),
        },
        {
            "id": "axis_adapter",
            "top": "axis_adapter",
            "source_family": "verilog-axis",
            "upstream": "https://github.com/alexforencich/verilog-axis",
            "upstream_commit": AXIS_SHA,
            "hdl": "verilog-2001",
            "clocks": ["clk"],
            "resets": ["rst"],
            "objective": "AXI-Stream width adapter.",
            "copies": [(axis / "rtl" / "axis_adapter.v", "axis_adapter.v")],
            "upstream_tb": [
                (axis / "tb" / "test_axis_adapter_8_64.v", "upstream/test_axis_adapter_8_64.v"),
                (axis / "tb" / "test_axis_adapter_8_64.py", "upstream/test_axis_adapter_8_64.py"),
            ],
            "rtl_names": ["axis_adapter.v"],
            "tb_file": "axis_adapter_tb.v",
            "tb_top": "axis_adapter_tb",
            "tb_sim_files": ["axis_adapter_tb.v"],
            "tb": pass_fail_tb(
                "axis_adapter_tb",
                """
    reg clk = 0, rst = 1;
    reg [7:0] s_data = 0;
    reg s_valid = 0, s_last = 0;
    wire s_ready;
    wire [31:0] m_data;
    wire [3:0] m_keep;
    wire m_valid, m_last;
    reg m_ready = 0;
    integer received = 0;
    always #5 clk = ~clk;

    axis_adapter #(
        .S_DATA_WIDTH(8), .S_KEEP_ENABLE(0),
        .M_DATA_WIDTH(32), .M_KEEP_ENABLE(1),
        .ID_ENABLE(0), .DEST_ENABLE(0), .USER_ENABLE(0)
    ) dut (
        .clk(clk), .rst(rst),
        .s_axis_tdata(s_data), .s_axis_tkeep(1'b1), .s_axis_tvalid(s_valid),
        .s_axis_tready(s_ready), .s_axis_tlast(s_last),
        .s_axis_tid(8'b0), .s_axis_tdest(8'b0), .s_axis_tuser(1'b0),
        .m_axis_tdata(m_data), .m_axis_tkeep(m_keep), .m_axis_tvalid(m_valid),
        .m_axis_tready(m_ready), .m_axis_tlast(m_last),
        .m_axis_tid(), .m_axis_tdest(), .m_axis_tuser()
    );

    integer i;
    initial begin
        repeat (4) @(posedge clk); rst = 0; m_ready = 1;
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge clk);
            s_data = 8'h10 + i[7:0];
            s_last = ((i % 4) == 3);
            s_valid = 1;
            @(posedge clk);
            while (!s_ready) @(posedge clk);
            @(negedge clk);
            s_valid = 0; s_last = 0;
        end
        wait (received == 2);
        if (errors == 0) $display("AXIS ADAPTER: ALL TESTS PASSED");
        else $display("AXIS ADAPTER: TESTS FAILED (%0d)", errors);
        $finish;
    end

    always @(posedge clk) begin
        if (!rst && m_valid && m_ready) begin
            received = received + 1;
            if (!m_last) begin
                $display("FAIL expected tlast on packed word");
                errors = errors + 1;
            end
        end
    end
""",
            ),
        },
        {
            "id": "arbiter",
            "top": "arbiter",
            "source_family": "verilog-axis",
            "upstream": "https://github.com/alexforencich/verilog-axis",
            "upstream_commit": AXIS_SHA,
            "hdl": "verilog-2001",
            "clocks": ["clk"],
            "resets": ["rst"],
            "objective": "Round-robin arbiter.",
            "copies": [
                (axis / "rtl" / "arbiter.v", "arbiter.v"),
                (axis / "rtl" / "priority_encoder.v", "priority_encoder.v"),
            ],
            "upstream_tb": [
                (axis / "tb" / "test_arbiter_rr.v", "upstream/test_arbiter_rr.v"),
                (axis / "tb" / "test_arbiter_rr.py", "upstream/test_arbiter_rr.py"),
            ],
            "rtl_names": ["arbiter.v", "priority_encoder.v"],
            "tb_file": "arbiter_tb.v",
            "tb_top": "arbiter_tb",
            "tb_sim_files": ["arbiter_tb.v"],
            "tb": pass_fail_tb(
                "arbiter_tb",
                """
    reg clk = 0, rst = 1;
    reg [3:0] request = 0, acknowledge = 0;
    wire [3:0] grant;
    wire grant_valid;
    wire [1:0] grant_encoded;
    always #5 clk = ~clk;

    arbiter #(
        .PORTS(4), .ARB_TYPE_ROUND_ROBIN(1), .ARB_BLOCK(0)
    ) dut (
        .clk(clk), .rst(rst),
        .request(request), .acknowledge(acknowledge),
        .grant(grant), .grant_valid(grant_valid), .grant_encoded(grant_encoded)
    );

    initial begin
        repeat (3) @(posedge clk); rst = 0;
        request = 4'b1010;
        @(posedge clk);
        @(posedge clk);
        if (!grant_valid || grant == 4'b0000) begin
            $display("FAIL no grant");
            errors = errors + 1;
        end
        request = 4'b0000;
        @(posedge clk);
        if (errors == 0) $display("ARBITER: ALL TESTS PASSED");
        else $display("ARBITER: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
            ),
        },
        {
            "id": "axis_switch",
            "top": "axis_switch",
            "source_family": "verilog-axis",
            "upstream": "https://github.com/alexforencich/verilog-axis",
            "upstream_commit": AXIS_SHA,
            "hdl": "verilog-2001",
            "clocks": ["clk"],
            "resets": ["rst"],
            "objective": "AXI-Stream packet router / switch.",
            "copies": [
                (axis / "rtl" / "axis_switch.v", "axis_switch.v"),
                (axis / "rtl" / "axis_register.v", "axis_register.v"),
                (axis / "rtl" / "arbiter.v", "arbiter.v"),
                (axis / "rtl" / "priority_encoder.v", "priority_encoder.v"),
            ],
            "upstream_tb": [
                (axis / "tb" / "test_axis_switch_4x4.v", "upstream/test_axis_switch_4x4.v"),
                (axis / "tb" / "axis_switch" / "test_axis_switch.py", "upstream/test_axis_switch.py"),
            ],
            "rtl_names": [
                "axis_switch.v",
                "axis_register.v",
                "arbiter.v",
                "priority_encoder.v",
            ],
            "tb_file": "axis_switch_tb.v",
            "tb_top": "axis_switch_tb",
            "tb_sim_files": ["axis_switch_tb.v"],
            "tb": pass_fail_tb(
                "axis_switch_tb",
                """
    reg clk = 0, rst = 1;
    reg [7:0] s_data = 0;
    reg s_valid = 0, s_last = 0;
    reg [1:0] s_dest = 0;
    wire [1:0] s_ready;
    wire [15:0] m_data;
    wire [1:0] m_valid, m_last;
    reg [1:0] m_ready = 2'b11;
    integer got1 = 0;
    always #5 clk = ~clk;

    axis_switch #(
        .S_COUNT(2), .M_COUNT(2), .DATA_WIDTH(8),
        .KEEP_ENABLE(0), .ID_ENABLE(0), .USER_ENABLE(0),
        .M_DEST_WIDTH(1), .S_DEST_WIDTH(1),
        .S_REG_TYPE(0), .M_REG_TYPE(0)
    ) dut (
        .clk(clk), .rst(rst),
        .s_axis_tdata({8'h00, s_data}), .s_axis_tkeep(2'b11),
        .s_axis_tvalid({1'b0, s_valid}), .s_axis_tready(s_ready),
        .s_axis_tlast({1'b0, s_last}), .s_axis_tid(16'b0),
        .s_axis_tdest({1'b0, s_dest[0]}), .s_axis_tuser(2'b0),
        .m_axis_tdata(m_data), .m_axis_tkeep(), .m_axis_tvalid(m_valid),
        .m_axis_tready(m_ready), .m_axis_tlast(m_last),
        .m_axis_tid(), .m_axis_tdest(), .m_axis_tuser()
    );

    initial begin
        repeat (4) @(posedge clk); rst = 0;
        @(negedge clk);
        s_data = 8'hA5; s_dest = 2'd1; s_last = 1; s_valid = 1;
        @(posedge clk);
        while (!s_ready[0]) @(posedge clk);
        @(negedge clk);
        s_valid = 0; s_last = 0;
        repeat (20) @(posedge clk);
        if (!got1) begin
            $display("FAIL packet did not reach port 1");
            errors = errors + 1;
        end
        if (errors == 0) $display("AXIS SWITCH: ALL TESTS PASSED");
        else $display("AXIS SWITCH: TESTS FAILED (%0d)", errors);
        $finish;
    end

    always @(posedge clk)
        if (!rst && m_valid[1] && m_ready[1] && m_data[15:8] === 8'hA5)
            got1 = 1;
""",
            ),
        },
    ]


def remaining_circuits() -> list[dict]:
    apb = CACHE / "apb"
    uart = CACHE / "uart16550"
    i2c = CACHE / "verilog-i2c"
    spi = CACHE / "spi_master_slave"
    axi = CACHE / "verilog-axi"
    zipc = CACHE / "wb2axip"
    uart_rtl = list((uart / "rtl" / "verilog").glob("*.v"))
    uart_tb = list((uart / "bench" / "verilog").rglob("*"))
    return [
        {
            "id": "apb_regs",
            "top": "apb_regs",
            "source_family": "pulp-platform",
            "upstream": "https://github.com/pulp-platform/apb",
            "upstream_commit": APB_SHA,
            "hdl": "systemverilog",
            "clocks": ["pclk_i"],
            "resets": ["preset_ni"],
            "objective": "PULP APB register block.",
            "copies": [
                (apb / "src" / "apb_regs.sv", "apb_regs.sv"),
                (apb / "src" / "apb_pkg.sv", "apb_pkg.sv"),
                (apb / "src" / "apb_intf.sv", "apb_intf.sv"),
                (apb / "include" / "apb" / "typedef.svh", "include/apb/typedef.svh"),
                (apb / "include" / "apb" / "assign.svh", "include/apb/assign.svh"),
                (VENDOR / "src" / "addr_decode.sv", "addr_decode.sv"),
                (VENDOR / "src" / "cf_math_pkg.sv", "cf_math_pkg.sv"),
            ],
            "upstream_tb": [
                (apb / "test" / "tb_apb_regs.sv", "upstream/tb_apb_regs.sv"),
                (apb / "src" / "apb_test.sv", "upstream/apb_test.sv"),
            ],
            "rtl_names": [
                "cf_math_pkg.sv",
                "apb_pkg.sv",
                "apb_intf.sv",
                "addr_decode.sv",
                "apb_regs.sv",
            ],
            "incdirs": [
                "$BENCH/fixed/rtl/include",
                "$ROOT/vendor/common_cells/include",
            ],
            "tb_file": "apb_regs_tb.sv",
            "tb_top": "apb_regs_tb",
            "tb_sim_files": ["apb_regs_tb.sv"],
            "tb": """`timescale 1ns/1ps
`include "apb/typedef.svh"

module apb_regs_tb;
    typedef logic [31:0] addr_t;
    typedef logic [31:0] data_t;
    typedef logic [3:0]  strb_t;
    `APB_TYPEDEF_REQ_T(apb_req_t, addr_t, data_t, strb_t)
    `APB_TYPEDEF_RESP_T(apb_resp_t, data_t)

    logic clk = 0, rst_n = 0;
    apb_req_t req;
    apb_resp_t resp;
    logic [1:0][15:0] regs;
    integer errors = 0;
    always #5 clk = ~clk;

    apb_regs #(
        .NoApbRegs(2), .ApbAddrWidth(32), .AddrOffset(4),
        .ApbDataWidth(32), .RegDataWidth(16), .ReadOnly(2'b00),
        .req_t(apb_req_t), .resp_t(apb_resp_t)
    ) dut (
        .pclk_i(clk), .preset_ni(rst_n), .req_i(req), .resp_o(resp),
        .base_addr_i(32'h0000_0000),
        .reg_init_i({16'h0000, 16'h0000}),
        .reg_q_o(regs)
    );

    task automatic apb_write(input addr_t addr, input data_t data);
        req = '{paddr: addr, pprot: 3'b000, psel: 1'b1, penable: 1'b0,
                pwrite: 1'b1, pwdata: data, pstrb: 4'hF};
        @(posedge clk);
        req.penable = 1'b1;
        @(posedge clk);
        while (!resp.pready) @(posedge clk);
        req = '0;
    endtask

    task automatic apb_read(input addr_t addr, output data_t data);
        req = '{paddr: addr, pprot: 3'b000, psel: 1'b1, penable: 1'b0,
                pwrite: 1'b0, pwdata: '0, pstrb: 4'h0};
        @(posedge clk);
        req.penable = 1'b1;
        @(posedge clk);
        while (!resp.pready) @(posedge clk);
        data = resp.prdata;
        req = '0;
    endtask

    data_t rdata;
    initial begin
        req = '0;
        repeat (3) @(posedge clk); rst_n = 1;
        apb_write(32'h0, 32'h0000_A5A5);
        apb_read(32'h0, rdata);
        if (rdata[15:0] !== 16'hA5A5) begin
            $display("FAIL readback %h", rdata);
            errors = errors + 1;
        end
        if (errors == 0) $display("APB REGS: ALL TESTS PASSED");
        else $display("APB REGS: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("APB_REGS_TB: TIMEOUT");
        $finish;
    end
endmodule
""",
        },
        {
            "id": "apbslave",
            "top": "apbslave",
            "source_family": "ZipCPU",
            "upstream": "https://github.com/ZipCPU/wb2axip",
            "upstream_commit": ZIP_SHA,
            "hdl": "verilog-2001",
            "clocks": ["PCLK"],
            "resets": ["PRESETn"],
            "objective": "Simple ZipCPU APB slave memory.",
            "copies": [(zipc / "rtl" / "apbslave.v", "apbslave.v")],
            "rtl_names": ["apbslave.v"],
            "tb_file": "apbslave_tb.v",
            "tb_top": "apbslave_tb",
            "tb_sim_files": ["apbslave_tb.v"],
            "tb": pass_fail_tb(
                "apbslave_tb",
                """
    reg PCLK = 0, PRESETn = 0, PSEL = 0, PENABLE = 0, PWRITE = 0;
    reg [11:0] PADDR = 0;
    reg [31:0] PWDATA = 0;
    reg [3:0] PWSTRB = 0;
    wire PREADY, PSLVERR;
    wire [31:0] PRDATA;
    always #5 PCLK = ~PCLK;

    apbslave dut (
        .PCLK(PCLK), .PRESETn(PRESETn), .PSEL(PSEL), .PENABLE(PENABLE),
        .PREADY(PREADY), .PADDR(PADDR), .PWRITE(PWRITE), .PWDATA(PWDATA),
        .PWSTRB(PWSTRB), .PPROT(3'b000), .PRDATA(PRDATA), .PSLVERR(PSLVERR)
    );

    task apb_write(input [11:0] addr, input [31:0] data);
        begin
            @(negedge PCLK);
            PSEL = 1; PENABLE = 0; PWRITE = 1; PADDR = addr;
            PWDATA = data; PWSTRB = 4'hF;
            @(posedge PCLK);
            @(negedge PCLK); PENABLE = 1;
            @(posedge PCLK);
            while (!PREADY) @(posedge PCLK);
            @(negedge PCLK);
            PSEL = 0; PENABLE = 0; PWRITE = 0;
        end
    endtask

    task apb_read(input [11:0] addr);
        begin
            @(negedge PCLK);
            PSEL = 1; PENABLE = 0; PWRITE = 0; PADDR = addr; PWSTRB = 0;
            @(posedge PCLK);
            @(negedge PCLK); PENABLE = 1;
            @(posedge PCLK);
            while (!PREADY) @(posedge PCLK);
            @(negedge PCLK);
            PSEL = 0; PENABLE = 0;
        end
    endtask

    initial begin
        repeat (3) @(posedge PCLK); PRESETn = 1;
        apb_write(12'h004, 32'h11223344);
        apb_read(12'h004);
        if (PRDATA !== 32'h11223344) begin
            $display("FAIL got %h", PRDATA);
            errors = errors + 1;
        end
        if (errors == 0) $display("APBSLAVE: ALL TESTS PASSED");
        else $display("APBSLAVE: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
            ),
        },
        {
            "id": "uart16550",
            "top": "uart_top",
            "source_family": "opencores",
            "upstream": "https://github.com/freecores/uart16550",
            "upstream_commit": UART_SHA,
            "hdl": "verilog-2001",
            "clocks": ["wb_clk_i"],
            "resets": ["wb_rst_i"],
            "objective": "OpenCores UART16550 with RX/TX FIFOs.",
            "copies": [(p, p.name) for p in sorted(uart_rtl)],
            "upstream_tb": [
                (p, Path("upstream") / p.relative_to(uart / "bench" / "verilog"))
                for p in sorted(uart_tb)
                if p.is_file()
            ],
            "rtl_names": [p.name for p in sorted(uart_rtl)],
            "incdirs": ["$BENCH/fixed/rtl"],
            "tb_file": "uart16550_tb.v",
            "tb_top": "uart16550_tb",
            "tb_sim_files": ["uart16550_tb.v"],
            "tb": pass_fail_tb(
                "uart16550_tb",
                """
    reg wb_clk_i = 0, wb_rst_i = 1;
    wire stx, int_o, rts, dtr, ack;
    wire [31:0] wb_dat_o;
    always #5 wb_clk_i = ~wb_clk_i;

    uart_top dut (
        .wb_clk_i(wb_clk_i), .wb_rst_i(wb_rst_i),
        .wb_adr_i(5'b0), .wb_dat_i(32'b0), .wb_dat_o(wb_dat_o),
        .wb_we_i(1'b0), .wb_stb_i(1'b0), .wb_cyc_i(1'b0),
        .wb_ack_o(ack), .wb_sel_i(4'b0), .int_o(int_o),
        .stx_pad_o(stx), .srx_pad_i(stx),
        .rts_pad_o(rts), .cts_pad_i(1'b1), .dtr_pad_o(dtr),
        .dsr_pad_i(1'b1), .ri_pad_i(1'b1), .dcd_pad_i(1'b1)
    );

    initial begin
        repeat (8) @(posedge wb_clk_i);
        wb_rst_i = 0;
        repeat (8) @(posedge wb_clk_i);
        if (stx !== 1'b1) begin
            $display("FAIL TX line not idle-high");
            errors = errors + 1;
        end
        if (errors == 0) $display("UART16550: ALL TESTS PASSED");
        else $display("UART16550: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
            ),
        },
        {
            "id": "i2c_master",
            "top": "i2c_master",
            "source_family": "verilog-i2c",
            "upstream": "https://github.com/alexforencich/verilog-i2c",
            "upstream_commit": I2C_SHA,
            "hdl": "verilog-2001",
            "clocks": ["clk"],
            "resets": ["rst"],
            "objective": "I2C controller with host stream command interface.",
            "copies": [
                (i2c / "rtl" / "i2c_master.v", "i2c_master.v"),
                (i2c / "rtl" / "i2c_slave.v", "i2c_slave.v"),
            ],
            "upstream_tb": [
                (i2c / "tb" / "test_i2c_master.v", "upstream/test_i2c_master.v"),
                (i2c / "tb" / "test_i2c_master.py", "upstream/test_i2c_master.py"),
            ],
            "rtl_names": ["i2c_master.v", "i2c_slave.v"],
            "tb_file": "i2c_master_tb.v",
            "tb_top": "i2c_master_tb",
            "tb_sim_files": ["i2c_master_tb.v"],
            "tb": pass_fail_tb(
                "i2c_master_tb",
                """
    reg clk = 0, rst = 1;
    wire scl_o, scl_t, sda_o, sda_t, scl_s, sda_s;
    wire scl = (scl_t ? 1'b1 : scl_o) & (scl_s ? 1'b1 : 1'b1);
    wire sda = (sda_t ? 1'b1 : sda_o) & (sda_s ? 1'b1 : 1'b1);
    wire cmd_ready, busy;
    always #5 clk = ~clk;

    i2c_master dut (
        .clk(clk), .rst(rst),
        .s_axis_cmd_address(7'h50), .s_axis_cmd_start(1'b0),
        .s_axis_cmd_read(1'b0), .s_axis_cmd_write(1'b0),
        .s_axis_cmd_write_multiple(1'b0), .s_axis_cmd_stop(1'b0),
        .s_axis_cmd_valid(1'b0), .s_axis_cmd_ready(cmd_ready),
        .s_axis_data_tdata(8'h00), .s_axis_data_tvalid(1'b0),
        .s_axis_data_tready(), .s_axis_data_tlast(1'b0),
        .m_axis_data_tdata(), .m_axis_data_tvalid(),
        .m_axis_data_tready(1'b1), .m_axis_data_tlast(),
        .scl_i(scl), .scl_o(scl_o), .scl_t(scl_t),
        .sda_i(sda), .sda_o(sda_o), .sda_t(sda_t),
        .busy(busy), .bus_control(), .bus_active(), .missed_ack(),
        .prescale(16'd4), .stop_on_idle(1'b0)
    );

    i2c_slave slave (
        .clk(clk), .rst(rst), .release_bus(1'b0),
        .s_axis_data_tdata(8'hA5), .s_axis_data_tvalid(1'b1),
        .s_axis_data_tready(), .s_axis_data_tlast(1'b1),
        .m_axis_data_tdata(), .m_axis_data_tvalid(),
        .m_axis_data_tready(1'b1), .m_axis_data_tlast(),
        .scl_i(scl), .scl_o(), .scl_t(scl_s),
        .sda_i(sda), .sda_o(), .sda_t(sda_s),
        .busy(), .bus_address(), .bus_addressed(), .bus_active(),
        .enable(1'b1), .device_address(7'h50), .device_address_mask(7'h7F)
    );

    initial begin
        repeat (4) @(posedge clk); rst = 0;
        repeat (8) @(posedge clk);
        if (busy !== 1'b0) begin
            $display("FAIL master busy after reset");
            errors = errors + 1;
        end
        if (errors == 0) $display("I2C MASTER: ALL TESTS PASSED");
        else $display("I2C MASTER: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
            ),
        },
        {
            "id": "spi_master_slave",
            "top": "spi_master",
            "source_family": "opencores",
            "upstream": "https://github.com/freecores/spi_master_slave",
            "upstream_commit": SPI_SHA,
            "hdl": "vhdl",
            "clocks": ["sclk_i", "pclk_i"],
            "resets": ["rst_i"],
            "objective": "OpenCores SPI master/slave with independent serial and parallel clocks.",
            "copies": [
                (spi / "rtl" / "spi_master_slave" / "spi_master.vhd", "spi_master.vhd"),
                (spi / "rtl" / "spi_master_slave" / "spi_slave.vhd", "spi_slave.vhd"),
                (spi / "rtl" / "spi_master_slave" / "spi_loopback.vhd", "spi_loopback.vhd"),
            ],
            "upstream_tb": [
                (
                    spi / "rtl" / "spi_master_slave" / "spi_loopback_test.vhd",
                    "upstream/spi_loopback_test.vhd",
                )
            ],
            "rtl_names": ["spi_master.vhd", "spi_slave.vhd"],
            "tb_file": "spi_master_slave_tb.v",
            "tb_top": "spi_master_slave_tb",
            "tb_sim_files": ["spi_master_slave_tb.v"],
            "xrun_extra": ["-v93", "-relax"],
            "tb": pass_fail_tb(
                "spi_master_slave_tb",
                """
    reg sclk_i = 0, pclk_i = 0, rst_i = 1, wren_i = 0;
    wire ssel, sck, mosi, di_req, wr_ack, do_valid;
    wire [7:0] do_o;
    always #5 sclk_i = ~sclk_i;
    always #5 pclk_i = ~pclk_i;

    spi_master #(.N(8), .SPI_2X_CLK_DIV(2)) dut (
        .sclk_i(sclk_i), .pclk_i(pclk_i), .rst_i(rst_i),
        .spi_ssel_o(ssel), .spi_sck_o(sck), .spi_mosi_o(mosi),
        .spi_miso_i(mosi),
        .di_req_o(di_req), .di_i(8'h5A), .wren_i(wren_i),
        .wr_ack_o(wr_ack), .do_valid_o(do_valid), .do_o(do_o)
    );

    initial begin
        repeat (8) @(posedge pclk_i); rst_i = 0;
        @(negedge pclk_i); wren_i = 1;
        @(negedge pclk_i); wren_i = 0;
        repeat (80) @(posedge pclk_i);
        if (do_o !== 8'h5A) begin
            $display("FAIL loopback got %h", do_o);
            errors = errors + 1;
        end
        if (errors == 0) $display("SPI MASTER SLAVE: ALL TESTS PASSED");
        else $display("SPI MASTER SLAVE: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
                40000,
            ),
        },
        {
            "id": "axi_dma",
            "top": "axi_dma",
            "source_family": "verilog-axi",
            "upstream": "https://github.com/alexforencich/verilog-axi",
            "upstream_commit": AXI_SHA,
            "hdl": "verilog-2001",
            "clocks": ["clk"],
            "resets": ["rst"],
            "objective": "AXI to AXI-Stream DMA engine.",
            "copies": [
                (axi / "rtl" / "axi_dma.v", "axi_dma.v"),
                (axi / "rtl" / "axi_dma_rd.v", "axi_dma_rd.v"),
                (axi / "rtl" / "axi_dma_wr.v", "axi_dma_wr.v"),
            ],
            "upstream_tb": [
                (axi / "tb" / "test_axi_dma_32_32.v", "upstream/test_axi_dma_32_32.v"),
                (axi / "tb" / "test_axi_dma_32_32.py", "upstream/test_axi_dma_32_32.py"),
                (axi / "tb" / "axi_dma" / "test_axi_dma.py", "upstream/test_axi_dma.py"),
            ],
            "rtl_names": ["axi_dma.v", "axi_dma_rd.v", "axi_dma_wr.v"],
            "tb_file": "axi_dma_tb.v",
            "tb_top": "axi_dma_tb",
            "tb_sim_files": ["axi_dma_tb.v"],
            "tb": pass_fail_tb(
                "axi_dma_tb",
                """
    reg clk = 0, rst = 1;
    wire read_ready, write_ready;
    always #5 clk = ~clk;

    axi_dma #(
        .AXI_DATA_WIDTH(32), .AXI_ADDR_WIDTH(16), .AXI_ID_WIDTH(8),
        .AXIS_DATA_WIDTH(32), .ENABLE_SG(0), .ENABLE_UNALIGNED(0)
    ) dut (
        .clk(clk), .rst(rst),
        .s_axis_read_desc_addr(16'h0), .s_axis_read_desc_len(20'd4),
        .s_axis_read_desc_tag(8'h0), .s_axis_read_desc_id(8'h0),
        .s_axis_read_desc_dest(8'h0), .s_axis_read_desc_user(1'b0),
        .s_axis_read_desc_valid(1'b0), .s_axis_read_desc_ready(read_ready),
        .m_axis_read_desc_status_tag(), .m_axis_read_desc_status_error(),
        .m_axis_read_desc_status_valid(),
        .m_axis_read_data_tdata(), .m_axis_read_data_tkeep(),
        .m_axis_read_data_tvalid(), .m_axis_read_data_tready(1'b1),
        .m_axis_read_data_tlast(), .m_axis_read_data_tid(),
        .m_axis_read_data_tdest(), .m_axis_read_data_tuser(),
        .s_axis_write_desc_addr(16'h0), .s_axis_write_desc_len(20'd4),
        .s_axis_write_desc_tag(8'h0), .s_axis_write_desc_valid(1'b0),
        .s_axis_write_desc_ready(write_ready),
        .m_axis_write_desc_status_len(), .m_axis_write_desc_status_tag(),
        .m_axis_write_desc_status_id(), .m_axis_write_desc_status_dest(),
        .m_axis_write_desc_status_user(), .m_axis_write_desc_status_error(),
        .m_axis_write_desc_status_valid(),
        .s_axis_write_data_tdata(32'h0), .s_axis_write_data_tkeep(4'hF),
        .s_axis_write_data_tvalid(1'b0), .s_axis_write_data_tready(),
        .s_axis_write_data_tlast(1'b0), .s_axis_write_data_tid(8'h0),
        .s_axis_write_data_tdest(8'h0), .s_axis_write_data_tuser(1'b0),
        .m_axi_awid(), .m_axi_awaddr(), .m_axi_awlen(), .m_axi_awsize(),
        .m_axi_awburst(), .m_axi_awlock(), .m_axi_awcache(), .m_axi_awprot(),
        .m_axi_awvalid(), .m_axi_awready(1'b1), .m_axi_wdata(), .m_axi_wstrb(),
        .m_axi_wlast(), .m_axi_wvalid(), .m_axi_wready(1'b1),
        .m_axi_bid(8'h0), .m_axi_bresp(2'b00), .m_axi_bvalid(1'b0),
        .m_axi_bready(),
        .m_axi_arid(), .m_axi_araddr(), .m_axi_arlen(), .m_axi_arsize(),
        .m_axi_arburst(), .m_axi_arlock(), .m_axi_arcache(), .m_axi_arprot(),
        .m_axi_arvalid(), .m_axi_arready(1'b1),
        .m_axi_rid(8'h0), .m_axi_rdata(32'h0), .m_axi_rresp(2'b00),
        .m_axi_rlast(1'b1), .m_axi_rvalid(1'b0), .m_axi_rready(),
        .read_enable(1'b1), .write_enable(1'b1), .write_abort(1'b0)
    );

    initial begin
        repeat (4) @(posedge clk); rst = 0;
        repeat (8) @(posedge clk);
        if (read_ready !== 1'b1 || write_ready !== 1'b1) begin
            $display("FAIL DMA not ready after reset");
            errors = errors + 1;
        end
        if (errors == 0) $display("AXI DMA: ALL TESTS PASSED");
        else $display("AXI DMA: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
            ),
        },
        {
            "id": "axidma",
            "top": "axidma",
            "source_family": "ZipCPU",
            "upstream": "https://github.com/ZipCPU/wb2axip",
            "upstream_commit": ZIP_SHA,
            "hdl": "verilog-2001",
            "clocks": ["S_AXI_ACLK"],
            "resets": ["S_AXI_ARESETN"],
            "objective": "ZipCPU memory-to-memory AXI DMA.",
            "copies": [
                (zipc / "rtl" / "axidma.v", "axidma.v"),
                (zipc / "rtl" / "skidbuffer.v", "skidbuffer.v"),
                (zipc / "rtl" / "sfifo.v", "sfifo.v"),
            ],
            "rtl_names": ["axidma.v", "skidbuffer.v", "sfifo.v"],
            "tb_file": "axidma_tb.v",
            "tb_top": "axidma_tb",
            "tb_sim_files": ["axidma_tb.v"],
            "tb": pass_fail_tb(
                "axidma_tb",
                """
    reg clk = 0, rstn = 0;
    wire awready, wready, arready;
    always #5 clk = ~clk;

    axidma #(
        .C_AXI_ID_WIDTH(1), .C_AXI_ADDR_WIDTH(32), .C_AXI_DATA_WIDTH(32),
        .OPT_UNALIGNED(1'b0)
    ) dut (
        .S_AXI_ACLK(clk), .S_AXI_ARESETN(rstn),
        .S_AXIL_AWVALID(1'b0), .S_AXIL_AWREADY(awready),
        .S_AXIL_AWADDR(5'h0), .S_AXIL_AWPROT(3'b0),
        .S_AXIL_WVALID(1'b0), .S_AXIL_WREADY(wready),
        .S_AXIL_WDATA(32'h0), .S_AXIL_WSTRB(4'h0),
        .S_AXIL_BVALID(), .S_AXIL_BREADY(1'b1), .S_AXIL_BRESP(),
        .S_AXIL_ARVALID(1'b0), .S_AXIL_ARREADY(arready),
        .S_AXIL_ARADDR(5'h0), .S_AXIL_ARPROT(3'b0),
        .S_AXIL_RVALID(), .S_AXIL_RREADY(1'b1),
        .S_AXIL_RDATA(), .S_AXIL_RRESP(),
        .M_AXI_AWVALID(), .M_AXI_AWREADY(1'b1), .M_AXI_AWID(),
        .M_AXI_AWADDR(), .M_AXI_AWLEN(), .M_AXI_AWSIZE(),
        .M_AXI_AWBURST(), .M_AXI_AWLOCK(), .M_AXI_AWCACHE(),
        .M_AXI_AWPROT(), .M_AXI_AWQOS(),
        .M_AXI_WVALID(), .M_AXI_WREADY(1'b1), .M_AXI_WDATA(),
        .M_AXI_WSTRB(), .M_AXI_WLAST(),
        .M_AXI_BVALID(1'b0), .M_AXI_BREADY(), .M_AXI_BID(1'b0),
        .M_AXI_BRESP(2'b00),
        .M_AXI_ARVALID(), .M_AXI_ARREADY(1'b1), .M_AXI_ARID(),
        .M_AXI_ARADDR(), .M_AXI_ARLEN(), .M_AXI_ARSIZE(),
        .M_AXI_ARBURST(), .M_AXI_ARLOCK(), .M_AXI_ARCACHE(),
        .M_AXI_ARPROT(), .M_AXI_ARQOS(),
        .M_AXI_RVALID(1'b0), .M_AXI_RREADY(), .M_AXI_RID(1'b0),
        .M_AXI_RDATA(32'h0), .M_AXI_RRESP(2'b00), .M_AXI_RLAST(1'b1),
        .o_int()
    );

    initial begin
        repeat (4) @(posedge clk); rstn = 1;
        repeat (8) @(posedge clk);
        if (awready !== 1'b1) begin
            $display("FAIL AXI-lite not ready");
            errors = errors + 1;
        end
        if (errors == 0) $display("AXIDMA: ALL TESTS PASSED");
        else $display("AXIDMA: TESTS FAILED (%0d)", errors);
        $finish;
    end
""",
            ),
        },
    ]


def install(cfg: dict) -> None:
    dest = BENCH / cfg["id"]
    if dest.exists():
        shutil.rmtree(dest)
    for src, name in cfg["copies"]:
        copy_file(Path(src), dest / "original" / "rtl" / name)
        copy_file(Path(src), dest / "fixed" / "rtl" / name)
    for src, name in cfg.get("upstream_tb", []):
        copy_file(Path(src), dest / "tb" / name)
    write_text(dest / "tb" / cfg["tb_file"], cfg["tb"])
    for name, text in cfg.get("extra_tb_files", {}).items():
        write_text(dest / "tb" / name, text)
    write_text(dest / "manifest.yaml", manifest(cfg))
    write_text(dest / "specification.md", specification(cfg))
    write_text(dest / f"constraints/{cfg['id']}.sdc", sdc(cfg))
    run_sh = dest / "sim" / "run.sh"
    write_text(run_sh, sim_script(cfg))
    run_sh.chmod(0o755)


def copy_licenses() -> None:
    mapping = {
        "dianluniuniu-async-fifo.MIT": CACHE / "async-fifo" / "LICENSE",
        "verilog-axis.MIT": CACHE / "verilog-axis" / "COPYING",
        "spi_master_slave.LGPL": CACHE / "spi_master_slave" / "license" / "lgpl.txt",
        "pulp-apb.SHL-0.51": CACHE / "apb" / "LICENSE",
    }
    for name, src in mapping.items():
        if src.exists():
            copy_file(src, ROOT / "LICENSES" / name)


def main() -> None:
    all_cfgs = circuits() + axis_stream_circuits() + remaining_circuits()
    for cfg in all_cfgs:
        print(f"import {cfg['id']}")
        install(cfg)
    copy_licenses()
    print(f"imported {len(all_cfgs)} circuits")


if __name__ == "__main__":
    main()
