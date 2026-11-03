// Pointer snapshot, read clock to write clock. Same one-bit
// request protocol as sync_w2r.
`timescale 1 ns / 1 ps
`default_nettype none

module sync_r2w
    #(
    parameter ASIZE = 4
    )(
    input  wire             rclk,
    input  wire             rrst_n,
    input  wire [ASIZE:0]   rptr,
    input  wire             wclk,
    input  wire             wrst_n,
    output reg  [ASIZE:0]   wq2_rptr
    );

    reg             req_q;
    reg [ASIZE:0]   data_q;
    reg [1:0]       ack_sync;
    reg             ack_q;
    reg [1:0]       req_sync;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            req_q    <= 1'b0;
            data_q   <= {ASIZE+1{1'b0}};
            ack_sync <= 2'b00;
        end else begin
            ack_sync <= {ack_sync[0], ack_q};
            if ((req_q == ack_sync[1]) && (rptr != data_q)) begin
                data_q <= rptr;
                req_q  <= ~req_q;
            end
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wq2_rptr <= {ASIZE+1{1'b0}};
            req_sync <= 2'b00;
            ack_q    <= 1'b0;
        end else begin
            req_sync <= {req_sync[0], req_q};
            if (req_sync[1] != ack_q) begin
                wq2_rptr <= data_q;
                ack_q    <= req_sync[1];
            end
        end
    end

endmodule

`resetall
