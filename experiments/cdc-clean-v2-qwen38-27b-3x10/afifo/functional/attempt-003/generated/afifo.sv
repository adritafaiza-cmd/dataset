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

	// Storage
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write pointer (write clock domain)
	reg [PTR_W-1:0] wptr;
	// Read pointer (read clock domain)
	reg [PTR_W-1:0] rptr;

	// Synchronizers: write pointer to read domain
	reg [PTR_W-1:0] wptr_sync [0:NFF-1];
	// Synchronizers: read pointer to write domain
	reg [PTR_W-1:0] rptr_sync [0:NFF-1];

	// Write clock domain logic
	wire wclk_edge = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;
	wire wclk_neg  = WRITE_ON_POSEDGE ? ~i_wclk : i_wclk;

	// Write pointer increment
	wire wptr_inc = i_wr & ~o_wr_full;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			wptr <= {PTR_W{1'b0}};
		else if (wptr_inc)
			wptr <= wptr + 1'b1;
	end

	// Write data
	always @(posedge i_wclk) begin
		if (wptr_inc)
			mem[wptr[LGFIFO-1:0]] <= i_wr_data;
	end

	// Synchronize read pointer to write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			rptr_sync[0] <= {PTR_W{1'b0}};
			for (int i = 1; i < NFF; i = i + 1)
				rptr_sync[i] <= {PTR_W{1'b0}};
		end else begin
			rptr_sync[0] <= rptr;
			for (int i = 1; i < NFF; i = i + 1)
				rptr_sync[i] <= rptr_sync[i-1];
		end
	end

	// Full flag: write pointer has lapped read pointer by DEPTH
	wire [PTR_W-1:0] rptr_synced = rptr_sync[NFF-1];
	wire full = (wptr[PTR_W-1] != rptr_synced[PTR_W-1]) &&
	            (wptr[LGFIFO-1:0] == rptr_synced[LGFIFO-1:0]);

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			o_wr_full <= 1'b0;
		else
			o_wr_full <= full;
	end

	// Read clock domain logic
	// Synchronize write pointer to read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			wptr_sync[0] <= {PTR_W{1'b0}};
			for (int i = 1; i < NFF; i = i + 1)
				wptr_sync[i] <= {PTR_W{1'b0}};
		end else begin
			wptr_sync[0] <= wptr;
			for (int i = 1; i < NFF; i = i + 1)
				wptr_sync[i] <= wptr_sync[i-1];
		end
	end

	wire [PTR_W-1:0] wptr_synced = wptr_sync[NFF-1];

	// Empty flag: read pointer equals write pointer
	wire empty = (rptr == wptr_synced);

	// Read pointer increment
	wire rptr_inc = i_rd & ~empty;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			rptr <= {PTR_W{1'b0}};
		else if (rptr_inc)
			rptr <= rptr + 1'b1;
	end

	// Read data
	wire [WIDTH-1:0] rd_data_raw = mem[rptr[LGFIFO-1:0]];

	// Output registering
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= {WIDTH{1'b0}};
			o_rd_empty <= 1'b1;
		end else begin
			if (OPT_REGISTER_READS) begin
				// Additional output holding register
				o_rd_data <= rd_data_raw;
				o_rd_empty <= empty;
			end else begin
				// Destination-clock sample
				o_rd_data <= rd_data_raw;
				o_rd_empty <= empty;
			end
		end
	end

endmodule
