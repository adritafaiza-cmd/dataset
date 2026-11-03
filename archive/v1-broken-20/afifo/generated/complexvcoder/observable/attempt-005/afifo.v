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

	// Internal signals for FIFO core
	wire [WIDTH-1:0] wr_data_reg;
	wire wr_full_reg;
	wire rd_empty_reg;
	wire [WIDTH-1:0] rd_data_reg;

	// FIFO core instance
	fifo_core #(
		.LGFIFO(LGFIFO),
		.WIDTH(WIDTH),
		.NFF(NFF)
	) fifo_core_inst (
		.i_clk(i_wclk),
		.i_reset_n(i_wr_reset_n),
		.i_wr(i_wr),
		.i_wr_data(i_wr_data),
		.o_wr_full(wr_full_reg),
		.i_clk(i_rclk),
		.i_reset_n(i_rd_reset_n),
		.i_rd(i_rd),
		.o_rd_data(rd_data_reg),
		.o_rd_empty(rd_empty_reg)
	);

	// Output assignment for write full flag
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= wr_full_reg;
		end
	end

	// Output assignment for read empty flag
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= rd_empty_reg;
		end
	end

	// Output assignment for read data
	if (OPT_REGISTER_READS) begin
		always @(posedge i_rclk or negedge i_rd_reset_n) begin
			if (!i_rd_reset_n) begin
				o_rd_data <= {WIDTH{1'b0}};
			end else begin
				o_rd_data <= rd_data_reg;
			end
		end
	end else begin
		o_rd_data <= rd_data_reg;
	end

endmodule
