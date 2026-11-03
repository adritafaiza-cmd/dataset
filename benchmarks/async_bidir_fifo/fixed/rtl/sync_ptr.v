// Pointer snapshot across one clock boundary. One synchronized
// request bit. The binary pointer is captured in the destination
// clock when that request changes.
`timescale 1 ns / 1 ps
`default_nettype none

module sync_ptr
    #(
    parameter ASIZE = 4
    )(
    input  wire             src_clk,
    input  wire             src_rst_n,
    input  wire [ASIZE:0]   src_ptr,
    input  wire             dest_clk,
    input  wire             dest_rst_n,
    output reg  [ASIZE:0]   dest_ptr
    );

    reg             req_q;
    reg [ASIZE:0]   data_q;
    reg [1:0]       ack_sync;
    reg             ack_q;
    reg [1:0]       req_sync;

    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            req_q    <= 1'b0;
            data_q   <= {ASIZE+1{1'b0}};
            ack_sync <= 2'b00;
        end else begin
            ack_sync <= {ack_sync[0], ack_q};
            if ((req_q == ack_sync[1]) && (src_ptr != data_q)) begin
                data_q <= src_ptr;
                req_q  <= ~req_q;
            end
        end
    end

    always @(posedge dest_clk or negedge dest_rst_n) begin
        if (!dest_rst_n) begin
            dest_ptr <= {ASIZE+1{1'b0}};
            req_sync <= 2'b00;
            ack_q    <= 1'b0;
        end else begin
            req_sync <= {req_sync[0], req_q};
            if (req_sync[1] != ack_q) begin
                dest_ptr <= data_q;
                ack_q    <= req_sync[1];
            end
        end
    end

endmodule

`resetall
