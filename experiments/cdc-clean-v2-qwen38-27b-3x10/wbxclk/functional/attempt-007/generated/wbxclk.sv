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
	localparam FIFO_PTR_W = LGFIFO;
	localparam DATA_W = AW + DW + (DW/8) + 2; // addr + data + sel + we + cyc

	// Request FIFO (wb -> xclk)
	reg [DATA_W-1:0] req_fifo [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W:0] req_wr_ptr, req_rd_ptr;
	wire req_full = (req_wr_ptr[FIFO_PTR_W] != req_rd_ptr[FIFO_PTR_W]) &&
	                 (req_wr_ptr[FIFO_PTR_W-1:0] == req_rd_ptr[FIFO_PTR_W-1:0]);
	wire req_empty = (req_wr_ptr == req_rd_ptr);

	// Response FIFO (xclk -> wb)
	reg [DW+1:0] rsp_fifo [0:FIFO_DEPTH-1]; // data + err
	reg [FIFO_PTR_W:0] rsp_wr_ptr, rsp_rd_ptr;
	wire rsp_full = (rsp_wr_ptr[FIFO_PTR_W] != rsp_rd_ptr[FIFO_PTR_W]) &&
	                 (rsp_wr_ptr[FIFO_PTR_W-1:0] == rsp_rd_ptr[FIFO_PTR_W-1:0]);
	wire rsp_empty = (rsp_wr_ptr == rsp_rd_ptr);

	// WB side: accept cycle when not full
	wire wb_accept = i_wb_cyc && !req_full;

	// Write to request FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= 0;
		end else if (wb_accept) begin
			req_fifo[req_wr_ptr[FIFO_PTR_W-1:0]] <= {i_wb_we, i_wb_cyc, i_wb_sel, i_wb_data, i_wb_addr};
			req_wr_ptr <= req_wr_ptr + 1;
		end
	end

	// XCLK side: read from request FIFO and drive xclk bus
	reg xclk_active;
	reg [DATA_W-1:0] xclk_req_reg;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			xclk_active <= 0;
			xclk_req_reg <= 0;
		end else begin
			if (!xclk_active && !req_empty) begin
				// Load next request
				xclk_req_reg <= req_fifo[req_rd_ptr[FIFO_PTR_W-1:0]];
				req_rd_ptr <= req_rd_ptr + 1;
				xclk_active <= 1;
				o_xclk_cyc <= 1;
				o_xclk_stb <= 1;
				o_xclk_we <= xclk_req_reg[DATA_W-1];
				o_xclk_addr <= xclk_req_reg[0:AW-1];
				o_xclk_data <= xclk_req_reg[AW:AW+DW-1];
				o_xclk_sel <= xclk_req_reg[AW+DW:AW+DW+(DW/8)-1];
			end else if (xclk_active && i_xclk_ack) begin
				// Ack received, write response to rsp fifo
				rsp_fifo[rsp_wr_ptr[FIFO_PTR_W-1:0]] <= {i_xclk_err, i_xclk_data};
				rsp_wr_ptr <= rsp_wr_ptr + 1;
				xclk_active <= 0;
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
			end
		end
	end

	// WB side: read from response FIFO and drive ack/err/data
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr <= 0;
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else if (!rsp_empty) begin
			o_wb_ack <= 1;
			o_wb_data <= rsp_fifo[rsp_rd_ptr[FIFO_PTR_W-1:0]][0:DW-1];
			o_wb_err <= rsp_fifo[rsp_rd_ptr[FIFO_PTR_W-1:0]][DW];
			rsp_rd_ptr <= rsp_rd_ptr + 1;
		end else begin
			o_wb_ack <= 0;
		end
	end

	// Stall output
	assign o_wb_stall = req_full;

endmodule
