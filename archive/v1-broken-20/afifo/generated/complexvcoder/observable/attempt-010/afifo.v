module afifo #(
	parameter LGFIFO = 3,
	parameter WIDTH  = 16,
	parameter NFF    = 2,
	parameter [0:0] WRITE_ON_POSEDGE = 1'b1,
	parameter [0:0] OPT_REGISTER_READS = 1'b1
) (
	input wire			i_wclk, i_wr_reset_n, i_wr,
	input wire	[WIDTH-1:0]	i_wr_data,
	output reg			o_wr_full,
	input wire			i_rclk, i_rd_reset_n, i_rd,
	output reg	[WIDTH-1:0]	o_rd_data,
	output reg			o_rd_empty
);

parameter FIFO_SIZE = 2**LGFIFO;
parameter FIFO_MASK = FIFO_SIZE - 1;

reg [WIDTH-1:0] fifo [0:FIFO_SIZE-1];
reg [LGFIFO-1:0] wr_ptr_reg, rd_ptr_reg;
reg [LGFIFO-1:0] wr_ptr_next, rd_ptr_next;
reg wr_full_reg, wr_full_next;
reg rd_empty_reg, rd_empty_next;

always @(posedge i_wclk or negedge i_wr_reset_n) begin
	if (!i_wr_reset_n) begin
		wr_ptr_reg <= 0;
		wr_full_reg <= 0;
	end else begin
		wr_ptr_reg <= wr_ptr_next;
		wr_full_reg <= wr_full_next;
	end
end

always @(posedge i_rclk or negedge i_rd_reset_n) begin
	if (!i_rd_reset_n) begin
		rd_ptr_reg <= 0;
		rd_empty_reg <= 1;
	end else begin
		rd_ptr_reg <= rd_ptr_next;
		rd_empty_reg <= rd_empty_next;
	end
end

always @(*) begin
	wr_ptr_next = wr_ptr_reg;
	wr_full_next = 1;
	rd_ptr_next = rd_ptr_reg;
	rd_empty_next = 0;

	if (i_wr && !wr_full_reg) begin
		fifo[wr_ptr_reg] <= i_wr_data;
		wr_ptr_next = wr_ptr_reg + 1;
		wr_full_next = (wr_ptr_next == rd_ptr_reg);
	end

	if (i_rd && !rd_empty_reg) begin
		o_rd_data = fifo[rd_ptr_reg];
		rd_ptr_next = rd_ptr_reg + 1;
		rd_empty_next = (wr_ptr_reg == rd_ptr_next);
	end
end

assign o_wr_full = wr_full_reg;
assign o_rd_empty = rd_empty_reg;

endmodule
