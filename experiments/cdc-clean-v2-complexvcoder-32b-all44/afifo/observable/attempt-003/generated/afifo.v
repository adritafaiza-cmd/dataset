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

	// Internal signals
	wire [LGFIFO-1:0] wr_gray, rd_gray;
	wire [LGFIFO-1:0] wr_bin, rd_bin;
	wire [LGFIFO-1:0] wr_bin_next, rd_bin_next;
	wire [LGFIFO-1:0] wr_gray_next, rd_gray_next;
	wire write_en, read_en;
	wire wr_full_raw, rd_empty_raw;
	wire [WIDTH-1:0] rd_data, rd_data_reg;

	// Write enable and read enable
	assign write_en = i_wr & ~o_wr_full;
	assign read_en = i_rd & ~o_rd_empty;

	// Write pointer in gray code
	gray_counter gray_counter_wr (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.load(write_en),
		.gray_out(wr_gray)
	);

	// Read pointer in gray code
	gray_counter gray_counter_rd (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.load(read_en),
		.gray_out(rd_gray)
	);

	// Convert write pointer from gray to binary
	gray_to_bin gray_to_bin_wr (
		.gray_in(wr_gray),
		.bin_out(wr_bin)
	);

	// Convert read pointer from gray to binary
	gray_to_bin gray_to_bin_rd (
		.gray_in(rd_gray),
		.bin_out(rd_bin)
	);

	// Dual-port RAM for FIFO storage
	dual_port_ram dual_port_ram_inst (
		.clk_w(i_wclk),
		.clk_r(i_rclk),
		.wr_en(write_en),
		.rd_en(read_en),
		.wr_addr(wr_bin),
		.rd_addr(rd_bin),
		.wr_data(i_wr_data),
		.rd_data(rd_data)
	);

	// Convert next write pointer from binary to gray
	bin_to_gray bin_to_gray_wr (
		.bin_in(wr_bin_next),
		.gray_out(wr_gray_next)
	);

	// Convert next read pointer from binary to gray
	bin_to_gray bin_to_gray_rd (
		.bin_in(rd_bin_next),
		.gray_out(rd_gray_next)
	);

	// Next write pointer
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			wr_bin_next <= {LGFIFO{1'b0}};
		else if (write_en)
			wr_bin_next <= wr_bin + 1;
	end

	// Next read pointer
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			rd_bin_next <= {LGFIFO{1'b0}};
		else if (read_en)
			rd_bin_next <= rd_bin + 1;
	end

	// FIFO full condition
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			o_wr_full <= 1'b0;
		else if (write_en && (wr_gray_next == rd_gray))
			o_wr_full <= 1'b1;
	end

	// FIFO empty condition
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			o_rd_empty <= 1'b1;
		else if (read_en && (wr_gray == rd_gray_next))
			o_rd_empty <= 1'b1;
		else
			o_rd_empty <= 1'b0;
	end

	// Output data register
	generate
		if (OPT_REGISTER_READS) begin : gen_opt_register_reads
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n)
					rd_data_reg <= {WIDTH{1'b0}};
				else if (read_en)
					rd_data_reg <= rd_data;
			end
			assign o_rd_data = rd_data_reg;
		end else begin : gen_no_opt_register_reads
			assign o_rd_data = rd_data;
		end
	endgenerate

endmodule

// Gray code counter
module gray_counter (
		input	wire			clk,
		input	wire			reset_n,
		input	wire			load,
		output	wire [LGFIFO-1:0]	gray_out
	);

	parameter LGFIFO = 3;

	reg [LGFIFO-1:0] gray_reg, gray_next;

	// Calculate next gray code value
	always @(*) begin
		gray_next = gray_reg + 1;
		gray_next[LGFIFO-1] = gray_reg[LGFIFO-2] ^ gray_next[LGFIFO-2];
	end

	// Update gray_reg on clock edge if load is high
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n)
			gray_reg <= {LGFIFO{1'b0}};
		else if (load)
			gray_reg <= gray_next;
	end

	assign gray_out = gray_reg;

endmodule

// Convert gray code to binary
module gray_to_bin (
		input	wire [LGFIFO-1:0]	gray_in,
		output	wire [LGFIFO-1:0]	bin_out
	);

	parameter LGFIFO = 3;

	assign bin_out[0] = gray_in[0];
	generate
		genvar i;
		for (i = 1; i < LGFIFO; i = i + 1) begin : gen_gray_to_bin
			assign bin_out[i] = bin_out[i-1] ^ gray_in[i];
		end
	endgenerate

endmodule

// Dual-port RAM for FIFO storage
module dual_port_ram (
		input	wire			clk_w,
		input	wire			clk_r,
		input	wire			wr_en,
		input	wire			rd_en,
		input	wire [LGFIFO-1:0]	wr_addr,
		input	wire [LGFIFO-1:0]	rd_addr,
		input	wire [WIDTH-1:0]	wr_data,
		output	wire [WIDTH-1:0]	rd_data
	);

	parameter LGFIFO = 3;
	parameter WIDTH  = 16;

	reg [WIDTH-1:0] mem [0:(1<<LGFIFO)-1];

	// Write operation on write clock edge
	always @(posedge clk_w) begin
		if (wr_en)
			mem[wr_addr] <= wr_data;
	end

	// Read operation on read clock edge
	always @(posedge clk_r) begin
		if (rd_en)
			rd_data <= mem[rd_addr];
		else
			rd_data <= rd_data;
	end

endmodule

// Convert binary to gray code
module bin_to_gray (
		input	wire [LGFIFO-1:0]	bin_in,
		output	wire [LGFIFO-1:0]	gray_out
	);

	parameter LGFIFO = 3;

	assign gray_out[LGFIFO-1] = bin_in[LGFIFO-1];
	generate
		genvar i;
		for (i = 0; i < LGFIFO-1; i = i + 1) begin : gen_bin_to_gray
			assign gray_out[i] = bin_in[i] ^ bin_in[i+1];
		end
	endgenerate

endmodule
