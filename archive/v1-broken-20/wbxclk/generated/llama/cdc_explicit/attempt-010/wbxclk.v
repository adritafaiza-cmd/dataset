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

	reg	[AW-1:0]	fifo_addr[2**LGFIFO-1:0];
	reg	[(DW-1):0]	fifo_data[2**LGFIFO-1:0];
	reg	[(DW/8-1):0]	fifo_sel[2**LGFIFO-1:0];
	reg			fifo_we[2**LGFIFO-1:0];
	reg			fifo_cyc[2**LGFIFO-1:0];
	reg			fifo_stb[2**LGFIFO-1:0];
	reg			fifo_valid[2**LGFIFO-1:0];
	reg	[1:0]	fifo_rptr, fifo_wptr;
	wire			fifo_full, fifo_empty;

	assign	fifo_full = (fifo_wptr == (fifo_rptr + 1) % (2**LGFIFO));
	assign	fifo_empty = (fifo_wptr == fifo_rptr);
	assign	o_wb_stall = fifo_full;

	always @(posedge i_wb_clk or posedge i_reset)
	begin
		if (i_reset)
		begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			fifo_rptr <= 0;
			fifo_wptr <= 0;
			fifo_valid[0] <= 0;
		end
		else
		begin
			if (i_wb_cyc && i_wb_stb && !fifo_full)
			begin
				fifo_addr[fifo_wptr] <= i_wb_addr;
				fifo_data[fifo_wptr] <= i_wb_data;
				fifo_sel[fifo_wptr] <= i_wb_sel;
				fifo_we[fifo_wptr] <= i_wb_we;
				fifo_cyc[fifo_wptr] <= i_wb_cyc;
				fifo_stb[fifo_wptr] <= i_wb_stb;
				fifo_valid[fifo_wptr] <= 1;
				fifo_wptr <= (fifo_wptr + 1) % (2**LGFIFO);
			end

			if (i_xclk_ack && !fifo_empty)
			begin
				o_wb_ack <= 1;
				o_wb_data <= i_xclk_data;
				o_wb_err <= i_xclk_err;
				fifo_valid[fifo_rptr] <= 0;
				fifo_rptr <= (fifo_rptr + 1) % (2**LGFIFO);
			end
			else
			begin
				o_wb_ack <= 0;
			end

			if (!fifo_empty && !i_xclk_stall)
			begin
				o_xclk_cyc <= fifo_cyc[fifo_rptr];
				o_xclk_stb <= fifo_stb[fifo_rptr];
				o_xclk_we <= fifo_we[fifo_rptr];
				o_xclk_addr <= fifo_addr[fifo_rptr];
				o_xclk_data <= fifo_data[fifo_rptr];
				o_xclk_sel <= fifo_sel[fifo_rptr];
			end
			else
			begin
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
