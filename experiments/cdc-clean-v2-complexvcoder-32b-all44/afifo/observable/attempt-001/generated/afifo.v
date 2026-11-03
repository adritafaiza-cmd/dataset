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

	wire [LGFIFO:0] wr_gray_sync, rd_gray_sync;
	wire [LGFIFO-1:0] wr_bin_count, rd_bin_count;
	wire [LGFIFO:0] wr_gray_count, rd_gray_count;

	gray_counter #(.LGFIFO(LGFIFO)) wr_gray_counter (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.enable(i_wr),
		.bin_count(wr_bin_count),
		.gray_count(wr_gray_count),
		.wr_gray_sync(rd_gray_sync),
		.rd_gray_sync(wr_gray_sync)
	);

	gray_counter #(.LGFIFO(LGFIFO)) rd_gray_counter (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.enable(i_rd),
		.bin_count(rd_bin_count),
		.gray_count(rd_gray_count),
		.wr_gray_sync(wr_gray_sync),
		.rd_gray_sync(rd_gray_sync)
	);

	sync_register #(.WIDTH(LGFIFO+1)) wr_gray_sync_reg (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.data_in(wr_gray_count),
		.data_out(wr_gray_sync)
	);

	sync_register #(.WIDTH(LGFIFO+1)) rd_gray_sync_reg (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.data_in(rd_gray_count),
		.data_out(rd_gray_sync)
	);

	dual_port_ram #(.LGFIFO(LGFIFO), .WIDTH(WIDTH), .NFF(NFF)) fifo_memory (
		.wr_clk(i_wclk),
		.wr_reset_n(i_wr_reset_n),
		.wr_en(i_wr),
		.wr_addr(wr_bin_count),
		.wr_data(i_wr_data),
		.rd_clk(i_rclk),
		.rd_reset_n(i_rd_reset_n),
		.rd_addr(rd_bin_count),
		.rd_data(o_rd_data)
	);

	wire [LGFIFO:0] wr_gray_sync_r, rd_gray_sync_r;
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_gray_sync_r <= {(LGFIFO+1){1'b0}};
		end else begin
			wr_gray_sync_r <= wr_gray_sync;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_gray_sync_r <= {(LGFIFO+1){1'b0}};
		end else begin
			rd_gray_sync_r <= rd_gray_sync;
		end
	end

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= (wr_gray_sync_r == {1'b1, rd_gray_count[LGFIFO-1:0]});
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= (rd_gray_sync_r == {1'b0, wr_gray_count[LGFIFO-1:0]});
		end
	end

	reg [WIDTH-1:0] rd_data_reg;
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_reg <= {WIDTH{1'b0}};
		end else if (OPT_REGISTER_READS && i_rd) begin
			rd_data_reg <= o_rd_data;
		end
	end

	assign o_rd_data = OPT_REGISTER_READS ? rd_data_reg : o_rd_data;

endmodule

module gray_counter #(
		parameter	LGFIFO = 3
	) (
		input	wire			clk,
		input	wire			reset_n,
		input	wire			enable,
		output	reg	[LGFIFO-1:0]	bin_count,
		output	reg	[LGFIFO:0]	gray_count,
		input	wire	[LGFIFO:0]	wr_gray_sync,
		input	wire	[LGFIFO:0]	rd_gray_sync
	);

	wire [LGFIFO:0] gray_next;
	wire [LGFIFO-1:0] bin_next;

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			bin_count <= {(LGFIFO){1'b0}};
		end else if (enable) begin
			bin_count <= bin_next;
		end
	end

	always @(*) begin
		bin_next = bin_count + 1;
		gray_next = {bin_next[LGFIFO-1], bin_next[LGFIFO-1:LGFIFO-1] ^ bin_next[LGFIFO-2:0]};
		gray_count = gray_next;
	end

endmodule

module sync_register #(
		parameter WIDTH = 8
	) (
		input	wire			clk,
		input	wire			reset_n,
		input	wire	[WIDTH-1:0]	data_in,
		output	reg	[WIDTH-1:0]	data_out
	);

	reg [WIDTH-1:0] reg1, reg2;

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			reg1 <= {WIDTH{1'b0}};
			reg2 <= {WIDTH{1'b0}};
			data_out <= {WIDTH{1'b0}};
		end else begin
			reg1 <= data_in;
			reg2 <= reg1;
			data_out <= reg2;
		end
	end

endmodule

module dual_port_ram #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2
	) (
		input	wire			wr_clk,
		input	wire			wr_reset_n,
		input	wire			wr_en,
		input	wire	[LGFIFO-1:0]	wr_addr,
		input	wire	[WIDTH-1:0]	wr_data,
		input	wire			rd_clk,
		input	wire			rd_reset_n,
		input	wire	[LGFIFO-1:0]	rd_addr,
		output	reg	[WIDTH-1:0]	rd_data
	);

	reg [WIDTH-1:0] mem [0:(2**LGFIFO)-1];

	always @(posedge wr_clk or negedge wr_reset_n) begin
		if (!wr_reset_n) begin
			for (integer i = 0; i < 2**LGFIFO; i = i + 1) begin
				mem[i] <= {WIDTH{1'b0}};
			end
		end else if (wr_en) begin
			mem[wr_addr] <= wr_data;
		end
	end

	always @(posedge rd_clk or negedge rd_reset_n) begin
		if (!rd_reset_n) begin
			rd_data <= {WIDTH{1'b0}};
		end else begin
			rd_data <= mem[rd_addr];
		end
	end

endmodule
