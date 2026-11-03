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
	localparam DATA_W = AW + DW + DW/8 + 1; // addr + data + sel + we

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
	wire wb_accept = i_wb_cyc && i_wb_stb && !req_full;

	// Write to request FIFO
	wire [DATA_W-1:0] req_data = {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= 0;
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
			rsp_rd_ptr <= 0;
		end else begin
			if (wb_accept) begin
				req_fifo[req_wr_ptr[FIFO_PTR_W-1:0]] <= req_data;
				req_wr_ptr <= req_wr_ptr + 1;
			end

			// Read from response FIFO
			if (!rsp_empty) begin
				o_wb_ack <= 1;
				o_wb_data <= rsp_fifo[rsp_rd_ptr[FIFO_PTR_W-1:0]][DW:0];
				o_wb_err <= rsp_fifo[rsp_rd_ptr[FIFO_PTR_W-1:0]][DW+1];
				rsp_rd_ptr <= rsp_rd_ptr + 1;
			end else begin
				o_wb_ack <= 0;
			end
		end
	end

	assign o_wb_stall = req_full;

	// XCLK side: read from request FIFO and drive outputs
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
			// Read from request FIFO
			if (!req_empty) begin
				o_xclk_cyc <= 1;
				o_xclk_stb <= 1;
				o_xclk_we <= req_fifo[req_rd_ptr[FIFO_PTR_W-1:0]][DATA_W-1];
				o_xclk_addr <= req_fifo[req_rd_ptr[FIFO_PTR_W-1:0]][DATA_W-2:DW+DW/8];
				o_xclk_data <= req_fifo[req_rd_ptr[FIFO_PTR_W-1:0]][DW+DW/8-1:DW/8];
				o_xclk_sel <= req_fifo[req_rd_ptr[FIFO_PTR_W-1:0]][DW/8-1:0];
				req_rd_ptr <= req_rd_ptr + 1;
			end else begin
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
			end

			// Write to response FIFO when ack received
			if (i_xclk_ack && !rsp_full) begin
				rsp_fifo[rsp_wr_ptr[FIFO_PTR_W-1:0]] <= {i_xclk_err, i_xclk_data};
				rsp_wr_ptr <= rsp_wr_ptr + 1;
			end
		end
	end

endmodule
