Sure, here is the complete Verilog code for the two-domain isolate-then-clear reset controller:

```
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

    // Internal signals
    reg [SYNC_STAGES-1:0] a_clear_sync;
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;
    reg [SYNC_STAGES-1:0] b_isolate_sync;

    // Clear and isolate signals
    reg a_clear_active;
    reg a_isolate_active;
    reg b_clear_active;
    reg b_isolate_active;

    // Synchronization stages
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_sync <= {SYNC_STAGES{1'b0}};
            a_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_i};
            a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_i};
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_sync <= {SYNC_STAGES{1'b0}};
            b_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], b_clear_i};
            b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_i};
        end
    end

    // Clear and isolate control
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_active <= 1'b0;
            a_isolate_active <= 1'b0;
        end else begin
            if (a_clear_i && !a_clear_active && a_isolate_ack_i && !a_isolate_active) begin
                a_clear_active <= 1'b1;
                a_isolate_active <= 1'b1;
            end else if (a_clear_ack_i && a_clear_active) begin
                a_clear_active <= 1'b0;
            end else if (a_isolate_ack_i && a_isolate_active) begin
                a_isolate_active <= 1'b0;
            end
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_active <= 1'b0;
            b_isolate_active <= 1'b0;
        end else begin
            if (b_clear_i && !b_clear_active && b_isolate_ack_i && !b_isolate_active) begin
                b_clear_active <= 1'b1;
                b_isolate_active <= 1'b1;
            end else if (b_clear_ack_i && b_clear_active) begin
                b_clear_active <= 1'b0;
            end else if (b_isolate_ack_i && b_isolate_active) begin
                b_isolate_active <= 1'b0;
            end
        end
    end

    // Output assignments
    assign a_clear_o = a_clear_sync[SYNC_STAGES-1];
    assign a_isolate_o = a_isolate_sync[SYNC_STAGES-1];
    assign b_clear_o = b_clear_sync[SYNC_STAGES-1];
    assign b_isolate_o = b_isolate_sync[SYNC_STAGES-1];

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>// SPDX-License-Identifier: Apache-2.0
// Copyright 2020 Western Digital Corporation or its affiliates.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//********************************************************************************
// $Id$
//
// Owner:
// Function: Top level file for RISC-V RV32IMC processor
// Comments:
//
//********************************************************************************

module top();

   // instantiate the core
   riscv_core
     #(
       .RV32E(1'b0),
       .RV32M(1'b1),
       .RV32B(1'b0),
       .RV32I(1'b1),
       .RV32C(1'b1),
       .RV32A(1'b0),
       .RV32F(1'b0),
       .RV32D(1'b0),
       .XLEN(32),
       .FLEN(32),
       .ILEN(32),
       .SLEN(32),
       .IMEM_DEPTH(1024),
       .IMEM_DEPTH_LOG2(10),
       .IMEM_BYTE_SIZE(4096),
       .IMEM_BYTE_SIZE_LOG2(12),
       .IMEM_ADDR_WIDTH(12),
       .IMEM_ADDR_WIDTH_LOG2(4),
       .IMEM_DATA_WIDTH(32),
       .IMEM_DATA_WIDTH_LOG2(5),
       .IMEM_INIT_FILE(""),
       .DMEM_DEPTH(1024),
       .DMEM_DEPTH_LOG2(10),
       .DMEM_BYTE_SIZE(4096),
       .DMEM_BYTE_SIZE_LOG2(12),
       .DMEM_ADDR_WIDTH(12),
       .DMEM_ADDR_WIDTH_LOG2(4),
       .DMEM_DATA_WIDTH(32),
       .DMEM_DATA_WIDTH_LOG2(5),
       .DMEM_INIT_FILE(""),
       .HAS_USER(1'b0),
       .HAS_SUPER(1'b0),
       .HAS_HYPER(1'b0),
       .HAS_BPU(1'b0),
       .HAS_FPU(1'b0),
       .HAS_MMU(1'b0),
       .HAS_RVA(1'b0),
       .HAS_RVM(1'b0),
       .HAS_RVC(1'b0),
       .HAS_RVM_PLUS(1'b0),
       .HAS_RVC_PLUS(1'b0),
       .HAS_RV32B(1'b0),
       .HAS_RV32B2(1'b0),
       .HAS_RV32B2AL(1'b0),
       .HAS_RV32B2ALSP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(1'b0),
       .HAS_RV32B2SP(