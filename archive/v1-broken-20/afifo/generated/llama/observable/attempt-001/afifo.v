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

	reg [WIDTH-1:0]	ram[2**LGFIFO-1:0];
	reg [LGFIFO-1:0]	wr_ptr, rd_ptr;
	reg [LGFIFO-1:0]	wr_ptr_gray, rd_ptr_gray;
	reg [LGFIFO-1:0]	wr_ptr_gray_sync, rd_ptr_gray_sync;
	reg			wr_full, rd_empty;
	reg			wr_full_sync, rd_empty_sync;

	always @(posedge i_wclk or negedge i_wr_reset_n)
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
			wr_full <= 0;
		end else if (i_wr &&!wr_full) begin
			ram[wr_ptr] <= i_wr_data;
			wr_ptr <= wr_ptr + 1;
			wr_ptr_gray <= wr_ptr_gray + 1;
			if (wr_ptr == 2**LGFIFO-1) wr_full <= 1;
		end

	always @(posedge i_rclk or negedge i_rd_reset_n)
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
			rd_empty <= 1;
		end else if (i_rd &&!rd_empty) begin
			rd_ptr <= rd_ptr + 1;
			rd_ptr_gray <= rd_ptr_gray + 1;
			if (rd_ptr == 2**LGFIFO-1) rd_empty <= 1;
		end

	always @(posedge i_wclk)
		wr_ptr_gray_sync <= wr_ptr_gray;

	always @(posedge i_rclk)
		rd_ptr_gray_sync <= rd_ptr_gray;

	always @(posedge i_rclk)
		if (rd_ptr_gray_sync == wr_ptr_gray_sync) rd_empty_sync <= 1;
		else rd_empty_sync <= 0;

	always @(posedge i_wclk)
		if (wr_ptr_gray == 2**LGFIFO-1) wr_full_sync <= 1;
		else wr_full_sync <= 0;

	always @(posedge i_rclk)
		if (OPT_REGISTER_READS) begin
			if (i_rd &&!rd_empty_sync) o_rd_data <= ram[rd_ptr];
		end else begin
			o_rd_data <= ram[rd_ptr];
		end

	assign o_wr_full = wr_full_sync;
	assign o_rd_empty = rd_empty_sync;

endmodule
