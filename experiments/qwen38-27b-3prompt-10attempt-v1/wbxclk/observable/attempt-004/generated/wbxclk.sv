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
	output	reg	[(DW/1):0]	o_wb_data,
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

	// FIFO depth and width
	localparam REQ_FIFO_DEPTH = 1 << LGFIFO;
	localparam REQ_FIFO_WIDTH = AW + DW + (DW/8) + 1; // addr + data + sel + we
	localparam RSP_FIFO_DEPTH = 1 << LGFIFO;
	localparam RSP_FIFO_WIDTH = DW + 1; // data + err

	// Request FIFO (Wishbone side -> xclk side)
	reg [REQ_FIFO_WIDTH-1:0] req_fifo_mem [0:REQ_FIFO_DEPTH-1];
	reg [LGFIFO:0] req_wr_ptr, req_rd_ptr;
	reg req_wr_en, req_rd_en;
	wire req_empty, req_full;

	// Response FIFO (xclk side -> Wishbone side)
	reg [RSP_FIFO_WIDTH-1:0] rsp_fifo_mem [0:RSP_FIFO_DEPTH-1];
	reg [LGFIFO:0] rsp_wr_ptr, rsp_rd_ptr;
	reg rsp_wr_en, rsp_rd_en;
	wire rsp_empty, rsp_full;

	// Outstanding request counter (Wishbone clock domain)
	reg [LGFIFO:0] outstanding_cnt;
	assign o_wb_stall = (outstanding_cnt != 0);

	// Request FIFO full/empty
	assign req_full  = (req_wr_ptr[LGFIFO] != req_rd_ptr[LGFIFO]) &&
	                   (req_wr_ptr[LGFIFO-1:0] == req_rd_ptr[LGFIFO-1:0]);
	assign req_empty = (req_wr_ptr == req_rd_ptr);

	// Response FIFO full/empty
	assign rsp_full  = (rsp_wr_ptr[LGFIFO] != rsp_rd_ptr[LGFIFO]) &&
	                   (rsp_wr_ptr[LGFIFO-1:0] == rsp_rd_ptr[LGFIFO-1:0]);
	assign rsp_empty = (rsp_wr_ptr == rsp_rd_ptr);

	// Wishbone clock domain: write to request FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= 0;
			outstanding_cnt <= 0;
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else begin
			// Write request to FIFO if not full and Wishbone is active
			req_wr_en <= i_wb_cyc && i_wb_stb && !req_full;
			if (i_wb_cyc && i_wb_stb && !req_full) begin
				req_fifo_mem[req_wr_ptr[LGFIFO-1:0]] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
				req_wr_ptr <= req_wr_ptr + 1;
				outstanding_cnt <= outstanding_cnt + 1;
			end

			// Read response from FIFO
			rsp_rd_en <= !rsp_empty;
			if (!rsp_empty) begin
				rsp_rd_ptr <= rsp_rd_ptr + 1;
				outstanding_cnt <= outstanding_cnt - 1;
				o_wb_ack <= 1;
				o_wb_data <= rsp_fifo_mem[rsp_rd_ptr[LGFIFO-1:0]][RSP_FIFO_WIDTH-1:1];
				o_wb_err <= rsp_fifo_mem[rsp_rd_ptr[LGFIFO-1:0]][0];
			end else begin
				o_wb_ack <= 0;
			end
		end
	end

	// xclk clock domain: read from request FIFO, write to response FIFO
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr <= 0;
			rsp_wr_ptr <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			// Read request from FIFO if not empty and xclk is not stalled
			req_rd_en <= !req_empty && !i_xclk_stall;
			if (!req_empty && !i_xclk_stall) begin
				req_rd_ptr <= req_rd_ptr + 1;
				o_xclk_cyc <= 1;
				o_xclk_stb <= 1;
				o_xclk_we <= req_fifo_mem[req_rd_ptr[LGFIFO-1:0]][REQ_FIFO_WIDTH-1];
				o_xclk_addr <= req_fifo_mem[req_rd_ptr[LGFIFO-1:0]][REQ_FIFO_WIDTH-2:AW+DW+DW/8];
				o_xclk_data <= req_fifo_mem[req_rd_ptr[LGFIFO-1:0]][AW+DW+DW/8-1:DW/8];
				o_xclk_sel <= req_fifo_mem[req_rd_ptr[LGFIFO-1:0]][DW/8-1:0];
			end else begin
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
			end

			// Write response to FIFO if xclk ack is high
			rsp_wr_en <= i_xclk_ack;
			if (i_xclk_ack) begin
				rsp_fifo_mem[rsp_wr_ptr[LGFIFO-1:0]] <= {i_xclk_err, i_xclk_data};
				rsp_wr_ptr <= rsp_wr_ptr + 1;
			end
		end
	end

endmodule
