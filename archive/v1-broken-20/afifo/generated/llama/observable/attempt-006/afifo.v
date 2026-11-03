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
	reg [LGFIFO-1:0]	wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray;
	reg [LGFIFO:0]	wr_cnt, rd_cnt;
	wire			wr_full, rd_empty;
	wire			wr_clk, rd_clk;

	assign wr_clk = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;
	assign rd_clk = i_rclk;

	always @(posedge wr_clk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_cnt <= 0;
		end else if (i_wr && !wr_full) begin
			ram[wr_ptr] <= i_wr_data;
			wr_ptr <= wr_ptr + 1;
			wr_cnt <= wr_cnt + 1;
		end
	end

	always @(posedge rd_clk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_cnt <= 0;
		end else if (i_rd && !rd_empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= ram[rd_ptr];
			end
			rd_ptr <= rd_ptr + 1;
			rd_cnt <= rd_cnt - 1;
		end
	end

	always @(posedge wr_clk) begin
		wr_ptr_gray <= wr_ptr;
	end

	always @(posedge rd_clk) begin
		rd_ptr_gray <= rd_ptr;
	end

	assign wr_full = (wr_cnt == 2**LGFIFO);
	assign rd_empty = (rd_cnt == 0);

	always @(posedge wr_clk) begin
		o_wr_full <= wr_full;
	end

	always @(posedge rd_clk) begin
		if (OPT_REGISTER_READS) begin
			o_rd_empty <= rd_empty;
		end else begin
			o_rd_empty <= rd_empty || (rd_cnt == 1 && rd_ptr == rd_ptr_gray);
		end
	end

	generate
		genvar i;
		for (i = 0; i < NFF; i = i + 1) begin : gray_ff
			reg [LGFIFO-1:0] ff;
			always @(posedge i_rclk) begin
				ff <= wr_ptr_gray;
			end
			assign wr_ptr_gray = (i == 0) ? wr_ptr : ff;
		end
	endgenerate

	generate
		genvar i;
		for (i = 0; i < NFF; i = i + 1) begin : gray_ff2
			reg [LGFIFO-1:0] ff;
			always @(posedge i_wclk) begin
				ff <= rd_ptr_gray;
			end
			assign rd_ptr_gray = (i == 0) ? rd_ptr : ff;
		end
	endgenerate

endmodule
