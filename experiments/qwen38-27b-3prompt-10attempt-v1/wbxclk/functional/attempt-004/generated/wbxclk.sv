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
	localparam FIFO_WIDTH = AW + DW + (DW/8) + 1; // addr + data + sel + we

	// Request FIFO (wb -> xclk)
	reg [FIFO_WIDTH-1:0] req_fifo [0:FIFO_DEPTH-1];
	reg [LGFIFO:0] req_wr_ptr;
	reg [LGFIFO:0] req_rd_ptr;
	reg [LGFIFO:0] req_count;

	// Response FIFO (xclk -> wb)
	reg [DW+1:0] rsp_fifo [0:FIFO_DEPTH-1]; // data + err
	reg [LGFIFO:0] rsp_wr_ptr;
	reg [LGFIFO:0] rsp_rd_ptr;
	reg [LGFIFO:0] rsp_count;

	// Synchronizers for request FIFO pointers
	reg [LGFIFO:0] req_wr_ptr_sync1, req_wr_ptr_sync2;
	reg [LGFIFO:0] req_rd_ptr_sync1, req_rd_ptr_sync2;

	// Synchronizers for response FIFO pointers
	reg [LGFIFO:0] rsp_wr_ptr_sync1, rsp_wr_ptr_sync2;
	reg [LGFIFO:0] rsp_rd_ptr_sync1, rsp_rd_ptr_sync2;

	// Internal signals
	wire req_full;
	wire req_empty;
	wire rsp_full;
	wire rsp_empty;

	wire [FIFO_WIDTH-1:0] req_wr_data;
	wire [FIFO_WIDTH-1:0] req_rd_data;

	wire [DW+1:0] rsp_wr_data;
	wire [DW+1:0] rsp_rd_data;

	assign req_full  = (req_count == FIFO_DEPTH);
	assign req_empty  = (req_count == 0);
	assign rsp_full   = (rsp_count == FIFO_DEPTH);
	assign rsp_empty  = (rsp_count == 0);

	assign o_wb_stall = req_full;

	// Request write side (wb clock domain)
	assign req_wr_data = {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};

	wire req_wr_en = i_wb_cyc & i_wb_stb & ~req_full;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= 0;
			req_count  <= 0;
		end else begin
			if (req_wr_en) begin
				req_fifo[req_wr_ptr[LGFIFO-1:0]] <= req_wr_data;
				req_wr_ptr <= req_wr_ptr + 1;
			end
			if (req_wr_en && ~req_empty) begin
				req_count <= req_count; // net zero
			end else if (req_wr_en) begin
				req_count <= req_count + 1;
			end else if (~req_empty) begin
				req_count <= req_count - 1;
			end
		end
	end

	// Synchronize req_wr_ptr to xclk domain
	always @(posedge i_xclk_clk) begin
		req_wr_ptr_sync1 <= req_wr_ptr;
		req_wr_ptr_sync2 <= req_wr_ptr_sync1;
	end

	// Synchronize req_rd_ptr to wb domain
	always @(posedge i_wb_clk) begin
		req_rd_ptr_sync1 <= req_rd_ptr;
		req_rd_ptr_sync2 <= req_rd_ptr_sync1;
	end

	// Request read side (xclk clock domain)
	wire req_rd_en = ~req_empty & ~i_xclk_stall;

	always @(posedge i_xclk_clk) begin
		if (req_rd_en) begin
			req_rd_data <= req_fifo[req_rd_ptr[LGFIFO-1:0]];
			req_rd_ptr  <= req_rd_ptr + 1;
		end
	end

	// Drive xclk outputs
	always @(posedge i_xclk_clk) begin
		if (req_rd_en) begin
			o_xclk_cyc  <= 1'b1;
			o_xclk_stb  <= 1'b1;
			o_xclk_we   <= req_rd_data[FIFO_WIDTH-1];
			o_xclk_addr <= req_rd_data[FIFO_WIDTH-2:FIFO_WIDTH-1-AW];
			o_xclk_data <= req_rd_data[FIFO_WIDTH-1-AW:FIFO_WIDTH-1-AW-DW];
			o_xclk_sel  <= req_rd_data[FIFO_WIDTH-1-AW-DW:FIFO_WIDTH-1-AW-DW-(DW/8)];
		end else begin
			o_xclk_cyc  <= 1'b0;
			o_xclk_stb  <= 1'b0;
			o_xclk_we   <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel  <= {(DW/8){1'b0}};
		end
	end

	// Response write side (xclk clock domain)
	assign rsp_wr_data = {i_xclk_err, i_xclk_data};

	wire rsp_wr_en = i_xclk_ack & ~rsp_full;

	always @(posedge i_xclk_clk) begin
		if (rsp_wr_en) begin
			rsp_fifo[rsp_wr_ptr[LGFIFO-1:0]] <= rsp_wr_data;
			rsp_wr_ptr <= rsp_wr_ptr + 1;
		end
		if (rsp_wr_en && ~rsp_empty) begin
			rsp_count <= rsp_count;
		end else if (rsp_wr_en) begin
			rsp_count <= rsp_count + 1;
		end else if (~rsp_empty) begin
			rsp_count <= rsp_count - 1;
		end
	end

	// Synchronize rsp_wr_ptr to wb domain
	always @(posedge i_wb_clk) begin
		rsp_wr_ptr_sync1 <= rsp_wr_ptr;
		rsp_wr_ptr_sync2 <= rsp_wr_ptr_sync1;
	end

	// Synchronize rsp_rd_ptr to xclk domain
	always @(posedge i_xclk_clk) begin
		rsp_rd_ptr_sync1 <= rsp_rd_ptr;
		rsp_rd_ptr_sync2 <= rsp_rd_ptr_sync1;
	end

	// Response read side (wb clock domain)
	wire rsp_rd_en = ~rsp_empty;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr <= 0;
			o_wb_ack   <= 1'b0;
			o_wb_data  <= {DW{1'b0}};
			o_wb_err   <= 1'b0;
		end else begin
			if (rsp_rd_en) begin
				rsp_rd_data <= rsp_fifo[rsp_rd_ptr[LGFIFO-1:0]];
				rsp_rd_ptr  <= rsp_rd_ptr + 1;
				o_wb_ack    <= 1'b1;
				o_wb_data   <= rsp_rd_data[DW-1:0];
				o_wb_err    <= rsp_rd_data[DW];
			end else begin
				o_wb_ack    <= 1'b0;
			end
		end
	end

endmodule
