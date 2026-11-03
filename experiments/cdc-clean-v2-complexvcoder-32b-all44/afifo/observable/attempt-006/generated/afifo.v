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

	localparam DEPTH = 2**LGFIFO;

	wire [LGFIFO:0] wr_gray, rd_gray, wr_gray_sync, rd_gray_sync;
	wire [LGFIFO-1:0] wr_addr, rd_addr;
	wire mem_wr_en;

	gray_counter #(.LGFIFO(LGFIFO))
		gray_counter_wr (
			.i_clk(i_wclk),
			.i_reset_n(i_wr_reset_n),
			.i_gray_sync(rd_gray_sync),
			.o_gray(wr_gray),
			.o_addr(wr_addr)
		);

	gray_counter #(.LGFIFO(LGFIFO))
		gray_counter_rd (
			.i_clk(i_rclk),
			.i_reset_n(i_rd_reset_n),
			.i_gray_sync(wr_gray_sync),
			.o_gray(rd_gray),
			.o_addr(rd_addr)
		);

	sync_register #(.LGFIFO(LGFIFO))
		sync_wr_gray (
			.i_clk(i_rclk),
			.i_d(wr_gray),
			.o_q(wr_gray_sync)
		);

	sync_register #(.LGFIFO(LGFIFO))
		sync_rd_gray (
			.i_clk(i_wclk),
			.i_d(rd_gray),
			.o_q(rd_gray_sync)
		);

	memory #(.LGFIFO(LGFIFO), .WIDTH(WIDTH))
		mem (
			.i_clk(i_wclk),
			.i_wr_data(i_wr_data),
			.i_wr_addr(wr_addr),
			.i_wr_en(mem_wr_en),
			.i_rd_addr(rd_addr),
			.o_rd_data(o_rd_data)
		);

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= (wr_gray_sync[LGFIFO:LGFIFO-1] == rd_gray[LGFIFO:LGFIFO-1]) && (wr_gray_sync[LGFIFO-1:0] == rd_gray[LGFIFO-1:0] + 1);
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= (wr_gray_sync[LGFIFO:LGFIFO-1] == rd_gray[LGFIFO:LGFIFO-1]) && (wr_gray_sync[LGFIFO-1:0] == rd_gray[LGFIFO-1:0]);
		end
	end

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			mem_wr_en <= 1'b0;
		end else if (WRITE_ON_POSEDGE) begin
			mem_wr_en <= i_wr && !o_wr_full;
		end else begin
			mem_wr_en <= ~i_wr && !o_wr_full;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= 0;
		end else if (OPT_REGISTER_READS) begin
			o_rd_data <= mem.o_rd_data;
		end
	end

endmodule

module gray_counter #(
		parameter	LGFIFO = 3
	) (
		input	wire	i_clk, i_reset_n,
		input	wire	[LGFIFO:0]	i_gray_sync,
		output	wire	[LGFIFO:0]	o_gray,
		output	wire	[LGFIFO-1:0]	o_addr
	);

	reg [LGFIFO:0] gray;
	reg [LGFIFO-1:0] addr;

	always @(posedge i_clk or negedge i_reset_n) begin
		if (!i_reset_n) begin
			gray <= 0;
			addr <= 0;
		end else begin
			if (gray[LGFIFO:LGFIFO-1] != i_gray_sync[LGFIFO:LGFIFO-1]) begin
				gray <= gray + 1;
				addr <= gray[LGFIFO-1:0] + 1;
			end
		end
	end

	assign o_gray = gray;
	assign o_addr = addr;

endmodule

module sync_register #(
		parameter	LGFIFO = 3
	) (
		input	wire	i_clk,
		input	wire	[LGFIFO:0]	i_d,
		output	wire	[LGFIFO:0]	o_q
	);

	reg [LGFIFO:0] q_reg1, q_reg2;

	always @(posedge i_clk) begin
		q_reg1 <= i_d;
		q_reg2 <= q_reg1;
	end

	assign o_q = q_reg2;

endmodule

module memory #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16
	) (
		input	wire	i_clk,
		input	wire	[WIDTH-1:0]	i_wr_data,
		input	wire	[LGFIFO-1:0]	i_wr_addr,
		input	wire	i_wr_en,
		input	wire	[LGFIFO-1:0]	i_rd_addr,
		output	wire	[WIDTH-1:0]	o_rd_data
	);

	reg [WIDTH-1:0] mem_array [0:2**LGFIFO-1];

	always @(posedge i_clk) begin
		if (i_wr_en) begin
			mem_array[i_wr_addr] <= i_wr_data;
		end
	end

	assign o_rd_data = mem_array[i_rd_addr];

endmodule
