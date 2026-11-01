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
	reg [LGFIFO:0] req_wr_ptr, req_rd_ptr;
	reg [LGFIFO:0] req_wr_ptr_sync0, req_wr_ptr_sync1;
	reg [LGFIFO:0] req_rd_ptr_sync0, req_rd_ptr_sync1;

	// Response FIFO (xclk -> wb)
	reg [DW+1:0] rsp_mem [0:FIFO_DEPTH-1]; // data + err
	reg [LGFIFO:0] rsp_wr_ptr, rsp_rd_ptr;
	reg [LGFIFO:0] rsp_wr_ptr_sync0, rsp_wr_ptr_sync1;
	reg [LGFIFO:0] rsp_rd_ptr_sync0, rsp_rd_ptr_sync1;

	// Internal signals
	wire req_full;
	wire req_empty;
	wire rsp_full;
	wire rsp_empty;

	wire [FIFO_WIDTH-1:0] req_wr_data;
	wire [FIFO_WIDTH-1:0] req_rd_data;
	wire [DW+1:0] rsp_wr_data;
	wire [DW+1:0] rsp_rd_data;

	wire req_wr_en;
	wire req_rd_en;
	wire rsp_wr_en;
	wire rsp_rd_en;

	// Request FIFO full/empty
	assign req_full = (req_wr_ptr - req_rd_ptr_sync1) == FIFO_DEPTH;
	assign req_empty = (req_wr_ptr_sync1 == req_rd_ptr);

	// Response FIFO full/empty
	assign rsp_full = (rsp_wr_ptr - rsp_rd_ptr_sync1) == FIFO_DEPTH;
	assign rsp_empty = (rsp_wr_ptr_sync1 == rsp_rd_ptr);

	// Stall output: stall when request FIFO is full
	assign o_wb_stall = req_full;

	// Request write enable: accept cycle when not stalled
	assign req_wr_en = i_wb_cyc & i_wb_stb & ~req_full;

	// Request write data
	assign req_wr_data = {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};

	// Request read enable: read when not empty and destination not stalled
	assign req_rd_en = ~req_empty & ~i_xclk_stall;

	// Response write enable: write when ack received
	assign rsp_wr_en = i_xclk_ack;

	// Response write data
	assign rsp_wr_data = {i_xclk_err, i_xclk_data};

	// Response read enable: read when not empty
	assign rsp_rd_en = ~rsp_empty;

	// Request FIFO write pointer (wb domain)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			req_wr_ptr <= 0;
		else if (req_wr_en)
			req_wr_ptr <= req_wr_ptr + 1;
	end

	// Request FIFO read pointer (xclk domain)
	always @(posedge i_xclk_clk) begin
		if (req_rd_en)
			req_rd_ptr <= req_rd_ptr + 1;
	end

	// Request FIFO write pointer synchronization (xclk domain)
	always @(posedge i_xclk_clk) begin
		req_wr_ptr_sync0 <= req_wr_ptr;
		req_wr_ptr_sync1 <= req_wr_ptr_sync0;
	end

	// Request FIFO read pointer synchronization (wb domain)
	always @(posedge i_wb_clk) begin
		req_rd_ptr_sync0 <= req_rd_ptr;
		req_rd_ptr_sync1 <= req_rd_ptr_sync0;
	end

	// Request FIFO memory write (wb domain)
	always @(posedge i_wb_clk) begin
		if (req_wr_en)
			req_mem[req_wr_ptr[LGFIFO-1:0]] <= req_wr_data;
	end

	// Request FIFO memory read (xclk domain)
	always @(posedge i_xclk_clk) begin
		if (req_rd_en)
			req_rd_data <= req_mem[req_rd_ptr[LGFIFO-1:0]];
	end

	// Response FIFO write pointer (xclk domain)
	always @(posedge i_xclk_clk) begin
		if (rsp_wr_en)
			rsp_wr_ptr <= rsp_wr_ptr + 1;
	end

	// Response FIFO read pointer (wb domain)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			rsp_rd_ptr <= 0;
		else if (rsp_rd_en)
			rsp_rd_ptr <= rsp_rd_ptr + 1;
	end

	// Response FIFO write pointer synchronization (wb domain)
	always @(posedge i_wb_clk) begin
		rsp_wr_ptr_sync0 <= rsp_wr_ptr;
		rsp_wr_ptr_sync1 <= rsp_wr_ptr_sync0;
	end

	// Response FIFO read pointer synchronization (xclk domain)
	always @(posedge i_xclk_clk) begin
		rsp_rd_ptr_sync0 <= rsp_rd_ptr;
		rsp_rd_ptr_sync1 <= rsp_rd_ptr_sync0;
	end

	// Response FIFO memory write (xclk domain)
	always @(posedge i_xclk_clk) begin
		if (rsp_wr_en)
			rsp_mem[rsp_wr_ptr[LGFIFO-1:0]] <= rsp_wr_data;
	end

	// Response FIFO memory read (wb domain)
	always @(posedge i_wb_clk) begin
		if (rsp_rd_en)
			rsp_rd_data <= rsp_mem[rsp_rd_ptr[LGFIFO-1:0]];
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

	// Output to wb bus
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack   <= 1'b0;
			o_wb_data  <= {DW{1'b0}};
			o_wb_err   <= 1'b0;
		end else if (rsp_rd_en) begin
			o_wb_ack   <= 1'b1;
			o_wb_data  <= rsp_rd_data[DW:0];
			o_wb_err   <= rsp_rd_data[DW+1];
		end else begin
			o_wb_ack   <= 1'b0;
			o_wb_data  <= {DW{1'b0}};
			o_wb_err   <= 1'b0;
		end
	end

endmodule
