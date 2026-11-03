// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module async_fifo

    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE" // First word fall-through without latency
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        output wire             wfull,
        output wire             awfull,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             rempty,
        output wire             arempty
    );

    wire [ASIZE-1:0] waddr, raddr;
    wire [ASIZE  :0] wptr, rptr, wq2_rptr, rq2_wptr;
    wire             rempty_raw;
    wire             data_hold;
    wire wrst_n_sync;
    wire rrst_n_sync;

    (* async_reg = "true" *) reg [1:0] wrst_sync_ff;
    (* async_reg = "true" *) reg [1:0] rrst_sync_ff;

    // Asynchronous assertion, synchronous deassertion to wclk
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
           wrst_sync_ff <= 2'b00;
        else
            wrst_sync_ff <= {wrst_sync_ff[0], 1'b1};
    end

    // Asynchronous assertion, synchronous deassertion to rclk
    always @(posedge rclk or negedge rrst_n) begin
       if (!rrst_n)
           rrst_sync_ff <= 2'b00;
       else
          rrst_sync_ff <= {rrst_sync_ff[0], 1'b1};
    end

    assign wrst_n_sync = wrst_sync_ff[1];
    assign rrst_n_sync = rrst_sync_ff[1];

    // The module synchronizing the read point
    // from read to write domain
    sync_r2w
    #(ASIZE)
    sync_r2w (
    .wq2_rptr (wq2_rptr),
    .rptr     (rptr),
    .rclk     (rclk),
    .rrst_n   (rrst_n_sync),
    .wclk     (wclk),
    .wrst_n   (wrst_n_sync)
    );

    // The module synchronizing the write point
    // from write to read domain
    sync_w2r
    #(ASIZE)
    sync_w2r (
    .rq2_wptr (rq2_wptr),
    .wptr     (wptr),
    .wclk     (wclk),
    .wrst_n   (wrst_n_sync),
    .rclk     (rclk),
    .rrst_n   (rrst_n_sync)
    );

    // The module handling the write requests
    wptr_full
    #(ASIZE)
    wptr_full (
    .awfull   (awfull),
    .wfull    (wfull),
    .waddr    (waddr),
    .wptr     (wptr),
    .wq2_rptr (wq2_rptr),
    .winc     (winc),
    .wclk     (wclk),
    .wrst_n   (wrst_n_sync)
    );

    // The DC-RAM
    fifomem
    #(DSIZE, ASIZE, FALLTHROUGH)
    fifomem (
    .rclken (rinc),
    .rclk   (rclk),
    .rrst_n (rrst_n_sync),
    .rdata  (rdata),
    .rempty (rempty_raw),
    .data_hold (data_hold),
    .wdata  (wdata),
    .waddr  (waddr),
    .raddr  (raddr),
    .wclken (winc),
    .wfull  (wfull),
    .wclk   (wclk)
    );

    // The module handling read requests
    rptr_empty
    #(ASIZE)
    rptr_empty (
    .arempty  (arempty),
    .rempty   (rempty_raw),
    .raddr    (raddr),
    .rptr     (rptr),
    .rq2_wptr (rq2_wptr),
    .rinc     (rinc),
    .data_hold (data_hold),
    .rclk     (rclk),
    .rrst_n   (rrst_n_sync)
    );

    assign rempty = rempty_raw | ~data_hold;

endmodule

`resetall
