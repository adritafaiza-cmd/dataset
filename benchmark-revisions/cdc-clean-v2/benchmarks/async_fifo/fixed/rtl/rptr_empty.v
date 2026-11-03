// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module rptr_empty

    #(
    parameter ADDRSIZE = 4
    )(
    input  wire                rclk,
    input  wire                rrst_n,
    input  wire                rinc,
    input  wire                data_hold,
    input  wire [ADDRSIZE  :0] rq2_wptr,
    output reg                 rempty,
    output reg                 arempty,
    output wire [ADDRSIZE-1:0] raddr,
    output reg  [ADDRSIZE  :0] rptr
    );

    reg  [ADDRSIZE:0] rbin;
    wire [ADDRSIZE:0] rbinnext;
    wire              arempty_val, rempty_val;

    // Binary pointer. It advances only when a held read word is accepted.
    always @(posedge rclk or negedge rrst_n) begin

        if (!rrst_n)
            {rbin, rptr} <= 0;
        else
            {rbin, rptr} <= {rbinnext, rbinnext};

    end

    assign raddr     = rbin[ADDRSIZE-1:0];
    assign rbinnext  = rbin + ((rinc & data_hold & ~rempty) ? 1 : 0);

    assign rempty_val = (rbinnext == rq2_wptr);
    assign arempty_val = ((rq2_wptr - rbinnext) == {{ADDRSIZE{1'b0}}, 1'b1});

    always @ (posedge rclk or negedge rrst_n) begin

        if (!rrst_n) begin
            arempty <= 1'b0;
            rempty <= 1'b1;
        end
        else begin
            arempty <= arempty_val;
            rempty <= rempty_val;
        end

    end

endmodule

`resetall
