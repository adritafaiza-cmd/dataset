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

	localparam DEPTH = 1 << LGFIFO;
	localparam PTR_W = LGFIFO + 1;
	localparam NFF_SAFE = (NFF < 2) ? 2 : NFF;

	// Write pointer (write clock domain)
	reg [PTR_W-1:0] wptr;
	// Read pointer (read clock domain)
	reg [PTR_W-1:0] rptr;

	// Gray code pointers
	wire [PTR_W-1:0] wptr_gray = wptr ^ {1'b0, wptr[PTR_W-1:1]};
	wire [PTR_W-1:0] rptr_gray = rptr ^ {1'b0, rptr[PTR_W-1:1]};

	// Synchronize write pointer gray to read clock domain
	reg [PTR_W-1:0] wptr_gray_r1, wptr_gray_r2, wptr_gray_r3;
	reg [PTR_W-1:0] wptr_gray_sync;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			wptr_gray_r1 <= {PTR_W{1'b0}};
			wptr_gray_r2 <= {PTR_W{1'b0}};
			wptr_gray_r3 <= {PTR_W{1'b0}};
			wptr_gray_sync <= {PTR_W{1'b0}};
		end else begin
			wptr_gray_r1 <= wptr_gray;
			wptr_gray_r2 <= wptr_gray_r1;
			wptr_gray_r3 <= wptr_gray_r2;
			wptr_gray_sync <= wptr_gray_r3;
		end
	end

	// Synchronize read pointer gray to write clock domain
	reg [PTR_W-1:0] rptr_gray_r1, rptr_gray_r2, rptr_gray_r3;
	reg [PTR_W-1:0] rptr_gray_sync;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			rptr_gray_r1 <= {PTR_W{1'b0}};
			rptr_gray_r2 <= {PTR_W{1'b0}};
			rptr_gray_r3 <= {PTR_W{1'b0}};
			rptr_gray_sync <= {PTR_W{1'b0}};
		end else begin
			rptr_gray_r1 <= rptr_gray;
			rptr_gray_r2 <= rptr_gray_r1;
			rptr_gray_r3 <= rptr_gray_r2;
			rptr_gray_sync <= rptr_gray_r3;
		end
	end

	// Convert synchronized gray to binary for comparison
	function [PTR_W-1:0] gray2bin;
		input [PTR_W-1:0] gray;
		reg [PTR_W-1:0] bin;
		integer i;
		begin
			bin[PTR_W-1] = gray[PTR_W-1];
			for (i = PTR_W-2; i >= 0; i = i - 1)
				bin[i] = bin[i+1] ^ gray[i];
			gray2bin = bin;
		end
	endfunction

	wire [PTR_W-1:0] wptr_gray_sync_bin = gray2bin(wptr_gray_sync);
	wire [PTR_W-1:0] rptr_gray_sync_bin = gray2bin(rptr_gray_sync);

	// Full condition: write pointer has lapped read pointer by DEPTH
	// In gray code, full when wptr_gray_sync_bin == rptr_gray_sync_bin with MSB different
	// Actually, for async FIFO, full when the upper bit of write pointer differs from read pointer
	// and the lower bits are equal.
	// wptr_gray_sync_bin is the binary write pointer as seen in read domain
	// rptr_gray_sync_bin is the binary read pointer as seen in write domain

	// Full: write pointer has advanced DEPTH ahead of read pointer
	// This means wptr_gray_sync_bin[PTR_W-1] != rptr_gray_sync_bin[PTR_W-1]
	// and wptr_gray_sync_bin[PTR_W-2:0] == rptr_gray_sync_bin[PTR_W-2:0]
	// But we need to be careful. The standard approach:
	// Full when the MSB of write pointer (in read domain) differs from MSB of read pointer
	// and the remaining bits are equal.

	wire full_internal = (wptr_gray_sync_bin[PTR_W-1] != rptr_gray_sync_bin[PTR_W-1]) &&
	                     (wptr_gray_sync_bin[PTR_W-2:0] == rptr_gray_sync_bin[PTR_W-2:0]);

	// Empty condition: write pointer equals read pointer
	wire empty_internal = (wptr_gray_sync_bin == rptr_gray_sync_bin);

	// Write pointer update
	wire wclk_edge = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;
	wire wr_en = i_wr & ~o_wr_full;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			wptr <= {PTR_W{1'b0}};
		else if (wr_en)
			wptr <= wptr + 1'b1;
	end

	// Read pointer update
	wire rd_en = i_rd & ~o_rd_empty;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			rptr <= {PTR_W{1'b0}};
		else if (rd_en)
			rptr <= rptr + 1'b1;
	end

	// Memory
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write to memory
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			// No action needed for memory on reset
		end else if (wr_en) begin
			mem[wptr[LGFIFO-1:0]] <= i_wr_data;
		end
	end

	// Read from memory
	wire [LGFIFO-1:0] rd_addr = rptr[LGFIFO-1:0];
	wire [WIDTH-1:0] mem_rd = mem[rd_addr];

	// Output logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
			o_rd_data <= {WIDTH{1'b0}};
		end else begin
			o_rd_empty <= empty_internal;
			if (OPT_REGISTER_READS)
				o_rd_data <= mem_rd;
			else
				o_rd_data <= mem_rd;
		end
	end

	// Full flag output
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			o_wr_full <= 1'b0;
		else
			o_wr_full <= full_internal;
	end

endmodule
