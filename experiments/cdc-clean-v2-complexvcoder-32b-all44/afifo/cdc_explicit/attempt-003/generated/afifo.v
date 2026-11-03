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

	// Internal signals for synchronization
	wire write_sync_ctrl;
	wire read_sync_ctrl;

	// Instantiate memory module
	async_fifo_memory #(
		.LGFIFO(LGFIFO),
		.WIDTH(WIDTH),
		.NFF(NFF),
		.WRITE_ON_POSEDGE(WRITE_ON_POSEDGE),
		.OPT_REGISTER_READS(OPT_REGISTER_READS)
	) memory (
		.wclk(i_wclk),
		.wreset_n(i_wr_reset_n),
		.wr(write_sync_ctrl),
		.wr_data(i_wr_data),
		.rclk(i_rclk),
		.rreset_n(i_rd_reset_n),
		.rd(read_sync_ctrl),
		.rd_data(o_rd_data),
		.wr_full(o_wr_full),
		.rd_empty(o_rd_empty)
	);

	// Instantiate write control synchronizer
	sync_control #(
		.NFF(NFF)
	) write_sync (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.async_control(i_wr),
		.sync_control(write_sync_ctrl)
	);

	// Instantiate read control synchronizer
	sync_control #(
		.NFF(NFF)
	) read_sync (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.async_control(i_rd),
		.sync_control(read_sync_ctrl)
	);

endmodule

module async_fifo_memory #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2,
		parameter [0:0]	WRITE_ON_POSEDGE = 1'b1,
		parameter [0:0]	OPT_REGISTER_READS = 1'b1
	) (
		input	wire			wclk, wreset_n, wr,
		input	wire	[WIDTH-1:0]	wr_data,
		input	wire			rclk, rreset_n, rd,
		output	reg	[WIDTH-1:0]	rd_data,
		output	reg			wr_full,
		output	reg			rd_empty
	);

	localparam DEPTH = 1 << LGFIFO;
	localparam ADDR_WIDTH = LGFIFO;

	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [ADDR_WIDTH:0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray;
	reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

	// Gray code conversion functions
	function [ADDR_WIDTH:0] bin_to_gray;
		input [ADDR_WIDTH:0] bin;
		bin_to_gray = bin ^ (bin >> 1);
	endfunction

	function [ADDR_WIDTH:0] gray_to_bin;
		input [ADDR_WIDTH:0] gray;
		integer i;
		reg [ADDR_WIDTH:0] bin;
		bin = gray;
		for (i = ADDR_WIDTH-1; i >= 0; i = i - 1) begin
			bin[i] = bin[i+1] ^ gray[i];
		end
		gray_to_bin = bin;
	endfunction

	// Write pointer logic
	always @(posedge wclk or negedge wreset_n) begin
		if (!wreset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
		end else if (wr && !wr_full) begin
			wr_ptr <= wr_ptr + 1;
			wr_ptr_gray <= bin_to_gray(wr_ptr + 1);
		end
	end

	// Read pointer logic
	always @(posedge rclk or negedge rreset_n) begin
		if (!rreset_n) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
		end else if (rd && !rd_empty) begin
			rd_ptr <= rd_ptr + 1;
			rd_ptr_gray <= bin_to_gray(rd_ptr + 1);
		end
	end

	// Synchronize write pointer gray code to read clock
	sync_control #(
		.NFF(NFF)
	) wr_ptr_gray_sync_inst (
		.clk(rclk),
		.reset_n(rreset_n),
		.async_control(wr_ptr_gray),
		.sync_control(wr_ptr_gray_sync)
	);

	// Synchronize read pointer gray code to write clock
	sync_control #(
		.NFF(NFF)
	) rd_ptr_gray_sync_inst (
		.clk(wclk),
		.reset_n(wreset_n),
		.async_control(rd_ptr_gray),
		.sync_control(rd_ptr_gray_sync)
	);

	// Write full flag
	assign wr_full = (wr_ptr_gray_sync == {1'b1, rd_ptr_gray_sync[ADDR_WIDTH-1:0]});

	// Read empty flag
	assign rd_empty = (rd_ptr_gray_sync == {1'b1, wr_ptr_gray_sync[ADDR_WIDTH-1:0]});

	// Write data to memory
	always @(posedge wclk) begin
		if (wr && !wr_full) begin
			mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
		end
	end

	// Read data from memory
	always @(posedge rclk) begin
		if (rd && !rd_empty) begin
			if (OPT_REGISTER_READS) begin
				rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
			end else begin
				rd_data <= mem[gray_to_bin(rd_ptr_gray_sync)[ADDR_WIDTH-1:0]];
			end
		end
	end

endmodule

module sync_control #(
		parameter	NFF = 2
	) (
		input	wire	clk, reset_n, async_control,
		output	reg	sync_control
	);

	reg [NFF-1:0] sync_chain;

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			sync_chain <= 0;
		end else begin
			sync_chain <= {async_control, sync_chain[NFF-1:1]};
		end
	end

	assign sync_control = sync_chain[0];

endmodule
