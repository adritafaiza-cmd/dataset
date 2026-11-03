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

	// FIFO for requests from i_wb_clk domain to i_xclk_clk domain
	reg [AW-1:0] wb_addr_fifo [0:FIFO_DEPTH-1];
	reg [DW-1:0] wb_data_fifo [0:FIFO_DEPTH-1];
	reg [DW/8-1:0] wb_sel_fifo [0:FIFO_DEPTH-1];
	reg wb_we_fifo [0:FIFO_DEPTH-1];
	reg wb_cyc_fifo [0:FIFO_DEPTH-1];
	reg wb_stb_fifo [0:FIFO_DEPTH-1];
	reg [$clog2(FIFO_DEPTH)-1:0] wb_fifo_wr_ptr, wb_fifo_rd_ptr;
	reg wb_fifo_full, wb_fifo_empty;

	// FIFO for responses from i_xclk_clk domain to i_wb_clk domain
	reg [DW-1:0] xclk_data_fifo [0:FIFO_DEPTH-1];
	reg xclk_err_fifo [0:FIFO_DEPTH-1];
	reg [$clog2(FIFO_DEPTH)-1:0] xclk_fifo_wr_ptr, xclk_fifo_rd_ptr;
	reg xclk_fifo_full, xclk_fifo_empty;

	// FIFO control logic for i_wb_clk domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_wr_ptr <= 0;
			wb_fifo_rd_ptr <= 0;
			wb_fifo_full <= 0;
			wb_fifo_empty <= 1;
		end else begin
			if (i_wb_cyc && i_wb_stb && !wb_fifo_full) begin
				wb_addr_fifo[wb_fifo_wr_ptr] <= i_wb_addr;
				wb_data_fifo[wb_fifo_wr_ptr] <= i_wb_data;
				wb_sel_fifo[wb_fifo_wr_ptr] <= i_wb_sel;
				wb_we_fifo[wb_fifo_wr_ptr] <= i_wb_we;
				wb_cyc_fifo[wb_fifo_wr_ptr] <= i_wb_cyc;
				wb_stb_fifo[wb_fifo_wr_ptr] <= i_wb_stb;
				wb_fifo_wr_ptr <= wb_fifo_wr_ptr + 1;
				wb_fifo_empty <= 0;
				if (wb_fifo_wr_ptr == wb_fifo_rd_ptr - 1)
					wb_fifo_full <= 1;
			end else if (wb_fifo_rd_ptr != wb_fifo_wr_ptr) begin
				wb_fifo_empty <= 0;
				if (wb_fifo_wr_ptr == wb_fifo_rd_ptr + 1)
					wb_fifo_full <= 0;
			end else begin
				wb_fifo_empty <= 1;
				wb_fifo_full <= 0;
			end
		end
	end

	// FIFO control logic for i_xclk_clk domain
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_fifo_wr_ptr <= 0;
			xclk_fifo_rd_ptr <= 0;
			xclk_fifo_full <= 0;
			xclk_fifo_empty <= 1;
		end else begin
			if (i_xclk_ack && !xclk_fifo_full) begin
				xclk_data_fifo[xclk_fifo_wr_ptr] <= i_xclk_data;
				xclk_err_fifo[xclk_fifo_wr_ptr] <= i_xclk_err;
				xclk_fifo_wr_ptr <= xclk_fifo_wr_ptr + 1;
				xclk_fifo_empty <= 0;
				if (xclk_fifo_wr_ptr == xclk_fifo_rd_ptr - 1)
					xclk_fifo_full <= 1;
			end else if (xclk_fifo_rd_ptr != xclk_fifo_wr_ptr) begin
				xclk_fifo_empty <= 0;
				if (xclk_fifo_wr_ptr == xclk_fifo_rd_ptr + 1)
					xclk_fifo_full <= 0;
			end else begin
				xclk_fifo_empty <= 1;
				xclk_fifo_full <= 0;
			end
		end
	end

	// Cross-domain signals
	reg wb_req_crossed;
	reg wb_req_crossed_d;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_req_crossed <= 0;
			wb_req_crossed_d <= 0;
		end else begin
			if (!wb_fifo_empty && !wb_req_crossed) begin
				wb_req_crossed <= 1;
			end else if (i_xclk_ack) begin
				wb_req_crossed <= 0;
			end
			wb_req_crossed_d <= wb_req_crossed;
		end
	end

	// Output signals for i_xclk_clk domain
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (!wb_fifo_empty && !wb_req_crossed) begin
				o_xclk_cyc <= wb_cyc_fifo[wb_fifo_rd_ptr];
				o_xclk_stb <= wb_stb_fifo[wb_fifo_rd_ptr];
				o_xclk_we <= wb_we_fifo[wb_fifo_rd_ptr];
				o_xclk_addr <= wb_addr_fifo[wb_fifo_rd_ptr];
				o_xclk_data <= wb_data_fifo[wb_fifo_rd_ptr];
				o_xclk_sel <= wb_sel_fifo[wb_fifo_rd_ptr];
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
				wb_fifo_rd_ptr <= wb_fifo_rd_ptr + 1;
			end
		end
	end

	// Output signals for i_wb_clk domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
			o_wb_stall <= 0;
		end else begin
			if (!xclk_fifo_empty) begin
				o_wb_ack <= 1;
				o_wb_data <= xclk_data_fifo[xclk_fifo_rd_ptr];
				o_wb_err <= xclk_err_fifo[xclk_fifo_rd_ptr];
				xclk_fifo_rd_ptr <= xclk_fifo_rd_ptr + 1;
			end else begin
				o_wb_ack <= 0;
				o_wb_data <= 0;
				o_wb_err <= 0;
			end
			o_wb_stall <= wb_fifo_full;
		end
	end

endmodule
