// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module fifomem

    #(
        parameter  DATASIZE = 8,    // Memory data word width
        parameter  ADDRSIZE = 4,    // Number of mem address bits
        parameter  FALLTHROUGH = "TRUE" // First word fall-through
    ) (
        input  wire                wclk,
        input  wire                wclken,
        input  wire [ADDRSIZE-1:0] waddr,
        input  wire [DATASIZE-1:0] wdata,
        input  wire                wfull,
        input  wire                rclk,
        input  wire                rrst_n,
        input  wire                rclken,
        input  wire [ADDRSIZE-1:0] raddr,
        input  wire                rempty,
        output wire                data_hold,
        output wire [DATASIZE-1:0] rdata
    );

    localparam DEPTH = 1<<ADDRSIZE;

    reg [DATASIZE-1:0] mem [0:DEPTH-1];
    reg [DATASIZE-1:0] rdata_r;
    reg                hold_q;

    (* ASYNC_REG = "TRUE" *) reg [DATASIZE-1:0] payload_meta_q, payload_sync_q;
    reg [1:0] sample_wait_q;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            payload_meta_q <= {DATASIZE{1'b0}};
            payload_sync_q <= {DATASIZE{1'b0}};
        end else begin
            payload_meta_q <= mem[raddr];
            payload_sync_q <= payload_meta_q;
        end
    end

    always @(posedge wclk) begin
        if (wclken && !wfull)
            mem[waddr] <= wdata;
    end

    // One sample of the addressed word. FALLTHROUGH still presents
    // that word when the public empty flag falls. Between words the
    // hold drops for one read clock.
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_r <= {DATASIZE{1'b0}};
            hold_q  <= 1'b0;
            sample_wait_q <= 0;
        end else if (!hold_q && !rempty) begin
            if (sample_wait_q == 2) begin
            rdata_r <= payload_sync_q;
            hold_q  <= 1'b1;
            sample_wait_q <= 0;
            end else sample_wait_q <= sample_wait_q + 1'b1;
        end else if (hold_q && rclken) begin
            hold_q  <= 1'b0;
            sample_wait_q <= 0;
        end else sample_wait_q <= 0;
    end

    assign data_hold = hold_q;
    assign rdata = rdata_r;

endmodule

`resetall
