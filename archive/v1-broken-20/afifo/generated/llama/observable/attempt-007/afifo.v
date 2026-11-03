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

	localparam	DEPTH = 1 << LGFIFO;

	reg	[WIDTH-1:0]	ram[DEPTH-1:0];
	reg	[LGFIFO-1:0]	wr_ptr, rd_ptr;
	reg	[LGFIFO-1:0]	wr_ptr_gray, rd_ptr_gray;
	reg	[LGFIFO-1:0]	wr_ptr_gray_sync;
	reg			wr_full, rd_empty;
	reg			wr_full_sync;
	reg	[WIDTH-1:0]	data_out;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
			wr_full <= 0;
		end else if (i_wr &&!wr_full) begin
			ram[wr_ptr] <= i_wr_data;
			wr_ptr <= wr_ptr + 1;
			wr_ptr_gray <= wr_ptr_gray + 1;
			if (wr_ptr == DEPTH - 1) begin
				wr_full <= 1;
			end
		end
	end

	always @(posedge i_wclk) begin
		wr_ptr_gray <= {wr_ptr_gray[LGFIFO-2:0], wr_ptr[0]};
	end

	generate
		for (genvar i = 0; i < NFF; i = i + 1) begin : sync_wptr
			always @(posedge i_rclk) begin
				if (i == 0) begin
					wr_ptr_gray_sync <= wr_ptr_gray;
				end else begin
					wr_ptr_gray_sync <= wr_ptr_gray_sync;
				end
			end
		end
	endgenerate

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
			rd_empty <= 1;
			o_rd_empty <= 1;
		end else if (i_rd &&!rd_empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= ram[rd_ptr];
			end
			rd_ptr <= rd_ptr + 1;
			rd_ptr_gray <= rd_ptr_gray + 1;
			if (rd_ptr == DEPTH - 1) begin
				rd_empty <= 1;
			end
		end
	end

	always @(posedge i_rclk) begin
		rd_ptr_gray <= {rd_ptr_gray[LGFIFO-2:0], rd_ptr[0]};
	end

	always @(posedge i_rclk) begin
		if (!i_rd_reset_n) begin
			wr_full_sync <= 0;
		end else begin
			wr_full_sync <= wr_full;
		end
	end

	always @(posedge i_rclk) begin
		if (!i_rd_reset_n) begin
			o_wr_full <= 0;
		end else begin
			o_wr_full <= wr_full_sync;
		end
	end

	always @(posedge i_rclk) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1;
		end else if (rd_ptr_gray == wr_ptr_gray_sync) begin
			if (wr_full_sync) begin
				o_rd_empty <= 0;
			end else begin
				o_rd_empty <= 1;
			end
		end
	end

	always @(posedge i_rclk) begin
		if (OPT_REGISTER_READS) begin
			data_out <= o_rd_data;
		end else begin
			data_out <= ram[rd_ptr];
		end
	end

	assign o_rd_data = data_out;

endmodule
