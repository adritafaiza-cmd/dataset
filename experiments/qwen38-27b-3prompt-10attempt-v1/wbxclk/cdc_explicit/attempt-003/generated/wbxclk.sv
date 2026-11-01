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

	// Local parameters
	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FIFO_WIDTH = AW + DW + (DW/8) + 1; // addr + data + sel + we
	localparam PTR_WIDTH = LGFIFO;

	// Request FIFO (wb -> xclk)
	reg [FIFO_WIDTH-1:0] req_fifo [0:FIFO_DEPTH-1];
	reg [PTR_WIDTH-1:0] req_wr_ptr;
	reg [PTR_WIDTH-1:0] req_rd_ptr;
	reg [PTR_WIDTH-1:0] req_rd_ptr_sync1;
	reg [PTR_WIDTH-1:0] req_rd_ptr_sync2;

	// Response FIFO (xclk -> wb)
	reg [DW+1:0] rsp_fifo [0:FIFO_DEPTH-1]; // data + err
	reg [PTR_WIDTH-1:0] rsp_wr_ptr;
	reg [PTR_WIDTH-1:0] rsp_rd_ptr;
	reg [PTR_WIDTH-1:0] rsp_rd_ptr_sync1;
	reg [PTR_WIDTH-1:0] rsp_rd_ptr_sync2;

	// Synchronizers for request read pointer (xclk domain)
	always @(posedge i_xclk_clk) begin
		req_rd_ptr_sync1 <= req_rd_ptr;
		req_rd_ptr_sync2 <= req_rd_ptr_sync1;
	end

	// Synchronizers for response read pointer (wb domain)
	always @(posedge i_wb_clk) begin
		rsp_rd_ptr_sync1 <= rsp_rd_ptr;
		rsp_rd_ptr_sync2 <= rsp_rd_ptr_sync1;
	end

	// Request FIFO full/empty logic
	wire req_full = (req_wr_ptr == req_rd_ptr_sync2) && (req_wr_ptr[PTR_WIDTH-1] != req_rd_ptr_sync2[PTR_WIDTH-1]);
	wire req_empty = (req_wr_ptr == req_rd_ptr_sync2);

	// Response FIFO full/empty logic
	wire rsp_full = (rsp_wr_ptr == rsp_rd_ptr_sync2) && (rsp_wr_ptr[PTR_WIDTH-1] != rsp_rd_ptr_sync2[PTR_WIDTH-1]);
	wire rsp_empty = (rsp_wr_ptr == rsp_rd_ptr_sync2);

	// o_wb_stall: high when request FIFO is full
	assign o_wb_stall = req_full;

	// Write to request FIFO in wb domain
	wire req_wr_en = i_wb_cyc && i_wb_stb && !req_full;

	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			req_wr_ptr <= {PTR_WIDTH{1'b0}};
		end else if (req_wr_en) begin
			req_fifo[req_wr_ptr] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
			req_wr_ptr <= req_wr_ptr + 1'b1;
		end
	end

	// Read from request FIFO in xclk domain
	wire req_rd_en = !req_empty && !i_xclk_stall;

	always @(posedge i_xclk_clk) begin
		if (req_rd_en) begin
			req_rd_ptr <= req_rd_ptr + 1'b1;
		end
	end

	// Drive xclk outputs from request FIFO
	always @(posedge i_xclk_clk) begin
		if (req_rd_en) begin
			o_xclk_cyc <= 1'b1;
			o_xclk_stb <= 1'b1;
			o_xclk_we <= req_fifo[req_rd_ptr][FIFO_WIDTH-1];
			o_xclk_addr <= req_fifo[req_rd_ptr][FIFO_WIDTH-2:FIFO_WIDTH-1-DW];
			o_xclk_data <= req_fifo[req_rd_ptr][FIFO_WIDTH-1-DW:FIFO_WIDTH-1-DW-(DW/8)];
			o_xclk_sel <= req_fifo[req_rd_ptr][FIFO_WIDTH-1-DW-(DW/8)-1:0];
		end else begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
		end
	end

	// Write to response FIFO in xclk domain
	wire rsp_wr_en = i_xclk_ack && !rsp_full;

	always @(posedge i_xclk_clk) begin
		if (rsp_wr_en) begin
			rsp_fifo[rsp_wr_ptr] <= {i_xclk_err, i_xclk_data};
			rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
		end
	end

	// Read from response FIFO in wb domain
	wire rsp_rd_en = !rsp_empty;

	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			rsp_rd_ptr <= {PTR_WIDTH{1'b0}};
			o_wb_ack <= 1'b0;
			o_wb_data <= {DW{1'b0}};
			o_wb_err <= 1'b0;
		end else if (rsp_rd_en) begin
			rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
			o_wb_ack <= 1'b1;
			o_wb_data <= rsp_fifo[rsp_rd_ptr][DW:0];
			o_wb_err <= rsp_fifo[rsp_rd_ptr][DW+1];
		end else begin
			o_wb_ack <= 1'b0;
			o_wb_data <= {DW{1'b0}};
			o_wb_err <= 1'b0;
		end
	end

endmodule
