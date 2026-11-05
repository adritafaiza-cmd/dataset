// Pointer snapshot, write clock to read clock. One synchronized
// request bit. The binary pointer is captured in the read clock
// when that request changes, so the full and empty compares do not
// reconverge a synchronized Gray bus.
`timescale 1 ns / 1 ps
`default_nettype none

module sync_w2r
    #(
    parameter ASIZE = 4
    )(
    input  wire             wclk,
    input  wire             wrst_n,
    input  wire [ASIZE:0]   wptr,
    input  wire             rclk,
    input  wire             rrst_n,
    output reg  [ASIZE:0]   rq2_wptr
    );

    reg             req_q;
    reg [ASIZE:0]   data_q;
    reg [1:0]       ack_sync;
    reg             ack_q;
    reg [1:0]       req_sync;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            req_q    <= 1'b0;
            data_q   <= {ASIZE+1{1'b0}};
            ack_sync <= 2'b00;
        end else begin
            ack_sync <= {ack_sync[0], ack_q};
            if ((req_q == ack_sync[1]) && (wptr != data_q)) begin
                data_q <= wptr;
                req_q  <= ~req_q;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rq2_wptr <= {ASIZE+1{1'b0}};
            req_sync <= 2'b00;
            ack_q    <= 1'b0;
        end else begin
            req_sync <= {req_sync[0], req_q};
            if (req_sync[1] != ack_q) begin
                rq2_wptr <= data_q;
                ack_q    <= req_sync[1];
            end
        end
    end

endmodule

`resetall
