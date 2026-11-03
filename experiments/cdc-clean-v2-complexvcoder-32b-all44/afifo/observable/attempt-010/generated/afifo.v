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

	wire	[LGFIFO:0]	wr_gray_count, rd_gray_count;
	wire	[LGFIFO:0]	wr_bin_count, rd_bin_count;
	wire	[LGFIFO-1:0]	wr_addr, rd_addr;
	wire			wr_en;

	gray_counter wr_gray_counter (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.count(wr_gray_count)
	);

	gray_counter rd_gray_counter (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.count(rd_gray_count)
	);

	gray_to_bin wr_gray_to_bin (
		.gray(wr_gray_count),
		.bin(wr_bin_count)
	);

	gray_to_bin rd_gray_to_bin (
		.gray(rd_gray_count),
		.bin(rd_bin_count)
	);

	fifo_status fifo_status_inst (
		.wr_bin_count(wr_bin_count),
		.rd_bin_count(rd_bin_count),
		.reset_n(i_wr_reset_n),
		.o_wr_full(o_wr_full),
		.o_rd_empty(o_rd_empty)
	);

	fifo_memory fifo_mem (
		.clk_w(i_wclk),
		.clk_r(i_rclk),
		.we(wr_en),
		.wa(wr_addr),
		.wd(i_wr_data),
		.ra(rd_addr),
		.rd(o_rd_data)
	);

	assign wr_addr = wr_bin_count[LGFIFO-1:0];
	assign rd_addr = rd_bin_count[LGFIFO-1:0];
	assign wr_en = i_wr & ~o_wr_full;

	// Register read data if OPT_REGISTER_READS is set
	reg [WIDTH-1:0] rd_data_reg;
	generate
		if (OPT_REGISTER_READS) begin : gen_opt_reg
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n)
					rd_data_reg <= {WIDTH{1'b0}};
				else if (i_rd & ~o_rd_empty)
					rd_data_reg <= o_rd_data;
			end
			assign o_rd_data = rd_data_reg;
		end
	endgenerate

endmodule

module gray_counter (
		input	wire			clk,
		input	wire			reset_n,
		output	reg	[LGFIFO:0]	count
	);

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n)
			count <= {LGFIFO+1{1'b0}};
		else
			count <= count + 1;
	end

endmodule

module fifo_memory #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16
	) (
		input	wire			clk_w,
		input	wire			clk_r,
		input	wire			we,
		input	wire	[LGFIFO-1:0]	wa,
		input	wire	[WIDTH-1:0]	wd,
		input	wire	[LGFIFO-1:0]	ra,
		output	reg	[WIDTH-1:0]	rd
	);

	reg [WIDTH-1:0] mem [0:(2**LGFIFO)-1];

	always @(posedge clk_w) begin
		if (we)
			mem[wa] <= wd;
	end

	always @(posedge clk_r) begin
		rd <= mem[ra];
	end

endmodule

module gray_to_bin #(
		parameter	LGFIFO = 3
	) (
		input	wire	[LGFIFO:0]	gray,
		output	reg	[LGFIFO:0]	bin
	);

	integer i;
	always @(*) begin
		bin[LGFIFO] = gray[LGFIFO];
		for (i = LGFIFO-1; i >= 0; i = i - 1)
			bin[i] = bin[i+1] ^ gray[i];
	end

endmodule

module fifo_status #(
		parameter	LGFIFO = 3
	) (
		input	wire	[LGFIFO:0]	wr_bin_count,
		input	wire	[LGFIFO:0]	rd_bin_count,
		input	wire			reset_n,
		output	reg			o_wr_full,
		output	reg			o_rd_empty
	);

	wire [LGFIFO:0] wr_bin_msb, rd_bin_msb;
	assign wr_bin_msb = wr_bin_count[LGFIFO];
	assign rd_bin_msb = rd_bin_count[LGFIFO];

	always @(posedge i_wclk or negedge reset_n) begin
		if (!reset_n)
			o_wr_full <= 1'b0;
		else
			o_wr_full <= (wr_bin_msb != rd_bin_msb) && (wr_bin_count[LGFIFO-1:0] == rd_bin_count[LGFIFO-1:0]);
	end

	always @(posedge i_rclk or negedge reset_n) begin
		if (!reset_n)
			o_rd_empty <= 1'b1;
		else
			o_rd_empty <= (wr_bin_count == rd_bin_count);
	end

endmodule
