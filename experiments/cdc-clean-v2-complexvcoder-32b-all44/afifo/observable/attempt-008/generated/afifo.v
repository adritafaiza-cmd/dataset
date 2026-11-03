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

	wire [LGFIFO-1:0] write_gray_count, read_gray_count;
	wire [LGFIFO-1:0] write_bin_count, read_bin_count;
	wire [LGFIFO-1:0] write_bin_count_sync, read_bin_count_sync;
	wire sync_wr_full, sync_wr_empty;
	wire [WIDTH-1:0] sync_rd_data;
	wire sync_rd_en;
	wire sync_wr_full_sync;

	gray_counter write_gray_counter (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.en(i_wr),
		.gray_count(write_gray_count)
	);

	gray_counter read_gray_counter (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.en(i_rd),
		.gray_count(read_gray_count)
	);

	gray_to_bin write_gray_to_bin (
		.gray(write_gray_count),
		.bin(write_bin_count)
	);

	gray_to_bin read_gray_to_bin (
		.gray(read_gray_count),
		.bin(read_bin_count)
	);

	sync_fifo sync_fifo_inst (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.wr_en(i_wr),
		.rd_en(sync_rd_en),
		.wr_data(i_wr_data),
		.rd_data(sync_rd_data),
		.full(sync_wr_full),
		.empty(sync_wr_empty)
	);

	sync_register write_bin_count_sync (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.d(write_bin_count),
		.q(write_bin_count_sync)
	);

	sync_register sync_wr_full_sync (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.d(sync_wr_full),
		.q(sync_wr_full_sync)
	);

	sync_register read_bin_count_sync (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.d(read_bin_count),
		.q(read_bin_count_sync)
	);

	assign sync_rd_en = i_rd & ~o_rd_empty;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= sync_wr_full;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= sync_wr_empty;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= {WIDTH{1'b0}};
		end else if (i_rd & !o_rd_empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= sync_rd_data;
			end else begin
				o_rd_data <= sync_rd_data;
			end
		end
	end

endmodule

module gray_counter (
		input wire clk,
		input wire reset_n,
		input wire en,
		output reg [LGFIFO-1:0] gray_count
	);

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			gray_count <= {LGFIFO{1'b0}};
		end else if (en) begin
			gray_count <= gray_count + 1'b1;
		end
	end

endmodule

module gray_to_bin (
		input wire [LGFIFO-1:0] gray,
		output reg [LGFIFO-1:0] bin
	);

	integer i;
	always @(*) begin
		bin[0] = gray[0];
		for (i = 1; i < LGFIFO; i = i + 1) begin
			bin[i] = bin[i-1] ^ gray[i];
		end
	end

endmodule

module sync_fifo #(
		parameter LGFIFO = 3,
		parameter WIDTH  = 16
	) (
		input wire clk,
		input wire reset_n,
		input wire wr_en,
		input wire rd_en,
		input wire [WIDTH-1:0] wr_data,
		output reg [WIDTH-1:0] rd_data,
		output reg full,
		output reg empty
	);

	localparam DEPTH = 1 << LGFIFO;
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [LGFIFO:0] wr_ptr, rd_ptr;
	reg [LGFIFO:0] wr_ptr_gray, rd_ptr_gray;

	assign full = (wr_ptr_gray[LGFIFO-1:0] == rd_ptr_gray[LGFIFO-1:0] + 1'b1) && (wr_ptr_gray[LGFIFO] != rd_ptr_gray[LGFIFO]);
	assign empty = (wr_ptr_gray == rd_ptr_gray);

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
			full <= 1'b0;
		end else if (wr_en && !full) begin
			mem[wr_ptr[LGFIFO-1:0]] <= wr_data;
			wr_ptr <= wr_ptr + 1'b1;
			wr_ptr_gray <= wr_ptr_gray + 1'b1;
		end
	end

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
			empty <= 1'b1;
		end else if (rd_en && !empty) begin
			rd_ptr <= rd_ptr + 1'b1;
			rd_ptr_gray <= rd_ptr_gray + 1'b1;
		end
	end

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			rd_data <= 0;
		end else if (rd_en && !empty) begin
			rd_data <= mem[rd_ptr[LGFIFO-1:0]];
		end
	end

endmodule

module sync_register #(
		parameter WIDTH = 16
	) (
		input wire clk,
		input wire reset_n,
		input wire [WIDTH-1:0] d,
		output reg [WIDTH-1:0] q
	);

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			q <= 0;
		end else begin
			q <= d;
		end
	end

endmodule
