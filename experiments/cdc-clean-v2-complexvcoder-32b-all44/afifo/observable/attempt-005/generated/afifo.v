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

	wire [LGFIFO:0] wr_gray, rd_gray;
	wire [LGFIFO:0] wr_bin, rd_bin;
	wire [LGFIFO:0] synced_wr_gray, synced_rd_gray;
	wire full_raw, empty_raw;
	wire [LGFIFO:0] wr_ptr_gray_synced, rd_ptr_gray_synced;
	wire [LGFIFO:0] wr_ptr_bin_synced, rd_ptr_bin_synced;
	wire wr_edge, rd_edge;
	reg [LGFIFO:0] wr_gray_reg, rd_gray_reg;
	reg [WIDTH-1:0] rd_data_reg;
	reg rd_valid_reg;

	gray_counter gray_counter_wr (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.enable(i_wr),
		.gray(wr_gray)
	);

	gray_counter gray_counter_rd (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.enable(i_rd),
		.gray(rd_gray)
	);

	gray_to_bin gray_to_bin_wr (
		.gray(wr_gray),
		.bin(wr_bin)
	);

	gray_to_bin gray_to_bin_rd (
		.gray(rd_gray),
		.bin(rd_bin)
	);

	sync_register sync_wr_gray (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.d(wr_gray),
		.q(synced_wr_gray)
	);

	sync_register sync_rd_gray (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.d(rd_gray),
		.q(synced_rd_gray)
	);

	dual_port_ram dual_port_ram_inst (
		.clk(i_rclk),
		.wr_addr(wr_bin),
		.wr_data(i_wr_data),
		.wr_en(i_wr & ~full_raw),
		.rd_addr(rd_bin),
		.rd_data(o_rd_data)
	);

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_gray_reg <= 0;
			wr_ptr_gray_synced <= 0;
			wr_ptr_bin_synced <= 0;
			o_wr_full <= 0;
		end else begin
			if (i_wr & ~full_raw) begin
				wr_gray_reg <= wr_gray;
			end
			wr_ptr_gray_synced <= synced_wr_gray;
			wr_ptr_bin_synced <= wr_bin;
			o_wr_full <= full_raw;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_gray_reg <= 0;
			rd_data_reg <= 0;
			rd_valid_reg <= 0;
			rd_ptr_gray_synced <= 0;
			rd_ptr_bin_synced <= 0;
			o_rd_empty <= 1;
		end else begin
			if (i_rd & ~empty_raw) begin
				rd_gray_reg <= rd_gray;
				rd_data_reg <= dual_port_ram_inst.rd_data;
				rd_valid_reg <= 1;
			end
			rd_ptr_gray_synced <= synced_rd_gray;
			rd_ptr_bin_synced <= rd_bin;
			o_rd_empty <= empty_raw;
		end
	end

	assign full_raw = (synced_wr_gray == (synced_rd_gray ^ (1 << LGFIFO))) && (synced_wr_gray != synced_rd_gray);
	assign empty_raw = (synced_wr_gray == synced_rd_gray);

endmodule

module gray_counter (
		input	wire	clk, reset_n, enable,
		output	wire	[LGFIFO:0] gray
	);
	parameter LGFIFO = 3;

	reg [LGFIFO:0] count, count_next;

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			count <= 0;
		end else if (enable) begin
			count <= count_next;
		end
	end

	assign count_next = count ^ (count >> 1) + enable;
	assign gray = count;
endmodule

module gray_to_bin (
		input	wire	[LGFIFO:0] gray,
		output	wire	[LGFIFO:0] bin
	);
	parameter LGFIFO = 3;

	wire [LGFIFO:0] gray_shifted1, gray_shifted2, gray_shifted3, gray_shifted4;

	assign gray_shifted1 = gray >> 1;
	assign gray_shifted2 = gray >> 2;
	assign gray_shifted3 = gray >> 3;
	assign gray_shifted4 = gray >> 4;

	assign bin = gray ^ gray_shifted1 ^ gray_shifted2 ^ gray_shifted3 ^ gray_shifted4;
endmodule

module dual_port_ram #(
		parameter LGFIFO = 3,
		parameter WIDTH  = 16
	) (
		input	wire	clk,
		input	wire	[LGFIFO:0] wr_addr,
		input	wire	[WIDTH-1:0] wr_data,
		input	wire	wr_en,
		input	wire	[LGFIFO:0] rd_addr,
		output	reg	[WIDTH-1:0] rd_data
	);

	reg [WIDTH-1:0] memory [0:(2**(LGFIFO+1))-1];

	always @(posedge clk) begin
		if (wr_en) begin
			memory[wr_addr] <= wr_data;
		end
		rd_data <= memory[rd_addr];
	end

endmodule

module sync_register #(
		parameter LGFIFO = 3
	) (
		input	wire	clk, reset_n,
		input	wire	[LGFIFO:0] d,
		output	reg	[LGFIFO:0] q
	);

	reg [LGFIFO:0] q_reg1, q_reg2;

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			q_reg1 <= 0;
			q_reg2 <= 0;
			q <= 0;
		end else begin
			q_reg1 <= d;
			q_reg2 <= q_reg1;
			q <= q_reg2;
		end
	end

endmodule
