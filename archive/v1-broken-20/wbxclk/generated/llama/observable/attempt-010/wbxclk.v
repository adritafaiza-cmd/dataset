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

	reg	[AW+DW+DW/8+2:0]	fifo_in;
	reg	[AW+DW+DW/8+2:0]	fifo_out;
	reg	[LGFIFO-1:0]	fifo_cnt;
	reg			fifo_empty;
	reg			fifo_full;

	wire			fifo_wr;
	wire			fifo_rd;

	always @(posedge i_wb_clk or posedge i_reset)
	begin
		if (i_reset)
		begin
			o_wb_ack <= 1'b0;
			o_wb_data <= {(DW){1'b0}};
			o_wb_err <= 1'b0;
		end
		else
		begin
			if (i_wb_cyc && i_wb_stb && !o_wb_stall)
			begin
				o_wb_ack <= 1'b1;
			end
			else
			begin
				o_wb_ack <= 1'b0;
			end

			if (i_xclk_ack)
			begin
				o_wb_data <= i_xclk_data;
				o_wb_err <= i_xclk_err;
			end
		end
	end

	always @(posedge i_wb_clk or posedge i_reset)
	begin
		if (i_reset)
		begin
			fifo_in <= {(AW+DW+DW/8+2){1'b0}};
			fifo_cnt <= {(LGFIFO){1'b0}};
			fifo_empty <= 1'b1;
			fifo_full <= 1'b0;
		end
		else
		begin
			if (fifo_wr && !fifo_full)
			begin
				fifo_in <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
				fifo_cnt <= fifo_cnt + 1'b1;
				fifo_empty <= 1'b0;
				if (fifo_cnt == (1 << LGFIFO) - 1)
				begin
					fifo_full <= 1'b1;
				end
			end

			if (fifo_rd && !fifo_empty)
			begin
				fifo_cnt <= fifo_cnt - 1'b1;
				fifo_full <= 1'b0;
				if (fifo_cnt == 0)
				begin
					fifo_empty <= 1'b1;
				end
			end
		end
	end

	assign fifo_wr = i_wb_cyc && i_wb_stb && !o_wb_stall;
	assign fifo_rd = !i_xclk_stall && o_xclk_cyc && o_xclk_stb;

	assign o_wb_stall = fifo_full;

	always @(posedge i_xclk_clk or posedge i_reset)
	begin
		if (i_reset)
		begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {(AW){1'b0}};
			o_xclk_data <= {(DW){1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
		end
		else
		begin
			if (!fifo_empty && !i_xclk_stall)
			begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= fifo_in[AW+DW+DW/8+1];
				o_xclk_addr <= fifo_in[AW+DW+DW/8:DW+DW/8];
				o_xclk_data <= fifo_in[DW+DW/8-1:DW/8];
				o_xclk_sel <= fifo_in[DW/8-1:0];
			end
			else
			begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= {(AW){1'b0}};
				o_xclk_data <= {(DW){1'b0}};
				o_xclk_sel <= {(DW/8){1'b0}};
			end
		end
	end

endmodule
