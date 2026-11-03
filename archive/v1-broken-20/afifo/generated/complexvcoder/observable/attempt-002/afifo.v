module afifo #(
	parameter LGFIFO = 3,
	parameter WIDTH = 16,
	parameter NFF = 2,
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

localparam FIFO_DEPTH = 1 << LGFIFO;
localparam ADDR_WIDTH = LGFIFO;

reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
reg [WIDTH-1:0] mem [0:FIFO_DEPTH-1];
reg wr_full, rd_empty;

always @(posedge i_wclk or negedge i_wr_reset_n) begin
	if (!i_wr_reset_n) begin
		wr_ptr <= 0;
		wr_full <= 1'b0;
	end else if (WRITE_ON_POSEDGE && i_wr && !wr_full) begin
		mem[wr_ptr] <= i_wr_data;
		wr_ptr <= wr_ptr + 1;
		if (wr_ptr == rd_ptr)
			wr_full <= 1'b1;
		else
			wr_full <= 1'b0;
	end
end

always @(posedge i_rclk or negedge i_rd_reset_n) begin
	if (!i_rd_reset_n) begin
		rd_ptr <= 0;
		rd_empty <= 1'b1;
	end else if (i_rd && !rd_empty) begin
		rd_ptr <= rd_ptr + 1;
		if (rd_ptr == wr_ptr)
			rd_empty <= 1'b1;
		else
			rd_empty <= 1'b0;
	end
end

assign o_wr_full = wr_full;
assign o_rd_empty = rd_empty;

assign o_rd_data = mem[rd_ptr];

endmodule
