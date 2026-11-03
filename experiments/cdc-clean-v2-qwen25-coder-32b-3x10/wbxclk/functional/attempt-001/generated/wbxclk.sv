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
	reg [AW-1:0] fifo_addr [0:(1<<LGFIFO)-1];
	reg [DW-1:0] fifo_data [0:(1<<LGFIFO)-1];
	reg [(DW/8-1):0] fifo_sel [0:(1<<LGFIFO)-1];
	reg fifo_we [0:(1<<LGFIFO)-1];
	reg fifo_stb [0:(1<<LGFIFO)-1];
	reg fifo_cyc [0:(1<<LGFIFO)-1];
	reg [LGFIFO:0] wb_wr_ptr, wb_rd_ptr;
	reg [LGFIFO:0] wb_full, wb_empty;

	// FIFO for XCLK to Wishbone
	reg [DW-1:0] fifo_xclk_data [0:(1<<LGFIFO)-1];
	reg fifo_xclk_err [0:(1<<LGFIFO)-1];
	reg fifo_xclk_ack [0:(1<<LGFIFO)-1];
	reg [LGFIFO:0] xclk_wr_ptr, xclk_rd_ptr;
	reg [LGFIFO:0] xclk_full, xclk_empty;

	// FIFO control logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_wr_ptr <= 0;
			wb_rd_ptr <= 0;
			wb_full <= 0;
			wb_empty <= 1;
		end else begin
			if (i_wb_stb && !wb_full) begin
				fifo_addr[wb_wr_ptr] <= i_wb_addr;
				fifo_data[wb_wr_ptr] <= i_wb_data;
				fifo_sel[wb_wr_ptr] <= i_wb_sel;
				fifo_we[wb_wr_ptr] <= i_wb_we;
				fifo_stb[wb_wr_ptr] <= i_wb_stb;
				fifo_cyc[wb_wr_ptr] <= i_wb_cyc;
				wb_wr_ptr <= wb_wr_ptr + 1;
				wb_empty <= 0;
				if (wb_wr_ptr == wb_rd_ptr - 1)
					wb_full <= 1;
			end
			if (i_xclk_ack && !wb_empty) begin
				wb_rd_ptr <= wb_rd_ptr + 1;
				wb_full <= 0;
				if (wb_wr_ptr == wb_rd_ptr)
					wb_empty <= 1;
			end
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_wr_ptr <= 0;
			xclk_rd_ptr <= 0;
			xclk_full <= 0;
			xclk_empty <= 1;
		end else begin
			if (i_xclk_ack && !xclk_full) begin
				fifo_xclk_data[xclk_wr_ptr] <= i_xclk_data;
				fifo_xclk_err[xclk_wr_ptr] <= i_xclk_err;
				fifo_xclk_ack[xclk_wr_ptr] <= i_xclk_ack;
				xclk_wr_ptr <= xclk_wr_ptr + 1;
				xclk_empty <= 0;
				if (xclk_wr_ptr == xclk_rd_ptr - 1)
					xclk_full <= 1;
			end
			if (o_wb_stb && !xclk_empty) begin
				xclk_rd_ptr <= xclk_rd_ptr + 1;
				xclk_full <= 0;
				if (xclk_wr_ptr == xclk_rd_ptr)
					xclk_empty <= 1;
			end
		end
	end

	// Output assignments
	assign o_wb_stall = wb_full;
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else begin
			if (!xclk_empty) begin
				o_wb_ack <= fifo_xclk_ack[xclk_rd_ptr];
				o_wb_data <= fifo_xclk_data[xclk_rd_ptr];
				o_wb_err <= fifo_xclk_err[xclk_rd_ptr];
			end else begin
				o_wb_ack <= 0;
				o_wb_data <= 0;
				o_wb_err <= 0;
			end
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (!wb_empty && !i_xclk_stall) begin
				o_xclk_cyc <= fifo_cyc[wb_rd_ptr];
				o_xclk_stb <= fifo_stb[wb_rd_ptr];
				o_xclk_we <= fifo_we[wb_rd_ptr];
				o_xclk_addr <= fifo_addr[wb_rd_ptr];
				o_xclk_data <= fifo_data[wb_rd_ptr];
				o_xclk_sel <= fifo_sel[wb_rd_ptr];
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

endmodule
