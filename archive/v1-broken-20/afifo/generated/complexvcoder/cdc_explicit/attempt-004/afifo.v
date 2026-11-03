module afifo #(
	parameter LGFIFO = 3,
	parameter WIDTH = 16,
	parameter NFF = 2,
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

	localparam FIFO_SIZE = 2**LGFIFO;

	// Internal signals
	reg [LGFIFO:0] wr_ptr, rd_ptr;
	reg [LGFIFO:0] wr_count, rd_count;
	reg [WIDTH-1:0] mem [0:FIFO_SIZE-1];

	// Write logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_count <= 0;
		end else begin
			if (i_wr && !o_wr_full) begin
				mem[wr_ptr] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
				wr_count <= wr_count + 1;
			end
		end
	end

	// Read logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_count <= 0;
		end else begin
			if (i_rd && !o_rd_empty) begin
				rd_ptr <= rd_ptr + 1;
				rd_count <= rd_count - 1;
			end
		end
	end

	// Full/Empty flags
	assign o_wr_full = (wr_count == FIFO_SIZE);
	assign o_rd_empty = (rd_count == 0);

	// Output data
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= 0;
		end else begin
			if (i_rd && !o_rd_empty) begin
				o_rd_data <= mem[rd_ptr];
			end
		end
	end

	// Edge detection for write enable
	reg [0:0] wr_prev;
	always @(posedge i_wclk) begin
		wr_prev <= i_wr;
		if (WRITE_ON_POSEDGE && wr_prev && !i_wr) begin
			o_wr_full <= (wr_count == FIFO_SIZE);
		end
	end

endmodule
