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
	localparam FULL_THRESHOLD = DEPTH - NFF;
	localparam EMPTY_THRESHOLD = NFF;

	// Write side logic
	reg [LGFIFO-1:0] wr_ptr, wr_gray;
	reg [LGFIFO-1:0] wr_gray_next;
	reg [LGFIFO-1:0] wr_cnt;
	reg [LGFIFO-1:0] wr_cnt_next;
	reg [WIDTH-1:0] wr_data_reg;
	reg [WIDTH-1:0] wr_data_reg_next;

	// Read side logic
	reg [LGFIFO-1:0] rd_ptr, rd_gray;
	reg [LGFIFO-1:0] rd_gray_next;
	reg [LGFIFO-1:0] rd_cnt;
	reg [LGFIFO-1:0] rd_cnt_next;
	reg [WIDTH-1:0] rd_data_reg;
	reg [WIDTH-1:0] rd_data_reg_next;

	// Write pointer logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_cnt <= 0;
		end else if (i_wr) begin
			if (WRITE_ON_POSEDGE) begin
				wr_ptr <= wr_ptr + 1'b1;
				wr_cnt <= wr_cnt + 1'b1;
			end
		end
	end

	// Write pointer Gray code generation
	always @(*) begin
		wr_gray = wr_ptr;
		wr_gray_next = wr_gray;
		if (wr_gray[LGFIFO-1:1] != wr_gray[LGFIFO-1:1]) begin
			wr_gray_next = wr_gray ^ {1'b0, {LGFIFO-1{1'b1}}};
		end
	end

	// Write data register (optional register for read side)
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_data_reg <= 0;
		end else if (i_wr) begin
			wr_data_reg <= i_wr_data;
		end
	end

	// Read pointer logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_cnt <= 0;
		end else if (i_rd) begin
			if (OPT_REGISTER_READS) begin
				rd_ptr <= rd_ptr + 1'b1;
				rd_cnt <= rd_cnt + 1'b1;
			end
		end
	end

	// Read pointer Gray code generation
	always @(*) begin
		rd_gray = rd_ptr;
		rd_gray_next = rd_gray;
		if (rd_gray[LGFIFO-1:1] != rd_gray[LGFIFO-1:1]) begin
			rd_gray_next = rd_gray ^ {1'b0, {LGFIFO-1{1'b1}}};
		end
	end

	// Read data register (optional register for write side)
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_reg <= 0;
		end else if (OPT_REGISTER_READS && i_rd) begin
			rd_data_reg <= wr_data_reg;
		end
	end

	// Cross-domain pointers
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_gray <= 0;
		end else begin
			rd_gray <= wr_gray;
		end
	end

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_gray <= 0;
		end else begin
			wr_gray <= rd_gray;
		end
	end

	// Full flag logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= (wr_cnt >= FULL_THRESHOLD);
		end
	end

	// Empty flag logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= (rd_cnt < EMPTY_THRESHOLD);
		end
	end

	// Output data assignment
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= 0;
		end else if (OPT_REGISTER_READS && i_rd) begin
			o_rd_data <= rd_data_reg;
		end
	end

endmodule
```<|im_end|>
