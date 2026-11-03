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

	// Storage
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write pointer (read/write clock domain)
	reg [ADDR_W:0] wr_ptr;
	// Read pointer (read clock domain)
	reg [ADDR_W:0] rd_ptr;

	// Synchronizers for write pointer to read clock domain
	reg [ADDR_W:0] wr_ptr_sync [0:NFF-1];
	// Synchronizers for read pointer to write clock domain
	reg [ADDR_W:0] rd_ptr_sync [0:NFF-1];

	// Write side
	wire wr_en = i_wr & ~o_wr_full;
	wire [ADDR_W-1:0] wr_addr = wr_ptr[ADDR_W-1:0];

	// Read side
	wire rd_en = i_rd & ~o_rd_empty;
	wire [ADDR_W-1:0] rd_addr = rd_ptr[ADDR_W-1:0];

	// Write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= {(ADDR_W+1){1'b0}};
		end else if (wr_en) begin
			wr_ptr <= wr_ptr + 1'b1;
		end
	end

	// Write data
	always @(posedge i_wclk) begin
		if (wr_en) begin
			mem[wr_addr] <= i_wr_data;
		end
	end

	// Read pointer synchronizer to write clock domain
	always @(posedge i_wclk) begin
		wr_ptr_sync[0] <= rd_ptr;
		for (int i = 1; i < NFF; i = i + 1) begin
			wr_ptr_sync[i] <= wr_ptr_sync[i-1];
		end
	end

	// Full flag: write pointer has lapped read pointer by DEPTH
	// Compare the upper bits (gray code style or binary with extra bit)
	// For binary pointers, full when wr_ptr[ADDR_W] != rd_ptr_sync[NFF-1][ADDR_W] 
	// and wr_ptr[ADDR_W-1:0] == rd_ptr_sync[NFF-1][ADDR_W-1:0]
	// Actually, simpler: full when (wr_ptr - rd_ptr_sync[NFF-1]) == DEPTH
	// Using the standard approach: full when the MSB differs and the lower bits are equal
	wire [ADDR_W:0] rd_ptr_wclk = rd_ptr_sync[NFF-1];
	wire full_raw = (wr_ptr[ADDR_W] != rd_ptr_wclk[ADDR_W]) && 
	                (wr_ptr[ADDR_W-1:0] == rd_ptr_wclk[ADDR_W-1:0]);

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= full_raw;
		end
	end

	// Read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {(ADDR_W+1){1'b0}};
		end else if (rd_en) begin
			rd_ptr <= rd_ptr + 1'b1;
		end
	end

	// Write pointer synchronizer to read clock domain
	always @(posedge i_rclk) begin
		rd_ptr_sync[0] <= wr_ptr;
		for (int i = 1; i < NFF; i = i + 1) begin
			rd_ptr_sync[i] <= rd_ptr_sync[i-1];
		end
	end

	// Empty flag: read pointer equals write pointer
	wire [ADDR_W:0] wr_ptr_rclk = rd_ptr_sync[NFF-1];
	wire empty_raw = (rd_ptr == wr_ptr_rclk);

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= empty_raw;
		end
	end

	// Read data output
	// OPT_REGISTER_READS: if 1, register the read data; if 0, combinational read
	// But the spec says "the payload must always have destination-clock synchronization"
	// and "neither setting provides an asynchronous memory bypass"
	// So we always read from memory on the read clock.
	// OPT_REGISTER_READS selects an additional output holding register or a destination-clock sample.
	
	// First, read from memory
	reg [WIDTH-1:0] rd_data_reg;
	
	always @(posedge i_rclk) begin
		rd_data_reg <= mem[rd_addr];
	end

	// If OPT_REGISTER_READS is 1, add another register stage
	// If 0, just use the first register
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= {WIDTH{1'b0}};
		end else if (OPT_REGISTER_READS) begin
			o_rd_data <= rd_data_reg;
		end else begin
			o_rd_data <= rd_data_reg;
		end
	end

endmodule
