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
	reg [LGFIFO-1:0]	wr_ptr_sync, rd_ptr_sync;
	reg [LGFIFO-1:0]	wr_ptr_sync_gray, rd_ptr_sync_gray;
	reg [LGFIFO-1:0]	wr_ptr_sync_gray2, rd_ptr_sync_gray2;
	reg [LGFIFO-1:0]	wr_ptr_sync_gray3, rd_ptr_sync_gray3;
	reg [WIDTH-1:0]	data_sync, data_sync2;
	reg			wr_full_sync, wr_full_sync2;
	reg			rd_empty_sync, rd_empty_sync2;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
			o_wr_full <= 0;
		end else if (i_wr &&!o_wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				ram[wr_ptr] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
				wr_ptr_gray <= wr_ptr_gray + 1;
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
			o_rd_empty <= 1;
		end else if (i_rd &&!o_rd_empty) begin
			rd_ptr <= rd_ptr + 1;
			rd_ptr_gray <= rd_ptr_gray + 1;
		end
	end

	always @(posedge i_wclk) begin
		wr_ptr_sync <= wr_ptr;
		wr_ptr_sync_gray <= wr_ptr_gray;
	end

	always @(posedge i_rclk) begin
		rd_ptr_sync <= rd_ptr;
		rd_ptr_sync_gray <= rd_ptr_gray;
	end

	always @(posedge i_wclk) begin
		wr_ptr_sync_gray2 <= wr_ptr_sync_gray;
		wr_ptr_sync_gray3 <= wr_ptr_sync_gray2;
	end

	always @(posedge i_rclk) begin
		rd_ptr_sync_gray2 <= rd_ptr_sync_gray;
		rd_ptr_sync_gray3 <= rd_ptr_sync_gray2;
	end

	always @(posedge i_wclk) begin
		wr_full_sync <= (wr_ptr_sync_gray3 == rd_ptr_sync_gray3 + (2**LGFIFO-1));
		o_wr_full <= wr_full_sync;
	end

	always @(posedge i_rclk) begin
		rd_empty_sync <= (rd_ptr_sync_gray3 == wr_ptr_sync_gray3);
		o_rd_empty <= rd_empty_sync;
	end

	always @(posedge i_rclk) begin
		if (OPT_REGISTER_READS) begin
			if (i_rd &&!o_rd_empty) begin
				o_rd_data <= ram[rd_ptr];
			end
		end else begin
			o_rd_data <= ram[rd_ptr];
		end
	end

endmodule
