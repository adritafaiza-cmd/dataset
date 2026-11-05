//-----------------------------------------------------------------------------
// Copyright 2017 Damien Pretet ThotIP
// Copyright 2018 Julius Baxter
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------------------

`timescale 1 ns / 1 ps
`default_nettype none

module fifomem_dp

    #(
        parameter  DATASIZE     = 8,      // Memory data word width
        parameter  ADDRSIZE     = 4,      // Number of mem address bits
        parameter  FALLTHROUGH  = "TRUE"  // First word fall-through
    ) (
        input  wire                a_clk,
        input  wire                a_rst_n,
        input  wire                a_sample,
        input  wire [DATASIZE-1:0] a_wdata,
        output wire [DATASIZE-1:0] a_rdata,
        output wire                a_hold,
        input  wire [ADDRSIZE-1:0] a_addr,
        input  wire                a_rinc,
        input  wire                a_winc,

        input  wire                b_clk,
        input  wire                b_rst_n,
        input  wire                b_sample,
        input  wire [DATASIZE-1:0] b_wdata,
        output wire [DATASIZE-1:0] b_rdata,
        output wire                b_hold,
        input  wire [ADDRSIZE-1:0] b_addr,
        input  wire                b_rinc,
        input  wire                b_winc
    );

    localparam DEPTH = 1<<ADDRSIZE;
    reg [DATASIZE-1:0] mem_a_to_b [0:DEPTH-1];
    reg [DATASIZE-1:0] mem_b_to_a [0:DEPTH-1];
    reg [DATASIZE-1:0] a_rdata_r;
    reg [DATASIZE-1:0] b_rdata_r;
    reg a_hold_q;
    reg b_hold_q;

    (* ASYNC_REG = "TRUE" *) reg [DATASIZE-1:0] a_payload_meta, a_payload_sync;
    reg [1:0] a_payload_wait;
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_payload_meta <= 0;
            a_payload_sync <= 0;
            a_payload_wait <= 0;
        end else begin
            a_payload_meta <= mem_b_to_a[a_addr];
            a_payload_sync <= a_payload_meta;
            if (!a_hold_q && a_sample) begin
                if (a_payload_wait != 2) a_payload_wait <= a_payload_wait + 1'b1;
            end else a_payload_wait <= 0;
        end
    end
    (* ASYNC_REG = "TRUE" *) reg [DATASIZE-1:0] b_payload_meta, b_payload_sync;
    reg [1:0] b_payload_wait;
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_payload_meta <= 0;
            b_payload_sync <= 0;
            b_payload_wait <= 0;
        end else begin
            b_payload_meta <= mem_a_to_b[b_addr];
            b_payload_sync <= b_payload_meta;
            if (!b_hold_q && b_sample) begin
                if (b_payload_wait != 2) b_payload_wait <= b_payload_wait + 1'b1;
            end else b_payload_wait <= 0;
        end
    end
    // FALLTHROUGH no longer selects a combinational read. Each side
    // samples once while it is the reader, and drops the sample when
    // that read is accepted.
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_rdata_r <= {DATASIZE{1'b0}};
            a_hold_q <= 1'b0;
        end else if (!a_hold_q && a_sample && a_payload_wait == 2) begin
            a_rdata_r <= a_payload_sync;
            a_hold_q <= 1'b1;
        end else if (a_hold_q && a_rinc) begin
            a_hold_q <= 1'b0;
        end
    end

    always @(posedge a_clk) begin
        if (a_winc)
            mem_a_to_b[a_addr] <= a_wdata;
    end

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_rdata_r <= {DATASIZE{1'b0}};
            b_hold_q <= 1'b0;
        end else if (!b_hold_q && b_sample && b_payload_wait == 2) begin
            b_rdata_r <= b_payload_sync;
            b_hold_q <= 1'b1;
        end else if (b_hold_q && b_rinc) begin
            b_hold_q <= 1'b0;
        end
    end

    always @(posedge b_clk) begin
        if (b_winc)
            mem_b_to_a[b_addr] <= b_wdata;
    end

    assign a_rdata = a_rdata_r;
    assign b_rdata = b_rdata_r;
    assign a_hold = a_hold_q;
    assign b_hold = b_hold_q;


endmodule

`resetall
