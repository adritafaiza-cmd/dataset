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
	localparam FIFO_ADDR_WIDTH = LGFIFO;

	// Request FIFO (wb -> xclk)
	reg [DW-1:0] req_fifo_data [0:FIFO_DEPTH-1];
	reg [AW-1:0] req_fifo_addr [0:FIFO_DEPTH-1];
	reg [DW/8-1:0] req_fifo_sel [0:FIFO_DEPTH-1];
	reg req_fifo_we [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] req_wr_ptr, req_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] req_count;

	// Response FIFO (xclk -> wb)
	reg [DW-1:0] rsp_fifo_data [0:FIFO_DEPTH-1];
	reg rsp_fifo_err [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] rsp_wr_ptr, rsp_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] rsp_count;

	// Synchronization signals
	reg [1:0] req_full_sync, req_empty_sync;
	reg [1:0] rsp_full_sync, rsp_empty_sync;

	// WB side: detect valid request
	wire wb_req_valid = i_wb_cyc & i_wb_stb;
	wire req_fifo_full = (req_count == FIFO_DEPTH);
	wire req_fifo_empty = (req_count == 0);
	wire can_accept = wb_req_valid & ~req_fifo_full;

	// Write to request FIFO on wb_clk
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= 0;
			req_rd_ptr <= 0;
			req_count <= 0;
		end else begin
			if (can_accept) begin
				req_fifo_data[req_wr_ptr] <= i_wb_data;
				req_fifo_addr[req_wr_ptr] <= i_wb_addr;
				req_fifo_sel[req_wr_ptr] <= i_wb_sel;
				req_fifo_we[req_wr_ptr] <= i_wb_we;
				req_wr_ptr <= req_wr_ptr + 1;
			end
			if (req_fifo_empty_sync[1] && ~req_fifo_empty) begin
				// This is handled by the read pointer increment on xclk side
			end
			// Update count
			if (can_accept && (req_fifo_empty_sync[1] || req_count > 0)) begin
				// We need to be careful: the read happens on xclk side
				// So we just track writes here, and reads are synchronized
			end
		end
	end

	// Actually, let's use a simpler approach with separate write/read pointers
	// and synchronize the pointers.

	// Reset the above and do it properly:

	// Request FIFO write pointer (wb domain)
	reg [FIFO_ADDR_WIDTH-1:0] req_wr_ptr_wb;
	// Request FIFO read pointer (xclk domain)
	reg [FIFO_ADDR_WIDTH-1:0] req_rd_ptr_xclk;
	// Synchronized read pointer to wb domain
	reg [FIFO_ADDR_WIDTH-1:0] req_rd_ptr_wb_sync;
	reg [FIFO_ADDR_WIDTH-1:0] req_rd_ptr_wb_sync1;

	// Response FIFO write pointer (xclk domain)
	reg [FIFO_ADDR_WIDTH-1:0] rsp_wr_ptr_xclk;
	// Response FIFO read pointer (wb domain)
	reg [FIFO_ADDR_WIDTH-1:0] rsp_rd_ptr_wb;
	// Synchronized write pointer to wb domain
	reg [FIFO_ADDR_WIDTH-1:0] rsp_wr_ptr_wb_sync;
	reg [FIFO_ADDR_WIDTH-1:0] rsp_wr_ptr_wb_sync1;

	// Synchronize req_rd_ptr from xclk to wb
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr_wb_sync <= 0;
			req_rd_ptr_wb_sync1 <= 0;
		end else begin
			req_rd_ptr_wb_sync <= req_rd_ptr_wb_sync1;
			req_rd_ptr_wb_sync1 <= req_rd_ptr_xclk;
		end
	end

	// Synchronize rsp_wr_ptr from xclk to wb
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_wr_ptr_wb_sync <= 0;
			rsp_wr_ptr_wb_sync1 <= 0;
		end else begin
			rsp_wr_ptr_wb_sync <= rsp_wr_ptr_wb_sync1;
			rsp_wr_ptr_wb_sync1 <= rsp_wr_ptr_xclk;
		end
	end

	// Compute full/empty in wb domain
	wire [FIFO_ADDR_WIDTH:0] req_wr_minus_rd = req_wr_ptr_wb - req_rd_ptr_wb_sync;
	wire req_full_wb = (req_wr_minus_rd == FIFO_DEPTH);
	wire req_empty_wb = (req_wr_minus_rd == 0);

	wire [FIFO_ADDR_WIDTH:0] rsp_wr_minus_rd = rsp_wr_ptr_wb_sync - rsp_rd_ptr_wb;
	wire rsp_full_wb = (rsp_wr_minus_rd == FIFO_DEPTH);
	wire rsp_empty_wb = (rsp_wr_minus_rd == 0);

	// o_wb_stall: high when we cannot accept another request
	assign o_wb_stall = req_full_wb;

	// Write to request FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr_wb <= 0;
		end else if (wb_req_valid & ~req_full_wb) begin
			req_fifo_data[req_wr_ptr_wb] <= i_wb_data;
			req_fifo_addr[req_wr_ptr_wb] <= i_wb_addr;
			req_fifo_sel[req_wr_ptr_wb] <= i_wb_sel;
			req_fifo_we[req_wr_ptr_wb] <= i_wb_we;
			req_wr_ptr_wb <= req_wr_ptr_wb + 1;
		end
	end

	// Read from request FIFO and drive xclk outputs (xclk domain)
	// Synchronize req_wr_ptr from wb to xclk
	reg [FIFO_ADDR_WIDTH-1:0] req_wr_ptr_xclk_sync;
	reg [FIFO_ADDR_WIDTH-1:0] req_wr_ptr_xclk_sync1;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr_xclk_sync <= 0;
			req_wr_ptr_xclk_sync1 <= 0;
		end else begin
			req_wr_ptr_xclk_sync <= req_wr_ptr_xclk_sync1;
			req_wr_ptr_xclk_sync1 <= req_wr_ptr_wb;
		end
	end

	wire [FIFO_ADDR_WIDTH:0] req_wr_minus_rd_xclk = req_wr_ptr_xclk_sync - req_rd_ptr_xclk;
	wire req_empty_xclk = (req_wr_minus_rd_xclk == 0);

	// Read from response FIFO and drive wb outputs (wb domain)
	// Synchronize rsp_rd_ptr from wb to xclk
	reg [FIFO_ADDR_WIDTH-1:0] rsp_rd_ptr_xclk_sync;
	reg [FIFO_ADDR_WIDTH-1:0] rsp_rd_ptr_xclk_sync1;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr_xclk_sync <= 0;
			rsp_rd_ptr_xclk_sync1 <= 0;
		end else begin
			rsp_rd_ptr_xclk_sync <= rsp_rd_ptr_xclk_sync1;
			rsp_rd_ptr_xclk_sync1 <= rsp_rd_ptr_wb;
		end
	end

	wire [FIFO_ADDR_WIDTH:0] rsp_wr_minus_rd_xclk = rsp_wr_ptr_xclk - rsp_rd_ptr_xclk_sync;
	wire rsp_empty_xclk = (rsp_wr_minus_rd_xclk == 0);

	// XCLK side: read from request FIFO and present on o_xclk_*
	reg xclk_present;
	reg [DW-1:0] xclk_data_reg;
	reg [AW-1:0] xclk_addr_reg;
	reg [DW/8-1:0] xclk_sel_reg;
	reg xclk_we_reg;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr_xclk <= 0;
			rsp_wr_ptr_xclk <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			xclk_present <= 0;
			xclk_data_reg <= 0;
			xclk_addr_reg <= 0;
			xclk_sel_reg <= 0;
			xclk_we_reg <= 0;
		end else begin
			// Read from request FIFO if not empty and not stalled
			if (~req_empty_xclk & ~i_xclk_stall) begin
				xclk_data_reg <= req_fifo_data[req_rd_ptr_xclk];
				xclk_addr_reg <= req_fifo_addr[req_rd_ptr_xclk];
				xclk_sel_reg <= req_fifo_sel[req_rd_ptr_xclk];
				xclk_we_reg <= req_fifo_we[req_rd_ptr_xclk];
				req_rd_ptr_xclk <= req_rd_ptr_xclk + 1;
				xclk_present <= 1;
			end else if (i_xclk_ack & xclk_present) begin
				// Ack received, clear present
				xclk_present <= 0;
			end

			// Drive outputs
			if (xclk_present) begin
				o_xclk_cyc <= 1;
				o_xclk_stb <= 1;
				o_xclk_we <= xclk_we_reg;
				o_xclk_addr <= xclk_addr_reg;
				o_xclk_data <= xclk_data_reg;
				o_xclk_sel <= xclk_sel_reg;
			end else begin
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
				o_xclk_we <= 0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end

			// Write to response FIFO on ack
			if (i_xclk_ack & xclk_present) begin
				rsp_fifo_data[rsp_wr_ptr_xclk] <= i_xclk_data;
				rsp_fifo_err[rsp_wr_ptr_xclk] <= i_xclk_err;
				rsp_wr_ptr_xclk <= rsp_wr_ptr_xclk + 1;
			end
		end
	end

	// WB side: read from response FIFO and drive o_wb_*
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr_wb <= 0;
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else begin
			if (~rsp_empty_wb) begin
				o_wb_ack <= 1;
				o_wb_data <= rsp_fifo_data[rsp_rd_ptr_wb];
				o_wb_err <= rsp_fifo_err[rsp_rd_ptr_wb];
				rsp_rd_ptr_wb <= rsp_rd_ptr_wb + 1;
			end else begin
				o_wb_ack <= 0;
				o_wb_data <= 0;
				o_wb_err <= 0;
			end
		end
	end

endmodule
