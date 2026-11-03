module	wbxclk #(
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

	reg	[AW+DW+(DW/8)+2:0]	fifo_wb2xclk [2**LGFIFO-1:0];
	reg	[LGFIFO-1:0]		wb2xclk_rptr, wb2xclk_wptr;
	wire				wb2xclk_full, wb2xclk_empty;
	wire				wb2xclk_almost_full;

	reg	[DW+1:0]		fifo_xclk2wb [2**LGFIFO-1:0];
	reg	[LGFIFO-1:0]		xclk2wb_rptr, xclk2wb_wptr;
	wire				xclk2wb_full, xclk2wb_empty;
	wire				xclk2wb_almost_full;

	assign wb2xclk_full = (wb2xclk_wptr == {wb2xclk_rptr, 1'b1});
	assign wb2xclk_empty = (wb2xclk_wptr == wb2xclk_rptr);
	assign wb2xclk_almost_full = (wb2xclk_wptr == {wb2xclk_rptr, 1'b0});

	assign xclk2wb_full = (xclk2wb_wptr == {xclk2wb_rptr, 1'b1});
	assign xclk2wb_empty = (xclk2wb_wptr == xclk2wb_rptr);
	assign xclk2wb_almost_full = (xclk2wb_wptr == {xclk2wb_rptr, 1'b0});

	assign o_wb_stall = wb2xclk_almost_full;

	wire wb2xclk_write;
	wire wb2xclk_read;

	assign wb2xclk_write = i_wb_cyc && i_wb_stb && !wb2xclk_full;
	assign wb2xclk_read = !wb2xclk_empty && !i_xclk_stall;

	wire xclk2wb_write;
	wire xclk2wb_read;

	assign xclk2wb_write = i_xclk_ack && !xclk2wb_full;
	assign xclk2wb_read = !xclk2wb_empty && i_wb_cyc;

	always @(posedge i_wb_clk or posedge i_reset)
	begin
		if (i_reset)
		begin
			wb2xclk_wptr <= 0;
			wb2xclk_rptr <= 0;
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end
		else
		begin
			if (wb2xclk_write)
			begin
				fifo_wb2xclk[wb2xclk_wptr] <= {i_wb_addr, i_wb_data, i_wb_sel, i_wb_we, i_wb_cyc};
				if (wb2xclk_wptr == (2**LGFIFO-2))
					wb2xclk_wptr <= 0;
				else
					wb2xclk_wptr <= wb2xclk_wptr + 1;
			end

			if (xclk2wb_read)
			begin
				o_wb_ack <= 1;
				o_wb_data <= fifo_xclk2wb[xclk2wb_rptr][DW+1:2];
				o_wb_err <= fifo_xclk2wb[xclk2wb_rptr][1:0] == 2'b10;
				if (xclk2wb_rptr == (2**LGFIFO-2))
					xclk2wb_rptr <= 0;
				else
					xclk2wb_rptr <= xclk2wb_rptr + 1;
			end
			else
			begin
				o_wb_ack <= 0;
			end
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset)
	begin
		if (i_reset)
		begin
			xclk2wb_wptr <= 0;
			xclk2wb_rptr <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end
		else
		begin
			if (wb2xclk_read)
			begin
				o_xclk_cyc <= 1;
				o_xclk_stb <= 1;
				o_xclk_we <= fifo_wb2xclk[wb2xclk_rptr][1];
				o_xclk_addr <= fifo_wb2xclk[wb2xclk_rptr][AW+1:2];
				o_xclk_data <= fifo_wb2xclk[wb2xclk_rptr][AW+DW/8+1:AW+2];
				o_xclk_sel <= fifo_wb2xclk[wb2xclk_rptr][AW+DW/8-1:AW];
				if (wb2xclk_rptr == (2**LGFIFO-2))
					wb2xclk_rptr <= 0;
				else
					wb2xclk_rptr <= wb2xclk_rptr + 1;
			end
			else
			begin
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
			end

			if (xclk2wb_write)
			begin
				fifo_xclk2wb[xclk2wb_wptr] <= {i_xclk_data, {i_xclk_err, 1'b0}};
				if (xclk2wb_wptr == (2**LGFIFO-2))
					xclk2wb_wptr <= 0;
				else
					xclk2wb_wptr <= xclk2wb_wptr + 1;
			end
		end
	end
endmodule
