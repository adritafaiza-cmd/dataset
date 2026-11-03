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

	localparam DEPTH = 1 << LGFIFO;

	reg [WIDTH-1:0] mem [DEPTH-1:0];
	reg [$clog2(DEPTH)-1:0] wptr, rptr;
	reg [$clog2(DEPTH)-1:0] wptr_g, rptr_g;
	reg [NFF-1:0] wff, rff;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr <= 0;
			wff <= 0;
		end else if (i_wr && !o_wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				mem[wptr] <= i_wr_data;
			end
			wptr <= wptr + 1;
			wff <= wff + 1;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr <= 0;
			rff <= 0;
		end else if (i_rd && !o_rd_empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= mem[rptr];
			end
			rptr <= rptr + 1;
			rff <= rff - 1;
		end
	end

	always @(posedge i_wclk) begin
		wptr_g <= wptr;
	end

	always @(posedge i_rclk) begin
		rptr_g <= rptr;
	end

	always @(posedge i_rclk) begin
		o_rd_empty <= (rptr_g == wptr_g) && (rff == 0);
	end

	always @(posedge i_wclk) begin
		o_wr_full <= (wptr == {rptr_g, {LGFIFO{1'b0}}} + 1) && (wff == DEPTH);
	end

	always @(posedge i_rclk) begin
		if (OPT_REGISTER_READS) begin
			o_rd_data <= mem[rptr];
		end else begin
			o_rd_data <= mem[rptr_g];
		end
	end

endmodule
