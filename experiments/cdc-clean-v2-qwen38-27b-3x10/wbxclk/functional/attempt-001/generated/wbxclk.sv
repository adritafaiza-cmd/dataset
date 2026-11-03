module wbxclk #(
	parameter AW=32,
	parameter DW=32,
	parameter LGFIFO = 5
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

	// Request FIFO (wb -> xclk)
	reg [DW-1:0] req_fifo_data [0:FIFO_DEPTH-1];
	reg [AW-1:0] req_fifo_addr [0:FIFO_DEPTH-1];
	reg [DW/8-1:0] req_fifo_sel [0:FIFO_DEPTH-1];
	reg req_fifo_we [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W-1:0] req_wr_ptr, req_rd_ptr;
	reg [FIFO_PTR_W:0] req_count;

	// Response FIFO (xclk -> wb)
	reg [DW-1:0] rsp_fifo_data [0:FIFO_DEPTH-1];
	reg rsp_fifo_err [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W-1:0] rsp_wr_ptr, rsp_rd_ptr;
	reg [FIFO_PTR_W:0] rsp_count;

	// Synchronization signals
	reg [1:0] req_full_sync;
	reg [1:0] rsp_full_sync;
	reg [1:0] req_empty_sync;
	reg [1:0] rsp_empty_sync;

	// WB side: accept request
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

	// Synchronize rsp_full to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			rsp_full_sync <= 2'b00;
		else
			rsp_full_sync <= {rsp_full_sync[0], rsp_full};
	end

	// Synchronize req_empty to xclk domain
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset)
			req_empty_sync <= 2'b00;
		else
			req_empty_sync <= {req_empty_sync[0], req_empty};
	end

	// Synchronize rsp_empty to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			rsp_empty_sync <= 2'b00;
		else
			rsp_empty_sync <= {rsp_empty_sync[0], rsp_empty};
	end

	// WB side: stall when request FIFO is full
	assign o_wb_stall = req_full_sync[1];

	// WB side: accept a new request when not stalled and cyc/stb are high
	wire wb_accept = i_wb_cyc & i_wb_stb & ~req_full_sync[1];

	// WB side: write to request FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= {FIFO_PTR_W{1'b0}};
			req_count <= {(FIFO_PTR_W+1){1'b0}};
		end else begin
			if (wb_accept) begin
				req_fifo_data[req_wr_ptr] <= i_wb_data;
				req_fifo_addr[req_wr_ptr] <= i_wb_addr;
				req_fifo_sel[req_wr_ptr] <= i_wb_sel;
				req_fifo_we[req_wr_ptr] <= i_wb_we;
				req_wr_ptr <= req_wr_ptr + 1'b1;
				req_count <= req_count + 1'b1;
			end else if (req_empty_sync[1] == 1'b0 && req_rd_ptr != req_wr_ptr) begin
				// This branch is handled in xclk domain for read pointer
				// We only update count here on write
			end
		end
	end

	// XCLK side: read from request FIFO and drive xclk bus
	reg xclk_active;
	reg [DW-1:0] xclk_data_reg;
	reg [AW-1:0] xclk_addr_reg;
	reg [DW/8-1:0] xclk_sel_reg;
	reg xclk_we_reg;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr <= {FIFO_PTR_W{1'b0}};
			req_count <= {(FIFO_PTR_W+1){1'b0}};
			xclk_active <= 1'b0;
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
			xclk_data_reg <= {DW{1'b0}};
			xclk_addr_reg <= {AW{1'b0}};
			xclk_sel_reg <= {(DW/8){1'b0}};
			xclk_we_reg <= 1'b0;
		end else begin
			if (xclk_active) begin
				// Waiting for ack
				if (i_xclk_ack) begin
					xclk_active <= 1'b0;
					o_xclk_cyc <= 1'b0;
					o_xclk_stb <= 1'b0;
					// Read next from FIFO
					if (req_empty_sync[1] == 1'b0) begin
						// There is data in FIFO
						xclk_data_reg <= req_fifo_data[req_rd_ptr];
						xclk_addr_reg <= req_fifo_addr[req_rd_ptr];
						xclk_sel_reg <= req_fifo_sel[req_rd_ptr];
						xclk_we_reg <= req_fifo_we[req_rd_ptr];
						req_rd_ptr <= req_rd_ptr + 1'b1;
						req_count <= req_count - 1'b1;
						// Start next cycle
						xclk_active <= 1'b1;
						o_xclk_cyc <= 1'b1;
						o_xclk_stb <= 1'b1;
						o_xclk_we <= req_fifo_we[req_rd_ptr];
						o_xclk_addr <= req_fifo_addr[req_rd_ptr];
						o_xclk_data <= req_fifo_data[req_rd_ptr];
						o_xclk_sel <= req_fifo_sel[req_rd_ptr];
					end else begin
						// FIFO empty, stay idle
						xclk_active <= 1'b0;
						o_xclk_cyc <= 1'b0;
						o_xclk_stb <= 1'b0;
					end
				end
			end else begin
				// Not active, check if FIFO has data
				if (req_empty_sync[1] == 1'b0) begin
					// Start a new cycle
					xclk_active <= 1'b1;
					o_xclk_cyc <= 1'b1;
					o_xclk_stb <= 1'b1;
					o_xclk_we <= req_fifo_we[req_rd_ptr];
					o_xclk_addr <= req_fifo_addr[req_rd_ptr];
					o_xclk_data <= req_fifo_data[req_rd_ptr];
					o_xclk_sel <= req_fifo_sel[req_rd_ptr];
					xclk_data_reg <= req_fifo_data[req_rd_ptr];
					xclk_addr_reg <= req_fifo_addr[req_rd_ptr];
					xclk_sel_reg <= req_fifo_sel[req_rd_ptr];
					xclk_we_reg <= req_fifo_we[req_rd_ptr];
					req_rd_ptr <= req_rd_ptr + 1'b1;
					req_count <= req_count - 1'b1;
				end
			end
		end
	end

	// XCLK side: write response to FIFO
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_wr_ptr <= {FIFO_PTR_W{1'b0}};
			rsp_count <= {(FIFO_PTR_W+1){1'b0}};
		end else begin
			if (i_xclk_ack && ~rsp_full) begin
				rsp_fifo_data[rsp_wr_ptr] <= i_xclk_data;
				rsp_fifo_err[rsp_wr_ptr] <= i_xclk_err;
				rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
				rsp_count <= rsp_count + 1'b1;
			end
		end
	end

	// WB side: read from response FIFO and drive wb outputs
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr <= {FIFO_PTR_W{1'b0}};
			rsp_count <= {(FIFO_PTR_W+1){1'b0}};
			o_wb_ack <= 1'b0;
			o_wb_data <= {DW{1'b0}};
			o_wb_err <= 1'b0;
		end else begin
			if (rsp_empty_sync[1] == 1'b0) begin
				// There is a response in FIFO
				o_wb_ack <= 1'b1;
				o_wb_data <= rsp_fifo_data[rsp_rd_ptr];
				o_wb_err <= rsp_fifo_err[rsp_rd_ptr];
				rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
				rsp_count <= rsp_count - 1'b1;
			end else begin
				o_wb_ack <= 1'b0;
			end
		end
	end

endmodule
