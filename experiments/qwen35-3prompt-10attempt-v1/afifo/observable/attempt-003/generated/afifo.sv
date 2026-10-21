```verilog
module afifo #(
	parameter LGFIFO = 3,
	parameter WIDTH  = 16,
	parameter NFF    = 2,
	parameter [0:0]  WRITE_ON_POSEDGE = 1'b1,
	parameter [0:0]  OPT_REGISTER_READS = 1'b1
) (
	input  wire            i_wclk, i_wr_reset_n, i_wr,
	input  wire [WIDTH-1:0] i_wr_data,
	output reg             o_wr_full,
	input  wire            i_rclk, i_rd_reset_n, i_rd,
	output reg [WIDTH-1:0] o_rd_data,
	output reg             o_rd_empty
);

	localparam DEPTH = 1 << LGFIFO;
	localparam FULL_THRESHOLD = DEPTH - (1 << NFF);
	localparam EMPTY_THRESHOLD = 1 << NFF;

	// Write pointer (gray code)
	reg [LGFIFO-1:0] wr_gray;
	reg [LGFIFO-1:0] wr_gray_next;
	reg [LGFIFO-1:0] wr_cnt;

	// Read pointer (gray code)
	reg [LGFIFO-1:0] rd_gray;
	reg [LGFIFO-1:0] rd_gray_next;
	reg [LGFIFO-1:0] rd_cnt;

	// FIFO Memory
	reg [WIDTH-1:0] mem [DEPTH-1:0];

	// Write side logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_cnt <= 0;
			wr_gray <= 0;
			o_wr_full <= 1'b0;
		end else if (i_wr) begin
			if (wr_cnt < FULL_THRESHOLD) begin
				mem[wr_cnt] <= i_wr_data;
				wr_cnt <= wr_cnt + 1;
				
				// Gray code update
				wr_gray_next <= wr_gray ^ {wr_gray[0], wr_gray[1:LGFIFO-1]};
				wr_gray <= wr_gray_next;
			end
		end
	end

	// Read side logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_cnt <= 0;
			rd_gray <= 0;
			o_rd_empty <= 1'b1;
		end else if (i_rd) begin
			if (rd_cnt < EMPTY_THRESHOLD) begin
				o_rd_data <= mem[rd_cnt];
				rd_cnt <= rd_cnt + 1;
				
				// Gray code update
				rd_gray_next <= rd_gray ^ {rd_gray[0], rd_gray[1:LGFIFO-1]};
				rd_gray <= rd_gray_next;
			end else begin
				o_rd_empty <= 1'b1;
			end
		end
	end

	// Status flags
	always @(*) begin
		o_wr_full = (wr_cnt >= FULL_THRESHOLD);
		o_rd_empty = (rd_cnt >= EMPTY_THRESHOLD);
	end

endmodule
```<|im_end|>
