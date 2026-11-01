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
	input	wire	[(DW/8-1):0]	i_xclk_err
);

	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FIFO_ADDR_WIDTH = LGFIFO;
	localparam FIFO_FULL_THRESHOLD = FIFO_DEPTH - 1;

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
	reg [1:0] req_full_sync;
	reg [1:0] rsp_full_sync;
	reg [1:0] req_empty_sync;
	reg [1:0] rsp_empty_sync;

	// Internal signals
	wire req_full = (req_count == FIFO_DEPTH);
	wire rsp_full = (rsp_count == FIFO_DEPTH);
	wire req_empty = (req_count == 0);
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
			req_empty_sync <= 2'b11;
		else
			req_empty_sync <= {req_empty_sync[0], req_empty};
	end

	// Synchronize rsp_empty to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			rsp_empty_sync <= 2'b11;
		else
			rsp_empty_sync <= {rsp_empty_sync[0], rsp_empty};
	end

	// o_wb_stall: high when request FIFO is full or response FIFO is full
	assign o_wb_stall = req_full_sync[1] | rsp_full_sync[1];

	// WB side: accept cycle when not stalled
	wire wb_accept = i_wb_cyc & i_wb_stb & ~o_wb_stall;

	// Write to request FIFO on wb clock
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			req_count <= {(FIFO_ADDR_WIDTH+1){1'b0}};
		end else begin
			if (wb_accept) begin
				req_fifo_data[req_wr_ptr] <= i_wb_data;
				req_fifo_addr[req_wr_ptr] <= i_wb_addr;
				req_fifo_sel[req_wr_ptr] <= i_wb_sel;
				req_fifo_we[req_wr_ptr] <= i_wb_we;
				req_wr_ptr <= req_wr_ptr + 1'b1;
			end
			if (req_empty_sync[1] == 1'b0 && ~req_empty) begin
				// Read from request FIFO (xclk side)
			end
			// Update count
			case ({wb_accept, req_empty_sync[1] == 1'b0 && ~req_empty})
				2'b10: req_count <= req_count + 1'b1;
				2'b01: req_count <= req_count - 1'b1;
				2'b11: req_count <= req_count;
				2'b00: req_count <= req_count;
			endcase
		end
	end

	// XCLK side: read from request FIFO
	wire xclk_read = ~req_empty_sync[1] & ~i_xclk_stall;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
		end else begin
			if (xclk_read) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= req_fifo_we[req_rd_ptr];
				o_xclk_addr <= req_fifo_addr[req_rd_ptr];
				o_xclk_data <= req_fifo_data[req_rd_ptr];
				o_xclk_sel <= req_fifo_sel[req_rd_ptr];
				req_rd_ptr <= req_rd_ptr + 1'b1;
			end else begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
			end
		end
	end

	// XCLK side: write to response FIFO when ack
	wire xclk_ack_valid = i_xclk_ack;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			rsp_count <= {(FIFO_ADDR_WIDTH+1){1'b0}};
		end else begin
			if (xclk_ack_valid) begin
				rsp_fifo_data[rsp_wr_ptr] <= i_xclk_data;
				rsp_fifo_err[rsp_wr_ptr] <= i_xclk_err;
				rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
			end
			// Update count
			case ({xclk_ack_valid, rsp_empty_sync[1] == 1'b0 && ~rsp_empty})
				2'b10: rsp_count <= rsp_count + 1'b1;
				2'b01: rsp_count <= rsp_count - 1'b1;
				2'b11: rsp_count <= rsp_count;
				2'b00: rsp_count <= rsp_count;
			endcase
		end
	end

	// WB side: read from response FIFO
	wire wb_read = ~rsp_empty_sync[1] & ~rsp_empty;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			o_wb_ack <= 1'b0;
			o_wb_data <= {DW{1'b0}};
			o_wb_err <= 1'b0;
		end else begin
			if (wb_read) begin
				o_wb_ack <= 1'b1;
				o_wb_data <= rsp_fifo_data[rsp_rd_ptr];
				o_wb_err <= rsp_fifo_err[rsp_rd_ptr];
				rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
			end else begin
				o_wb_ack <= 1'b0;
			end
		end
	end

endmodule
