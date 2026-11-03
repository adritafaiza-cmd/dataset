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
	wire [LGFIFO:0] write_gray, read_gray;
	wire [LGFIFO:0] write_pointer, read_pointer;
	wire sync_wr_full, sync_rd_empty;
	wire [WIDTH-1:0] read_data_internal;

	// Write Gray Counter
	gray_counter #(.WIDTH(LGFIFO+1)) write_gray_counter (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.enable(i_wr & ~o_wr_full),
		.gray(write_gray),
		.binary(write_pointer)
	);

	// Read Gray Counter
	gray_counter #(.WIDTH(LGFIFO+1)) read_gray_counter (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.enable(i_rd & ~o_rd_empty),
		.gray(read_gray),
		.binary(read_pointer)
	);

	// Write Full Synchronizer
	sync_ff #(.WIDTH(1)) wr_full_sync (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.async_in(sync_wr_full),
		.sync_out(o_wr_full)
	);

	// Read Empty Synchronizer
	sync_ff #(.WIDTH(1)) rd_empty_sync (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.async_in(sync_rd_empty),
		.sync_out(o_rd_empty)
	);

	// FIFO Memory
	memory #(.LGFIFO(LGFIFO), .WIDTH(WIDTH)) fifo_memory (
		.clk_w(i_wclk),
		.reset_n_w(i_wr_reset_n),
		.write_pointer(write_pointer),
		.write_data(i_wr_data),
		.clk_r(i_rclk),
		.reset_n_r(i_rd_reset_n),
		.read_pointer(read_pointer),
		.read_data(read_data_internal)
	);

	// Full Condition
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			sync_wr_full <= 1'b0;
		end else begin
			// Detect when the FIFO is full
			if (write_gray == (read_gray ^ (1 << LGFIFO))) begin
				sync_wr_full <= 1'b1;
			end else if (i_wr & ~sync_wr_full) begin
				sync_wr_full <= 1'b0;
			end
		end
	end

	// Empty Condition
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			sync_rd_empty <= 1'b1;
		end else begin
			// Detect when the FIFO is empty
			if (write_gray == read_gray) begin
				sync_rd_empty <= 1'b1;
			end else if (i_rd & ~sync_rd_empty) begin
				sync_rd_empty <= 1'b0;
			end
		end
	end

	// Register read data if OPT_REGISTER_READS is set
	generate
		if (OPT_REGISTER_READS == 1'b1) begin : gen_opt_reg
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n) begin
					o_rd_data <= {WIDTH{1'b0}};
				end else if (i_rd & ~o_rd_empty) begin
					o_rd_data <= read_data_internal;
				end
			end
		end else begin : gen_no_opt_reg
			assign o_rd_data = read_data_internal;
		end
	endgenerate

endmodule

// Gray Code Counter
module gray_counter #(
		parameter WIDTH = 4
	) (
		input	wire			clk,
		input	wire			reset_n,
		input	wire			enable,
		output	wire	[WIDTH-1:0]	gray,
		output	wire	[WIDTH-1:0]	binary
	);

	reg [WIDTH-1:0] binary_next;

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			binary <= {WIDTH{1'b0}};
		end else if (enable) begin
			binary <= binary_next;
		end
	end

	assign binary_next = binary + 1;

	assign gray = binary_next ^ (binary_next >> 1);

endmodule

// Synchronizer Flip-Flop
module sync_ff #(
		parameter WIDTH = 1
	) (
		input	wire			clk,
		input	wire			reset_n,
		input	wire	[WIDTH-1:0]	async_in,
		output	reg	[WIDTH-1:0]	sync_out
	);

	reg [WIDTH-1:0] ff1, ff2;

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			ff1 <= {WIDTH{1'b0}};
			ff2 <= {WIDTH{1'b0}};
		end else begin
			ff1 <= async_in;
			ff2 <= ff1;
		end
	end

	assign sync_out = ff2;

endmodule

// FIFO Memory
module memory #(
		parameter LGFIFO = 3,
		parameter WIDTH  = 16
	) (
		input	wire			clk_w,
		input	wire			reset_n_w,
		input	wire	[LGFIFO:0]	write_pointer,
		input	wire	[WIDTH-1:0]	write_data,
		input	wire			clk_r,
		input	wire			reset_n_r,
		input	wire	[LGFIFO:0]	read_pointer,
		output	reg	[WIDTH-1:0]	read_data
	);

	reg [WIDTH-1:0] memory_array [0:(2**LGFIFO)-1];

	// Write Operation
	always @(posedge clk_w or negedge reset_n_w) begin
		if (!reset_n_w) begin
			// Do nothing on reset
		end else if (write_pointer < (1 << LGFIFO)) begin
			memory_array[write_pointer[LGFIFO-1:0]] <= write_data;
		end
	end

	// Read Operation
	always @(posedge clk_r or negedge reset_n_r) begin
		if (!reset_n_r) begin
			read_data <= {WIDTH{1'b0}};
		end else if (read_pointer < (1 << LGFIFO)) begin
			read_data <= memory_array[read_pointer[LGFIFO-1:0]];
		end
	end

endmodule
