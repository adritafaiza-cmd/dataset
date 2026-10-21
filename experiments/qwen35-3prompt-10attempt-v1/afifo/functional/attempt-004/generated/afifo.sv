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

	// FIFO Memory
	reg [WIDTH-1:0]	fifo_mem [FIFO_DEPTH-1:0];

	// Write Logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			w_ptr  <= 0;
			w_cnt  <= 0;
			o_wr_full <= 0;
		end else if (i_wr && !o_wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				fifo_mem[w_ptr] <= i_wr_data;
				w_ptr <= w_ptr + 1;
				w_cnt <= w_cnt + 1;
			end
			// Check for full condition based on counter
			if (w_cnt == (FIFO_DEPTH - 1)) begin
				o_wr_full <= 1;
			end
		end
	end

	// Read Logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			r_ptr  <= 0;
			r_cnt  <= 0;
			o_rd_empty <= 1;
		end else if (i_rd && !o_rd_empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= fifo_mem[r_ptr];
				r_ptr <= r_ptr + 1;
				r_cnt <= r_cnt + 1;
			end
			// Check for empty condition based on counter
			if (r_cnt == 0) begin
				o_rd_empty <= 1;
			end
		end
	end

	// Full Flag Logic (Gray Code for stability across clock domains)
	// We use a separate process to generate the full flag based on pointers
	// to ensure it is stable and meets the requirement that full is low on write reset.
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 0;
		end else begin
			// Calculate full condition: w_ptr == r_ptr and w_cnt == FIFO_DEPTH - 1
			// However, standard Gray code implementation for full flag:
			// Full is true when w_ptr == r_ptr AND w_cnt == FIFO_DEPTH - 1
			// But to avoid metastability on the read side, we usually rely on the write side logic
			// or a dedicated full flag generator. Here we implement the standard logic.
			
			// Note: In a true asynchronous FIFO, the full flag is generated on the write clock
			// and must be stable. The condition is: w_ptr == r_ptr AND w_cnt == FIFO_DEPTH - 1.
			// However, simply comparing w_ptr and r_ptr directly can be tricky if r_ptr is not Gray coded.
			// Standard practice: Use Gray code for pointers.
			
			// Let's implement Gray code pointers for robustness.
			// w_gray = w_ptr ^ (w_ptr >> 1)
			// r_gray = r_ptr ^ (r_ptr >> 1)
			// Full = (w_gray == r_gray) && (w_cnt == FIFO_DEPTH - 1)
			
			// Re-architecting the pointer logic to use Gray code internally for the full flag generation
			// is safer. But the problem statement implies standard behavior.
			// Let's stick to the simplest correct implementation for the full flag.
			// The full flag is valid only when the FIFO is full.
			
			// To ensure o_wr_full is stable and correct:
			// We compare the current write pointer with the read pointer.
			// Since r_ptr is updated on i_rclk, we cannot directly compare w_ptr and r_ptr
			// inside the i_wclk process without potential glitches if not careful.
			// However, the standard solution is to generate the full flag using the write pointer
			// and the read pointer's Gray code version, or simply rely on the counter.
			
			// Correct approach for Full Flag in Async FIFO:
			// Full = (w_ptr == r_ptr) && (w_cnt == FIFO_DEPTH - 1)
			// This comparison happens on the write clock. r_ptr is a register.
			// This is acceptable as long as r_ptr is stable at the sampling instant.
			// To be extra safe and standard, we often use Gray code for the pointers.
			
			// Let's use Gray code for pointers to ensure glitch-free full/empty flags.
			// w_gray = w_ptr ^ (w_ptr >> 1)
			// r_gray = r_ptr ^ (r_ptr >> 1)
			// Full = (w_gray == r_gray) && (w_cnt == FIFO_DEPTH - 1)
			
			// However, the prompt asks for a specific behavior. Let's implement the standard
			// Gray code pointer approach which is the industry standard for Async FIFOs.
			
			// We need to store the Gray code versions or compute them on the fly.
			// Computing on the fly:
			reg [LGFIFO-1:0] w_gray;
			reg [LGFIFO-1:0] r_gray;
			
			// Update Gray codes
			w_gray <= w_ptr ^ (w_ptr >> 1);
			r_gray <= r_ptr ^ (r_ptr >> 1);
			
			if (w_gray == r_gray && w_cnt == (FIFO_DEPTH - 1)) begin
				o_wr_full <= 1;
			end else begin
				o_wr_full <= 0;
			end
		end
	end

	// Empty Flag Logic
	// Empty is true when r_ptr == w_ptr and r_cnt == 0
	// Similar logic to full flag, but on the read side.
	// However, the empty flag is output on the read side, so it's naturally stable on i_rclk.
	// We just need to ensure it's correct.
	
	// Re-evaluating the Full Flag logic:
	// The previous block inside the always @(posedge i_wclk...) was getting complex with local vars.
	// Let's refactor to be clean.
	
	// Refactored Write Process
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			w_ptr  <= 0;
			w_cnt  <= 0;
			o_wr_full <= 0;
		end else if (i_wr && !o_wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				fifo_mem[w_ptr] <= i_wr_data;
				w_ptr <= w_ptr + 1;
				w_cnt <= w_cnt + 1;
			end
			if (w_cnt == (FIFO_DEPTH - 1)) begin
				o_wr_full <= 1;
			end
		end
	end

	// Refactored Read Process
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			r_ptr  <= 0;
			r_cnt  <= 0;
			o_rd_empty <= 1;
		end else if (i_rd && !o_rd_empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= fifo_mem[r_ptr];
				r_ptr <= r_ptr + 1;
				r_cnt <= r_cnt + 1;
			end
			if (r_cnt == 0) begin
				o_rd_empty <= 1;
			end
		end
	end

	// Full Flag Generation (Must be stable on i_wclk domain)
	// Full = (w_ptr == r_ptr) && (w_cnt == FIFO_DEPTH - 1)
	// To prevent glitches when r_ptr changes, we use Gray code for comparison.
	// w_gray = w_ptr ^ (w_ptr >> 1)
	// r_gray = r_ptr ^ (r_ptr >> 1)
	
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 0;
		end else begin
			reg [LGFIFO-1:0] w_gray, r_gray;
			w_gray <= w_ptr ^ (w_ptr >> 1);
			r_gray <= r_ptr ^ (r_ptr >> 1);
			
			if (w_gray == r_gray && w_cnt == (FIFO_DEPTH - 1)) begin
				o_wr_full <= 1;
			end else begin
				o_wr_full <= 0;
			end
		end
	end

	// Empty Flag Generation (Must be stable on i_rclk domain)
	// Empty = (r_ptr == w_ptr) && (r_cnt == 0)
	// Similarly, use Gray code for w_ptr to compare with r_ptr.
	
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1;
		end else begin
			reg [LGFIFO-1:0] w_gray, r_gray;
			w_gray <= w_ptr ^ (w_ptr >> 1);
			r_gray <= r_ptr ^ (r_ptr >> 1);
			
			if (w_gray == r_gray && r_cnt == 0) begin
				o_rd_empty <= 1;
			end else begin
				o_rd_empty <= 0;
			end
		end
	end

endmodule
```<|im_end|>
