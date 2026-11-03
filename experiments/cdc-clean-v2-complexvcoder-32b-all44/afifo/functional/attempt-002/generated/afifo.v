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
	reg [LGFIFO-1:0] wr_ptr_bin, wr_ptr_gray, wr_ptr_gray_sync;
	reg [LGFIFO-1:0] rd_ptr_bin, rd_ptr_gray, rd_ptr_gray_sync;
	reg [LGFIFO-1:0] wr_ptr_next, rd_ptr_next;
	wire [WIDTH-1:0] o_rd_data_raw;
	reg [WIDTH-1:0] o_rd_data_reg;
	reg full_flag, empty_flag;

	// Write pointer logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr_bin <= {LGFIFO{1'b0}};
		end else if (i_wr && !o_wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				wr_ptr_bin <= wr_ptr_next;
			end
		end
	end

	always @(*) begin
		if (WRITE_ON_POSEDGE) begin
			wr_ptr_next = wr_ptr_bin + 1;
		end else begin
			wr_ptr_next = wr_ptr_bin;
		end
	end

	assign wr_ptr_gray = wr_ptr_bin ^ (wr_ptr_bin >> 1);

	// Read pointer logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr_bin <= {LGFIFO{1'b0}};
		end else if (i_rd && !o_rd_empty) begin
			rd_ptr_bin <= rd_ptr_bin + 1;
		end
	end

	assign rd_ptr_gray = rd_ptr_bin ^ (rd_ptr_bin >> 1);

	// Synchronize pointers
	sync_ff #(.LGFIFO(LGFIFO)) sync_wr_ptr (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.data_in(wr_ptr_gray),
		.data_out(wr_ptr_gray_sync)
	);

	sync_ff #(.LGFIFO(LGFIFO)) sync_rd_ptr (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.data_in(rd_ptr_gray),
		.data_out(rd_ptr_gray_sync)
	);

	// FIFO memory
	fifo_memory #(.LGFIFO(LGFIFO), .WIDTH(WIDTH)) fifo_memory_inst (
		.wclk(i_wclk),
		.wr_reset_n(i_wr_reset_n),
		.waddr(wr_ptr_bin),
		.we(i_wr && !o_wr_full),
		.din(i_wr_data),
		.rclk(i_rclk),
		.raddr(rd_ptr_bin),
		.dout(o_rd_data_raw)
	);

	// Full and empty flags
	assign full_flag = (wr_ptr_gray_sync + 1) == rd_ptr_gray;
	assign empty_flag = wr_ptr_gray == rd_ptr_gray;

	assign o_wr_full = full_flag;
	assign o_rd_empty = empty_flag;

	// Output data handling
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data_reg <= {WIDTH{1'b0}};
		end else if (i_rd && !o_rd_empty) begin
			o_rd_data_reg <= o_rd_data_raw;
		end
	end

	assign o_rd_data = OPT_REGISTER_READS ? o_rd_data_reg : o_rd_data_raw;

endmodule

// Synchronizer Flip-Flop
module sync_ff #(
		parameter	LGFIFO = 3
	) (
		input	wire			clk,
		input	wire			reset_n,
		input	wire	[LGFIFO-1:0]	data_in,
		output	reg	[LGFIFO-1:0]	data_out
	);

	reg [LGFIFO-1:0] sync_reg [0:NFF-1];

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			sync_reg <= '{default: {LGFIFO{1'b0}}};
		end else begin
			sync_reg[0] <= data_in;
			for (int i = 1; i < NFF; i = i + 1) begin
				sync_reg[i] <= sync_reg[i-1];
			end
		end
	end

	assign data_out = sync_reg[NFF-1];

endmodule

// Dual-Port FIFO Memory
module fifo_memory #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16
	) (
		input	wire			wclk,
		input	wire			wr_reset_n,
		input	wire	[LGFIFO-1:0]	waddr,
		input	wire			we,
		input	wire	[WIDTH-1:0]	din,
		input	wire			rclk,
		input	wire	[LGFIFO-1:0]	raddr,
		output	reg	[WIDTH-1:0]	dout
	);

	reg [WIDTH-1:0] memory [0:(2**LGFIFO)-1];

	always @(posedge wclk or negedge wr_reset_n) begin
		if (!wr_reset_n) begin
			for (int i = 0; i < (2**LGFIFO); i = i + 1) begin
				memory[i] <= {WIDTH{1'b0}};
			end
		end else if (we) begin
			memory[waddr] <= din;
		end
	end

	always @(posedge rclk) begin
		dout <= memory[raddr];
	end

endmodule
