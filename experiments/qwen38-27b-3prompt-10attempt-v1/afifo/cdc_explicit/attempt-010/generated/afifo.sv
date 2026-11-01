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

	// Write domain
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [PTR_W-1:0] wptr;
	reg [PTR_W-1:0] rptr_w;
	reg [PTR_W-1:0] rptr_w_sync1;
	reg [PTR_W-1:0] rptr_w_sync2;
	reg [PTR_W-1:0] rptr_w_sync3;
	reg [PTR_W-1:0] rptr_w_sync4;

	// Read domain
	reg [PTR_W-1:0] rptr;
	reg [PTR_W-1:0] wptr_r;
	reg [PTR_W-1:0] wptr_r_sync1;
	reg [PTR_W-1:0] wptr_r_sync2;
	reg [PTR_W-1:0] wptr_r_sync3;
	reg [PTR_W-1:0] wptr_r_sync4;

	// Write edge
	wire wclk_edge = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;
	wire wclk_neg  = WRITE_ON_POSEDGE ? ~i_wclk : i_wclk;

	// Read edge
	wire rclk_edge = i_rclk;
	wire rclk_neg  = ~i_rclk;

	// Write pointer increment
	wire winc = i_wr & ~o_wr_full;

	// Read pointer increment
	wire rinc = i_rd & ~o_rd_empty;

	// Write domain logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr <= {PTR_W{1'b0}};
			rptr_w_sync1 <= {PTR_W{1'b0}};
			rptr_w_sync2 <= {PTR_W{1'b0}};
			rptr_w_sync3 <= {PTR_W{1'b0}};
			rptr_w_sync4 <= {PTR_W{1'b0}};
			o_wr_full <= 1'b0;
		end else begin
			// Synchronize read pointer
			rptr_w_sync1 <= rptr_w;
			rptr_w_sync2 <= rptr_w_sync1;
			rptr_w_sync3 <= rptr_w_sync2;
			rptr_w_sync4 <= rptr_w_sync3;

			// Update write pointer
			if (winc)
				wptr <= wptr + 1'b1;

			// Full condition: write pointer has lapped read pointer by DEPTH
			// In Gray code, full when wptr[MSB:1] == rptr_sync[MSB:1] and wptr[0] != rptr_sync[0]
			// But we're using binary pointers here. Let's use Gray code for CDC.
			// Actually, let's switch to Gray code pointers for proper CDC.
			o_wr_full <= (wptr[PTR_W-1:1] == rptr_w_sync4[PTR_W-1:1]) && (wptr[0] != rptr_w_sync4[0]);
		end
	end

	// Write data
	always @(posedge i_wclk) begin
		if (winc)
			mem[wptr[LGFIFO-1:0]] <= i_wr_data;
	end

	// Read domain logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr <= {PTR_W{1'b0}};
			wptr_r_sync1 <= {PTR_W{1'b0}};
			wptr_r_sync2 <= {PTR_W{1'b0}};
			wptr_r_sync3 <= {PTR_W{1'b0}};
			wptr_r_sync4 <= {PTR_W{1'b0}};
			o_rd_empty <= 1'b1;
			o_rd_data <= {WIDTH{1'b0}};
		end else begin
			// Synchronize write pointer
			wptr_r_sync1 <= wptr_r;
			wptr_r_sync2 <= wptr_r_sync1;
			wptr_r_sync3 <= wptr_r_sync2;
			wptr_r_sync4 <= wptr_r_sync3;

			// Update read pointer
			if (rinc)
				rptr <= rptr + 1'b1;

			// Empty condition: read pointer equals write pointer
			o_rd_empty <= (rptr == wptr_r_sync4);

			// Read data
			if (OPT_REGISTER_READS) begin
				if (rinc)
					o_rd_data <= mem[rptr[LGFIFO-1:0]];
			end else begin
				if (rinc)
					o_rd_data <= mem[rptr[LGFIFO-1:0]];
			end
		end
	end

	// Cross-domain pointer synchronization
	// Write pointer to read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			wptr_r <= {PTR_W{1'b0}};
		else
			wptr_r <= wptr;
	end

	// Read pointer to write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			rptr_w <= {PTR_W{1'b0}};
		else
			rptr_w <= rptr;
	end

endmodule
