```verilog
module afifo #(
	parameter LGFIFO = 3,
	parameter WIDTH  = 16,
	parameter NFF    = 2,
	parameter [0:0] WRITE_ON_POSEDGE = 1'b1,
	parameter [0:0] OPT_REGISTER_READS = 1'b1
) (
	input	wire			i_wclk, i_wr_reset_n, i_wr,
	input	wire	[WIDTH-1:0]	i_wr_data,
	output	reg			o_wr_full,
	input	wire			i_rclk, i_rd_reset_n, i_rd,
	output	reg	[WIDTH-1:0]	o_rd_data,
	output	reg			o_rd_empty
);

	localparam DEPTH = 1 << LGFIFO;
	localparam MASK  = DEPTH - 1;

	// Write Pointer (Gray Code)
	reg [LGFIFO-1:0] wr_gray;
	reg [LGFIFO-1:0] wr_gray_next;
	reg [LGFIFO-1:0] wr_ptr;

	// Read Pointer (Gray Code)
	reg [LGFIFO-1:0] rd_gray;
	reg [LGFIFO-1:0] rd_gray_next;
	reg [LGFIFO-1:0] rd_ptr;

	// Counters for Full/Empty logic
	reg [LGFIFO+3:0] wr_cnt;
	reg [LGFIFO+3:0] rd_cnt;

	// Write Side Logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_gray <= 0;
			wr_cnt  <= 0;
			o_wr_full <= 1'b0;
		end else if (i_wr) begin
			// Generate Gray Code Next State
			wr_gray_next = wr_gray ^ {wr_gray[LGFIFO-1:1], 1'b0};
			
			// Handle Write Edge Sensing
			if (WRITE_ON_POSEDGE) begin
				// Simple edge detection on i_wr
				reg wr_prev;
				reg wr_edge;
				always @(posedge i_wclk) begin
					wr_prev <= i_wr;
					wr_edge <= (i_wr && !wr_prev);
				end
				if (wr_edge) begin
					wr_gray <= wr_gray_next;
					wr_cnt  <= wr_cnt + 1;
				end
			end else begin
				// Level sensitive (latch behavior on high)
				wr_gray <= wr_gray_next;
				wr_cnt  <= wr_cnt + 1;
			end
		end
	end

	// Read Side Logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_gray <= 0;
			rd_cnt  <= 0;
			o_rd_empty <= 1'b1;
		end else if (i_rd) begin
			// Generate Gray Code Next State
			rd_gray_next = rd_gray ^ {rd_gray[LGFIFO-1:1], 1'b0};

			if (OPT_REGISTER_READS) begin
				// Read from register (data is stable for one cycle)
				if (rd_gray == rd_gray_next) begin
					rd_gray <= rd_gray_next;
					rd_cnt  <= rd_cnt + 1;
				end
			end else begin
				// Read from latch (data valid immediately)
				rd_gray <= rd_gray_next;
				rd_cnt  <= rd_cnt + 1;
			end
		end
	end

	// Convert Gray Code to Binary
	function [LGFIFO-1:0] gray_to_bin;
		input [LGFIFO-1:0] gray;
		reg [LGFIFO-1:0] bin;
		reg [LGFIFO-1:0] temp;
		reg i;
	begin
		bin = 0;
		temp = gray;
		for (i = 0; i < LGFIFO; i = i + 1) begin
			bin[i] = temp[i] ^ bin[i+1];
		end
		gray_to_bin = bin;
	end
	endfunction

	// Full Logic
	// Full when write pointer catches up to read pointer + NFF
	// Using counters to avoid direct pointer comparison issues
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			o_wr_full <= 1'b0;
		else if (i_wr) begin
			// Full condition: (wr_cnt - rd_cnt) >= (DEPTH - NFF)
			// To avoid subtraction overflow, we check: wr_cnt >= rd_cnt + (DEPTH - NFF)
			// However, since rd_cnt is also incremented on read, we need to be careful.
			// Standard approach: Compare counters directly.
			// Full if: wr_cnt >= rd_cnt + (DEPTH - NFF)
			// But rd_cnt increments on read, so we must ensure we don't overestimate.
			// Correct logic: Full when the difference between write and read count reaches threshold.
			// Let's use the property: Full if (wr_cnt - rd_cnt) >= (DEPTH - NFF)
			// Since we can't easily subtract in combinational logic without risk, 
			// we rely on the fact that if wr_cnt wraps around and rd_cnt hasn't, it's full.
			// Actually, the standard robust way is:
			// Full if (wr_cnt >= rd_cnt + (DEPTH - NFF))
			// But rd_cnt is updated on read clock. 
			// Let's implement the counter comparison carefully.
			
			// Alternative robust implementation:
			// Full if (wr_cnt - rd_cnt) >= (DEPTH - NFF)
			// We will compute the difference safely.
			reg [LGFIFO+3:0] diff;
			if (wr_cnt >= rd_cnt)
				diff = wr_cnt - rd_cnt;
			else
				diff = wr_cnt + DEPTH - rd_cnt;
			
			if (diff >= (DEPTH - NFF))
				o_wr_full <= 1'b1;
			else
				o_wr_full <= 1'b0;
		end
	end

	// Empty Logic
	// Empty when read pointer catches up to write pointer
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			o_rd_empty <= 1'b1;
		else if (i_rd) begin
			reg [LGFIFO+3:0] diff;
			if (rd_cnt >= wr_cnt)
				diff = rd_cnt - wr_cnt;
			else
				diff = rd_cnt + DEPTH - wr_cnt;
			
			if (diff == 0)
				o_rd_empty <= 1'b1;
			else
				o_rd_empty <= 1'b0;
		end
	end

	// Data Memory
	// Write Port
	wire [WIDTH-1:0] wr_addr_bin = gray_to_bin(wr_gray);
	wire [WIDTH-1:0] wr_data = i_wr_data;

	// Read Port
	wire [WIDTH-1:0] rd_addr_bin = gray_to_bin(rd_gray);
	wire [WIDTH-1:0] rd_data;

	// Instantiate Memory
	// Using a generic memory block. Since no vendor primitives allowed, 
	// we define the memory as a reg array inside the module or use a procedural assignment.
	// For Verilog-2001, we can use a reg array if the size is known at compile time.
	// However, to be strictly compliant with "no vendor primitives" and standard synthesis,
	// we will use a reg array for the FIFO storage.
	
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write Process
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			// Clear memory on reset
			genvar g;
			for (g = 0; g < DEPTH; g = g + 1)
				mem[g] <= 0;
		end else if (i_wr) begin
			mem[wr_addr_bin] <= i_wr_data;
		end
	end

	// Read Process
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= 0;
		end else if (i_rd) begin
			o_rd_data <= mem[rd_addr_bin];
		end
	end

endmodule
```<|im_end|>
