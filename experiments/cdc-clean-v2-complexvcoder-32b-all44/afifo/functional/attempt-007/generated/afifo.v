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

wire [WIDTH-1:0] fifo_rd_data;
wire fifo_rd_empty;

async_fifo_core #(
	.LGFIFO(LGFIFO),
	.WIDTH(WIDTH),
	.NFF(NFF),
	.WRITE_ON_POSEDGE(WRITE_ON_POSEDGE),
	.OPT_REGISTER_READS(OPT_REGISTER_READS)
) fifo_core (
	.i_wclk(i_wclk),
	.i_wr_reset_n(i_wr_reset_n),
	.i_wr(i_wr),
	.i_wr_data(i_wr_data),
	.o_wr_full(o_wr_full),
	.i_rclk(i_rclk),
	.i_rd_reset_n(i_rd_reset_n),
	.i_rd(i_rd),
	.o_rd_data(fifo_rd_data),
	.o_rd_empty(fifo_rd_empty)
);

always @(posedge i_rclk or negedge i_rd_reset_n) begin
	if (!i_rd_reset_n) begin
		o_rd_data <= 0;
		o_rd_empty <= 1;
	end else begin
		o_rd_data <= fifo_rd_data;
		o_rd_empty <= fifo_rd_empty;
	end
end

endmodule

module async_fifo_core #(
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

reg [LGFIFO:0] wr_ptr, rd_ptr;
reg [LGFIFO:0] wr_ptr_gray, rd_ptr_gray;
reg [LGFIFO:0] wr_ptr_gray_synced, rd_ptr_gray_synced;
reg [LGFIFO:0] rd_wr_ptr_gray_synced, wr_rd_ptr_gray_synced;
reg [WIDTH-1:0] mem [0:(2**LGFIFO)-1];
reg wr_full, rd_empty;
reg [WIDTH-1:0] rd_data;

// Write Pointer Logic
always @(posedge i_wclk or negedge i_wr_reset_n) begin
	if (!i_wr_reset_n)
		wr_ptr <= 0;
	else if (i_wr && !wr_full)
		wr_ptr <= wr_ptr + 1;
end

// Read Pointer Logic
always @(posedge i_rclk or negedge i_rd_reset_n) begin
	if (!i_rd_reset_n)
		rd_ptr <= 0;
	else if (i_rd && !rd_empty)
		rd_ptr <= rd_ptr + 1;
end

// Binary to Gray Code Conversion
assign wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;
assign rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;

// Synchronization Stages
sync_stage #(.LGFIFO(LGFIFO)) sync_wr_to_rd (
	.sync_in(wr_ptr_gray),
	.i_clk(i_rclk),
	.i_reset_n(i_rd_reset_n),
	.sync_out(wr_ptr_gray_synced)
);

sync_stage #(.LGFIFO(LGFIFO)) sync_rd_to_wr (
	.sync_in(rd_ptr_gray),
	.i_clk(i_wclk),
	.i_reset_n(i_wr_reset_n),
	.sync_out(rd_ptr_gray_synced)
);

// Cross Domain Signals
assign rd_wr_ptr_gray_synced = wr_ptr_gray_synced;
assign wr_rd_ptr_gray_synced = rd_ptr_gray_synced;

// Full and Empty Flags
assign wr_full = (wr_ptr_gray_synced == {~rd_wr_ptr_gray_synced[LGFIFO], rd_wr_ptr_gray_synced[LGFIFO-1:0] + 1});
assign rd_empty = (wr_rd_ptr_gray_synced == rd_ptr_gray_synced);

// Write Memory
always @(posedge i_wclk) begin
	if (i_wr && !wr_full)
		mem[wr_ptr[LGFIFO-1:0]] <= i_wr_data;
end

// Read Memory
always @(posedge i_rclk) begin
	if (i_rd && !rd_empty)
		rd_data <= mem[rd_ptr[LGFIFO-1:0]];
end

// Output Data and Empty Flag
always @(posedge i_rclk or negedge i_rd_reset_n) begin
	if (!i_rd_reset_n) begin
		o_rd_data <= 0;
		o_rd_empty <= 1;
	end else begin
		o_rd_data <= rd_data;
		o_rd_empty <= rd_empty;
	end
end

endmodule

module sync_stage #(
		parameter	LGFIFO = 3
	) (
		input	wire	[LGFIFO:0] sync_in,
		input	wire	i_clk,
		input	wire	i_reset_n,
		output	reg	[LGFIFO:0] sync_out
	);

reg [LGFIFO:0] sync_stage_0, sync_stage_1;

always @(posedge i_clk or negedge i_reset_n) begin
	if (!i_reset_n) begin
		sync_stage_0 <= 0;
		sync_stage_1 <= 0;
		sync_out <= 0;
	end else begin
		sync_stage_0 <= sync_in;
		sync_stage_1 <= sync_stage_0;
		sync_out <= sync_stage_1;
	end
end

endmodule
