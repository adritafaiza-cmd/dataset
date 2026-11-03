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
	localparam ADDR_WIDTH = LGFIFO + 1;

	// Internal signals
	wire [ADDR_WIDTH-1:0] wr_gray_sync, rd_gray_sync;
	wire [ADDR_WIDTH-1:0] wr_ptr_gray, rd_ptr_gray;
	wire [ADDR_WIDTH-1:0] wr_ptr_bin, rd_ptr_bin;
	wire full_flag, empty_flag;

	// Gray code counters
	gray_counter gray_counter_wr (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.wr_en(i_wr),
		.rd_en(1'b0),
		.rd_gray_sync(rd_gray_sync),
		.gray_out(wr_ptr_gray),
		.wr_gray_sync(wr_gray_sync)
	);

	gray_counter gray_counter_rd (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.wr_en(1'b0),
		.rd_en(i_rd),
		.rd_gray_sync(wr_gray_sync),
		.gray_out(rd_ptr_gray),
		.wr_gray_sync(rd_gray_sync)
	);

	// Synchronization registers
	sync_register sync_wr_gray (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.d(wr_ptr_gray),
		.q(wr_gray_sync)
	);

	sync_register sync_rd_gray (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.d(rd_ptr_gray),
		.q(rd_gray_sync)
	);

	// Memory
	memory mem (
		.wr_clk(i_wclk),
		.wr_reset_n(i_wr_reset_n),
		.wr_clk_en(WRITE_ON_POSEDGE),
		.wr_addr(wr_gray_sync),
		.wr_data(i_wr_data),
		.rd_clk(i_rclk),
		.rd_reset_n(i_rd_reset_n),
		.rd_addr(rd_gray_sync),
		.rd_data(o_rd_data)
	);

	// Full and empty flags
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= (wr_ptr_gray == {1'b1, rd_gray_sync[ADDR_WIDTH-2:0]});
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= (wr_gray_sync == rd_ptr_gray);
		end
	end

endmodule

module gray_counter (
		input	wire			clk, reset_n, wr_en, rd_en,
		input	wire	[ADDR_WIDTH-1:0]	rd_gray_sync,
		output	reg	[ADDR_WIDTH-1:0]	gray_out, wr_gray_sync
	);

	// Internal signals
	reg [ADDR_WIDTH-1:0] counter_bin, next_counter_bin;
	reg [ADDR_WIDTH-1:0] counter_gray, next_counter_gray;

	// Binary to Gray code conversion
	assign gray_out = counter_gray;
	assign wr_gray_sync = counter_gray;

	// Next counter value logic
	always @(*) begin
		next_counter_bin = counter_bin;
		if (wr_en)
			next_counter_bin = counter_bin + 1;
		else if (rd_en)
			next_counter_bin = counter_bin - 1;
	end

	always @(*) begin
		next_counter_gray = next_counter_bin ^ (next_counter_bin >> 1);
	end

	// Register the counters
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			counter_bin <= {ADDR_WIDTH{1'b0}};
			counter_gray <= {ADDR_WIDTH{1'b0}};
		end else begin
			counter_bin <= next_counter_bin;
			counter_gray <= next_counter_gray;
		end
	end

endmodule

module sync_register (
		input	wire			clk, reset_n,
		input	wire	[ADDR_WIDTH-1:0]	d,
		output	reg	[ADDR_WIDTH-1:0]	q
	);

	// Internal signals
	reg [ADDR_WIDTH-1:0] sync_reg1;

	// Synchronize input signal using two flip-flops
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			sync_reg1 <= {ADDR_WIDTH{1'b0}};
			q <= {ADDR_WIDTH{1'b0}};
		end else begin
			sync_reg1 <= d;
			q <= sync_reg1;
		end
	end

endmodule

module memory #(
		parameter	ADDR_WIDTH = LGFIFO + 1,
		parameter	WIDTH = 16
	) (
		input	wire			wr_clk, wr_reset_n, wr_clk_en,
		input	wire	[ADDR_WIDTH-1:0]	wr_addr,
		input	wire	[WIDTH-1:0]	wr_data,
		input	wire			rd_clk, rd_reset_n,
		input	wire	[ADDR_WIDTH-1:0]	rd_addr,
		output	reg	[WIDTH-1:0]	rd_data
	);

	// Internal signals
	reg [WIDTH-1:0] mem_array [0:(2**ADDR_WIDTH)-1];

	// Write operation
	always @(posedge wr_clk or negedge wr_reset_n) begin
		if (!wr_reset_n) begin
			// Reset memory (optional)
		end else if (wr_clk_en) begin
			mem_array[wr_addr] <= wr_data;
		end
	end

	// Read operation
	always @(posedge rd_clk or negedge rd_reset_n) begin
		if (!rd_reset_n) begin
			rd_data <= {WIDTH{1'b0}};
		end else begin
			rd_data <= mem_array[rd_addr];
		end
	end

endmodule
