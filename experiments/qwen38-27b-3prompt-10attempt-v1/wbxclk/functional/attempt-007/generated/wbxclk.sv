module wbxclk #(
		parameter	AW=32,
				DW=32,
				LGFIFO = 5
	) (
		input	wire			i_wb_clk, i_reset,
		input	wire			i_wb_cyc, i_wb_stb, i_wb_we,
		input	wire	[(AW-1):0]	i_wb_addr,
		input	wire	[(DW-1):0]	i_wb_data,
		input	wire	[(DW/8-1):0]	i_wb_sel,
		output	wire			o_wb_stall,
		output	reg			o_wb_ack,
		output	reg	[(DW-1):0]	o_wb_data,
		output	reg			o_wb_err,
		input	wire			i_xclk_clk,
		output	reg			o_xclk_cyc,
		output	reg			o_xclk_stb,
		output	reg			o_xclk_we,
		output	reg	[(AW-1):0]	o_xclk_addr,
		output	reg	[(DW-1):0]	o_xclk_data,
		output	reg	[(DW/8-1):0]	o_xclk_sel,
		input	wire			i_xclk_stall,
		input	wire			i_xclk_ack,
		input	wire	[(DW-1):0]	i_xclk_data,
		input	wire			i_xclk_err
	);

	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FIFO_PTR_W = LGFIFO;
	localparam FIFO_FULL_THRESH = FIFO_DEPTH - 1;

	// Request FIFO (Wishbone side to XCLK side)
	reg [DW*2+AW+DW/8+1-1:0] req_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W-1:0] req_wr_ptr, req_rd_ptr;
	reg [FIFO_PTR_W:0] req_count;

	// Response FIFO (XCLK side to Wishbone side)
	reg [DW+1-1:0] resp_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W-1:0] resp_wr_ptr, resp_rd_ptr;
	reg [FIFO_PTR_W:0] resp_count;

	// Synchronization signals
	reg [1:0] req_full_sync_0, req_full_sync_1, req_full_sync_2;
	reg [1:0] resp_full_sync_0, resp_full_sync_1, resp_full_sync_2;
	reg [1:0] req_empty_sync_0, req_empty_sync_1, req_empty_sync_2;
	reg [1:0] resp_empty_sync_0, resp_empty_sync_1, resp_empty_sync_2;

	wire req_full = (req_count == FIFO_DEPTH);
	wire resp_full = (resp_count == FIFO_DEPTH);
	wire req_empty = (req_count == 0);
	wire resp_empty = (resp_count == 0);

	// Synchronize req_full to xclk domain
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_full_sync_0 <= 2'b00;
			req_full_sync_1 <= 2'b00;
			req_full_sync_2 <= 2'b00;
		end else begin
			req_full_sync_0 <= {req_full_sync_0[0], req_full};
			req_full_sync_1 <= req_full_sync_0;
			req_full_sync_2 <= req_full_sync_1;
		end
	end
	wire req_full_xclk = req_full_sync_2[1];

	// Synchronize resp_full to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_full_sync_0 <= 2'b00;
			resp_full_sync_1 <= 2'b00;
			resp_full_sync_2 <= 2'b00;
		end else begin
			resp_full_sync_0 <= {resp_full_sync_0[0], resp_full};
			resp_full_sync_1 <= resp_full_sync_0;
			resp_full_sync_2 <= resp_full_sync_1;
		end
	end
	wire resp_full_wb = resp_full_sync_2[1];

	// Synchronize req_empty to xclk domain
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_empty_sync_0 <= 2'b00;
			req_empty_sync_1 <= 2'b00;
			req_empty_sync_2 <= 2'b00;
		end else begin
			req_empty_sync_0 <= {req_empty_sync_0[0], req_empty};
			req_empty_sync_1 <= req_empty_sync_0;
			req_empty_sync_2 <= req_empty_sync_1;
		end
	end
	wire req_empty_xclk = req_empty_sync_2[1];

	// Synchronize resp_empty to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_empty_sync_0 <= 2'b00;
			resp_empty_sync_1 <= 2'b00;
			resp_empty_sync_2 <= 2'b00;
		end else begin
			resp_empty_sync_0 <= {resp_empty_sync_0[0], resp_empty};
			resp_empty_sync_1 <= resp_empty_sync_0;
			resp_empty_sync_2 <= resp_empty_sync_1;
		end
	end
	wire resp_empty_wb = resp_empty_sync_2[1];

	// o_wb_stall: high when we cannot accept another cycle
	// We can accept if req_fifo is not full AND resp_fifo is not full (to avoid deadlock)
	assign o_wb_stall = req_full_wb | resp_full_wb;

	// Wishbone side: accept cycle when not stalled and cyc/stb are high
	wire wb_accept = i_wb_cyc & i_wb_stb & ~o_wb_stall;

	// Write to request FIFO on wb_clk
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= {FIFO_PTR_W{1'b0}};
			req_count <= {(FIFO_PTR_W+1){1'b0}};
		end else begin
			if (wb_accept) begin
				req_fifo_mem[req_wr_ptr] <= {i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
				req_wr_ptr <= req_wr_ptr + 1'b1;
				req_count <= req_count + 1'b1;
			end
		end
	end

	// XCLK side: read from request FIFO and drive o_xclk_*
	// We can read if req_fifo is not empty and xclk is not stalled
	wire xclk_read = ~req_empty_xclk & ~i_xclk_stall;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {(AW){1'b0}};
			o_xclk_data <= {(DW){1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
			req_rd_ptr <= {FIFO_PTR_W{1'b0}};
		end else begin
			if (xclk_read) begin
				{o_xclk_cyc, o_xclk_stb, o_xclk_we, o_xclk_addr, o_xclk_data, o_xclk_sel} <= req_fifo_mem[req_rd_ptr];
				req_rd_ptr <= req_rd_ptr + 1'b1;
			end
		end
	end

	// Update req_count on xclk side (decrement when read)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			// req_count is updated on wb side for writes, xclk side for reads
			// We need a shared counter or separate tracking. Let's use a different approach.
		end
	end

	// Actually, let's restructure: use separate write and read pointers and compute count
	// But since they're in different clock domains, we need to synchronize counts.
	// Simpler: use a single counter updated in each domain with synchronization.
	// Let's use a different approach: track count in each domain and synchronize.

	// Let me redo this with a cleaner approach using Gray codes or simple count sync.
	// For simplicity, I'll use a counter that is written in one domain and read in another with sync.

	// Actually, the cleanest way for a simple FIFO across clock domains is to use
	// separate write pointer (wb domain) and read pointer (xclk domain) and synchronize
	// the read pointer to wb domain and write pointer to xclk domain to compute full/empty.

	// Let me restart with a proper CDC FIFO design.

	// Request FIFO:
	// - Write in wb_clk domain
	// - Read in xclk_clk domain
	// - Need to sync read pointer to wb domain for full detection
	// - Need to sync write pointer to xclk domain for empty detection

	reg [FIFO_PTR_W-1:0] req_wr_ptr_wb;
	reg [FIFO_PTR_W-1:0] req_rd_ptr_xclk;
	reg [FIFO_PTR_W-1:0] req_rd_ptr_wb_sync_0, req_rd_ptr_wb_sync_1, req_rd_ptr_wb_sync_2;
	reg [FIFO_PTR_W-1:0] req_wr_ptr_xclk_sync_0, req_wr_ptr_xclk_sync_1, req_wr_ptr_xclk_sync_2;

	// Response FIFO:
	// - Write in xclk_clk domain
	// - Read in wb_clk domain
	// - Need to sync read pointer to xclk domain for full detection
	// - Need to sync write pointer to wb domain for empty detection

	reg [FIFO_PTR_W-1:0] resp_wr_ptr_xclk;
	reg [FIFO_PTR_W-1:0] resp_rd_ptr_wb;
	reg [FIFO_PTR_W-1:0] resp_rd_ptr_xclk_sync_0, resp_rd_ptr_xclk_sync_1, resp_rd_ptr_xclk_sync_2;
	reg [FIFO_PTR_W-1:0] resp_wr_ptr_wb_sync_0, resp_wr_ptr_wb_sync_1, resp_wr_ptr_wb_sync_2;

	// Request FIFO write (wb domain)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr_wb <= {FIFO_PTR_W{1'b0}};
		end else if (wb_accept) begin
			req_fifo_mem[req_wr_ptr_wb] <= {i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
			req_wr_ptr_wb <= req_wr_ptr_wb + 1'b1;
		end
	end

	// Sync req_wr_ptr to xclk domain
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr_xclk_sync_0 <= {FIFO_PTR_W{1'b0}};
			req_wr_ptr_xclk_sync_1 <= {FIFO_PTR_W{1'b0}};
			req_wr_ptr_xclk_sync_2 <= {FIFO_PTR_W{1'b0}};
		end else begin
			req_wr_ptr_xclk_sync_0 <= req_wr_ptr_wb;
			req_wr_ptr_xclk_sync_1 <= req_wr_ptr_xclk_sync_0;
			req_wr_ptr_xclk_sync_2 <= req_wr_ptr_xclk_sync_1;
		end
	end

	// Request FIFO read (xclk domain)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr_xclk <= {FIFO_PTR_W{1'b0}};
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {(AW){1'b0}};
			o_xclk_data <= {(DW){1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
		end else if (xclk_read) begin
			{o_xclk_cyc, o_xclk_stb, o_xclk_we, o_xclk_addr, o_xclk_data, o_xclk_sel} <= req_fifo_mem[req_rd_ptr_xclk];
			req_rd_ptr_xclk <= req_rd_ptr_xclk + 1'b1;
		end
	end

	// Sync req_rd_ptr to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr_wb_sync_0 <= {FIFO_PTR_W{1'b0}};
			req_rd_ptr_wb_sync_1 <= {FIFO_PTR_W{1'b0}};
			req_rd_ptr_wb_sync_2 <= {FIFO_PTR_W{1'b0}};
		end else begin
			req_rd_ptr_wb_sync_0 <= req_rd_ptr_xclk;
			req_rd_ptr_wb_sync_1 <= req_rd_ptr_wb_sync_0;
			req_rd_ptr_wb_sync_2 <= req_rd_ptr_wb_sync_1;
		end
	end

	// Compute req_full in wb domain
	wire [FIFO_PTR_W:0] req_wr_ptr_ext = {1'b0, req_wr_ptr_wb};
	wire [FIFO_PTR_W:0] req_rd_ptr_ext = {1'b0, req_rd_ptr_wb_sync_2};
	wire [FIFO_PTR_W:0] req_diff = req_wr_ptr_ext - req_rd_ptr_ext;
	wire req_full_wb = (req_diff == FIFO_DEPTH);

	// Compute req_empty in xclk domain
	wire [FIFO_PTR_W:0] req_wr_ptr_xclk_ext = {1'b0, req_wr_ptr_xclk_sync_2};
	wire [FIFO_PTR_W:0] req_rd_ptr_xclk_ext = {1'b0, req_rd_ptr_xclk};
	wire [FIFO_PTR_W:0] req_diff_xclk = req_wr_ptr_xclk_ext - req_rd_ptr_xclk_ext;
	wire req_empty_xclk = (req_diff_xclk == 0);

	// Response FIFO write (xclk domain)
	wire xclk_resp_write = i_xclk_ack;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_wr_ptr_xclk <= {FIFO_PTR_W{1'b0}};
		end else if (xclk_resp_write) begin
			resp_fifo_mem[resp_wr_ptr_xclk] <= {i_xclk_err, i_xclk_data};
			resp_wr_ptr_xclk <= resp_wr_ptr_xclk + 1'b1;
		end
	end

	// Sync resp_wr_ptr to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_wr_ptr_wb_sync_0 <= {FIFO_PTR_W{1'b0}};
			resp_wr_ptr_wb_sync_1 <= {FIFO_PTR_W{1'b0}};
			resp_wr_ptr_wb_sync_2 <= {FIFO_PTR_W{1'b0}};
		end else begin
			resp_wr_ptr_wb_sync_0 <= resp_wr_ptr_xclk;
			resp_wr_ptr_wb_sync_1 <= resp_wr_ptr_wb_sync_0;
			resp_wr_ptr_wb_sync_2 <= resp_wr_ptr_wb_sync_1;
		end
	end

	// Response FIFO read (wb domain)
	wire wb_resp_read = ~resp_empty_wb;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_rd_ptr_wb <= {FIFO_PTR_W{1'b0}};
			o_wb_ack <= 1'b0;
			o_wb_data <= {(DW){1'b0}};
			o_wb_err <= 1'b0;
		end else if (wb_resp_read) begin
			{o_wb_err, o_wb_data} <= resp_fifo_mem[resp_rd_ptr_wb];
			o_wb_ack <= 1'b1;
			resp_rd_ptr_wb <= resp_rd_ptr_wb + 1'b1;
		end else begin
			o_wb_ack <= 1'b0;
		end
	end

	// Sync resp_rd_ptr to xclk domain
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_rd_ptr_xclk_sync_0 <= {FIFO_PTR_W{1'b0}};
			resp_rd_ptr_xclk_sync_1 <= {FIFO_PTR_W{1'b0}};
			resp_rd_ptr_xclk_sync_2 <= {FIFO_PTR_W{1'b0}};
		end else begin
			resp_rd_ptr_xclk_sync_0 <= resp_rd_ptr_wb;
			resp_rd_ptr_xclk_sync_1 <= resp_rd_ptr_xclk_sync_0;
			resp_rd_ptr_xclk_sync_2 <= resp_rd_ptr_xclk_sync_1;
		end
	end

	// Compute resp_full in xclk domain
	wire [FIFO_PTR_W:0] resp_wr_ptr_xclk_ext = {1'b0, resp_wr_ptr_xclk};
	wire [FIFO_PTR_W:0] resp_rd_ptr_xclk_ext = {1'b0, resp_rd_ptr_xclk_sync_2};
	wire [FIFO_PTR_W:0] resp_diff_xclk = resp_wr_ptr_xclk_ext - resp_rd_ptr_xclk_ext;
	wire resp_full_xclk = (resp_diff_xclk == FIFO_DEPTH);

	// Compute resp_empty in wb domain
	wire [FIFO_PTR_W:0] resp_wr_ptr_wb_ext = {1'b0, resp_wr_ptr_wb_sync_2};
	wire [FIFO_PTR_W:0] resp_rd_ptr_wb_ext = {1'b0, resp_rd_ptr_wb};
	wire [FIFO_PTR_W:0] resp_diff_wb = resp_wr_ptr_wb_ext - resp_rd_ptr_wb_ext;
	wire resp_empty_wb = (resp_diff_wb == 0);

	// o_wb_stall: high when req_fifo is full or resp_fifo is full
	assign o_wb_stall = req_full_wb | resp_full_xclk;

	// xclk_read: can read from req_fifo if not empty and xclk not stalled
	assign xclk_read = ~req_empty_xclk & ~i_xclk_stall;

endmodule
