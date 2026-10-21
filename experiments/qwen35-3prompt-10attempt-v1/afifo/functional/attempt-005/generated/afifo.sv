```verilog
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

	localparam	FIFO_DEPTH = 1 << LGFIFO;

	// Write pointer and counter
	reg [LGFIFO-1:0]	w_ptr;
	reg [LGFIFO-1:0]	w_cnt;

	// Read pointer and counter
	reg [LGFIFO-1:0]	r_ptr;
	reg [LGFIFO-1:0]	r_cnt;

	// Data memory
	reg [WIDTH-1:0]	mem [FIFO_DEPTH-1:0];

	// Full flag logic
	reg			full_flag;

	// Empty flag logic (internal)
	reg			empty_flag;

	// Write stage registers
	reg [WIDTH-1:0]	w_reg;
	reg			w_reg_valid;

	// Read stage registers
	reg [WIDTH-1:0]	r_reg;
	reg			r_reg_valid;

	// ---------------------------------------------------------
	// Write Logic
	// ---------------------------------------------------------
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			w_ptr     <= 0;
			w_cnt     <= 0;
			w_reg     <= 0;
			w_reg_valid <= 0;
			full_flag <= 0;
		end else begin
			// Check for full condition
			if (w_cnt == (FIFO_DEPTH - 1)) begin
				full_flag <= 1;
			end else begin
				full_flag <= 0;
			end

			// Write enable logic
			if (i_wr && !full_flag) begin
				if (WRITE_ON_POSEDGE) begin
					// Sample on rising edge of i_wr
					if (i_wr) begin
						w_reg <= i_wr_data;
						w_reg_valid <= 1;
					end
				end else begin
					// Level sensitive
					w_reg <= i_wr_data;
					w_reg_valid <= 1;
				end
			end
		end
	end

	// Update write pointer and memory
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			w_ptr <= 0;
		end else begin
			if (w_reg_valid && !full_flag) begin
				mem[w_ptr] <= w_reg;
				w_ptr <= w_ptr + 1;
				w_reg_valid <= 0;
			end
		end
	end

	// ---------------------------------------------------------
	// Read Logic
	// ---------------------------------------------------------
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			r_ptr     <= 0;
			r_cnt     <= 0;
			r_reg     <= 0;
			r_reg_valid <= 0;
			empty_flag <= 1;
		end else begin
			// Check for empty condition
			if (r_cnt == 0) begin
				empty_flag <= 1;
			end else begin
				empty_flag <= 0;
			end

			// Read enable logic
			if (i_rd && !empty_flag) begin
				if (OPT_REGISTER_READS) begin
					// Sample on rising edge of i_rd
					if (i_rd) begin
						r_reg <= mem[r_ptr];
						r_reg_valid <= 1;
					end
				end else begin
					// Level sensitive
					r_reg <= mem[r_ptr];
					r_reg_valid <= 1;
				end
			end
		end
	end

	// Update read pointer and memory
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			r_ptr <= 0;
		end else begin
			if (r_reg_valid && !empty_flag) begin
				mem[r_ptr] <= mem[r_ptr]; // No-op to keep data stable if needed, but pointer moves
				r_ptr <= r_ptr + 1;
				r_reg_valid <= 0;
			end
		end
	end

	// ---------------------------------------------------------
	// Output Logic
	// ---------------------------------------------------------
	// o_wr_full is driven by full_flag
	assign o_wr_full = full_flag;

	// o_rd_data is driven by r_reg
	assign o_rd_data = r_reg;

	// o_rd_empty is driven by empty_flag
	assign o_rd_empty = empty_flag;

endmodule
```<|im_end|>
