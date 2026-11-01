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

	// FIFO depth
	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FIFO_WIDTH = AW + DW + DW/8 + 1; // addr + data + sel + we
	localparam FIFO_ADDR_WIDTH = LGFIFO;

	// Request FIFO (Wishbone -> xclk)
	reg [FIFO_WIDTH-1:0] req_fifo [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH:0] req_wr_ptr, req_rd_ptr;
	wire req_full = (req_wr_ptr[FIFO_ADDR_WIDTH] != req_rd_ptr[FIFO_ADDR_WIDTH]) &&
	                 (req_wr_ptr[FIFO_ADDR_WIDTH-1:0] == req_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	wire req_empty = (req_wr_ptr == req_rd_ptr);

	// Response FIFO (xclk -> Wishbone)
	reg [DW+1:0] rsp_fifo [0:FIFO_DEPTH-1]; // data + err
	reg [FIFO_ADDR_WIDTH:0] rsp_wr_ptr, rsp_rd_ptr;
	wire rsp_full = (rsp_wr_ptr[FIFO_ADDR_WIDTH] != rsp_rd_ptr[FIFO_ADDR_WIDTH]) &&
	                 (rsp_wr_ptr[FIFO_ADDR_WIDTH-1:0] == rsp_rd_ptr[FIFO_ADDR_WIDTH-1:0]);
	wire rsp_empty = (rsp_wr_ptr == rsp_rd_ptr);

	// Outstanding request count (for o_wb_stall)
	reg [FIFO_ADDR_WIDTH:0] outstanding_cnt;
	assign o_wb_stall = (outstanding_cnt != 0);

	// Wishbone side: accept request when not full
	wire wb_accept = i_wb_cyc && i_wb_stb && !req_full;

	// Write to request FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= 0;
			outstanding_cnt <= 0;
		end else begin
			if (wb_accept) begin
				req_fifo[req_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
				req_wr_ptr <= req_wr_ptr + 1;
				outstanding_cnt <= outstanding_cnt + 1;
			end
		end
	end

	// xclk side: read from request FIFO and drive xclk outputs
	reg [FIFO_WIDTH-1:0] req_rd_data;
	wire xclk_can_read = !req_empty && !i_xclk_stall;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (xclk_can_read) begin
				req_rd_data <= req_fifo[req_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				req_rd_ptr <= req_rd_ptr + 1;
				o_xclk_cyc <= 1;
				o_xclk_stb <= 1;
				o_xclk_we <= req_rd_data[FIFO_WIDTH-1];
				o_xclk_addr <= req_rd_data[FIFO_WIDTH-2:FIFO_WIDTH-1-AW];
				o_xclk_data <= req_rd_data[FIFO_WIDTH-1-AW:FIFO_WIDTH-1-AW-DW];
				o_xclk_sel <= req_rd_data[FIFO_WIDTH-1-AW-DW:FIFO_WIDTH-1-AW-DW-DW/8];
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
			end
		end
	end

	// xclk side: write response to FIFO
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_wr_ptr <= 0;
		end else begin
			if (i_xclk_ack && !rsp_full) begin
				rsp_fifo[rsp_wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= {i_xclk_err, i_xclk_data};
				rsp_wr_ptr <= rsp_wr_ptr + 1;
			end
		end
	end

	// Wishbone side: read from response FIFO and drive wb outputs
	reg [DW+1:0] rsp_rd_data;
	wire wb_can_read = !rsp_empty;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr <= 0;
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else begin
			if (wb_can_read) begin
				rsp_rd_data <= rsp_fifo[rsp_rd_ptr[FIFO_ADDR_WIDTH-1:0]];
				rsp_rd_ptr <= rsp_rd_ptr + 1;
				o_wb_ack <= 1;
				o_wb_data <= rsp_rd_data[DW-1:0];
				o_wb_err <= rsp_rd_data[DW];
			end else begin
				o_wb_ack <= 0;
			end
		end
	end

	// Decrement outstanding count when response is read
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			outstanding_cnt <= 0;
		end else begin
			if (wb_accept && wb_can_read) begin
				// Both increment and decrement in same cycle
			end else if (wb_accept) begin
				outstanding_cnt <= outstanding_cnt + 1;
			end else if (wb_can_read) begin
				outstanding_cnt <= outstanding_cnt - 1;
			end
		end
	end

endmodule
