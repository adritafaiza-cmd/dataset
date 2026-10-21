```verilog
module afifo #(
	parameter LGFIFO = 3,
	parameter WIDTH  = 16,
	parameter NFF    = 2,
	parameter [0:0]  WRITE_ON_POSEDGE = 1'b1,
	parameter [0:0]  OPT_REGISTER_READS = 1'b1
) (
	input  wire      i_wclk, i_wr_reset_n, i_wr,
	input  wire      [WIDTH-1:0] i_wr_data,
	output reg       o_wr_full,
	input  wire      i_rclk, i_rd_reset_n, i_rd,
	output reg       [WIDTH-1:0] o_rd_data,
	output reg       o_rd_empty
);

	localparam DEPTH = 1 << LGFIFO;
	localparam FULL_THRESHOLD = DEPTH - NFF;
	localparam EMPTY_THRESHOLD = NFF;

	// Write side logic
	reg [DEPTH-1:0] wr_ptr, rd_ptr;
	reg [LGFIFO-1:0] wr_gray, rd_gray;
	reg [LGFIFO-1:0] wr_gray_next, rd_gray_next;
	reg [LGFIFO-1:0] wr_gray_curr, rd_gray_curr;
	reg [WIDTH-1:0] wr_data_reg;
	reg [WIDTH-1:0] rd_data_reg;
	reg [WIDTH-1:0] rd_data_reg_next;
	reg [WIDTH-1:0] rd_data_reg_prev;
	reg wr_en_reg;
	reg rd_en_reg;
	reg [LGFIFO-1:0] wr_gray_next_reg;
	reg [LGFIFO-1:0] rd_gray_next_reg;

	// Write pointer update
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= '0;
			wr_gray <= '0;
			wr_gray_curr <= '0;
			wr_gray_next <= '0;
			wr_en_reg <= 1'b0;
		end else if (i_wr) begin
			if (WRITE_ON_POSEDGE) begin
				wr_en_reg <= 1'b1;
			end else begin
				wr_en_reg <= 1'b0;
			end
		end
	end

	// Write data register update
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_data_reg <= '0;
		end else if (wr_en_reg) begin
			wr_data_reg <= i_wr_data;
		end
	end

	// Write pointer Gray code generation
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_gray_next <= '0;
			wr_gray_curr <= '0;
		end else begin
			wr_gray_next <= wr_gray_curr;
			wr_gray_curr <= wr_gray_next;
			if (wr_en_reg) begin
				wr_gray_next <= wr_gray_next + 1'b1;
			end
		end
	end

	// Read side logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= '0;
			rd_gray <= '0;
			rd_gray_curr <= '0;
			rd_gray_next <= '0;
			rd_en_reg <= 1'b0;
		end else if (i_rd) begin
			if (OPT_REGISTER_READS) begin
				rd_en_reg <= 1'b1;
			end else begin
				rd_en_reg <= 1'b0;
			end
		end
	end

	// Read data register update
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_reg <= '0;
			rd_data_reg_next <= '0;
			rd_data_reg_prev <= '0;
		end else if (rd_en_reg) begin
			rd_data_reg_prev <= rd_data_reg;
			rd_data_reg <= rd_data_reg_next;
		end
	end

	// Read pointer Gray code generation
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_gray_next <= '0;
			rd_gray_curr <= '0;
		end else begin
			rd_gray_next <= rd_gray_curr;
			rd_gray_curr <= rd_gray_next;
			if (rd_en_reg) begin
				rd_gray_next <= rd_gray_next + 1'b1;
			end
		end
	end

	// Cross-domain pointers
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= '0;
		end else begin
			rd_ptr <= wr_gray_curr;
		end
	end

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= '0;
		end else begin
			wr_ptr <= rd_gray_curr;
		end
	end

	// Full/Empty flags
	assign o_wr_full = (wr_gray_curr >= FULL_THRESHOLD);
	assign o_rd_empty = (rd_gray_curr >= EMPTY_THRESHOLD);

	// Data output
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= '0;
			o_rd_empty <= 1'b1;
		end else if (rd_en_reg) begin
			o_rd_data <= rd_data_reg;
			o_rd_empty <= (rd_gray_curr >= EMPTY_THRESHOLD);
		end
	end

	// Write enable logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_en_reg <= 1'b0;
		end else if (i_wr) begin
			if (WRITE_ON_POSEDGE) begin
				wr_en_reg <= 1'b1;
			end else begin
				wr_en_reg <= 1'b0;
			end
		end
	end

	// Read enable logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_en_reg <= 1'b0;
		end else if (i_rd) begin
			if (OPT_REGISTER_READS) begin
				rd_en_reg <= 1'b1;
			end else begin
				rd_en_reg <= 1'b0;
			end
		end
	end

endmodule
```<|im_end|>
