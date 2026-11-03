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

	// FIFO for Wishbone to XCLK
	reg [AW-1:0] wb2xclk_addr_fifo [0:(1<<LGFIFO)-1];
	reg [DW-1:0] wb2xclk_data_fifo [0:(1<<LGFIFO)-1];
	reg [(DW/8-1):0] wb2xclk_sel_fifo [0:(1<<LGFIFO)-1];
	reg wb2xclk_we_fifo [0:(1<<LGFIFO)-1];
	reg wb2xclk_cyc_fifo [0:(1<<LGFIFO)-1];
	reg [LGFIFO-1:0] wb2xclk_wr_ptr, wb2xclk_rd_ptr;
	reg wb2xclk_full, wb2xclk_empty;

	// FIFO for XCLK to Wishbone
	reg [DW-1:0] xclk2wb_data_fifo [0:(1<<LGFIFO)-1];
	reg xclk2wb_err_fifo [0:(1<<LGFIFO)-1];
	reg [LGFIFO-1:0] xclk2wb_wr_ptr, xclk2wb_rd_ptr;
	reg xclk2wb_full, xclk2wb_empty;

	// FIFO control logic for Wishbone to XCLK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb2xclk_wr_ptr <= 0;
			wb2xclk_rd_ptr <= 0;
			wb2xclk_full <= 0;
			wb2xclk_empty <= 1;
		end else begin
			if (i_wb_stb && !wb2xclk_full && !o_wb_stall) begin
				wb2xclk_addr_fifo[wb2xclk_wr_ptr] <= i_wb_addr;
				wb2xclk_data_fifo[wb2xclk_wr_ptr] <= i_wb_data;
				wb2xclk_sel_fifo[wb2xclk_wr_ptr] <= i_wb_sel;
				wb2xclk_we_fifo[wb2xclk_wr_ptr] <= i_wb_we;
				wb2xclk_cyc_fifo[wb2xclk_wr_ptr] <= i_wb_cyc;
				wb2xclk_wr_ptr <= wb2xclk_wr_ptr + 1;
				wb2xclk_empty <= 0;
				if (wb2xclk_wr_ptr == wb2xclk_rd_ptr - 1)
					wb2xclk_full <= 1;
			end
			if (i_xclk_ack && !wb2xclk_empty) begin
				wb2xclk_rd_ptr <= wb2xclk_rd_ptr + 1;
				wb2xclk_full <= 0;
				if (wb2xclk_wr_ptr == wb2xclk_rd_ptr)
					wb2xclk_empty <= 1;
			end
		end
	end

	// FIFO control logic for XCLK to Wishbone
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk2wb_wr_ptr <= 0;
			xclk2wb_rd_ptr <= 0;
			xclk2wb_full <= 0;
			xclk2wb_empty <= 1;
		end else begin
			if (i_xclk_ack && !xclk2wb_full) begin
				xclk2wb_data_fifo[xclk2wb_wr_ptr] <= i_xclk_data;
				xclk2wb_err_fifo[xclk2wb_wr_ptr] <= i_xclk_err;
				xclk2wb_wr_ptr <= xclk2wb_wr_ptr + 1;
				xclk2wb_empty <= 0;
				if (xclk2wb_wr_ptr == xclk2wb_rd_ptr - 1)
					xclk2wb_full <= 1;
			end
			if (o_wb_ack && !xclk2wb_empty) begin
				xclk2wb_rd_ptr <= xclk2wb_rd_ptr + 1;
				xclk2wb_full <= 0;
				if (xclk2wb_wr_ptr == xclk2wb_rd_ptr)
					xclk2wb_empty <= 1;
			end
		end
	end

	// Output assignments for Wishbone side
	assign o_wb_stall = wb2xclk_full;
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else begin
			if (!wb2xclk_empty && i_xclk_ack) begin
				o_wb_ack <= 1;
				o_wb_data <= xclk2wb_data_fifo[xclk2wb_rd_ptr];
				o_wb_err <= xclk2wb_err_fifo[xclk2wb_rd_ptr];
			end else begin
				o_wb_ack <= 0;
			end
		end
	end

	// Output assignments for XCLK side
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (!wb2xclk_empty && !i_xclk_stall) begin
				o_xclk_cyc <= wb2xclk_cyc_fifo[wb2xclk_rd_ptr];
				o_xclk_stb <= 1;
				o_xclk_we <= wb2xclk_we_fifo[wb2xclk_rd_ptr];
				o_xclk_addr <= wb2xclk_addr_fifo[wb2xclk_rd_ptr];
				o_xclk_data <= wb2xclk_data_fifo[wb2xclk_rd_ptr];
				o_xclk_sel <= wb2xclk_sel_fifo[wb2xclk_rd_ptr];
			end else begin
				o_xclk_stb <= 0;
			end
		end
	end

endmodule
