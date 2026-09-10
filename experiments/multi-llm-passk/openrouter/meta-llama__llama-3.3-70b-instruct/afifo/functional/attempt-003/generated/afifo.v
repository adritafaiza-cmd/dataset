module afifo #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2,
		parameter [0:0]	WRITE_ON_POSEDGE = 1'b1,
		parameter [0:0]	OPT_REGISTER_READS = 1'b1
	) (
		input	wire			i_wclk, i_wr_reset_n, i_wr,
		input	wire	[WIDTH-1:0]	i_wr_data,
		output	reg			o_wr_full,
		input	wire			i_rclk, i_rd_reset_n, i_rd,
		output	reg	[WIDTH-1:0]	o_rd_data,
		output	reg			o_rd_empty
	);

	reg [WIDTH-1:0] fifo [2**LGFIFO-1:0];
	reg [LGFIFO-1:0] wptr, rptr;
	reg [LGFIFO:0] wcnt, rcnt;
	wire wfull, wempty, rfull, rempty;

	assign wfull = (wcnt == (1 << LGFIFO));
	assign wempty = (wcnt == 0);
	assign rfull = (rcnt == (1 << LGFIFO));
	assign rempty = (rcnt == 0);

	assign o_wr_full = wfull;
	assign o_rd_empty = rempty;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr <= 0;
			wcnt <= 0;
		end else if (i_wr && !wfull) begin
			if (WRITE_ON_POSEDGE) begin
				fifo[wptr] <= i_wr_data;
				wptr <= wptr + 1;
				wcnt <= wcnt + 1;
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr <= 0;
			rcnt <= 0;
		end else if (i_rd && !rempty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= fifo[rptr];
			end
			rptr <= rptr + 1;
			rcnt <= rcnt + 1;
		end
	end

	always @(posedge i_rclk) begin
		if (OPT_REGISTER_READS) begin
			if (rempty) begin
				o_rd_data <= 0;
			end
		end else begin
			o_rd_data <= fifo[rptr];
		end
	end

endmodule
