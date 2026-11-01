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

	// Request FIFO: wb_clk domain
	reg [FIFO_WIDTH-1:0] req_fifo [0:FIFO_DEPTH-1];
	reg [LGFIFO:0] req_wr_ptr;
	reg [LGFIFO:0] req_rd_ptr;
	reg [LGFIFO:0] req_rd_ptr_sync1;
	reg [LGFIFO:0] req_rd_ptr_sync2;
	reg [LGFIFO:0] req_wr_ptr_sync1;
	reg [LGFIFO:0] req_wr_ptr_sync2;

	// Response FIFO: xclk_clk domain
	reg [DW+1:0] rsp_fifo [0:FIFO_DEPTH-1]; // data + err
	reg [LGFIFO:0] rsp_wr_ptr;
	reg [LGFIFO:0] rsp_rd_ptr;
	reg [LGFIFO:0] rsp_rd_ptr_sync1;
	reg [LGFIFO:0] rsp_rd_ptr_sync2;
	reg [LGFIFO:0] rsp_wr_ptr_sync1;
	reg [LGFIFO:0] rsp_wr_ptr_sync2;

	// Request FIFO write logic (wb_clk domain)
	wire req_full = (req_wr_ptr - req_rd_ptr_sync2) == FIFO_DEPTH;
	wire req_empty = (req_wr_ptr == req_rd_ptr_sync2);
	wire req_can_write = !req_full;
	wire req_write = i_wb_cyc && i_wb_stb && req_can_write;

	assign o_wb_stall = req_full;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= 0;
		end else if (req_write) begin
			req_fifo[req_wr_ptr[LGFIFO-1:0]] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
			req_wr_ptr <= req_wr_ptr + 1;
		end
	end

	// Request FIFO read pointer sync (xclk_clk domain)
	always @(posedge i_xclk_clk) begin
		req_rd_ptr_sync1 <= req_rd_ptr;
		req_rd_ptr_sync2 <= req_rd_ptr_sync1;
	end

	// Request FIFO read logic (xclk_clk domain)
	wire req_xclk_empty = (req_rd_ptr == req_wr_ptr_sync2);
	wire req_xclk_can_read = !req_xclk_empty && !i_xclk_stall;
	wire req_xclk_read = req_xclk_can_read;

	always @(posedge i_xclk_clk) begin
		if (req_xclk_read) begin
			o_xclk_cyc <= 1'b1;
			o_xclk_stb <= 1'b1;
			o_xclk_we <= req_fifo[req_rd_ptr[LGFIFO-1:0]][FIFO_WIDTH-1];
			o_xclk_addr <= req_fifo[req_rd_ptr[LGFIFO-1:0]][FIFO_WIDTH-2:FIFO_WIDTH-1-AW];
			o_xclk_data <= req_fifo[req_rd_ptr[LGFIFO-1:0]][FIFO_WIDTH-1-AW:FIFO_WIDTH-1-AW-DW];
			o_xclk_sel <= req_fifo[req_rd_ptr[LGFIFO-1:0]][FIFO_WIDTH-1-AW-DW:FIFO_WIDTH-1-AW-DW-(DW/8)];
			req_rd_ptr <= req_rd_ptr + 1;
		end else begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
		end
	end

	// Request FIFO write pointer sync (xclk_clk domain)
	always @(posedge i_xclk_clk) begin
		req_wr_ptr_sync1 <= req_wr_ptr;
		req_wr_ptr_sync2 <= req_wr_ptr_sync1;
	end

	// Response FIFO write logic (xclk_clk domain)
	wire rsp_full = (rsp_wr_ptr - rsp_rd_ptr_sync2) == FIFO_DEPTH;
	wire rsp_write = i_xclk_ack && !rsp_full;

	always @(posedge i_xclk_clk) begin
		if (rsp_write) begin
			rsp_fifo[rsp_wr_ptr[LGFIFO-1:0]] <= {i_xclk_err, i_xclk_data};
			rsp_wr_ptr <= rsp_wr_ptr + 1;
		end
	end

	// Response FIFO read pointer sync (wb_clk domain)
	always @(posedge i_wb_clk) begin
		rsp_rd_ptr_sync1 <= rsp_rd_ptr;
		rsp_rd_ptr_sync2 <= rsp_rd_ptr_sync1;
	end

	// Response FIFO read logic (wb_clk domain)
	wire rsp_wb_empty = (rsp_rd_ptr == rsp_wr_ptr_sync2);
	wire rsp_wb_can_read = !rsp_wb_empty;
	wire rsp_wb_read = rsp_wb_can_read;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr <= 0;
			o_wb_ack <= 1'b0;
			o_wb_data <= 0;
			o_wb_err <= 1'b0;
		end else if (rsp_wb_read) begin
			o_wb_ack <= 1'b1;
			o_wb_err <= rsp_fifo[rsp_rd_ptr[LGFIFO-1:0]][DW];
			o_wb_data <= rsp_fifo[rsp_rd_ptr[LGFIFO-1:0]][DW-1:0];
			rsp_rd_ptr <= rsp_rd_ptr + 1;
		end else begin
			o_wb_ack <= 1'b0;
		end
	end

	// Response FIFO write pointer sync (wb_clk domain)
	always @(posedge i_wb_clk) begin
		rsp_wr_ptr_sync1 <= rsp_wr_ptr;
		rsp_wr_ptr_sync2 <= rsp_wr_ptr_sync1;
	end

endmodule
