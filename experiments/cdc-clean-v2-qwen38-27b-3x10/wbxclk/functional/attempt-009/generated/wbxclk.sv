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
	wire [DATA_W-1:0] req_data = {i_wb_we, i_wb_cyc, i_wb_sel, i_wb_data, i_wb_addr};

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= 0;
		end else if (wb_accept) begin
			req_fifo[req_wr_ptr[FIFO_PTR_W-1:0]] <= req_data;
			req_wr_ptr <= req_wr_ptr + 1;
		end
	end

	// XCLK side: read from request FIFO and drive o_xclk_*
	// We need to present a valid cycle when the FIFO is not empty and the destination is ready
	wire xclk_ready = !i_xclk_stall;
	wire xclk_pop = !req_empty && xclk_ready;

	// Register the output to xclk
	reg [DATA_W-1:0] req_out_reg;
	reg xclk_valid;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr <= 0;
			req_out_reg <= 0;
			xclk_valid <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (xclk_pop) begin
				req_out_reg <= req_fifo[req_rd_ptr[FIFO_PTR_W-1:0]];
				req_rd_ptr <= req_rd_ptr + 1;
				xclk_valid <= 1;
			end else if (i_xclk_ack) begin
				xclk_valid <= 0;
			end

			if (xclk_valid) begin
				o_xclk_cyc <= req_out_reg[DATA_W-1];
				o_xclk_stb <= 1;
				o_xclk_we <= req_out_reg[DATA_W-2];
				o_xclk_sel <= req_out_reg[DATA_W-3:DW/8];
				o_xclk_data <= req_out_reg[DW/8+DW-1:DW/8];
				o_xclk_addr <= req_out_reg[DW/8+DW+AW-1:DW/8+DW];
			end else begin
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
				o_xclk_we <= 0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// XCLK side: write response to FIFO
	wire [DW+1:0] rsp_data = {i_xclk_err, i_xclk_data};
	wire rsp_write = i_xclk_ack && !rsp_full;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_wr_ptr <= 0;
		end else if (rsp_write) begin
			rsp_fifo[rsp_wr_ptr[FIFO_PTR_W-1:0]] <= rsp_data;
			rsp_wr_ptr <= rsp_wr_ptr + 1;
		end
	end

	// WB side: read from response FIFO and drive o_wb_*
	wire rsp_pop = !rsp_empty;

	reg [DW+1:0] rsp_out_reg;
	reg wb_valid;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr <= 0;
			rsp_out_reg <= 0;
			wb_valid <= 0;
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else begin
			if (rsp_pop) begin
				rsp_out_reg <= rsp_fifo[rsp_rd_ptr[FIFO_PTR_W-1:0]];
				rsp_rd_ptr <= rsp_rd_ptr + 1;
				wb_valid <= 1;
			end else if (o_wb_ack) begin
				wb_valid <= 0;
			end

			if (wb_valid) begin
				o_wb_ack <= 1;
				o_wb_data <= rsp_out_reg[DW-1:0];
				o_wb_err <= rsp_out_reg[DW];
			end else begin
				o_wb_ack <= 0;
				o_wb_data <= 0;
				o_wb_err <= 0;
			end
		end
	end

	// Backpressure: stall when request FIFO is full
	assign o_wb_stall = req_full;

endmodule
