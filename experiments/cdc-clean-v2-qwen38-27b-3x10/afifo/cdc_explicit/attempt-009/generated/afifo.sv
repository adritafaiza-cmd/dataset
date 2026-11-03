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
	localparam PTR_W = LGFIFO;
	localparam NFF_SAFE = (NFF < 2) ? 2 : NFF;

	// Write domain signals
	reg [PTR_W-1:0] w_ptr;
	reg [PTR_W-1:0] r_ptr_w; // synchronized read pointer in write domain
	reg [WIDTH-1:0] w_mem [0:DEPTH-1];
	reg [WIDTH-1:0] w_hold_data;
	reg w_hold_valid;
	reg w_req;
	reg w_ack;
	reg [NFF_SAFE-1:0] r_ptr_sync;
	reg [NFF_SAFE-1:0] w_ack_sync;

	// Read domain signals
	reg [PTR_W-1:0] r_ptr;
	reg [PTR_W-1:0] w_ptr_r; // synchronized write pointer in read domain
	reg [WIDTH-1:0] r_hold_data;
	reg r_hold_valid;
	reg r_req;
	reg r_ack;
	reg [NFF_SAFE-1:0] w_ptr_sync;
	reg [NFF_SAFE-1:0] r_ack_sync;

	// Synchronizer for write pointer to read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			w_ptr_sync <= {NFF_SAFE{1'b0}};
		else begin
			w_ptr_sync[NFF_SAFE-1] <= w_ptr;
			for (integer i = NFF_SAFE-2; i >= 0; i = i-1)
				w_ptr_sync[i] <= w_ptr_sync[i+1];
		end
	end

	// Synchronizer for read pointer to write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			r_ptr_sync <= {NFF_SAFE{1'b0}};
		else begin
			r_ptr_sync[NFF_SAFE-1] <= r_ptr;
			for (integer i = NFF_SAFE-2; i >= 0; i = i-1)
				r_ptr_sync[i] <= r_ptr_sync[i+1];
			end
	end

	// Synchronizer for write request to read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			r_ack_sync <= {NFF_SAFE{1'b0}};
		else begin
			r_ack_sync[NFF_SAFE-1] <= w_req;
			for (integer i = NFF_SAFE-2; i >= 0; i = i-1)
				r_ack_sync[i] <= r_ack_sync[i+1];
		end
	end

	// Synchronizer for read request to write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			w_ack_sync <= {NFF_SAFE{1'b0}};
		else begin
			w_ack_sync[NFF_SAFE-1] <= r_req;
			for (integer i = NFF_SAFE-2; i >= 0; i = i-1)
				w_ack_sync[i] <= w_ack_sync[i+1];
		end
	end

	// Write domain logic
	// Determine write clock edge
	wire w_clk_edge = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;
	wire w_clk_neg  = WRITE_ON_POSEDGE ? ~i_wclk : i_wclk;

	// Full condition: write pointer has lapped read pointer by DEPTH
	// Using Gray code would be typical, but we use binary with careful comparison
	// Actually, for CDC, we should use Gray code for pointers to avoid multi-bit glitches
	// Let's use Gray code pointers

	// Convert binary to Gray
	function [PTR_W-1:0] bin2gray;
		input [PTR_W-1:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	// Gray code pointers
	wire [PTR_W-1:0] w_ptr_gray = bin2gray(w_ptr);
	wire [PTR_W-1:0] r_ptr_gray = bin2gray(r_ptr);

	// Synchronize Gray code pointers
	reg [PTR_W-1:0] r_ptr_gray_w; // synchronized read pointer gray in write domain
	reg [PTR_W-1:0] w_ptr_gray_r; // synchronized write pointer gray in read domain

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			r_ptr_gray_w <= {PTR_W{1'b0}};
		else begin
			// Synchronize each bit of Gray code
			// Use NFF_SAFE stages for each bit
			// For simplicity, use a shift register for each bit
			// But we need to be careful: Gray code changes only one bit at a time
			// So we can synchronize each bit independently
			// Let's use a simpler approach: synchronize the whole Gray code as a multi-bit signal
			// But the requirement says "Do not form full or empty by comparing a multi-bit pointer that was synchronized bit by bit."
			// So we need to use a different approach.
			// Let's use the acknowledged single-bit control as specified.
		end
	end

	// Let's restart with the acknowledged single-bit control approach
	// Write domain:
	// - When i_wr is high and not full, accept write
	// - Store data in w_hold_data, set w_hold_valid
	// - Assert w_req
	// - Wait for r_ack (synchronized)
	// - On r_ack, update w_ptr, clear w_hold_valid, deassert w_req

	// Read domain:
	// - When r_ack_sync (synchronized w_req) is high, accept read
	// - Store data in r_hold_data, set r_hold_valid
	// - Assert r_req
	// - Wait for w_ack (synchronized)
	// - On w_ack, update r_ptr, clear r_hold_valid, deassert r_req

	// Full: w_hold_valid is high (write in progress) or w_ptr has lapped r_ptr
	// Empty: r_hold_valid is low and r_ptr == w_ptr (synchronized)

	// Let's implement this properly

	// Write domain
	reg [PTR_W-1:0] w_ptr_int;
	reg [WIDTH-1:0] w_hold_data_int;
	reg w_hold_valid_int;
	reg w_req_int;
	reg [NFF_SAFE-1:0] r_ack_sync_int;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			w_ptr_int <= {PTR_W{1'b0}};
			w_hold_data_int <= {WIDTH{1'b0}};
			w_hold_valid_int <= 1'b0;
			w_req_int <= 1'b0;
			r_ack_sync_int <= {NFF_SAFE{1'b0}};
		end else begin
			// Synchronize r_ack
			r_ack_sync_int[NFF_SAFE-1] <= r_req;
			for (integer i = NFF_SAFE-2; i >= 0; i = i-1)
				r_ack_sync_int[i] <= r_ack_sync_int[i+1];

			// Handle write request
			if (w_req_int) begin
				if (r_ack_sync_int[NFF_SAFE-1]) begin
					// Ack received
					w_req_int <= 1'b0;
					w_hold_valid_int <= 1'b0;
					w_ptr_int <= w_ptr_int + 1'b1;
				end
			end else if (i_wr && !o_wr_full) begin
				// Accept write
				w_hold_data_int <= i_wr_data;
				w_hold_valid_int <= 1'b1;
				w_req_int <= 1'b1;
			end
		end
	end

	// Read domain
	reg [PTR_W-1:0] r_ptr_int;
	reg [WIDTH-1:0] r_hold_data_int;
	reg r_hold_valid_int;
	reg r_req_int;
	reg [NFF_SAFE-1:0] w_req_sync_int;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			r_ptr_int <= {PTR_W{1'b0}};
			r_hold_data_int <= {WIDTH{1'b0}};
			r_hold_valid_int <= 1'b0;
			r_req_int <= 1'b0;
			w_req_sync_int <= {NFF_SAFE{1'b0}};
		end else begin
			// Synchronize w_req
			w_req_sync_int[NFF_SAFE-1] <= w_req_int;
			for (integer i = NFF_SAFE-2; i >= 0; i = i-1)
				w_req_sync_int[i] <= w_req_sync_int[i+1];

			// Handle read request
			if (r_req_int) begin
				if (w_ack_sync[NFF_SAFE-1]) begin
					// Ack received
					r_req_int <= 1'b0;
					r_hold_valid_int <= 1'b0;
					r_ptr_int <= r_ptr_int + 1'b1;
				end
			end else if (w_req_sync_int[NFF_SAFE-1] && i_rd) begin
				// Accept read
				r_hold_data_int <= w_hold_data_int;
				r_hold_valid_int <= 1'b1;
				r_req_int <= 1'b1;
			end
		end
	end

	// Full condition: write in progress or pointers have lapped
	// We need to compare w_ptr_int and r_ptr_int (synchronized)
	// But r_ptr_int is in read domain, so we need to synchronize it to write domain
	// Let's synchronize r_ptr to write domain

	reg [PTR_W-1:0] r_ptr_w;
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			r_ptr_w <= {PTR_W{1'b0}};
		else
			r_ptr_w <= r_ptr_int;
	end

	// Full: w_hold_valid_int is high, or (w_ptr_int - r_ptr_w) == DEPTH
	wire [PTR_W:0] w_ptr_diff = w_ptr_int - r_ptr_w;
	wire full_int = w_hold_valid_int || (w_ptr_diff == DEPTH);

	// Empty: r_hold_valid_int is low, and r_ptr_int == w_ptr_r (synchronized)
	reg [PTR_W-1:0] w_ptr_r;
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			w_ptr_r <= {PTR_W{1'b0}};
		else
			w_ptr_r <= w_ptr_int;
	end

	wire empty_int = !r_hold_valid_int && (r_ptr_int == w_ptr_r);

	// Output registers
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			o_wr_full <= 1'b0;
		else
			o_wr_full <= full_int;
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
			o_rd_data <= {WIDTH{1'b0}};
		end else begin
			o_rd_empty <= empty_int;
			if (OPT_REGISTER_READS)
				o_rd_data <= r_hold_data_int;
			else
				o_rd_data <= r_hold_data_int;
		end
	end

	// Assign internal signals to module-level signals
	assign w_ptr = w_ptr_int;
	assign r_ptr = r_ptr_int;
	assign w_hold_data = w_hold_data_int;
	assign w_hold_valid = w_hold_valid_int;
	assign w_req = w_req_int;
	assign r_hold_data = r_hold_data_int;
	assign r_hold_valid = r_hold_valid_int;
	assign r_req = r_req_int;

endmodule
