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

	// Memory
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write pointer (binary)
	reg [PTR_W-1:0] wptr_bin;
	// Read pointer (binary)
	reg [PTR_W-1:0] rptr_bin;

	// Gray code pointers
	wire [PTR_W-1:0] wptr_gray = wptr_bin ^ (wptr_bin >> 1);
	wire [PTR_W-1:0] rptr_gray = rptr_bin ^ (rptr_bin >> 1);

	// Synchronizers for write pointer gray to read clock domain
	reg [PTR_W-1:0] wptr_gray_r1, wptr_gray_r2, wptr_gray_r3;
	// Synchronizers for read pointer gray to write clock domain
	reg [PTR_W-1:0] rptr_gray_r1, rptr_gray_r2, rptr_gray_r3;

	// Write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr_bin <= {PTR_W{1'b0}};
		end else begin
			if (i_wr && !o_wr_full) begin
				wptr_bin <= wptr_bin + 1'b1;
			end
		end
	end

	// Read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr_bin <= {PTR_W{1'b0}};
		end else begin
			if (i_rd && !o_rd_empty) begin
				rptr_bin <= rptr_bin + 1'b1;
			end
		end
	end

	// Synchronize wptr_gray to read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			wptr_gray_r1 <= {PTR_W{1'b0}};
			wptr_gray_r2 <= {PTR_W{1'b0}};
			wptr_gray_r3 <= {PTR_W{1'b0}};
		end else begin
			wptr_gray_r1 <= wptr_gray;
			wptr_gray_r2 <= wptr_gray_r1;
			wptr_gray_r3 <= wptr_gray_r2;
		end
	end

	// Synchronize rptr_gray to write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			rptr_gray_r1 <= {PTR_W{1'b0}};
			rptr_gray_r2 <= {PTR_W{1'b0}};
			rptr_gray_r3 <= {PTR_W{1'b0}};
		end else begin
			rptr_gray_r1 <= rptr_gray;
			rptr_gray_r2 <= rptr_gray_r1;
			rptr_gray_r3 <= rptr_gray_r2;
		end
	end

	// Convert gray to binary
	function [PTR_W-1:0] gray2bin;
		input [PTR_W-1:0] gray;
		reg [PTR_W-1:0] bin;
		begin
			bin[PTR_W-1] = gray[PTR_W-1];
			for (integer i = PTR_W-2; i >= 0; i = i - 1) begin
				bin[i] = bin[i+1] ^ gray[i];
			end
			gray2bin = bin;
		end
	endfunction

	// Full flag: write pointer has lapped read pointer by DEPTH
	// In gray code, full when wptr_gray == rptr_gray with MSB different
	// Actually: full when (wptr_gray ^ rptr_gray) == (1 << (LGFIFO)) i.e., only bit LGFIFO differs
	// More precisely: full when wptr_gray[PTR_W-1] != rptr_gray[PTR_W-1] and wptr_gray[LGFIFO-1:0] == rptr_gray[LGFIFO-1:0]
	wire full_flag = (wptr_gray[PTR_W-1] != rptr_gray_r3[PTR_W-1]) && 
					 (wptr_gray[LGFIFO-1:0] == rptr_gray_r3[LGFIFO-1:0]);

	// Empty flag: read pointer equals write pointer
	wire empty_flag = (rptr_gray == wptr_gray_r3);

	// Write full output
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= full_flag;
		end
	end

	// Read empty output
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= empty_flag;
		end
	end

	// Memory write
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			// No action needed for memory
		end else begin
			if (i_wr && !o_wr_full) begin
				mem[wptr_bin[LGFIFO-1:0]] <= i_wr_data;
			end
		end
	end

	// Read data output
	// If OPT_REGISTER_READS, register the read data
	// The read address is rptr_bin[LGFIFO-1:0]
	// For registered reads, we need to capture the data when a read is accepted
	// For combinational reads, o_rd_data is directly from memory

	// We'll use a registered approach for OPT_REGISTER_READS
	// The read address for the current read is rptr_bin[LGFIFO-1:0]
	// When a read is accepted, we capture mem[rptr_bin[LGFIFO-1:0]]

	// For simplicity and correctness, let's use:
	// - If OPT_REGISTER_READS: o_rd_data is registered, updated on read
	// - If !OPT_REGISTER_READS: o_rd_data is combinational from memory

	// Let's implement both cases
	// We need to be careful: the read address is rptr_bin[LGFIFO-1:0]
	// When a read is accepted, the data at that address is valid

	// For registered reads:
	// On posedge i_rclk, if i_rd && !o_rd_empty, capture mem[rptr_bin[LGFIFO-1:0]]
	// But rptr_bin is updated on the same clock edge, so we need to use the old rptr_bin
	// Actually, in the always block, rptr_bin is the current value before update
	// So mem[rptr_bin[LGFIFO-1:0]] is the correct data to read

	// Let's use a wire for the read data from memory
	wire [WIDTH-1:0] mem_rd_data = mem[rptr_bin[LGFIFO-1:0]];

	// For registered reads
	reg [WIDTH-1:0] rd_data_reg;
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_reg <= {WIDTH{1'b0}};
		end else begin
			if (i_rd && !o_rd_empty) begin
				rd_data_reg <= mem_rd_data;
			end
		end
	end

	// Assign o_rd_data based on OPT_REGISTER_READS
	// We need to use a continuous assignment or an always block
	// Since o_rd_data is a reg, we'll use an always block

	always @(*) begin
		if (OPT_REGISTER_READS) begin
			o_rd_data = rd_data_reg;
		end else begin
			o_rd_data = mem_rd_data;
		end
	end

endmodule
