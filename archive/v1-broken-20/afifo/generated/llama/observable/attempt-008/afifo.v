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

	reg [WIDTH-1:0]	storage [2**LGFIFO-1:0];
	reg [LGFIFO-1:0]	wr_ptr, rd_ptr;
	reg [LGFIFO:0]	wr_cnt, rd_cnt;
	wire			wr_full, rd_empty;

	assign wr_full = (wr_cnt == (1 << LGFIFO));
	assign rd_empty = (rd_cnt == 0);

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_cnt <= 0;
			o_wr_full <= 1'b0;
		end else if (i_wr && !wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				storage[wr_ptr] <= i_wr_data;
			end
			wr_ptr <= wr_ptr + 1;
			wr_cnt <= wr_cnt + 1;
		end
		if (wr_full) begin
			o_wr_full <= 1'b1;
		end else begin
			o_wr_full <= 1'b0;
		end
	end

	generate
		if (NFF == 2) begin
			reg [LGFIFO-1:0]	wr_ptr_gray, wr_ptr_bin;
			reg [LGFIFO:0]	wr_cnt_gray, wr_cnt_bin;
			always @(posedge i_rclk) begin
				wr_ptr_gray <= wr_ptr;
				wr_cnt_gray <= wr_cnt;
			end
			always @(posedge i_rclk) begin
				wr_ptr_bin <= wr_ptr_gray;
				wr_cnt_bin <= wr_cnt_gray;
			end
			assign rd_ptr <= wr_ptr_bin;
			assign rd_cnt <= wr_cnt_bin;
		end else if (NFF == 1) begin
			reg [LGFIFO-1:0]	wr_ptr_gray;
			reg [LGFIFO:0]	wr_cnt_gray;
			always @(posedge i_rclk) begin
				wr_ptr_gray <= wr_ptr;
				wr_cnt_gray <= wr_cnt;
			end
			assign rd_ptr <= wr_ptr_gray;
			assign rd_cnt <= wr_cnt_gray;
		end else begin
			assign rd_ptr <= wr_ptr;
			assign rd_cnt <= wr_cnt;
		end
	endgenerate

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_cnt <= 0;
			o_rd_empty <= 1'b1;
		end else if (i_rd && !rd_empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= storage[rd_ptr];
			end
			rd_ptr <= rd_ptr + 1;
			rd_cnt <= rd_cnt - 1;
		end
		if (rd_empty) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= 1'b0;
		end
		if (!OPT_REGISTER_READS) begin
			o_rd_data <= storage[rd_ptr];
		end
	end

endmodule
