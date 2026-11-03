module afifo #(
	parameter LGFIFO = 3,
	parameter WIDTH  = 16,
	parameter NFF    = 2,
	parameter [0:0] WRITE_ON_POSEDGE = 1'b1,
	parameter [0:0] OPT_REGISTER_READS = 1'b1
) (
	input wire i_wclk, i_wr_reset_n, i_wr,
	input wire [WIDTH-1:0] i_wr_data,
	output reg o_wr_full,
	input wire i_rclk, i_rd_reset_n, i_rd,
	output reg [WIDTH-1:0] o_rd_data,
	output reg o_rd_empty
);

parameter FIFO_SIZE = 1 << LGFIFO;
parameter ADDR_WIDTH = $clog2(FIFO_SIZE);

reg [ADDR_WIDTH-1:0] wr_address, rd_address;
reg [WIDTH-1:0] memory [0:FIFO_SIZE-1];
reg wr_en_sync, rd_en_sync;
wire wr_full, rd_empty;

// Write controller
always @(posedge i_wclk or negedge i_wr_reset_n) begin
	if (!i_wr_reset_n) begin
		wr_address <= 0;
		wr_en_sync <= 0;
	end else begin
		wr_en_sync <= i_wr;
		if (wr_en_sync && !o_wr_full) begin
			wr_address <= wr_address + 1;
		end
	end
end

// Read controller
always @(posedge i_rclk or negedge i_rd_reset_n) begin
	if (!i_rd_reset_n) begin
		rd_address <= 0;
		rd_en_sync <= 0;
	end else begin
		rd_en_sync <= i_rd;
		if (rd_en_sync && !o_rd_empty) begin
			rd_address <= rd_address + 1;
		end
	end
end

// Full flag
assign wr_full = wr_address == rd_address;

// Empty flag
assign rd_empty = wr_address == rd_address;

// Write data to memory
always @(posedge i_wclk) begin
	if (wr_en_sync && !o_wr_full) begin
		memory[wr_address] <= i_wr_data;
	end
end

// Read data from memory
always @(posedge i_rclk) begin
	if (rd_en_sync && !o_rd_empty) begin
		o_rd_data <= memory[rd_address];
	end
end

// Assign full and empty flags
assign o_wr_full = wr_full;
assign o_rd_empty = rd_empty;

endmodule
