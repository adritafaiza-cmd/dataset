#!/usr/bin/env python3
"""Package leftover CDC circuits as Verilog-only benchmarks."""

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
AXIS_SHA = "48ff7a7"
AXI_SHA = "516bd5d"
ZIP_SHA = "2e8d3bc"


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def snapshot_rtl(bench: Path, names: list[str]) -> None:
    for name in names:
        src = bench / "fixed" / "rtl" / name
        dst = bench / "original" / "rtl" / name
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)


def manifest(cfg: dict) -> str:
    rtl = "\n".join(f"  - original/rtl/{n}" for n in cfg["rtl_names"])
    fixed = "\n".join(f"  - fixed/rtl/{n}" for n in cfg["rtl_names"])
    clocks = "\n".join(f"  - {c}" for c in cfg["clocks"])
    resets = "\n".join(f"  - {r}" for r in cfg["resets"])
    return f"""schema_version: 1
id: {cfg["id"]}
top_module: {cfg["top"]}
source_family: {cfg["source_family"]}
upstream: {cfg["upstream"]}
upstream_commit: {cfg["upstream_commit"]}
hdl: verilog-2001
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
  Verilog-only snapshot of an open-source CDC circuit. fixed/rtl is currently
  an unmodified functional reference. This circuit is not part of the
  Jasper-verified 11-circuit pilot.
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
        f"#############################################################################",
        f"# CDC constraints for {cfg['id']} ({cfg['source_family']})",
        f"# {cfg['sdc_note']}",
        f"#############################################################################",
        "",
    ]
    if cfg.get("generated_clock"):
        src, dst, div = cfg["generated_clock"]
        lines.append(f"create_clock -name {src} -period 10.000 [get_ports {src}]")
        lines.append(
            f"create_generated_clock -name {dst} -source [get_ports {src}] "
            f"-divide_by {div} [get_ports {dst}]"
        )
        return "\n".join(lines) + "\n"
    for i, clk in enumerate(clocks):
        period = 10.000 + i * 4.000
        lines.append(f"create_clock -name {clk} -period {period:.3f} [get_ports {clk}]")
    if len(clocks) > 1:
        groups = " \\\n    ".join(f"-group {{{c}}}" for c in clocks)
        lines += ["", "set_clock_groups -asynchronous \\", f"    {groups}"]
    return "\n".join(lines) + "\n"


def run_sh(cfg: dict) -> str:
    rtl_args = " \\\n  ".join(f'"$BENCH/fixed/rtl/{n}"' for n in cfg["rtl_names"])
    extra = cfg.get("xrun_extra", "")
    extra_line = f"  {extra} \\\n" if extra else ""
    return f"""#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${{BASH_SOURCE[0]}}")/../../.." && pwd)"
BENCH="$ROOT/benchmarks/{cfg["id"]}"
mkdir -p "$ROOT/build/sim"
XRUN_MODE=()
if [[ "${{COMPILE_ONLY:-0}}" == "1" ]]; then
  XRUN_MODE=(-elaborate)
fi
xrun "${{XRUN_MODE[@]}}" -64bit -sv -timescale 1ns/1ps -top {cfg["tb_top"]} \\
{extra_line}  -xmlibdirname "$ROOT/build/sim/{cfg["id"]}" \\
  {rtl_args} \\
  "$BENCH/tb/{cfg["tb_file"]}"
"""


def install(cfg: dict) -> None:
    bench = BENCH / cfg["id"]
    write_text(bench / "manifest.yaml", manifest(cfg))
    write_text(bench / "specification.md", specification(cfg))
    write_text(bench / f"constraints/{cfg['id']}.sdc", sdc(cfg))
    write_text(bench / "sim/run.sh", run_sh(cfg))
    (bench / "sim/run.sh").chmod(0o755)
    snapshot_rtl(bench, cfg["rtl_names"])


# ---------------------------------------------------------------------------
# Shared gray FIFO used by cdc_fifo_gray, clearable, and apb_cdc
# ---------------------------------------------------------------------------

CDC_FIFO_GRAY_V = r'''// Copyright 2018-2019 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 flattening of pulp-platform/common_cells cdc_fifo_gray.

module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam PTRW = LOG_DEPTH + 1;
    localparam [PTRW-1:0] PTR_FULL = {1'b1, {LOG_DEPTH{1'b0}}};

    function [PTRW-1:0] bin2gray;
        input [PTRW-1:0] b;
        begin
            bin2gray = b ^ (b >> 1);
        end
    endfunction

    function [PTRW-1:0] gray2bin;
        input [PTRW-1:0] g;
        integer k;
        begin
            gray2bin[PTRW-1] = g[PTRW-1];
            for (k = PTRW-2; k >= 0; k = k - 1)
                gray2bin[k] = gray2bin[k+1] ^ g[k];
        end
    endfunction

    reg [WIDTH-1:0] mem [0:(1<<LOG_DEPTH)-1];
    reg [PTRW-1:0] wptr_bin, rptr_bin;
    wire [PTRW-1:0] wptr_gray = bin2gray(wptr_bin);
    wire [PTRW-1:0] rptr_gray = bin2gray(rptr_bin);

    (* ASYNC_REG = "TRUE" *) reg [PTRW-1:0] rptr_sync [0:SYNC_STAGES-1];
    (* ASYNC_REG = "TRUE" *) reg [PTRW-1:0] wptr_sync [0:SYNC_STAGES-1];

    integer s;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (s = 0; s < SYNC_STAGES; s = s + 1)
                rptr_sync[s] <= {PTRW{1'b0}};
        end else begin
            rptr_sync[0] <= rptr_gray;
            for (s = 1; s < SYNC_STAGES; s = s + 1)
                rptr_sync[s] <= rptr_sync[s-1];
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (s = 0; s < SYNC_STAGES; s = s + 1)
                wptr_sync[s] <= {PTRW{1'b0}};
        end else begin
            wptr_sync[0] <= wptr_gray;
            for (s = 1; s < SYNC_STAGES; s = s + 1)
                wptr_sync[s] <= wptr_sync[s-1];
        end
    end

    wire [PTRW-1:0] rptr_bin_src = gray2bin(rptr_sync[SYNC_STAGES-1]);
    wire [PTRW-1:0] wptr_bin_dst = gray2bin(wptr_sync[SYNC_STAGES-1]);

    assign src_ready_o = ((wptr_bin ^ rptr_bin_src) != PTR_FULL);
    assign dst_valid_o = (wptr_bin_dst != rptr_bin);
    assign dst_data_o  = mem[rptr_bin[LOG_DEPTH-1:0]];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            wptr_bin <= {PTRW{1'b0}};
        else if (src_valid_i && src_ready_o) begin
            mem[wptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
            wptr_bin <= wptr_bin + 1'b1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            rptr_bin <= {PTRW{1'b0}};
        else if (dst_valid_o && dst_ready_i)
            rptr_bin <= rptr_bin + 1'b1;
    end

endmodule
'''

VALID_READY_TB = r'''`timescale 1ns/1ps

module {tb_top};
    integer errors = 0;
    integer received = 0;

    reg src_clk = 0, dst_clk = 0, src_rst_n = 0, dst_rst_n = 0;
    always #{src_half} src_clk = ~src_clk;
    always #{dst_half} dst_clk = ~dst_clk;

    reg [7:0] src_data = 0;
    reg src_valid = 0;
    wire src_ready;
    wire [7:0] dst_data;
    wire dst_valid;
    reg dst_ready = 0;

    {dut}

    task send;
        input [7:0] value;
        begin
            @(negedge src_clk);
            while (!src_ready) @(negedge src_clk);
            src_data = value;
            src_valid = 1;
            @(posedge src_clk);
            @(negedge src_clk);
            src_valid = 0;
        end
    endtask

    always @(posedge dst_clk) begin
        if (dst_rst_n && dst_valid && dst_ready) begin
            if (dst_data !== (8'h40 + received[7:0])) begin
                $display("FAIL {name} item=%0d actual=%h expected=%h",
                    received, dst_data, 8'h40 + received[7:0]);
                errors = errors + 1;
            end
            received = received + 1;
        end
    end

    integer i;
    initial begin
        repeat (5) @(posedge src_clk);
        @(negedge src_clk); src_rst_n = 1;
        repeat (5) @(posedge dst_clk);
        @(negedge dst_clk); dst_rst_n = 1; dst_ready = 1;
        repeat (4) @(posedge src_clk);
        repeat (4) @(posedge dst_clk);

        for (i = 0; i < 8; i = i + 1)
            send(8'h40 + i);

        wait (received == 8);
        repeat (3) @(posedge dst_clk);
        if (errors == 0)
            $display("{banner}: ALL TESTS PASSED");
        else
            $display("{banner}: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #80000;
        $display("{banner}: TIMEOUT");
        $finish;
    end
endmodule
'''


def write_valid_ready_tb(path: Path, **kwargs) -> None:
    write_text(path, VALID_READY_TB.format(**kwargs))


def add_cdc_fifo_gray() -> None:
    bench = BENCH / "cdc_fifo_gray"
    write_text(bench / "fixed/rtl/cdc_fifo_gray.v", CDC_FIFO_GRAY_V)
    write_valid_ready_tb(
        bench / "tb/cdc_fifo_gray_tb.v",
        tb_top="cdc_fifo_gray_tb",
        src_half=5,
        dst_half=7,
        name="cdc_fifo_gray",
        banner="CDC FIFO GRAY",
        dut="""cdc_fifo_gray #(.WIDTH(8), .LOG_DEPTH(3)) dut (
        .src_rst_ni(src_rst_n), .src_clk_i(src_clk),
        .src_data_i(src_data), .src_valid_i(src_valid), .src_ready_o(src_ready),
        .dst_rst_ni(dst_rst_n), .dst_clk_i(dst_clk),
        .dst_data_o(dst_data), .dst_valid_o(dst_valid), .dst_ready_i(dst_ready)
    );""",
    )
    install({
        "id": "cdc_fifo_gray",
        "top": "cdc_fifo_gray",
        "source_family": "pulp-platform",
        "upstream": "https://github.com/pulp-platform/common_cells",
        "upstream_commit": PULP_SHA,
        "rtl_names": ["cdc_fifo_gray.v"],
        "clocks": ["src_clk_i", "dst_clk_i"],
        "resets": ["src_rst_ni", "dst_rst_ni"],
        "tb_file": "cdc_fifo_gray_tb.v",
        "tb_top": "cdc_fifo_gray_tb",
        "objective": "Gray-pointer asynchronous FIFO for valid/ready payload CDC.",
        "sdc_note": "TWO asynchronous clock domains. Crossing: gray-coded pointers.",
    })


CDC_FIFO_GRAY_CLEARABLE_V = r'''// Copyright 2018-2019 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 flattening of pulp-platform cdc_fifo_gray_clearable.
// Isolate both sides, then synchronously clear pointers.

module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam PTRW = LOG_DEPTH + 1;
    localparam [PTRW-1:0] PTR_FULL = {1'b1, {LOG_DEPTH{1'b0}}};

    function [PTRW-1:0] bin2gray;
        input [PTRW-1:0] b;
        begin
            bin2gray = b ^ (b >> 1);
        end
    endfunction

    function [PTRW-1:0] gray2bin;
        input [PTRW-1:0] g;
        integer k;
        begin
            gray2bin[PTRW-1] = g[PTRW-1];
            for (k = PTRW-2; k >= 0; k = k - 1)
                gray2bin[k] = gray2bin[k+1] ^ g[k];
        end
    endfunction

    reg [WIDTH-1:0] mem [0:(1<<LOG_DEPTH)-1];
    reg [PTRW-1:0] wptr_bin, rptr_bin;
    wire [PTRW-1:0] wptr_gray = bin2gray(wptr_bin);
    wire [PTRW-1:0] rptr_gray = bin2gray(rptr_bin);

    (* ASYNC_REG = "TRUE" *) reg [PTRW-1:0] rptr_sync [0:SYNC_STAGES-1];
    (* ASYNC_REG = "TRUE" *) reg [PTRW-1:0] wptr_sync [0:SYNC_STAGES-1];
    (* ASYNC_REG = "TRUE" *) reg [SYNC_STAGES-1:0] src_req_sync;
    (* ASYNC_REG = "TRUE" *) reg [SYNC_STAGES-1:0] dst_req_sync;
    (* ASYNC_REG = "TRUE" *) reg [SYNC_STAGES-1:0] src_done_sync;
    (* ASYNC_REG = "TRUE" *) reg [SYNC_STAGES-1:0] dst_done_sync;

    reg src_req, dst_req;
    reg src_cleared, dst_cleared;
    integer s;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (s = 0; s < SYNC_STAGES; s = s + 1)
                rptr_sync[s] <= {PTRW{1'b0}};
            dst_req_sync <= {SYNC_STAGES{1'b0}};
            dst_done_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            rptr_sync[0] <= rptr_gray;
            for (s = 1; s < SYNC_STAGES; s = s + 1)
                rptr_sync[s] <= rptr_sync[s-1];
            dst_req_sync <= {dst_req_sync[SYNC_STAGES-2:0], dst_req};
            dst_done_sync <= {dst_done_sync[SYNC_STAGES-2:0], dst_cleared};
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (s = 0; s < SYNC_STAGES; s = s + 1)
                wptr_sync[s] <= {PTRW{1'b0}};
            src_req_sync <= {SYNC_STAGES{1'b0}};
            src_done_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            wptr_sync[0] <= wptr_gray;
            for (s = 1; s < SYNC_STAGES; s = s + 1)
                wptr_sync[s] <= wptr_sync[s-1];
            src_req_sync <= {src_req_sync[SYNC_STAGES-2:0], src_req};
            src_done_sync <= {src_done_sync[SYNC_STAGES-2:0], src_cleared};
        end
    end

    wire [PTRW-1:0] rptr_bin_src = gray2bin(rptr_sync[SYNC_STAGES-1]);
    wire [PTRW-1:0] wptr_bin_dst = gray2bin(wptr_sync[SYNC_STAGES-1]);
    wire src_remote_req = dst_req_sync[SYNC_STAGES-1];
    wire dst_remote_req = src_req_sync[SYNC_STAGES-1];
    wire src_remote_done = dst_done_sync[SYNC_STAGES-1];
    wire dst_remote_done = src_done_sync[SYNC_STAGES-1];

    wire src_isolate = src_req | src_remote_req;
    wire dst_isolate = dst_req | dst_remote_req;
    wire fifo_ready = ((wptr_bin ^ rptr_bin_src) != PTR_FULL);
    wire fifo_valid = (wptr_bin_dst != rptr_bin);

    assign src_ready_o = fifo_ready & ~src_isolate;
    assign dst_valid_o = fifo_valid & ~dst_isolate;
    assign dst_data_o  = mem[rptr_bin[LOG_DEPTH-1:0]];
    assign src_clear_pending_o = src_isolate;
    assign dst_clear_pending_o = dst_isolate;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr_bin <= {PTRW{1'b0}};
            src_req <= 1'b0;
            src_cleared <= 1'b0;
        end else begin
            if (src_clear_i)
                src_req <= 1'b1;
            else if (src_cleared && src_remote_done)
                src_req <= 1'b0;

            if (src_isolate && !src_cleared) begin
                wptr_bin <= {PTRW{1'b0}};
                src_cleared <= 1'b1;
            end else if (!src_isolate)
                src_cleared <= 1'b0;
            else if (src_valid_i && src_ready_o) begin
                mem[wptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
                wptr_bin <= wptr_bin + 1'b1;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr_bin <= {PTRW{1'b0}};
            dst_req <= 1'b0;
            dst_cleared <= 1'b0;
        end else begin
            if (dst_clear_i)
                dst_req <= 1'b1;
            else if (dst_cleared && dst_remote_done)
                dst_req <= 1'b0;

            if (dst_isolate && !dst_cleared) begin
                rptr_bin <= {PTRW{1'b0}};
                dst_cleared <= 1'b1;
            end else if (!dst_isolate)
                dst_cleared <= 1'b0;
            else if (dst_valid_o && dst_ready_i)
                rptr_bin <= rptr_bin + 1'b1;
        end
    end

endmodule
'''


def add_cdc_fifo_gray_clearable() -> None:
    bench = BENCH / "cdc_fifo_gray_clearable"
    write_text(bench / "fixed/rtl/cdc_fifo_gray_clearable.v", CDC_FIFO_GRAY_CLEARABLE_V)
    write_text(bench / "tb/cdc_fifo_gray_clearable_tb.v", r'''`timescale 1ns/1ps

module cdc_fifo_gray_clearable_tb;
    integer errors = 0;
    integer received = 0;

    reg src_clk = 0, dst_clk = 0, src_rst_n = 0, dst_rst_n = 0;
    always #5 src_clk = ~src_clk;
    always #7 dst_clk = ~dst_clk;

    reg [7:0] src_data = 0;
    reg src_valid = 0, src_clear = 0, dst_clear = 0;
    wire src_ready, src_pending, dst_pending;
    wire [7:0] dst_data;
    wire dst_valid;
    reg dst_ready = 0;

    cdc_fifo_gray_clearable #(.WIDTH(8), .LOG_DEPTH(3)) dut (
        .src_rst_ni(src_rst_n), .src_clk_i(src_clk),
        .src_clear_i(src_clear), .src_clear_pending_o(src_pending),
        .src_data_i(src_data), .src_valid_i(src_valid), .src_ready_o(src_ready),
        .dst_rst_ni(dst_rst_n), .dst_clk_i(dst_clk),
        .dst_clear_i(dst_clear), .dst_clear_pending_o(dst_pending),
        .dst_data_o(dst_data), .dst_valid_o(dst_valid), .dst_ready_i(dst_ready)
    );

    task send;
        input [7:0] value;
        begin
            @(negedge src_clk);
            while (!src_ready) @(negedge src_clk);
            src_data = value;
            src_valid = 1;
            @(posedge src_clk);
            @(negedge src_clk);
            src_valid = 0;
        end
    endtask

    always @(posedge dst_clk) begin
        if (dst_rst_n && dst_valid && dst_ready) begin
            if (dst_data !== (8'hA0 + received[7:0])) begin
                $display("FAIL clearable item=%0d actual=%h", received, dst_data);
                errors = errors + 1;
            end
            received = received + 1;
        end
    end

    integer i;
    initial begin
        repeat (4) @(posedge src_clk); src_rst_n = 1;
        repeat (4) @(posedge dst_clk); dst_rst_n = 1; dst_ready = 1;
        repeat (4) @(posedge src_clk);
        send(8'h11);
        send(8'h22);
        @(negedge src_clk); src_clear = 1;
        @(negedge src_clk); src_clear = 0;
        wait (src_pending === 1'b1);
        wait (src_pending === 1'b0);
        wait (dst_pending === 1'b0);
        received = 0;
        for (i = 0; i < 4; i = i + 1)
            send(8'hA0 + i);
        wait (received == 4);
        if (errors == 0)
            $display("CDC FIFO GRAY CLEARABLE: ALL TESTS PASSED");
        else
            $display("CDC FIFO GRAY CLEARABLE: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #80000;
        $display("CDC FIFO GRAY CLEARABLE: TIMEOUT");
        $finish;
    end
endmodule
''')
    install({
        "id": "cdc_fifo_gray_clearable",
        "top": "cdc_fifo_gray_clearable",
        "source_family": "pulp-platform",
        "upstream": "https://github.com/pulp-platform/common_cells",
        "upstream_commit": PULP_SHA,
        "rtl_names": ["cdc_fifo_gray_clearable.v"],
        "clocks": ["src_clk_i", "dst_clk_i"],
        "resets": ["src_rst_ni", "dst_rst_ni"],
        "tb_file": "cdc_fifo_gray_clearable_tb.v",
        "tb_top": "cdc_fifo_gray_clearable_tb",
        "objective": "Gray-pointer async FIFO with lock-step isolate/clear on either side.",
        "sdc_note": "TWO asynchronous clock domains. Crossing: gray pointers plus clear request.",
    })


CDC_FIFO_2PHASE_V = r'''// Copyright 2018 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 flattening of pulp-platform/common_cells cdc_fifo_2phase.

module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam PTRW = LOG_DEPTH + 1;
    localparam [PTRW-1:0] PTR_FULL = {1'b1, {LOG_DEPTH{1'b0}}};

    reg [WIDTH-1:0] fifo_data [0:(1<<LOG_DEPTH)-1];
    reg [PTRW-1:0] src_wptr_q, dst_rptr_q;
    wire [PTRW-1:0] dst_wptr, src_rptr;
    integer i;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wptr_q <= {PTRW{1'b0}};
            for (i = 0; i < (1<<LOG_DEPTH); i = i + 1)
                fifo_data[i] <= {WIDTH{1'b0}};
        end else if (src_valid_i && src_ready_o) begin
            fifo_data[src_wptr_q[LOG_DEPTH-1:0]] <= src_data_i;
            src_wptr_q <= src_wptr_q + 1'b1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_rptr_q <= {PTRW{1'b0}};
        else if (dst_valid_o && dst_ready_i)
            dst_rptr_q <= dst_rptr_q + 1'b1;
    end

    assign src_ready_o = ((src_wptr_q ^ src_rptr) != PTR_FULL);
    assign dst_valid_o = (dst_rptr_q != dst_wptr);
    assign dst_data_o  = fifo_data[dst_rptr_q[LOG_DEPTH-1:0]];

    cdc_2phase #(.WIDTH(PTRW)) i_cdc_wptr (
        .src_rst_ni(src_rst_ni), .src_clk_i(src_clk_i),
        .src_data_i(src_wptr_q), .src_valid_i(1'b1), .src_ready_o(),
        .dst_rst_ni(dst_rst_ni), .dst_clk_i(dst_clk_i),
        .dst_data_o(dst_wptr), .dst_valid_o(), .dst_ready_i(1'b1)
    );

    cdc_2phase #(.WIDTH(PTRW)) i_cdc_rptr (
        .src_rst_ni(dst_rst_ni), .src_clk_i(dst_clk_i),
        .src_data_i(dst_rptr_q), .src_valid_i(1'b1), .src_ready_o(),
        .dst_rst_ni(src_rst_ni), .dst_clk_i(src_clk_i),
        .dst_data_o(src_rptr), .dst_valid_o(), .dst_ready_i(1'b1)
    );

endmodule
'''


def add_cdc_fifo_2phase() -> None:
    bench = BENCH / "cdc_fifo_2phase"
    copy_file(BENCH / "cdc_2phase/fixed/rtl/cdc_2phase.v", bench / "fixed/rtl/cdc_2phase.v")
    write_text(bench / "fixed/rtl/cdc_fifo_2phase.v", CDC_FIFO_2PHASE_V)
    write_valid_ready_tb(
        bench / "tb/cdc_fifo_2phase_tb.v",
        tb_top="cdc_fifo_2phase_tb",
        src_half=5,
        dst_half=7,
        name="cdc_fifo_2phase",
        banner="CDC FIFO 2PHASE",
        dut="""cdc_fifo_2phase #(.WIDTH(8), .LOG_DEPTH(3)) dut (
        .src_rst_ni(src_rst_n), .src_clk_i(src_clk),
        .src_data_i(src_data), .src_valid_i(src_valid), .src_ready_o(src_ready),
        .dst_rst_ni(dst_rst_n), .dst_clk_i(dst_clk),
        .dst_data_o(dst_data), .dst_valid_o(dst_valid), .dst_ready_i(dst_ready)
    );""",
    )
    install({
        "id": "cdc_fifo_2phase",
        "top": "cdc_fifo_2phase",
        "source_family": "pulp-platform",
        "upstream": "https://github.com/pulp-platform/common_cells",
        "upstream_commit": PULP_SHA,
        "rtl_names": ["cdc_fifo_2phase.v", "cdc_2phase.v"],
        "clocks": ["src_clk_i", "dst_clk_i"],
        "resets": ["src_rst_ni", "dst_rst_ni"],
        "tb_file": "cdc_fifo_2phase_tb.v",
        "tb_top": "cdc_fifo_2phase_tb",
        "objective": "Async FIFO that crosses read/write pointers with 2-phase handshakes.",
        "sdc_note": "TWO asynchronous clock domains. Crossing: 2-phase pointer CDC.",
    })


CDC_RESET_CTRLR_V = r'''// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 lock-step isolate/clear sequencer matching cdc_reset_ctrlr ports.

module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  a_clear_i,
    output a_clear_o,
    input  a_clear_ack_i,
    output a_isolate_o,
    input  a_isolate_ack_i,
    input  b_clk_i,
    input  b_rst_ni,
    input  b_clear_i,
    output b_clear_o,
    input  b_clear_ack_i,
    output b_isolate_o,
    input  b_isolate_ack_i
);

    localparam IDLE = 2'd0;
    localparam ISOLATE = 2'd1;
    localparam CLEAR = 2'd2;
    localparam WAIT_PEER = 2'd3;

    reg [1:0] a_state, b_state;
    (* ASYNC_REG = "TRUE" *) reg [SYNC_STAGES-1:0] a2b_req_sync, b2a_req_sync;
    (* ASYNC_REG = "TRUE" *) reg [SYNC_STAGES-1:0] a2b_done_sync, b2a_done_sync;
    wire a_req = (a_state != IDLE);
    wire b_req = (b_state != IDLE);
    wire a_done = (a_state == WAIT_PEER);
    wire b_done = (b_state == WAIT_PEER);
    wire a_peer_req = b2a_req_sync[SYNC_STAGES-1];
    wire b_peer_req = a2b_req_sync[SYNC_STAGES-1];
    wire a_peer_done = b2a_done_sync[SYNC_STAGES-1];
    wire b_peer_done = a2b_done_sync[SYNC_STAGES-1];

    assign a_isolate_o = (a_state == ISOLATE) || (a_state == CLEAR) || (a_state == WAIT_PEER);
    assign a_clear_o   = (a_state == CLEAR);
    assign b_isolate_o = (b_state == ISOLATE) || (b_state == CLEAR) || (b_state == WAIT_PEER);
    assign b_clear_o   = (b_state == CLEAR);

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= IDLE;
            b2a_req_sync <= {SYNC_STAGES{1'b0}};
            b2a_done_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b2a_req_sync <= {b2a_req_sync[SYNC_STAGES-2:0], b_req};
            b2a_done_sync <= {b2a_done_sync[SYNC_STAGES-2:0], b_done};
            case (a_state)
                IDLE: if (a_clear_i || a_peer_req) a_state <= ISOLATE;
                ISOLATE: if (a_isolate_ack_i) a_state <= CLEAR;
                CLEAR: if (a_clear_ack_i) a_state <= WAIT_PEER;
                WAIT_PEER: if (a_peer_done || !a_peer_req) a_state <= IDLE;
                default: a_state <= IDLE;
            endcase
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= IDLE;
            a2b_req_sync <= {SYNC_STAGES{1'b0}};
            a2b_done_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a2b_req_sync <= {a2b_req_sync[SYNC_STAGES-2:0], a_req};
            a2b_done_sync <= {a2b_done_sync[SYNC_STAGES-2:0], a_done};
            case (b_state)
                IDLE: if (b_clear_i || b_peer_req) b_state <= ISOLATE;
                ISOLATE: if (b_isolate_ack_i) b_state <= CLEAR;
                CLEAR: if (b_clear_ack_i) b_state <= WAIT_PEER;
                WAIT_PEER: if (b_peer_done || !b_peer_req) b_state <= IDLE;
                default: b_state <= IDLE;
            endcase
        end
    end

endmodule
'''


def add_cdc_reset_ctrlr() -> None:
    bench = BENCH / "cdc_reset_ctrlr"
    write_text(bench / "fixed/rtl/cdc_reset_ctrlr.v", CDC_RESET_CTRLR_V)
    write_text(bench / "tb/cdc_reset_ctrlr_tb.v", r'''`timescale 1ns/1ps

module cdc_reset_ctrlr_tb;
    integer errors = 0;

    reg a_clk = 0, b_clk = 0, a_rst_n = 0, b_rst_n = 0;
    always #5 a_clk = ~a_clk;
    always #8 b_clk = ~b_clk;

    reg a_clear = 0, b_clear = 0;
    reg a_clear_ack = 0, b_clear_ack = 0;
    reg a_iso_ack = 0, b_iso_ack = 0;
    wire a_clear_o, b_clear_o, a_iso, b_iso;
    integer saw_a_iso = 0, saw_b_iso = 0, saw_a_clr = 0, saw_b_clr = 0;

    cdc_reset_ctrlr dut (
        .a_clk_i(a_clk), .a_rst_ni(a_rst_n), .a_clear_i(a_clear),
        .a_clear_o(a_clear_o), .a_clear_ack_i(a_clear_ack),
        .a_isolate_o(a_iso), .a_isolate_ack_i(a_iso_ack),
        .b_clk_i(b_clk), .b_rst_ni(b_rst_n), .b_clear_i(b_clear),
        .b_clear_o(b_clear_o), .b_clear_ack_i(b_clear_ack),
        .b_isolate_o(b_iso), .b_isolate_ack_i(b_iso_ack)
    );

    always @(posedge a_clk) begin
        if (a_iso) begin
            saw_a_iso = 1;
            a_iso_ack <= 1'b1;
        end else
            a_iso_ack <= 1'b0;
        if (a_clear_o) begin
            saw_a_clr = 1;
            a_clear_ack <= 1'b1;
        end else
            a_clear_ack <= 1'b0;
    end

    always @(posedge b_clk) begin
        if (b_iso) begin
            saw_b_iso = 1;
            b_iso_ack <= 1'b1;
        end else
            b_iso_ack <= 1'b0;
        if (b_clear_o) begin
            saw_b_clr = 1;
            b_clear_ack <= 1'b1;
        end else
            b_clear_ack <= 1'b0;
    end

    initial begin
        repeat (4) @(posedge a_clk); a_rst_n = 1;
        repeat (4) @(posedge b_clk); b_rst_n = 1;
        @(negedge a_clk); a_clear = 1;
        @(negedge a_clk); a_clear = 0;
        repeat (40) @(posedge a_clk);
        if (!saw_a_iso || !saw_b_iso) begin
            $display("FAIL isolate not asserted on both sides");
            errors = errors + 1;
        end
        if (!saw_a_clr || !saw_b_clr) begin
            $display("FAIL clear not asserted on both sides");
            errors = errors + 1;
        end
        if (a_iso !== 1'b0 || b_iso !== 1'b0) begin
            $display("FAIL isolate stuck after sequence");
            errors = errors + 1;
        end
        if (errors == 0)
            $display("CDC RESET CTRLR: ALL TESTS PASSED");
        else
            $display("CDC RESET CTRLR: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #40000;
        $display("CDC RESET CTRLR: TIMEOUT");
        $finish;
    end
endmodule
''')
    install({
        "id": "cdc_reset_ctrlr",
        "top": "cdc_reset_ctrlr",
        "source_family": "pulp-platform",
        "upstream": "https://github.com/pulp-platform/common_cells",
        "upstream_commit": PULP_SHA,
        "rtl_names": ["cdc_reset_ctrlr.v"],
        "clocks": ["a_clk_i", "b_clk_i"],
        "resets": ["a_rst_ni", "b_rst_ni"],
        "tb_file": "cdc_reset_ctrlr_tb.v",
        "tb_top": "cdc_reset_ctrlr_tb",
        "objective": "Lock-step isolate-then-clear sequencer for both sides of a CDC.",
        "sdc_note": "TWO asynchronous clock domains. Crossing: clear/isolate request bits.",
    })


SYNC_V = r'''// Copyright 2018 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.

module sync #(
    parameter STAGES = 2,
    parameter ResetValue = 1'b0
)(
    input  clk_i,
    input  rst_ni,
    input  serial_i,
    output serial_o
);

    (* dont_touch = "true" *)
    (* ASYNC_REG = "TRUE" *)
    reg [STAGES-1:0] reg_q;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            reg_q <= {STAGES{ResetValue}};
        else
            reg_q <= {reg_q[STAGES-2:0], serial_i};
    end

    assign serial_o = reg_q[STAGES-1];

endmodule
'''

SYNC_WEDGE_V = r'''// Copyright 2018 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 rewrite of sync_wedge. Clock-gate replaced by an enable flop.

module sync_wedge #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output r_edge_o,
    output f_edge_o,
    output serial_o
);

    wire serial;

    sync #(.STAGES(STAGES)) i_sync (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .serial_i(serial_i),
        .serial_o(serial)
    );

    reg serial_q;
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            serial_q <= 1'b0;
        else if (en_i)
            serial_q <= serial;
    end

    assign serial_o = serial_q;
    assign r_edge_o = serial & ~serial_q;
    assign f_edge_o = ~serial & serial_q;

endmodule
'''


def add_sync_wedge() -> None:
    bench = BENCH / "sync_wedge"
    write_text(bench / "fixed/rtl/sync.v", SYNC_V)
    write_text(bench / "fixed/rtl/sync_wedge.v", SYNC_WEDGE_V)
    write_text(bench / "tb/sync_wedge_tb.v", r'''`timescale 1ns/1ps

module sync_wedge_tb;
    integer errors = 0;
    integer rises = 0, falls = 0;

    reg clk_i = 0, rst_ni = 0, en_i = 1, serial_i = 0;
    wire r_edge_o, f_edge_o, serial_o;
    always #5 clk_i = ~clk_i;

    sync_wedge #(.STAGES(2)) dut (
        .clk_i(clk_i), .rst_ni(rst_ni), .en_i(en_i),
        .serial_i(serial_i), .r_edge_o(r_edge_o), .f_edge_o(f_edge_o),
        .serial_o(serial_o)
    );

    always @(posedge clk_i) begin
        if (rst_ni && r_edge_o) rises = rises + 1;
        if (rst_ni && f_edge_o) falls = falls + 1;
    end

    initial begin
        repeat (3) @(posedge clk_i);
        rst_ni = 1;
        @(negedge clk_i); serial_i = 1;
        repeat (6) @(posedge clk_i);
        @(negedge clk_i); serial_i = 0;
        repeat (6) @(posedge clk_i);
        if (rises != 1 || falls != 1) begin
            $display("FAIL edges rise=%0d fall=%0d", rises, falls);
            errors = errors + 1;
        end
        if (serial_o !== 1'b0) begin
            $display("FAIL serial_o stuck");
            errors = errors + 1;
        end
        if (errors == 0)
            $display("SYNC WEDGE: ALL TESTS PASSED");
        else
            $display("SYNC WEDGE: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("SYNC WEDGE: TIMEOUT");
        $finish;
    end
endmodule
''')
    install({
        "id": "sync_wedge",
        "top": "sync_wedge",
        "source_family": "pulp-platform",
        "upstream": "https://github.com/pulp-platform/common_cells",
        "upstream_commit": PULP_SHA,
        "rtl_names": ["sync_wedge.v", "sync.v"],
        "clocks": ["clk_i"],
        "resets": ["rst_ni"],
        "tb_file": "sync_wedge_tb.v",
        "tb_top": "sync_wedge_tb",
        "objective": "2-flop synchronizer plus rising/falling edge detect on the synced bit.",
        "sdc_note": "SINGLE clock domain. serial_i is an asynchronous data input, not a clock.",
    })


ISO_SPILL_V = r'''// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 flattening of isochronous_spill_register.

module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

    reg [1:0] wr_pointer_q, rd_pointer_q;
    reg [WIDTH-1:0] mem0, mem1;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            wr_pointer_q <= 2'b00;
        else if (src_valid_i && src_ready_o)
            wr_pointer_q <= wr_pointer_q + 2'd1;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            rd_pointer_q <= 2'b00;
        else if (dst_valid_o && dst_ready_i)
            rd_pointer_q <= rd_pointer_q + 2'd1;
    end

    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o) begin
            if (wr_pointer_q[0] == 1'b0)
                mem0 <= src_data_i;
            else
                mem1 <= src_data_i;
        end
    end

    assign src_ready_o = ((rd_pointer_q ^ wr_pointer_q) != 2'b10);
    assign dst_valid_o = ((rd_pointer_q ^ wr_pointer_q) != 2'b00);
    assign dst_data_o  = rd_pointer_q[0] ? mem1 : mem0;

endmodule
'''

ISO_4PHASE_V = r'''// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 flattening of isochronous_4phase_handshake.

module isochronous_4phase_handshake (
    input  src_clk_i,
    input  src_rst_ni,
    input  src_valid_i,
    output src_ready_o,
    input  dst_clk_i,
    input  dst_rst_ni,
    output dst_valid_o,
    input  dst_ready_i
);

    reg src_req_q, src_ack_q;
    reg dst_req_q, dst_ack_q;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_req_q <= 1'b0;
        else if (src_valid_i && src_ready_o)
            src_req_q <= ~src_req_q;
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_ack_q <= 1'b0;
        else
            src_ack_q <= dst_ack_q;
    end

    assign src_ready_o = (src_req_q == src_ack_q);

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_ack_q <= 1'b0;
        else if (dst_valid_o && dst_ready_i)
            dst_ack_q <= ~dst_ack_q;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_req_q <= 1'b0;
        else
            dst_req_q <= src_req_q;
    end

    assign dst_valid_o = (dst_req_q != dst_ack_q);

endmodule
'''


def add_isochronous_spill() -> None:
    bench = BENCH / "isochronous_spill_register"
    write_text(bench / "fixed/rtl/isochronous_spill_register.v", ISO_SPILL_V)
    write_valid_ready_tb(
        bench / "tb/isochronous_spill_register_tb.v",
        tb_top="isochronous_spill_register_tb",
        src_half=5,
        dst_half=10,
        name="isochronous_spill_register",
        banner="ISOCHRONOUS SPILL",
        dut="""isochronous_spill_register #(.WIDTH(8)) dut (
        .src_clk_i(src_clk), .src_rst_ni(src_rst_n),
        .src_valid_i(src_valid), .src_ready_o(src_ready), .src_data_i(src_data),
        .dst_clk_i(dst_clk), .dst_rst_ni(dst_rst_n),
        .dst_valid_o(dst_valid), .dst_ready_i(dst_ready), .dst_data_o(dst_data)
    );""",
    )
    install({
        "id": "isochronous_spill_register",
        "top": "isochronous_spill_register",
        "source_family": "pulp-platform",
        "upstream": "https://github.com/pulp-platform/common_cells",
        "upstream_commit": PULP_SHA,
        "rtl_names": ["isochronous_spill_register.v"],
        "clocks": ["src_clk_i", "dst_clk_i"],
        "resets": ["src_rst_ni", "dst_rst_ni"],
        "tb_file": "isochronous_spill_register_tb.v",
        "tb_top": "isochronous_spill_register_tb",
        "objective": "Two-deep spill register between integer-ratio (isochronous) clocks.",
        "sdc_note": "Isochronous clocks: dst is a generated divide-by-2 of src. No async group.",
        "generated_clock": ("src_clk_i", "dst_clk_i", 2),
    })


def add_isochronous_4phase() -> None:
    bench = BENCH / "isochronous_4phase_handshake"
    write_text(bench / "fixed/rtl/isochronous_4phase_handshake.v", ISO_4PHASE_V)
    write_text(bench / "tb/isochronous_4phase_handshake_tb.v", r'''`timescale 1ns/1ps

module isochronous_4phase_handshake_tb;
    integer errors = 0;
    integer received = 0;

    reg src_clk = 0, dst_clk = 0, src_rst_n = 0, dst_rst_n = 0;
    always #5 src_clk = ~src_clk;
    always #10 dst_clk = ~dst_clk;

    reg src_valid = 0;
    wire src_ready;
    wire dst_valid;
    reg dst_ready = 0;

    isochronous_4phase_handshake dut (
        .src_clk_i(src_clk), .src_rst_ni(src_rst_n),
        .src_valid_i(src_valid), .src_ready_o(src_ready),
        .dst_clk_i(dst_clk), .dst_rst_ni(dst_rst_n),
        .dst_valid_o(dst_valid), .dst_ready_i(dst_ready)
    );

    always @(posedge dst_clk) begin
        if (dst_rst_n && dst_valid && dst_ready)
            received = received + 1;
    end

    integer i;
    initial begin
        repeat (4) @(posedge src_clk); src_rst_n = 1;
        repeat (4) @(posedge dst_clk); dst_rst_n = 1; dst_ready = 1;
        for (i = 0; i < 6; i = i + 1) begin
            @(negedge src_clk);
            while (!src_ready) @(negedge src_clk);
            src_valid = 1;
            @(posedge src_clk);
            @(negedge src_clk);
            src_valid = 0;
        end
        wait (received == 6);
        if (errors == 0)
            $display("ISOCHRONOUS 4PHASE: ALL TESTS PASSED");
        else
            $display("ISOCHRONOUS 4PHASE: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #80000;
        $display("ISOCHRONOUS 4PHASE: TIMEOUT");
        $finish;
    end
endmodule
''')
    install({
        "id": "isochronous_4phase_handshake",
        "top": "isochronous_4phase_handshake",
        "source_family": "pulp-platform",
        "upstream": "https://github.com/pulp-platform/common_cells",
        "upstream_commit": PULP_SHA,
        "rtl_names": ["isochronous_4phase_handshake.v"],
        "clocks": ["src_clk_i", "dst_clk_i"],
        "resets": ["src_rst_ni", "dst_rst_ni"],
        "tb_file": "isochronous_4phase_handshake_tb.v",
        "tb_top": "isochronous_4phase_handshake_tb",
        "objective": "4-phase valid/ready handshake between integer-ratio clocks (no data path).",
        "sdc_note": "Isochronous clocks: dst is a generated divide-by-2 of src. No async group.",
        "generated_clock": ("src_clk_i", "dst_clk_i", 2),
    })


APB_CDC_V = r'''// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 flattening of pulp-platform/apb apb_cdc (no structs).

module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    localparam REQW = ADDR_WIDTH + 3 + 1 + DATA_WIDTH + (DATA_WIDTH/8);
    localparam RSPW = DATA_WIDTH + 1;
    localparam SRC_IDLE = 1'b0;
    localparam SRC_BUSY = 1'b1;
    localparam DST_IDLE = 2'd0;
    localparam DST_ACCESS = 2'd1;
    localparam DST_BUSY = 2'd2;

    wire [REQW-1:0] src_req_data = {src_paddr_i, src_pprot_i, src_pwrite_i, src_pwdata_i, src_pstrb_i};
    wire [REQW-1:0] dst_req_data;
    wire [RSPW-1:0] src_resp_data;
    reg  [RSPW-1:0] dst_resp_data_q;
    wire src_req_ready, src_resp_valid;
    wire dst_req_valid, dst_resp_ready;
    reg src_req_valid, src_resp_ready;
    reg dst_req_ready, dst_resp_valid;
    reg src_state_q, src_pready_q;
    reg [1:0] dst_state_q;
    reg dst_psel_q, dst_penable_q;

    assign {dst_paddr_o, dst_pprot_o, dst_pwrite_o, dst_pwdata_o, dst_pstrb_o} = dst_req_data;
    assign src_prdata_o  = src_resp_data[DATA_WIDTH:1];
    assign src_pslverr_o = src_resp_data[0];
    assign src_pready_o  = src_pready_q;
    assign dst_psel_o    = dst_psel_q;
    assign dst_penable_o = dst_penable_q;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_state_q <= SRC_IDLE;
            src_req_valid <= 1'b0;
            src_resp_ready <= 1'b0;
            src_pready_q <= 1'b0;
        end else begin
            src_req_valid <= 1'b0;
            src_resp_ready <= 1'b0;
            src_pready_q <= 1'b0;
            case (src_state_q)
                SRC_IDLE: begin
                    if (src_psel_i && src_penable_i) begin
                        src_req_valid <= 1'b1;
                        if (src_req_ready)
                            src_state_q <= SRC_BUSY;
                    end
                end
                SRC_BUSY: begin
                    src_resp_ready <= 1'b1;
                    if (src_resp_valid) begin
                        src_pready_q <= 1'b1;
                        src_state_q <= SRC_IDLE;
                    end
                end
                default: src_state_q <= SRC_IDLE;
            endcase
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_state_q <= DST_IDLE;
            dst_req_ready <= 1'b0;
            dst_resp_valid <= 1'b0;
            dst_psel_q <= 1'b0;
            dst_penable_q <= 1'b0;
            dst_resp_data_q <= {RSPW{1'b0}};
        end else begin
            dst_req_ready <= 1'b0;
            dst_resp_valid <= 1'b0;
            dst_psel_q <= 1'b0;
            dst_penable_q <= 1'b0;
            case (dst_state_q)
                DST_IDLE: begin
                    if (dst_req_valid) begin
                        dst_psel_q <= 1'b1;
                        dst_state_q <= DST_ACCESS;
                    end
                end
                DST_ACCESS: begin
                    dst_psel_q <= 1'b1;
                    dst_penable_q <= 1'b1;
                    if (dst_pready_i) begin
                        dst_req_ready <= 1'b1;
                        dst_resp_data_q <= {dst_prdata_i, dst_pslverr_i};
                        dst_state_q <= DST_BUSY;
                    end
                end
                DST_BUSY: begin
                    dst_resp_valid <= 1'b1;
                    if (dst_resp_ready)
                        dst_state_q <= DST_IDLE;
                end
                default: dst_state_q <= DST_IDLE;
            endcase
        end
    end

    cdc_fifo_gray #(.WIDTH(REQW), .LOG_DEPTH(LOG_DEPTH)) i_req (
        .src_rst_ni(src_preset_ni), .src_clk_i(src_pclk_i),
        .src_data_i(src_req_data), .src_valid_i(src_req_valid), .src_ready_o(src_req_ready),
        .dst_rst_ni(dst_preset_ni), .dst_clk_i(dst_pclk_i),
        .dst_data_o(dst_req_data), .dst_valid_o(dst_req_valid), .dst_ready_i(dst_req_ready)
    );

    cdc_fifo_gray #(.WIDTH(RSPW), .LOG_DEPTH(LOG_DEPTH)) i_resp (
        .src_rst_ni(dst_preset_ni), .src_clk_i(dst_pclk_i),
        .src_data_i(dst_resp_data_q), .src_valid_i(dst_resp_valid), .src_ready_o(dst_resp_ready),
        .dst_rst_ni(src_preset_ni), .dst_clk_i(src_pclk_i),
        .dst_data_o(src_resp_data), .dst_valid_o(src_resp_valid), .dst_ready_i(src_resp_ready)
    );

endmodule
'''


def add_apb_cdc() -> None:
    bench = BENCH / "apb_cdc"
    write_text(bench / "fixed/rtl/cdc_fifo_gray.v", CDC_FIFO_GRAY_V)
    write_text(bench / "fixed/rtl/apb_cdc.v", APB_CDC_V)
    write_text(bench / "tb/apb_cdc_tb.v", r'''`timescale 1ns/1ps

module apb_cdc_tb;
    integer errors = 0;

    reg src_pclk = 0, dst_pclk = 0, src_rst_n = 0, dst_rst_n = 0;
    always #5 src_pclk = ~src_pclk;
    always #8 dst_pclk = ~dst_pclk;

    reg src_psel = 0, src_penable = 0, src_pwrite = 0;
    reg [7:0] src_paddr = 0;
    reg [31:0] src_pwdata = 0;
    wire src_pready;
    wire [31:0] src_prdata;
    wire src_pslverr;
    wire dst_psel, dst_penable, dst_pwrite;
    wire [7:0] dst_paddr;
    wire [31:0] dst_pwdata;
    wire dst_pready = 1'b1;
    wire [31:0] dst_prdata;
    wire dst_pslverr = 1'b0;

    reg [31:0] mem [0:15];
    integer i;
    initial for (i = 0; i < 16; i = i + 1) mem[i] = 32'h0;

    always @(posedge dst_pclk) begin
        if (dst_psel && dst_penable && dst_pwrite)
            mem[dst_paddr[5:2]] <= dst_pwdata;
    end
    assign dst_prdata = mem[dst_paddr[5:2]];

    apb_cdc #(.ADDR_WIDTH(8), .DATA_WIDTH(32), .LOG_DEPTH(1)) dut (
        .src_pclk_i(src_pclk), .src_preset_ni(src_rst_n),
        .src_psel_i(src_psel), .src_penable_i(src_penable), .src_pwrite_i(src_pwrite),
        .src_paddr_i(src_paddr), .src_pwdata_i(src_pwdata),
        .src_pstrb_i(4'hF), .src_pprot_i(3'b000),
        .src_pready_o(src_pready), .src_prdata_o(src_prdata), .src_pslverr_o(src_pslverr),
        .dst_pclk_i(dst_pclk), .dst_preset_ni(dst_rst_n),
        .dst_psel_o(dst_psel), .dst_penable_o(dst_penable), .dst_pwrite_o(dst_pwrite),
        .dst_paddr_o(dst_paddr), .dst_pwdata_o(dst_pwdata),
        .dst_pstrb_o(), .dst_pprot_o(),
        .dst_pready_i(dst_pready), .dst_prdata_i(dst_prdata), .dst_pslverr_i(dst_pslverr)
    );

    task apb_write;
        input [7:0] addr;
        input [31:0] data;
        begin
            @(negedge src_pclk);
            src_paddr = addr; src_pwdata = data; src_pwrite = 1; src_psel = 1; src_penable = 0;
            @(negedge src_pclk);
            src_penable = 1;
            while (!src_pready) @(negedge src_pclk);
            src_psel = 0; src_penable = 0; src_pwrite = 0;
        end
    endtask

    task apb_read;
        input [7:0] addr;
        output [31:0] data;
        begin
            @(negedge src_pclk);
            src_paddr = addr; src_pwrite = 0; src_psel = 1; src_penable = 0;
            @(negedge src_pclk);
            src_penable = 1;
            while (!src_pready) @(negedge src_pclk);
            data = src_prdata;
            src_psel = 0; src_penable = 0;
        end
    endtask

    reg [31:0] rdata;
    initial begin
        repeat (4) @(posedge src_pclk); src_rst_n = 1;
        repeat (4) @(posedge dst_pclk); dst_rst_n = 1;
        repeat (4) @(posedge src_pclk);
        apb_write(8'h04, 32'hA5A5_1234);
        apb_read(8'h04, rdata);
        if (rdata !== 32'hA5A5_1234) begin
            $display("FAIL APB CDC readback %h", rdata);
            errors = errors + 1;
        end
        if (src_pslverr !== 1'b0)
            errors = errors + 1;
        if (errors == 0)
            $display("APB CDC: ALL TESTS PASSED");
        else
            $display("APB CDC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #80000;
        $display("APB CDC: TIMEOUT");
        $finish;
    end
endmodule
''')
    install({
        "id": "apb_cdc",
        "top": "apb_cdc",
        "source_family": "pulp-platform",
        "upstream": "https://github.com/pulp-platform/apb",
        "upstream_commit": APB_SHA,
        "rtl_names": ["apb_cdc.v", "cdc_fifo_gray.v"],
        "clocks": ["src_pclk_i", "dst_pclk_i"],
        "resets": ["src_preset_ni", "dst_preset_ni"],
        "tb_file": "apb_cdc_tb.v",
        "tb_top": "apb_cdc_tb",
        "objective": "APB4 clock-domain crossing using gray FIFOs for request and response.",
        "sdc_note": "TWO asynchronous clock domains (src/dst PCLK). Crossing: req/resp FIFOs.",
    })


def add_axil_cdc() -> None:
    bench = BENCH / "axil_cdc"
    for name in ("axil_cdc.v", "axil_cdc_wr.v", "axil_cdc_rd.v"):
        copy_file(CACHE / "verilog-axi" / "rtl" / name, bench / "fixed/rtl" / name)
    write_text(bench / "tb/axil_cdc_tb.v", r'''`timescale 1ns/1ps

module axil_cdc_tb;
    integer errors = 0;

    reg s_clk = 0, m_clk = 0, s_rst = 1, m_rst = 1;
    always #5 s_clk = ~s_clk;
    always #8 m_clk = ~m_clk;

    reg [7:0] s_awaddr = 0, s_araddr = 0;
    reg [31:0] s_wdata = 0;
    reg s_awvalid = 0, s_wvalid = 0, s_bready = 0, s_arvalid = 0, s_rready = 0;
    wire s_awready, s_wready, s_bvalid, s_arready, s_rvalid;
    wire [1:0] s_bresp, s_rresp;
    wire [31:0] s_rdata;

    wire [7:0] m_awaddr, m_araddr;
    wire [31:0] m_wdata, m_rdata;
    wire [3:0] m_wstrb;
    wire [2:0] m_awprot, m_arprot;
    wire m_awvalid, m_awready, m_wvalid, m_wready, m_bvalid, m_bready;
    wire m_arvalid, m_arready, m_rvalid, m_rready;
    wire [1:0] m_bresp, m_rresp;

    reg [31:0] mem [0:15];
    integer i;
    initial for (i = 0; i < 16; i = i + 1) mem[i] = 32'h0;

    assign m_awready = 1'b1;
    assign m_wready = 1'b1;
    assign m_arready = 1'b1;
    assign m_bresp = 2'b00;
    assign m_rresp = 2'b00;
    assign m_rdata = mem[m_araddr[5:2]];

    reg b_pend = 0, r_pend = 0;
    always @(posedge m_clk) begin
        if (m_rst) begin
            b_pend <= 1'b0;
            r_pend <= 1'b0;
        end else begin
            if (m_awvalid && m_wvalid && m_awready && m_wready)
                mem[m_awaddr[5:2]] <= m_wdata;
            if (m_awvalid && m_wvalid && m_awready && m_wready)
                b_pend <= 1'b1;
            else if (m_bvalid && m_bready)
                b_pend <= 1'b0;
            if (m_arvalid && m_arready)
                r_pend <= 1'b1;
            else if (m_rvalid && m_rready)
                r_pend <= 1'b0;
        end
    end
    assign m_bvalid = b_pend;
    assign m_rvalid = r_pend;

    axil_cdc #(.DATA_WIDTH(32), .ADDR_WIDTH(8)) dut (
        .s_clk(s_clk), .s_rst(s_rst),
        .s_axil_awaddr(s_awaddr), .s_axil_awprot(3'b000),
        .s_axil_awvalid(s_awvalid), .s_axil_awready(s_awready),
        .s_axil_wdata(s_wdata), .s_axil_wstrb(4'hF),
        .s_axil_wvalid(s_wvalid), .s_axil_wready(s_wready),
        .s_axil_bresp(s_bresp), .s_axil_bvalid(s_bvalid), .s_axil_bready(s_bready),
        .s_axil_araddr(s_araddr), .s_axil_arprot(3'b000),
        .s_axil_arvalid(s_arvalid), .s_axil_arready(s_arready),
        .s_axil_rdata(s_rdata), .s_axil_rresp(s_rresp),
        .s_axil_rvalid(s_rvalid), .s_axil_rready(s_rready),
        .m_clk(m_clk), .m_rst(m_rst),
        .m_axil_awaddr(m_awaddr), .m_axil_awprot(m_awprot),
        .m_axil_awvalid(m_awvalid), .m_axil_awready(m_awready),
        .m_axil_wdata(m_wdata), .m_axil_wstrb(m_wstrb),
        .m_axil_wvalid(m_wvalid), .m_axil_wready(m_wready),
        .m_axil_bresp(m_bresp), .m_axil_bvalid(m_bvalid), .m_axil_bready(m_bready),
        .m_axil_araddr(m_araddr), .m_axil_arprot(m_arprot),
        .m_axil_arvalid(m_arvalid), .m_axil_arready(m_arready),
        .m_axil_rdata(m_rdata), .m_axil_rresp(m_rresp),
        .m_axil_rvalid(m_rvalid), .m_axil_rready(m_rready)
    );

    initial begin
        repeat (4) @(posedge s_clk); s_rst = 0;
        repeat (4) @(posedge m_clk); m_rst = 0;
        repeat (4) @(posedge s_clk);

        @(negedge s_clk);
        s_awaddr = 8'h08; s_wdata = 32'hDEAD_BEEF;
        s_awvalid = 1; s_wvalid = 1; s_bready = 1;
        while (!(s_awready && s_wready)) @(negedge s_clk);
        @(negedge s_clk);
        s_awvalid = 0; s_wvalid = 0;
        while (!s_bvalid) @(negedge s_clk);
        @(negedge s_clk);
        s_bready = 0;

        @(negedge s_clk);
        s_araddr = 8'h08; s_arvalid = 1; s_rready = 1;
        while (!s_arready) @(negedge s_clk);
        @(negedge s_clk);
        s_arvalid = 0;
        while (!s_rvalid) @(negedge s_clk);
        if (s_rdata !== 32'hDEAD_BEEF) begin
            $display("FAIL AXIL CDC readback %h", s_rdata);
            errors = errors + 1;
        end
        @(negedge s_clk);
        s_rready = 0;

        if (errors == 0)
            $display("AXIL CDC: ALL TESTS PASSED");
        else
            $display("AXIL CDC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #80000;
        $display("AXIL CDC: TIMEOUT");
        $finish;
    end
endmodule
''')
    install({
        "id": "axil_cdc",
        "top": "axil_cdc",
        "source_family": "verilog-axi",
        "upstream": "https://github.com/alexforencich/verilog-axi",
        "upstream_commit": AXI_SHA,
        "rtl_names": ["axil_cdc.v", "axil_cdc_wr.v", "axil_cdc_rd.v"],
        "clocks": ["s_clk", "m_clk"],
        "resets": ["s_rst", "m_rst"],
        "tb_file": "axil_cdc_tb.v",
        "tb_top": "axil_cdc_tb",
        "objective": "AXI4-Lite clock-domain crossing for write and read channels.",
        "sdc_note": "TWO asynchronous clock domains (s_clk / m_clk).",
    })


def add_sync_reset() -> None:
    bench = BENCH / "sync_reset"
    copy_file(CACHE / "verilog-axis" / "rtl" / "sync_reset.v", bench / "fixed/rtl/sync_reset.v")
    write_text(bench / "tb/sync_reset_tb.v", r'''`timescale 1ns/1ps

module sync_reset_tb;
    integer errors = 0;

    reg clk = 0, rst = 1;
    wire out;
    always #5 clk = ~clk;

    sync_reset #(.N(2)) dut (.clk(clk), .rst(rst), .out(out));

    initial begin
        repeat (3) @(posedge clk);
        if (out !== 1'b1) begin
            $display("FAIL reset not asserted");
            errors = errors + 1;
        end
        @(negedge clk); rst = 0;
        repeat (3) @(posedge clk);
        if (out !== 1'b0) begin
            $display("FAIL reset did not release");
            errors = errors + 1;
        end
        if (errors == 0)
            $display("SYNC RESET: ALL TESTS PASSED");
        else
            $display("SYNC RESET: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("SYNC RESET: TIMEOUT");
        $finish;
    end
endmodule
''')
    install({
        "id": "sync_reset",
        "top": "sync_reset",
        "source_family": "verilog-axis",
        "upstream": "https://github.com/alexforencich/verilog-axis",
        "upstream_commit": AXIS_SHA,
        "rtl_names": ["sync_reset.v"],
        "clocks": ["clk"],
        "resets": ["rst"],
        "tb_file": "sync_reset_tb.v",
        "tb_top": "sync_reset_tb",
        "objective": "Active-high async-assert / sync-deassert reset synchronizer.",
        "sdc_note": "SINGLE clock domain. rst is an asynchronous reset input, not a clock.",
    })


DATA_SYNC_V = r'''// Mux-based data synchronizer. Verilog rewrite of tweak_circuits data_sync.vhd.
// Designed by Mitu Raj, Chipmunk Logic.

module data_sync #(
    parameter STAGES = 2,
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    input                  dready_i,
    output reg [DWIDTH-1:0] dout,
    output reg             dready_o
);

    (* ASYNC_REG = "TRUE" *)
    reg [STAGES-1:0] flipflops;
    wire dready_sync = flipflops[STAGES-1];

    always @(posedge clk) begin
        if (!rstn)
            flipflops <= {STAGES{1'b0}};
        else
            flipflops <= {flipflops[STAGES-2:0], dready_i};
    end

    always @(posedge clk) begin
        if (!rstn) begin
            dout <= {DWIDTH{1'b0}};
            dready_o <= 1'b0;
        end else begin
            if (dready_sync)
                dout <= din;
            dready_o <= dready_sync;
        end
    end

endmodule
'''

ARESET_DEASSERT_V = r'''// Async-assert / sync-deassert reset. Verilog rewrite of
// tweak_circuits areset_deassert_sync.vhd. Designed by Mitu Raj.

module areset_deassert_sync #(
    parameter CHAINS = 2,
    parameter RST_POL = 1'b1
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    (* ASYNC_REG = "TRUE" *)
    reg [CHAINS-1:0] flipflops;
    wire rst_assert = (async_rst_i == RST_POL);

    assign sync_rst_o = flipflops[CHAINS-1];

    always @(posedge clk or posedge rst_assert) begin
        if (rst_assert)
            flipflops <= {CHAINS{RST_POL}};
        else
            flipflops <= {flipflops[CHAINS-2:0], ~RST_POL};
    end

endmodule
'''

SYNCHRONIZER_V = r'''// Single-bit multi-flop synchronizer. Verilog rewrite of
// tweak_circuits synchronizer.vhd. Designed by Mitu Raj.

module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);

    (* ASYNC_REG = "TRUE" *)
    reg [STAGES-1:0] flipflops;

    always @(posedge clk) begin
        if (!rstn)
            flipflops <= {STAGES{1'b0}};
        else
            flipflops <= {flipflops[STAGES-2:0], async_sig_i};
    end

    assign sync_sig_o = flipflops[STAGES-1];

endmodule
'''


def add_data_sync() -> None:
    bench = BENCH / "data_sync"
    write_text(bench / "fixed/rtl/data_sync.v", DATA_SYNC_V)
    write_text(bench / "tb/data_sync_tb.v", r'''`timescale 1ns/1ps

module data_sync_tb;
    integer errors = 0;

    reg clk = 0, rstn = 0, dready_i = 0;
    reg [7:0] din = 0;
    wire [7:0] dout;
    wire dready_o;
    always #5 clk = ~clk;

    data_sync #(.STAGES(2), .DWIDTH(8)) dut (
        .clk(clk), .rstn(rstn), .din(din), .dready_i(dready_i),
        .dout(dout), .dready_o(dready_o)
    );

    initial begin
        repeat (3) @(posedge clk); rstn = 1;
        din = 8'h5A; dready_i = 1;
        repeat (4) @(posedge clk);
        if (dready_o !== 1'b1 || dout !== 8'h5A) begin
            $display("FAIL data_sync captured %h ready=%b", dout, dready_o);
            errors = errors + 1;
        end
        dready_i = 0;
        repeat (4) @(posedge clk);
        if (dready_o !== 1'b0) begin
            $display("FAIL data_sync ready stuck");
            errors = errors + 1;
        end
        if (errors == 0)
            $display("DATA SYNC: ALL TESTS PASSED");
        else
            $display("DATA SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("DATA SYNC: TIMEOUT");
        $finish;
    end
endmodule
''')
    install({
        "id": "data_sync",
        "top": "data_sync",
        "source_family": "tweak_circuits",
        "upstream": "https://github.com/iammituraj/tweak_circuits",
        "upstream_commit": TWEAK_SHA,
        "rtl_names": ["data_sync.v"],
        "clocks": ["clk"],
        "resets": ["rstn"],
        "tb_file": "data_sync_tb.v",
        "tb_top": "data_sync_tb",
        "objective": "Ready-bit synchronizer plus mux-capture of a multi-bit data word.",
        "sdc_note": "SINGLE clock domain. din/dready_i are asynchronous data inputs.",
    })


def add_areset_deassert_sync() -> None:
    bench = BENCH / "areset_deassert_sync"
    write_text(bench / "fixed/rtl/areset_deassert_sync.v", ARESET_DEASSERT_V)
    write_text(bench / "tb/areset_deassert_sync_tb.v", r'''`timescale 1ns/1ps

module areset_deassert_sync_tb;
    integer errors = 0;

    reg clk = 0, async_rst_i = 1;
    wire sync_rst_o;
    always #5 clk = ~clk;

    areset_deassert_sync #(.CHAINS(2), .RST_POL(1'b1)) dut (
        .clk(clk), .async_rst_i(async_rst_i), .sync_rst_o(sync_rst_o)
    );

    initial begin
        repeat (3) @(posedge clk);
        if (sync_rst_o !== 1'b1) begin
            $display("FAIL reset not asserted");
            errors = errors + 1;
        end
        @(negedge clk); async_rst_i = 0;
        repeat (4) @(posedge clk);
        if (sync_rst_o !== 1'b0) begin
            $display("FAIL reset did not release");
            errors = errors + 1;
        end
        if (errors == 0)
            $display("ARESET DEASSERT SYNC: ALL TESTS PASSED");
        else
            $display("ARESET DEASSERT SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("ARESET DEASSERT SYNC: TIMEOUT");
        $finish;
    end
endmodule
''')
    install({
        "id": "areset_deassert_sync",
        "top": "areset_deassert_sync",
        "source_family": "tweak_circuits",
        "upstream": "https://github.com/iammituraj/tweak_circuits",
        "upstream_commit": TWEAK_SHA,
        "rtl_names": ["areset_deassert_sync.v"],
        "clocks": ["clk"],
        "resets": ["async_rst_i"],
        "tb_file": "areset_deassert_sync_tb.v",
        "tb_top": "areset_deassert_sync_tb",
        "objective": "Asynchronous reset assertion with synchronized de-assertion.",
        "sdc_note": "SINGLE clock domain. async_rst_i is an RDC, not a second clock.",
    })


def add_synchronizer() -> None:
    bench = BENCH / "synchronizer"
    write_text(bench / "fixed/rtl/synchronizer.v", SYNCHRONIZER_V)
    write_text(bench / "tb/synchronizer_tb.v", r'''`timescale 1ns/1ps

module synchronizer_tb;
    integer errors = 0;

    reg clk = 0, rstn = 0, async_sig_i = 0;
    wire sync_sig_o;
    always #5 clk = ~clk;

    synchronizer #(.STAGES(2)) dut (
        .clk(clk), .rstn(rstn), .async_sig_i(async_sig_i), .sync_sig_o(sync_sig_o)
    );

    initial begin
        repeat (3) @(posedge clk); rstn = 1;
        async_sig_i = 1;
        repeat (3) @(posedge clk);
        if (sync_sig_o !== 1'b1) begin
            $display("FAIL 2-FF did not propagate 1");
            errors = errors + 1;
        end
        async_sig_i = 0;
        repeat (3) @(posedge clk);
        if (sync_sig_o !== 1'b0) begin
            $display("FAIL 2-FF did not propagate 0");
            errors = errors + 1;
        end
        if (errors == 0)
            $display("SYNCHRONIZER: ALL TESTS PASSED");
        else
            $display("SYNCHRONIZER: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("SYNCHRONIZER: TIMEOUT");
        $finish;
    end
endmodule
''')
    install({
        "id": "synchronizer",
        "top": "synchronizer",
        "source_family": "tweak_circuits",
        "upstream": "https://github.com/iammituraj/tweak_circuits",
        "upstream_commit": TWEAK_SHA,
        "rtl_names": ["synchronizer.v"],
        "clocks": ["clk"],
        "resets": ["rstn"],
        "tb_file": "synchronizer_tb.v",
        "tb_top": "synchronizer_tb",
        "objective": "Synchronous-reset multi-flop single-bit synchronizer.",
        "sdc_note": "SINGLE clock domain. async_sig_i is an asynchronous data input.",
    })


def add_afifo() -> None:
    bench = BENCH / "afifo"
    copy_file(CACHE / "wb2axip" / "rtl" / "afifo.v", bench / "fixed/rtl/afifo.v")
    write_text(bench / "tb/afifo_tb.v", r'''`timescale 1ns/1ps

module afifo_tb;
    integer errors = 0;
    integer received = 0;

    reg i_wclk = 0, i_rclk = 0, i_wr_reset_n = 0, i_rd_reset_n = 0;
    always #5 i_wclk = ~i_wclk;
    always #9 i_rclk = ~i_rclk;

    reg i_wr = 0, i_rd = 0;
    reg [7:0] i_wr_data = 0;
    wire o_wr_full, o_rd_empty;
    wire [7:0] o_rd_data;

    afifo #(.LGFIFO(3), .WIDTH(8), .NFF(2), .OPT_REGISTER_READS(1'b1)) dut (
        .i_wclk(i_wclk), .i_wr_reset_n(i_wr_reset_n), .i_wr(i_wr),
        .i_wr_data(i_wr_data), .o_wr_full(o_wr_full),
        .i_rclk(i_rclk), .i_rd_reset_n(i_rd_reset_n), .i_rd(i_rd),
        .o_rd_data(o_rd_data), .o_rd_empty(o_rd_empty)
    );

    integer i;
    initial begin
        repeat (4) @(posedge i_wclk); i_wr_reset_n = 1;
        repeat (4) @(posedge i_rclk); i_rd_reset_n = 1;
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge i_wclk);
            while (o_wr_full) @(negedge i_wclk);
            i_wr_data = i[7:0];
            i_wr = 1;
            @(posedge i_wclk);
            @(negedge i_wclk);
            i_wr = 0;
        end
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge i_rclk);
            while (o_rd_empty) @(negedge i_rclk);
            i_rd = 1;
            @(posedge i_rclk);
            if (o_rd_data !== i[7:0]) begin
                $display("FAIL afifo item=%0d got=%h", i, o_rd_data);
                errors = errors + 1;
            end
            received = received + 1;
            @(negedge i_rclk);
            i_rd = 0;
        end
        if (errors == 0)
            $display("AFIFO: ALL TESTS PASSED");
        else
            $display("AFIFO: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #80000;
        $display("AFIFO: TIMEOUT");
        $finish;
    end
endmodule
''')
    install({
        "id": "afifo",
        "top": "afifo",
        "source_family": "zipcpu-wb2axip",
        "upstream": "https://github.com/ZipCPU/wb2axip",
        "upstream_commit": ZIP_SHA,
        "rtl_names": ["afifo.v"],
        "clocks": ["i_wclk", "i_rclk"],
        "resets": ["i_wr_reset_n", "i_rd_reset_n"],
        "tb_file": "afifo_tb.v",
        "tb_top": "afifo_tb",
        "objective": "ZipCPU gray-pointer asynchronous FIFO.",
        "sdc_note": "TWO asynchronous clock domains (write / read).",
    })


PULSE_SYNC_V = r'''// Handshake pulse synchronizer. Verilog rewrite of tweak_circuits pulse_sync.vhd.
// Designed by Mitu Raj, Chipmunk Logic.

module pulse_sync #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output pulseB_o,
    output busy_o
);

    (* ASYNC_REG = "TRUE" *)
    reg [STAGES-1:0] flipflops_a;
    (* ASYNC_REG = "TRUE" *)
    reg [STAGES-1:0] flipflops_b;
    reg pulseA_regA;
    reg busyB_delayed;
    wire busyB = flipflops_b[STAGES-1];
    wire busyB_syncA = flipflops_a[STAGES-1];

    always @(posedge clk_a) begin
        if (!rstn_a)
            flipflops_a <= {STAGES{1'b0}};
        else
            flipflops_a <= {flipflops_a[STAGES-2:0], busyB};
    end

    always @(posedge clk_a) begin
        if (!rstn_a)
            pulseA_regA <= 1'b0;
        else
            pulseA_regA <= pulseA_i | (pulseA_regA & ~busyB_syncA);
    end

    always @(posedge clk_b) begin
        if (!rstn_b) begin
            flipflops_b <= {STAGES{1'b0}};
            busyB_delayed <= 1'b0;
        end else begin
            flipflops_b <= {flipflops_b[STAGES-2:0], pulseA_regA};
            busyB_delayed <= flipflops_b[STAGES-1];
        end
    end

    assign busy_o = busyB_syncA | pulseA_regA;
    assign pulseB_o = busyB & ~busyB_delayed;

endmodule
'''

ARESET_SYNC_V = r'''// Level reset synchronizer. Verilog rewrite of tweak_circuits areset_sync.vhd.
// Designed by Mitu Raj, Chipmunk Logic.

module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);

    (* ASYNC_REG = "TRUE" *)
    reg [STAGES-1:0] flipflops;

    assign sync_rst_o = flipflops[STAGES-1];

    always @(posedge clk)
        flipflops <= {flipflops[STAGES-2:0], async_rst_i};

endmodule
'''


def convert_existing_vhdl() -> None:
    pulse = BENCH / "pulse_sync"
    write_text(pulse / "fixed/rtl/pulse_sync.v", PULSE_SYNC_V)
    write_text(pulse / "original/rtl/pulse_sync.v", PULSE_SYNC_V)
    for p in (pulse / "fixed/rtl/pulse_sync.vhd", pulse / "original/rtl/pulse_sync.vhd"):
        if p.exists():
            p.unlink()
    man = pulse / "manifest.yaml"
    text = man.read_text(encoding="utf-8")
    text = text.replace("hdl: vhdl", "hdl: verilog-2001")
    text = text.replace("pulse_sync.vhd", "pulse_sync.v")
    man.write_text(text, encoding="utf-8")
    write_text(pulse / "sim/run.sh", run_sh({
        "id": "pulse_sync",
        "tb_top": "pulse_sync_tb",
        "tb_file": "pulse_sync_tb.v",
        "rtl_names": ["pulse_sync.v"],
    }))
    (pulse / "sim/run.sh").chmod(0o755)

    areset = BENCH / "areset_sync"
    write_text(areset / "fixed/rtl/areset_sync.v", ARESET_SYNC_V)
    write_text(areset / "original/rtl/areset_sync.v", ARESET_SYNC_V)
    for p in (areset / "fixed/rtl/areset_sync.vhd", areset / "original/rtl/areset_sync.vhd"):
        if p.exists():
            p.unlink()
    man = areset / "manifest.yaml"
    text = man.read_text(encoding="utf-8")
    text = text.replace("hdl: vhdl", "hdl: verilog-2001")
    text = text.replace("areset_sync.vhd", "areset_sync.v")
    man.write_text(text, encoding="utf-8")
    write_text(areset / "sim/run.sh", run_sh({
        "id": "areset_sync",
        "tb_top": "areset_sync_tb",
        "tb_file": "areset_sync_tb.v",
        "rtl_names": ["areset_sync.v"],
    }))
    (areset / "sim/run.sh").chmod(0o755)


def main() -> None:
    add_cdc_fifo_gray()
    add_cdc_fifo_gray_clearable()
    add_cdc_fifo_2phase()
    add_cdc_reset_ctrlr()
    add_sync_wedge()
    add_isochronous_spill()
    add_isochronous_4phase()
    add_apb_cdc()
    add_axil_cdc()
    add_sync_reset()
    add_data_sync()
    add_areset_deassert_sync()
    add_synchronizer()
    add_afifo()
    convert_existing_vhdl()
    print("packaged 14 Verilog CDC benches and converted pulse_sync/areset_sync")


if __name__ == "__main__":
    main()
