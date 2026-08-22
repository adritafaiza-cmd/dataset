`default_nettype none

// Active-high reset synchronizer: asynchronous assertion and synchronous
// deassertion in the destination clock domain.
module cdc_reset_sync #(
	parameter integer NFF = 2
) (
	input  wire i_clk,
	input  wire i_async_reset,
	output wire o_reset
);
	(* ASYNC_REG = "TRUE" *) reg [NFF-1:0] sync_ff;

	initial sync_ff = {NFF{1'b1}};

	always @(posedge i_clk or posedge i_async_reset)
	if (i_async_reset)
		sync_ff <= {NFF{1'b1}};
	else
		sync_ff <= {sync_ff[NFF-2:0], 1'b0};

	assign o_reset = sync_ff[NFF-1];
endmodule

`default_nettype wire
