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

	// Internal parameters
	localparam DEPTH = 1 << LGFIFO;
	localparam ADDR_WIDTH = LGFIFO;
	localparam CNT_WIDTH = LGFIFO + 1;

	// Storage
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write pointer (write clock domain)
	reg [ADDR_WIDTH:0] wptr; // extra bit for gray code conversion

	// Read pointer (read clock domain)
	reg [ADDR_WIDTH:0] rptr;

	// Gray code pointers
	wire [ADDR_WIDTH:0] wptr_gray;
	wire [ADDR_WIDTH:0] rptr_gray;

	// Synchronizers
	reg [ADDR_WIDTH:0] wptr_gray_sync [0:NFF-1];
	reg [ADDR_WIDTH:0] rptr_gray_sync [0:NFF-1];

	// Full/Empty flags
	wire full;
	wire empty;

	// Write enable
	wire wr_en;

	// Read enable
	wire rd_en;

	// Write clock edge selection
	wire wclk_edge;

	// Gray code conversion
	function [ADDR_WIDTH:0] bin2gray;
		input [ADDR_WIDTH:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	// Write clock edge
	assign wclk_edge = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;

	// Write enable: write accepted when i_wr high and not full
	assign wr_en = i_wr & ~full;

	// Read enable: read accepted when i_rd high and not empty
	assign rd_en = i_rd & ~empty;

	// Gray code pointers
	assign wptr_gray = bin2gray(wptr);
	assign rptr_gray = bin2gray(rptr);

	// Full condition: write pointer has lapped read pointer
	// In gray code, full when wptr_gray == rptr_gray with the MSB different
	// Actually, for a FIFO of size 2^LGFIFO, full when:
	// wptr_gray[ADDR_WIDTH] != rptr_gray[ADDR_WIDTH] && wptr_gray[ADDR_WIDTH-1:0] == rptr_gray[ADDR_WIDTH-1:0]
	// But we need to use the synchronized read pointer in write domain
	// and synchronized write pointer in read domain

	// Synchronized read pointer in write domain
	wire [ADDR_WIDTH:0] rptr_gray_w = wptr_gray_sync[NFF-1];

	// Synchronized write pointer in read domain
	wire [ADDR_WIDTH:0] wptr_gray_r = rptr_gray_sync[NFF-1];

	// Full: write pointer gray MSB differs from read pointer gray MSB, and lower bits match
	assign full = (wptr_gray[ADDR_WIDTH] != rptr_gray_w[ADDR_WIDTH]) &&
	              (wptr_gray[ADDR_WIDTH-1:0] == rptr_gray_w[ADDR_WIDTH-1:0]);

	// Empty: write pointer gray equals read pointer gray
	assign empty = (wptr_gray_r == rptr_gray);

	// Write pointer update
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			wptr <= {(ADDR_WIDTH+1){1'b0}};
		else if (wr_en)
			wptr <= wptr + 1'b1;
	end

	// Read pointer update
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			rptr <= {(ADDR_WIDTH+1){1'b0}};
		else if (rd_en)
			rptr <= rptr + 1'b1;
	end

	// Memory write
	always @(posedge i_wclk) begin
		if (wr_en)
			mem[wptr[ADDR_WIDTH-1:0]] <= i_wr_data;
	end

	// Synchronizer for write pointer gray to read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			for (int i = 0; i < NFF; i = i + 1)
				rptr_gray_sync[i] <= {(ADDR_WIDTH+1){1'b0}};
		end else begin
			rptr_gray_sync[0] <= wptr_gray;
			for (int i = 1; i < NFF; i = i + 1)
				rptr_gray_sync[i] <= rptr_gray_sync[i-1];
		end
	end

	// Synchronizer for read pointer gray to write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			for (int i = 0; i < NFF; i = i + 1)
				wptr_gray_sync[i] <= {(ADDR_WIDTH+1){1'b0}};
		end else begin
			wptr_gray_sync[0] <= rptr_gray;
			for (int i = 1; i < NFF; i = i + 1)
				wptr_gray_sync[i] <= wptr_gray_sync[i-1];
		end
	end

	// Output flags
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			o_wr_full <= 1'b0;
		else
			o_wr_full <= full;
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			o_rd_empty <= 1'b1;
		else
			o_rd_empty <= empty;
	end

	// Read data output
	// The read address is the lower bits of rptr
	wire [ADDR_WIDTH-1:0] rd_addr = rptr[ADDR_WIDTH-1:0];

	// If OPT_REGISTER_READS is 1, register the read data
	// If OPT_REGISTER_READS is 0, still need destination-clock synchronization
	// The spec says: "the payload must always have destination-clock synchronization"
	// and "OPT_REGISTER_READS selects an additional output holding register or a destination-clock sample"
	// So in both cases, we need at least one register stage in the read clock domain.

	// Read data from memory
	wire [WIDTH-1:0] rd_data_comb = mem[rd_addr];

	// Register the read data in read clock domain
	reg [WIDTH-1:0] rd_data_reg;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			rd_data_reg <= {WIDTH{1'b0}};
		else
			rd_data_reg <= rd_data_comb;
	end

	// Output
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			o_rd_data <= {WIDTH{1'b0}};
		else
			o_rd_data <= rd_data_reg;
	end

endmodule
