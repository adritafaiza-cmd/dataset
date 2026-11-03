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

	wire [LGFIFO-1:0] gray_wptr, gray_rptr;
	wire [LGFIFO-1:0] bin_wptr, bin_rptr;
	wire full, empty;

	// Gray code counters
	gray_counter #(.WIDTH(LGFIFO)) gray_wptr_inst (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.en(i_wr & ~o_wr_full),
		.gray(gray_wptr)
	);

	gray_counter #(.WIDTH(LGFIFO)) gray_rptr_inst (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.en(i_rd & ~o_rd_empty),
		.gray(gray_rptr)
	);

	// Binary-gray converters
	binary_gray_converter #(.WIDTH(LGFIFO)) bin_wptr_inst (
		.gray(rptr_gray_sync_sync_out),
		.bin(bin_wptr)
	);

	binary_gray_converter #(.WIDTH(LGFIFO)) bin_rptr_inst (
		.gray(wptr_gray_sync_sync_out),
		.bin(bin_rptr)
	);

	// FIFO memory
	fifo_memory #(.WIDTH(WIDTH), .DEPTH(2**LGFIFO)) fifo_mem_inst (
		.clk(i_wclk),
		.wr_clk(i_wclk),
		.wr_reset_n(i_wr_reset_n),
		.rd_clk(i_rclk),
		.rd_reset_n(i_rd_reset_n),
		.wr_addr(bin_wptr),
		.rd_addr(bin_rptr),
		.wr_data(i_wr_data),
		.rd_data(o_rd_data)
	);

	// Synchronizers
	sync_signal #(.STAGES(NFF)) wptr_gray_sync_inst (
		.async_in(gray_wptr),
		.sync_out(wptr_gray_sync_sync_out),
		.clk(i_rclk),
		.reset_n(i_rd_reset_n)
	);

	sync_signal #(.STAGES(NFF)) rptr_gray_sync_inst (
		.async_in(gray_rptr),
		.sync_out(rptr_gray_sync_sync_out),
		.clk(i_wclk),
		.reset_n(i_wr_reset_n)
	);

	sync_signal #(.STAGES(NFF)) full_sync_inst (
		.async_in(full),
		.sync_out(o_wr_full),
		.clk(i_wclk),
		.reset_n(i_wr_reset_n)
	);

	sync_signal #(.STAGES(NFF)) empty_sync_inst (
		.async_in(empty),
		.sync_out(o_rd_empty),
		.clk(i_rclk),
		.reset_n(i_rd_reset_n)
	);

	// Full and empty flags
	assign full = (bin_wptr == {LGFIFO{1'b1}});
	assign empty = (bin_wptr == bin_rptr);

	// Register the read data if OPT_REGISTER_READS is set
	reg [WIDTH-1:0] rd_data_reg;

	generate
		if (OPT_REGISTER_READS == 1'b1) begin : reg_read_data
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n) begin
					rd_data_reg <= {WIDTH{1'b0}};
				end else if (i_rd & !o_rd_empty) begin
					rd_data_reg <= fifo_mem_inst.rd_data;
				end
			end
			assign o_rd_data = rd_data_reg;
		end else begin : no_reg_read_data
			assign o_rd_data = fifo_mem_inst.rd_data;
		end
	endgenerate

endmodule

module gray_counter #(
		parameter WIDTH = 3
	) (
		input wire clk,
		input wire reset_n,
		input wire en,
		output reg [WIDTH-1:0] gray
	);

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			gray <= {WIDTH{1'b0}};
		end else if (en) begin
			gray <= gray + 1;
		end
	end

endmodule

module binary_gray_converter #(
		parameter WIDTH = 3
	) (
		input wire [WIDTH-1:0] gray,
		output reg [WIDTH-1:0] bin
	);

	always @(*) begin
		bin = gray ^ (gray >> 1);
	end

endmodule

module fifo_memory #(
		parameter WIDTH = 16,
		parameter DEPTH = 8
	) (
		input wire clk,
		input wire wr_clk,
		input wire wr_reset_n,
		input wire rd_clk,
		input wire rd_reset_n,
		input wire [log2(DEPTH)-1:0] wr_addr,
		input wire [log2(DEPTH)-1:0] rd_addr,
		input wire [WIDTH-1:0] wr_data,
		output reg [WIDTH-1:0] rd_data
	);

	reg [WIDTH-1:0] mem [0:DEPTH-1];

	always @(posedge wr_clk or negedge wr_reset_n) begin
		if (!wr_reset_n) begin
			for (integer i = 0; i < DEPTH; i = i + 1) begin
				mem[i] <= {WIDTH{1'b0}};
			end
		end else begin
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

	function integer log2;
		input integer value;
		begin
			value = value - 1;
			for (log2 = 0; value > 0; log2 = log2 + 1)
				value = value >> 1;
		end
	endfunction

endmodule

module sync_signal #(
		parameter STAGES = 2
	) (
		input wire async_in,
		output reg sync_out,
		input wire clk,
		input wire reset_n
	);

	reg [STAGES-1:0] sync_reg;

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			sync_reg <= {STAGES{1'b0}};
		end else begin
			sync_reg <= {sync_reg[STAGES-2:0], async_in};
		end
	end

	assign sync_out = sync_reg[STAGES-1];

endmodule
