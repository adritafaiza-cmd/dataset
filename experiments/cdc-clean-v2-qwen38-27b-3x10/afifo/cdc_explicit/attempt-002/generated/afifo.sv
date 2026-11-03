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

	// Derived parameters
	localparam DEPTH = 1 << LGFIFO;
	localparam PTR_W = LGFIFO;
	localparam NFF_SAFE = (NFF < 2) ? 2 : NFF;

	// Write domain signals
	reg [PTR_W-1:0] w_ptr;
	reg [PTR_W-1:0] r_ptr_w_sync;
	reg [WIDTH-1:0] w_data_reg;
	reg w_req;
	reg w_ack_sync;
	reg [WIDTH-1:0] w_data_hold;
	reg w_data_hold_valid;

	// Read domain signals
	reg [PTR_W-1:0] r_ptr;
	reg [PTR_W-1:0] w_ptr_r_sync;
	reg [WIDTH-1:0] r_data_reg;
	reg r_ack;
	reg r_req_sync;
	reg [WIDTH-1:0] r_data_hold;
	reg r_data_hold_valid;

	// Synchronizer chains for control signals
	// w_req: write domain -> read domain
	reg [NFF_SAFE-1:0] w_req_sync;
	// w_ack: read domain -> write domain
	reg [NFF_SAFE-1:0] w_ack_sync;
	// r_req: read domain -> write domain (not used in this design, but for completeness)
	// r_ack: write domain -> read domain (not used in this design)

	// Synchronizer chains for pointer bits (for full/empty detection)
	// w_ptr: write domain -> read domain
	reg [NFF_SAFE-1:0][PTR_W-1:0] w_ptr_sync;
	// r_ptr: read domain -> write domain
	reg [NFF_SAFE-1:0][PTR_W-1:0] r_ptr_sync;

	// Write domain logic
	// Determine write clock edge
	wire w_clk_edge = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;
	wire w_clk_neg  = WRITE_ON_POSEDGE ? ~i_wclk : i_wclk;

	// Write pointer increment
	wire w_ptr_inc = i_wr & ~o_wr_full;

	// Write data register
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			w_data_reg <= {WIDTH{1'b0}};
		end else if (i_wr & ~o_wr_full) begin
			w_data_reg <= i_wr_data;
		end
	end

	// Write pointer
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			w_ptr <= {PTR_W{1'b0}};
		end else if (i_wr & ~o_wr_full) begin
			w_ptr <= w_ptr + 1'b1;
		end
	end

	// Write request generation
	// We generate a request when we have data to send and haven't been acknowledged yet
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			w_req <= 1'b0;
			w_data_hold <= {WIDTH{1'b0}};
			w_data_hold_valid <= 1'b0;
		end else begin
			if (w_ack_sync[NFF_SAFE-1]) begin
				// Acknowledged, clear request
				w_req <= 1'b0;
				w_data_hold_valid <= 1'b0;
			end else if (i_wr & ~o_wr_full) begin
				// New write, set request
				w_req <= 1'b1;
				w_data_hold <= i_wr_data;
				w_data_hold_valid <= 1'b1;
			end
		end
	end

	// Synchronize w_req to read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			w_req_sync <= {NFF_SAFE{1'b0}};
		end else begin
			w_req_sync <= {w_req_sync[NFF_SAFE-2:0], w_req};
		end
	end

	// Synchronize w_ack to write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			w_ack_sync <= {NFF_SAFE{1'b0}};
		end else begin
			w_ack_sync <= {w_ack_sync[NFF_SAFE-2:0], r_ack};
		end
	end

	// Synchronize w_ptr to read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			w_ptr_sync <= {NFF_SAFE{1'b0}};
		end else begin
			w_ptr_sync <= {w_ptr_sync[NFF_SAFE-2:0], w_ptr};
		end
	end

	// Synchronize r_ptr to write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			r_ptr_sync <= {NFF_SAFE{1'b0}};
		end else begin
			r_ptr_sync <= {r_ptr_sync[NFF_SAFE-2:0], r_ptr};
		end
	end

	// Full detection in write domain
	// Full when w_ptr - r_ptr_sync == DEPTH
	// i.e., w_ptr[MSB:1] == r_ptr_sync[MSB:1] and w_ptr[0] != r_ptr_sync[0]
	wire [PTR_W-1:0] r_ptr_w = r_ptr_sync[NFF_SAFE-1];
	wire full_internal = (w_ptr[PTR_W-1:1] == r_ptr_w[PTR_W-1:1]) && (w_ptr[0] != r_ptr_w[0]);

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= full_internal;
		end
	end

	// Read domain logic
	// Determine read clock edge (reads are always on posedge)
	wire r_clk_edge = i_rclk;

	// Read pointer increment
	wire r_ptr_inc = i_rd & ~o_rd_empty;

	// Read pointer
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			r_ptr <= {PTR_W{1'b0}};
		end else if (i_rd & ~o_rd_empty) begin
			r_ptr <= r_ptr + 1'b1;
		end
	end

	// Read acknowledge generation
	// We acknowledge when we have received a request and are ready to accept it
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			r_ack <= 1'b0;
			r_data_hold <= {WIDTH{1'b0}};
			r_data_hold_valid <= 1'b0;
		end else begin
			if (w_req_sync[NFF_SAFE-1] && !r_data_hold_valid) begin
				// Request received, hold data and acknowledge
				r_ack <= 1'b1;
				r_data_hold <= w_data_hold;
				r_data_hold_valid <= 1'b1;
			end else if (i_rd & ~o_rd_empty) begin
				// Data consumed, clear hold
				r_ack <= 1'b0;
				r_data_hold_valid <= 1'b0;
			end else begin
				r_ack <= 1'b0;
			end
		end
	end

	// Empty detection in read domain
	// Empty when w_ptr_sync - r_ptr == 0
	// i.e., w_ptr_sync == r_ptr
	wire [PTR_W-1:0] w_ptr_r = w_ptr_sync[NFF_SAFE-1];
	wire empty_internal = (w_ptr_r == r_ptr);

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= empty_internal;
		end
	end

	// Read data output
	// The data is held in r_data_hold when a request is received
	// We need to present the data when it's available
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= {WIDTH{1'b0}};
		end else begin
			if (r_data_hold_valid) begin
				o_rd_data <= r_data_hold;
			end
		end
	end

	// OPT_REGISTER_READS: additional output registering
	// If OPT_REGISTER_READS is 1, we add another stage of registering
	// The payload must always have destination-clock synchronization
	// We interpret this as: if OPT_REGISTER_READS is 1, o_rd_data is registered one more time
	// But since o_rd_data is already registered, we need to be careful
	// Let's use a separate register for the final output

	reg [WIDTH-1:0] o_rd_data_internal;
	reg o_rd_empty_internal;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data_internal <= {WIDTH{1'b0}};
			o_rd_empty_internal <= 1'b1;
		end else begin
			o_rd_data_internal <= o_rd_data;
			o_rd_empty_internal <= o_rd_empty;
		end
	end

	// Assign final outputs based on OPT_REGISTER_READS
	// If OPT_REGISTER_READS is 1, use the additional registered version
	// If 0, use the direct version
	// But o_rd_data and o_rd_empty are declared as reg, so we need to assign them
	// Let's restructure: use internal signals and assign to outputs

	// Actually, let's simplify: always register the output, and OPT_REGISTER_READS
	// controls whether we add an extra stage. Since the spec says "OPT_REGISTER_READS
	// selects additional output registering", we'll add one more stage when it's 1.

	// For now, let's just use the current o_rd_data and o_rd_empty as the final outputs
	// and add the extra stage if needed

	// Let me restructure the read data path
	// Stage 1: r_data_hold (when request received)
	// Stage 2: o_rd_data (registered)
	// Stage 3 (if OPT_REGISTER_READS): additional register

	reg [WIDTH-1:0] rd_data_stage1;
	reg [WIDTH-1:0] rd_data_stage2;
	reg rd_empty_stage1;
	reg rd_empty_stage2;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_stage1 <= {WIDTH{1'b0}};
			rd_empty_stage1 <= 1'b1;
		end else begin
			if (r_data_hold_valid) begin
				rd_data_stage1 <= r_data_hold;
			end
			rd_empty_stage1 <= empty_internal;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_stage2 <= {WIDTH{1'b0}};
			rd_empty_stage2 <= 1'b1;
		end else begin
			rd_data_stage2 <= rd_data_stage1;
			rd_empty_stage2 <= rd_empty_stage1;
		end
	end

	// Assign to outputs
	always @(*) begin
		if (OPT_REGISTER_READS) begin
			o_rd_data = rd_data_stage2;
			o_rd_empty = rd_empty_stage2;
		end else begin
			o_rd_data = rd_data_stage1;
			o_rd_empty = rd_empty_stage1;
		end
	end

endmodule
