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
	reg [FIFO_WIDTH-1:0] req_mem [0:FIFO_DEPTH-1];
	reg [LGFIFO:0] req_wr_ptr;
	reg [LGFIFO:0] req_rd_ptr;

	// Response FIFO (xclk -> wb)
	reg [DW+1:0] rsp_mem [0:FIFO_DEPTH-1]; // data + err
	reg [LGFIFO:0] rsp_wr_ptr;
	reg [LGFIFO:0] rsp_rd_ptr;

	// Request FIFO write logic (wb domain)
	wire req_wr_en = i_wb_cyc & i_wb_stb & ~o_wb_stall;
	wire [FIFO_WIDTH-1:0] req_wr_data = {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			req_wr_ptr <= {LGFIFO+1{1'b0}};
		else if (req_wr_en)
			req_wr_ptr <= req_wr_ptr + 1'b1;
	end

	// Request FIFO read logic (xclk domain)
	wire req_rd_en = ~i_xclk_stall & (req_rd_ptr != req_wr_ptr);
	wire [FIFO_WIDTH-1:0] req_rd_data = req_mem[req_rd_ptr[LGFIFO-1:0]];

	always @(posedge i_xclk_clk) begin
		if (req_rd_en)
			req_rd_ptr <= req_rd_ptr + 1'b1;
	end

	// Write to request FIFO memory (wb domain)
	always @(posedge i_wb_clk) begin
		if (req_wr_en)
			req_mem[req_wr_ptr[LGFIFO-1:0]] <= req_wr_data;
	end

	// Output to xclk bus
	always @(posedge i_xclk_clk) begin
		if (req_rd_en) begin
			o_xclk_cyc  <= 1'b1;
			o_xclk_stb  <= 1'b1;
			o_xclk_we   <= req_rd_data[FIFO_WIDTH-1];
			o_xclk_addr <= req_rd_data[FIFO_WIDTH-2:FIFO_WIDTH-1-AW];
			o_xclk_data <= req_rd_data[FIFO_WIDTH-1-AW:FIFO_WIDTH-1-AW-DW];
			o_xclk_sel  <= req_rd_data[FIFO_WIDTH-1-AW-DW-1:0];
		end else begin
			o_xclk_cyc  <= 1'b0;
			o_xclk_stb  <= 1'b0;
			o_xclk_we   <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel  <= {(DW/8){1'b0}};
		end
	end

	// Response FIFO write logic (xclk domain)
	wire rsp_wr_en = i_xclk_ack;
	wire [DW+1:0] rsp_wr_data = {i_xclk_err, i_xclk_data};

	always @(posedge i_xclk_clk) begin
		if (rsp_wr_en)
			rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
	end

	// Response FIFO read logic (wb domain)
	wire rsp_rd_en = (rsp_rd_ptr != rsp_wr_ptr);
	wire [DW+1:0] rsp_rd_data = rsp_mem[rsp_rd_ptr[LGFIFO-1:0]];

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			rsp_rd_ptr <= {LGFIFO+1{1'b0}};
		else if (rsp_rd_en)
			rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
	end

	// Write to response FIFO memory (xclk domain)
	always @(posedge i_xclk_clk) begin
		if (rsp_wr_en)
			rsp_mem[rsp_wr_ptr[LGFIFO-1:0]] <= rsp_wr_data;
	end

	// Output to wb bus
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack   <= 1'b0;
			o_wb_data  <= {DW{1'b0}};
			o_wb_err   <= 1'b0;
		end else if (rsp_rd_en) begin
			o_wb_ack   <= 1'b1;
			o_wb_data  <= rsp_rd_data[DW-1:0];
			o_wb_err   <= rsp_rd_data[DW];
		end else begin
			o_wb_ack   <= 1'b0;
			o_wb_data  <= {DW{1'b0}};
			o_wb_err   <= 1'b0;
		end
	end

	// Stall logic: stall when request FIFO is full
	// FIFO is full when write pointer and read pointer have same lower bits but different upper bits
	wire req_full = (req_wr_ptr[LGFIFO] != req_rd_ptr[LGFIFO]) && 
	                (req_wr_ptr[LGFIFO-1:0] == req_rd_ptr[LGFIFO-1:0]);

	assign o_wb_stall = req_full;

endmodule
