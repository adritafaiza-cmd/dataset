// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module wptr_full

	#(
		parameter ADDRSIZE = 4
	)(
		input  wire                wclk,
		input  wire                wrst_n,
		input  wire                winc,
		input  wire [ADDRSIZE  :0] wq2_rptr,
		output reg                 wfull,
		output reg                 awfull,
		output wire [ADDRSIZE-1:0] waddr,
		output reg  [ADDRSIZE  :0] wptr
	);

    reg  [ADDRSIZE:0] wbin;
    wire [ADDRSIZE:0] wbinnext;
    wire              awfull_val, wfull_val;
    localparam [ADDRSIZE:0] DEPTH = {1'b1, {ADDRSIZE{1'b0}}};
    localparam [ADDRSIZE:0] ALMOST = DEPTH - 1'b1;

	// Binary pointer. It advances only on an accepted write. The
	// value that crosses is a snapshot of this register.
	always @(posedge wclk or negedge wrst_n) begin

		if (!wrst_n)
			{wbin, wptr} <= 0;
		else
			{wbin, wptr} <= {wbinnext, wbinnext};

	end

    assign waddr = wbin[ADDRSIZE-1:0];
    assign wbinnext  = wbin + ((winc & ~wfull) ? 1 : 0);

     assign wfull_val = (wbinnext == {~wq2_rptr[ADDRSIZE], wq2_rptr[ADDRSIZE-1:0]});
     assign awfull_val = ((wbinnext - wq2_rptr) == ALMOST);

     always @(posedge wclk or negedge wrst_n) begin

        if (!wrst_n) begin
            awfull <= 1'b0;
            wfull  <= 1'b0;
        end else begin
            awfull <= awfull_val;
            wfull  <= wfull_val;
        end
    end

endmodule

`resetall
