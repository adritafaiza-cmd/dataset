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

wire [LGFIFO:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

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
	.o_rd_data(o_rd_data),
	.o_rd_empty(o_rd_empty),
	.wr_ptr_gray_sync(wr_ptr_gray_sync),
	.rd_ptr_gray_sync(rd_ptr_gray_sync)
);

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
		output	reg			o_rd_empty,
		output	wire [LGFIFO:0]	wr_ptr_gray_sync,
		output	wire [LGFIFO:0]	rd_ptr_gray_sync
	);

reg [LGFIFO:0] wr_ptr, rd_ptr;
reg [LGFIFO:0] wr_ptr_gray, rd_ptr_gray;
reg [LGFIFO:0] wr_ptr_gray_sync_reg [NFF-1:0];
reg [LGFIFO:0] rd_ptr_gray_sync_reg [NFF-1:0];
reg [WIDTH-1:0] fifo_memory [0:(2**LGFIFO)-1];
reg [WIDTH-1:0] rd_data_internal;
reg [WIDTH-1:0] rd_data_reg;
reg wr_full_internal;
reg rd_empty_internal;

// Write Domain Logic
always @(posedge i_wclk or negedge i_wr_reset_n) begin
	if (!i_wr_reset_n) begin
		wr_ptr <= 0;
		wr_ptr_gray <= 0;
		wr_full_internal <= 0;
	end else begin
		if (i_wr && !wr_full_internal) begin
			fifo_memory[wr_ptr[LGFIFO-1:0]] <= i_wr_data;
			if (WRITE_ON_POSEDGE)
				wr_ptr <= wr_ptr + 1;
		end
		wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
		wr_full_internal <= (wr_ptr_gray == {wr_ptr_gray_sync_reg[NFF-1][LGFIFO-1], wr_ptr_gray_sync_reg[NFF-1][LGFIFO-1:LGFIFO-1]});
	end
end

// Read Domain Logic
always @(posedge i_rclk or negedge i_rd_reset_n) begin
	if (!i_rd_reset_n) begin
		rd_ptr <= 0;
		rd_ptr_gray <= 0;
		rd_empty_internal <= 1;
		o_rd_data <= 0;
		rd_data_reg <= 0;
	end else begin
		if (i_rd && !rd_empty_internal) begin
			rd_ptr <= rd_ptr + 1;
		end
		rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);
		rd_empty_internal <= (rd_ptr_gray == {rd_ptr_gray_sync_reg[NFF-1][LGFIFO-1], rd_ptr_gray_sync_reg[NFF-1][LGFIFO-1:LGFIFO-1]});
		rd_data_internal <= fifo_memory[rd_ptr[LGFIFO-1:0]];
		if (OPT_REGISTER_READS)
			rd_data_reg <= rd_data_internal;
	end
end

// Gray Code Synchronization
generate
genvar i;
for (i = 0; i < NFF; i = i + 1) begin : sync_gen
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			wr_ptr_gray_sync_reg[i] <= 0;
		else
			wr_ptr_gray_sync_reg[i] <= (i == 0) ? rd_ptr_gray : wr_ptr_gray_sync_reg[i-1];
	end
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			rd_ptr_gray_sync_reg[i] <= 0;
		else
			rd_ptr_gray_sync_reg[i] <= (i == 0) ? wr_ptr_gray : rd_ptr_gray_sync_reg[i-1];
	end
end
endgenerate

assign wr_ptr_gray_sync = wr_ptr_gray_sync_reg[NFF-1];
assign rd_ptr_gray_sync = rd_ptr_gray_sync_reg[NFF-1];
assign o_wr_full = wr_full_internal;
assign o_rd_empty = rd_empty_internal;
assign o_rd_data = OPT_REGISTER_READS ? rd_data_reg : rd_data_internal;

endmodule
