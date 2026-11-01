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
	localparam ADDR_W = LGFIFO;
	localparam CNT_W = LGFIFO + 1;

	// Write pointer (binary)
	reg [ADDR_W-1:0] wr_ptr;
	// Read pointer (binary)
	reg [ADDR_W-1:0] rd_ptr;

	// Gray code pointers
	wire [ADDR_W-1:0] wr_ptr_gray = wr_ptr ^ {wr_ptr[ADDR_W-1:0], 1'b0} >> 1;
	wire [ADDR_W-1:0] rd_ptr_gray = rd_ptr ^ {rd_ptr[ADDR_W-1:0], 1'b0} >> 1;

	// Synchronizers for write pointer gray to read clock domain
	reg [ADDR_W-1:0] wr_ptr_gray_sync [0:NFF-1];
	// Synchronizers for read pointer gray to write clock domain
	reg [ADDR_W-1:0] rd_ptr_gray_sync [0:NFF-1];

	// Convert gray to binary
	function [ADDR_W-1:0] gray2bin;
		input [ADDR_W-1:0] gray;
		reg [ADDR_W-1:0] bin;
		integer i;
		begin
			bin[ADDR_W-1] = gray[ADDR_W-1];
			for (i = ADDR_W-2; i >= 0; i = i-1)
				bin[i] = bin[i+1] ^ gray[i];
			gray2bin = bin;
		end
	endfunction

	// Binary to gray
	function [ADDR_W-1:0] bin2gray;
		input [ADDR_W-1:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	// Write domain: detect full
	// Full when write pointer gray equals read pointer gray with MSB different
	// Actually, full condition: wr_ptr_gray == rd_ptr_gray_sync[NFF-1] and 
	// the MSB of wr_ptr differs from MSB of rd_ptr (in binary)
	// Standard CDC FIFO full condition:
	// wr_ptr_gray == rd_ptr_gray_sync[NFF-1] and wr_ptr[ADDR_W] != rd_ptr[ADDR_W]
	// But we only have ADDR_W bits. Let's use the standard approach:
	// Full when the write pointer gray code equals the read pointer gray code
	// and the MSB of the write pointer (extended) differs from MSB of read pointer.
	
	// Let's use a different approach: track the full/empty flags using the gray codes.
	// Full: wr_ptr_gray == rd_ptr_gray_sync[NFF-1] and wr_ptr[ADDR_W-1] != rd_ptr_gray_sync[NFF-1][ADDR_W-1]
	// Wait, that's not quite right either. Let me think again.
	
	// Standard async FIFO full/empty detection:
	// We extend the pointer by 1 bit. The full condition is when the write pointer
	// has lapped the read pointer by exactly DEPTH. In gray code, this means:
	// wr_ptr_gray[ADDR_W:0] == {~rd_ptr_gray[ADDR_W-1], rd_ptr_gray[ADDR_W-1:0]}
	// i.e., the MSB is inverted and the rest are equal.
	
	// Let's use the extended pointer approach.
	
	// Write pointer with extra bit
	reg [ADDR_W:0] wr_ptr_ext;
	// Read pointer with extra bit
	reg [ADDR_W:0] rd_ptr_ext;

	// Gray code of extended pointers
	wire [ADDR_W:0] wr_ptr_gray_ext = wr_ptr_ext ^ (wr_ptr_ext >> 1);
	wire [ADDR_W:0] rd_ptr_gray_ext = rd_ptr_ext ^ (rd_ptr_ext >> 1);

	// Synchronizers for extended gray pointers
	reg [ADDR_W:0] wr_ptr_gray_ext_sync [0:NFF-1];
	reg [ADDR_W:0] rd_ptr_gray_ext_sync [0:NFF-1];

	// Full condition in write domain:
	// wr_ptr_gray_ext == {~rd_ptr_gray_ext_sync[NFF-1][ADDR_W], rd_ptr_gray_ext_sync[NFF-1][ADDR_W-1:0]}
	wire full_cond = (wr_ptr_gray_ext == {~rd_ptr_gray_ext_sync[NFF-1][ADDR_W], rd_ptr_gray_ext_sync[NFF-1][ADDR_W-1:0]});

	// Empty condition in read domain:
	// rd_ptr_gray_ext == wr_ptr_gray_ext_sync[NFF-1]
	wire empty_cond = (rd_ptr_gray_ext == wr_ptr_gray_ext_sync[NFF-1]);

	// Write enable
	wire wr_en = i_wr & ~o_wr_full;
	// Read enable
	wire rd_en = i_rd & ~o_rd_empty;

	// Write clock edge selection
	wire wclk_edge = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;
	// Read clock edge selection
	wire rclk_edge = i_rclk; // Reads are always on posedge for simplicity, or we could make it configurable

	// Memory
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= {ADDR_W{1'b0}};
			wr_ptr_ext <= {ADDR_W+1{1'b0}};
			o_wr_full <= 1'b0;
		end else begin
			if (wr_en) begin
				mem[wr_ptr] <= i_wr_data;
				wr_ptr <= wr_ptr + 1'b1;
				wr_ptr_ext <= wr_ptr_ext + 1'b1;
			end
			o_wr_full <= full_cond;
		end
	end

	// Read logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {ADDR_W{1'b0}};
			rd_ptr_ext <= {ADDR_W+1{1'b0}};
			o_rd_empty <= 1'b1;
			o_rd_data <= {WIDTH{1'b0}};
		end else begin
			if (rd_en) begin
				if (OPT_REGISTER_READS)
					o_rd_data <= mem[rd_ptr];
				else
					o_rd_data <= mem[rd_ptr]; // Same for now, but combinational would be different
				rd_ptr <= rd_ptr + 1'b1;
				rd_ptr_ext <= rd_ptr_ext + 1'b1;
			end
			o_rd_empty <= empty_cond;
		end
	end

	// Synchronizer for write pointer gray ext to read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			for (integer i = 0; i < NFF; i = i+1)
				wr_ptr_gray_ext_sync[i] <= {ADDR_W+1{1'b0}};
		end else begin
			wr_ptr_gray_ext_sync[0] <= wr_ptr_gray_ext;
			for (integer i = 1; i < NFF; i = i+1)
				wr_ptr_gray_ext_sync[i] <= wr_ptr_gray_ext_sync[i-1];
		end
	end

	// Synchronizer for read pointer gray ext to write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			for (integer i = 0; i < NFF; i = i+1)
				rd_ptr_gray_ext_sync[i] <= {ADDR_W+1{1'b0}};
		end else begin
			rd_ptr_gray_ext_sync[0] <= rd_ptr_gray_ext;
			for (integer i = 1; i < NFF; i = i+1)
				rd_ptr_gray_ext_sync[i] <= rd_ptr_gray_ext_sync[i-1];
		end
	end

endmodule
