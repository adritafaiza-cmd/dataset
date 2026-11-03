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
	localparam FIFO_WIDTH = AW + DW + DW/8 + 1; // addr + data + sel + we

	// Request FIFO (wb -> xclk)
	reg [FIFO_WIDTH-1:0] req_fifo [0:FIFO_DEPTH-1];
	reg [LGFIFO:0] req_wr_ptr, req_rd_ptr;
	reg [LGFIFO:0] req_count;

	// Response FIFO (xclk -> wb)
	reg [DW+1:0] rsp_fifo [0:FIFO_DEPTH-1]; // data + err
	reg [LGFIFO:0] rsp_wr_ptr, rsp_rd_ptr;
	reg [LGFIFO:0] rsp_count;

	// Synchronization signals
	reg [1:0] req_full_sync, req_empty_sync;
	reg [1:0] rsp_full_sync, rsp_empty_sync;

	// Internal signals
	wire req_full = (req_count == FIFO_DEPTH);
	wire req_empty = (req_count == 0);
	wire rsp_full = (rsp_count == FIFO_DEPTH);
	wire rsp_empty = (rsp_count == 0);

	// Synchronize req_full to xclk domain
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset)
			req_full_sync <= 2'b00;
		else
			req_full_sync <= {req_full_sync[0], req_full};
	end

	// Synchronize req_empty to xclk domain
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset)
			req_empty_sync <= 2'b00;
		else
			req_empty_sync <= {req_empty_sync[0], req_empty};
	end

	// Synchronize rsp_full to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			rsp_full_sync <= 2'b00;
		else
			rsp_full_sync <= {rsp_full_sync[0], rsp_full};
	end

	// Synchronize rsp_empty to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			rsp_empty_sync <= 2'b00;
		else
			rsp_empty_sync <= {rsp_empty_sync[0], rsp_empty};
	end

	// WB domain: accept request when not full
	wire wb_accept = i_wb_cyc && i_wb_stb && !req_full;

	// WB domain: write to request FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= 0;
			req_count <= 0;
		end else begin
			if (wb_accept) begin
				req_fifo[req_wr_ptr[LGFIFO-1:0]] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
				req_wr_ptr <= req_wr_ptr + 1;
				req_count <= req_count + 1;
			end
			if (req_empty_sync[1] && !req_empty_sync[0]) begin
				// This is a glitch, ignore
			end
			// Read pointer is updated in xclk domain, but we need to track count
			// Actually, let's use a different approach: use pointers and compare
		end
	end

	// Let's redo the FIFO with proper pointer-based approach
	// Request FIFO: write in wb_clk, read in xclk_clk
	// We'll use a Gray code or just simple binary with careful synchronization
	
	// Actually, let's use a simpler approach with separate write/read pointers
	// and synchronize the read pointer to the write domain and vice versa

	// Request FIFO
	reg [LGFIFO:0] req_wr_ptr_wb, req_rd_ptr_wb;
	reg [LGFIFO:0] req_wr_ptr_xclk, req_rd_ptr_xclk;

	// Synchronize req_rd_ptr to wb domain
	reg [LGFIFO:0] req_rd_ptr_sync1, req_rd_ptr_sync2;
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr_sync1 <= 0;
			req_rd_ptr_sync2 <= 0;
		end else begin
			req_rd_ptr_sync1 <= req_rd_ptr_xclk;
			req_rd_ptr_sync2 <= req_rd_ptr_sync1;
		end
	end

	// Synchronize req_wr_ptr to xclk domain
	reg [LGFIFO:0] req_wr_ptr_sync1, req_wr_ptr_sync2;
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr_sync1 <= 0;
			req_wr_ptr_sync2 <= 0;
		end else begin
			req_wr_ptr_sync1 <= req_wr_ptr_wb;
			req_wr_ptr_sync2 <= req_wr_ptr_sync1;
		end
	end

	// Request FIFO full/empty
	wire req_full_wb = (req_wr_ptr_wb - req_rd_ptr_sync2) == FIFO_DEPTH;
	wire req_empty_xclk = (req_rd_ptr_xclk == req_wr_ptr_sync2);

	// WB domain: write to request FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr_wb <= 0;
		end else if (i_wb_cyc && i_wb_stb && !req_full_wb) begin
			req_fifo[req_wr_ptr_wb[LGFIFO-1:0]] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
			req_wr_ptr_wb <= req_wr_ptr_wb + 1;
		end
	end

	// XCLK domain: read from request FIFO
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr_xclk <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else if (!req_empty_xclk && !i_xclk_stall) begin
			o_xclk_cyc <= 1;
			o_xclk_stb <= 1;
			o_xclk_we <= req_fifo[req_rd_ptr_xclk[LGFIFO-1:0]][FIFO_WIDTH-1];
			o_xclk_addr <= req_fifo[req_rd_ptr_xclk[LGFIFO-1:0]][FIFO_WIDTH-2:FIFO_WIDTH-1-DW];
			o_xclk_data <= req_fifo[req_rd_ptr_xclk[LGFIFO-1:0]][FIFO_WIDTH-2-DW:FIFO_WIDTH-2-DW-DW/8];
			o_xclk_sel <= req_fifo[req_rd_ptr_xclk[LGFIFO-1:0]][FIFO_WIDTH-3-DW:FIFO_WIDTH-3-DW-DW/8];
			req_rd_ptr_xclk <= req_rd_ptr_xclk + 1;
		end else begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
		end
	end

	// Response FIFO: write in xclk_clk, read in wb_clk
	reg [LGFIFO:0] rsp_wr_ptr_xclk, rsp_rd_ptr_wb;

	// Synchronize rsp_rd_ptr to xclk domain
	reg [LGFIFO:0] rsp_rd_ptr_sync1, rsp_rd_ptr_sync2;
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr_sync1 <= 0;
			rsp_rd_ptr_sync2 <= 0;
		end else begin
			rsp_rd_ptr_sync1 <= rsp_rd_ptr_wb;
			rsp_rd_ptr_sync2 <= rsp_rd_ptr_sync1;
		end
	end

	// Synchronize rsp_wr_ptr to wb domain
	reg [LGFIFO:0] rsp_wr_ptr_sync1, rsp_wr_ptr_sync2;
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_wr_ptr_sync1 <= 0;
			rsp_wr_ptr_sync2 <= 0;
		end else begin
			rsp_wr_ptr_sync1 <= rsp_wr_ptr_xclk;
			rsp_wr_ptr_sync2 <= rsp_wr_ptr_sync1;
		end
	end

	// Response FIFO full/empty
	wire rsp_full_xclk = (rsp_wr_ptr_xclk - rsp_rd_ptr_sync2) == FIFO_DEPTH;
	wire rsp_empty_wb = (rsp_rd_ptr_wb == rsp_wr_ptr_sync2);

	// XCLK domain: write to response FIFO
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_wr_ptr_xclk <= 0;
		end else if (i_xclk_ack && !rsp_full_xclk) begin
			rsp_fifo[rsp_wr_ptr_xclk[LGFIFO-1:0]] <= {i_xclk_err, i_xclk_data};
			rsp_wr_ptr_xclk <= rsp_wr_ptr_xclk + 1;
		end
	end

	// WB domain: read from response FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr_wb <= 0;
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else if (!rsp_empty_wb) begin
			o_wb_ack <= 1;
			o_wb_data <= rsp_fifo[rsp_rd_ptr_wb[LGFIFO-1:0]][DW:0];
			o_wb_err <= rsp_fifo[rsp_rd_ptr_wb[LGFIFO-1:0]][DW+1];
			rsp_rd_ptr_wb <= rsp_rd_ptr_wb + 1;
		end else begin
			o_wb_ack <= 0;
		end
	end

	// o_wb_stall: high when request FIFO is full
	assign o_wb_stall = req_full_wb;

endmodule
