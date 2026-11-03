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

	wire	[AW-1:0]	fifo_addr;
	wire	[(DW-1):0]	fifo_data;
	wire	[(DW/8-1):0]	fifo_sel;
	wire			fifo_we;
	wire			fifo_empty;
	wire			fifo_full;
	wire			fifo_almost_full;

	wire	[AW-1:0]	fifo_out_addr;
	wire	[(DW-1):0]	fifo_out_data;
	wire	[(DW/8-1):0]	fifo_out_sel;
	wire			fifo_out_valid;
	wire			fifo_out_empty;

	wire			wb_stall;
	wire			wb_ack;
	wire			wb_err;

	wire			xclk_cyc;
	wire			xclk_stb;
	wire			xclk_we;
	wire	[AW-1:0]	xclk_addr;
	wire	[(DW-1):0]	xclk_data;
	wire	[(DW/8-1):0]	xclk_sel;

	wire			xclk_ack_sync;
	wire			xclk_err_sync;
	wire	[(DW-1):0]	xclk_data_sync;

	reg	[1:0]		wb_state;
	reg	[1:0]		xclk_state;

	always @(posedge i_wb_clk or posedge i_reset)
	begin
		if (i_reset)
		begin
			wb_state <= 0;
			o_wb_ack <= 0;
			o_wb_err <= 0;
			o_wb_data <= 0;
		end
		else
		begin
			case (wb_state)
				0:
				begin
					if (i_wb_cyc && i_wb_stb && !wb_stall)
					begin
						wb_state <= 1;
						o_wb_ack <= 0;
						o_wb_err <= 0;
						o_wb_data <= 0;
					end
				end
				1:
				begin
					if (wb_ack)
					begin
						wb_state <= 0;
						o_wb_ack <= 1;
						o_wb_err <= wb_err;
						o_wb_data <= fifo_out_data;
					end
				end
			endcase
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset)
	begin
		if (i_reset)
		begin
			xclk_state <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end
		else
		begin
			case (xclk_state)
				0:
				begin
					if (fifo_out_valid && !i_xclk_stall)
					begin
						xclk_state <= 1;
						o_xclk_cyc <= 1;
						o_xclk_stb <= 1;
						o_xclk_we <= fifo_out_we;
						o_xclk_addr <= fifo_out_addr;
						o_xclk_data <= fifo_out_data;
						o_xclk_sel <= fifo_out_sel;
					end
				end
				1:
				begin
					if (i_xclk_ack)
					begin
						xclk_state <= 0;
						o_xclk_cyc <= 0;
						o_xclk_stb <= 0;
						o_xclk_we <= 0;
						o_xclk_addr <= 0;
						o_xclk_data <= 0;
						o_xclk_sel <= 0;
					end
				end
			endcase
		end
	end

	assign wb_stall = fifo_almost_full;
	assign wb_ack = fifo_out_valid && !fifo_out_empty;
	assign wb_err = xclk_err_sync;

	assign xclk_cyc = o_xclk_cyc;
	assign xclk_stb = o_xclk_stb;
	assign xclk_we = o_xclk_we;
	assign xclk_addr = o_xclk_addr;
	assign xclk_data = o_xclk_data;
	assign xclk_sel = o_xclk_sel;

	assign fifo_addr = i_wb_addr;
	assign fifo_data = i_wb_data;
	assign fifo_sel = i_wb_sel;
	assign fifo_we = i_wb_we;

	assign fifo_out_addr = fifo_out_addr;
	assign fifo_out_data = fifo_out_data;
	assign fifo_out_sel = fifo_out_sel;
	assign fifo_out_valid = fifo_out_valid;
	assign fifo_out_empty = fifo_out_empty;

	assign xclk_ack_sync = i_xclk_ack;
	assign xclk_err_sync = i_xclk_err;
	assign xclk_data_sync = i_xclk_data;

	wire	[AW-1:0]	fifo_in_addr;
	wire	[(DW-1):0]	fifo_in_data;
	wire	[(DW/8-1):0]	fifo_in_sel;
	wire			fifo_in_we;
	wire			fifo_in_valid;

	assign fifo_in_addr = fifo_addr;
	assign fifo_in_data = fifo_data;
	assign fifo_in_sel = fifo_sel;
	assign fifo_in_we = fifo_we;
	assign fifo_in_valid = i_wb_cyc && i_wb_stb && !wb_stall;

	wire	[AW-1:0]	fifo_out_addr_sync;
	wire	[(DW-1):0]	fifo_out_data_sync;
	wire	[(DW/8-1):0]	fifo_out_sel_sync;
	wire			fifo_out_valid_sync;
	wire			fifo_out_empty_sync;

	assign fifo_out_addr_sync = fifo_out_addr;
	assign fifo_out_data_sync = fifo_out_data;
	assign fifo_out_sel_sync = fifo_out_sel;
	assign fifo_out_valid_sync = fifo_out_valid;
	assign fifo_out_empty_sync = fifo_out_empty;

	fifo #(
		.AW(AW),
		.DW(DW),
		.LGFIFO(LGFIFO)
	) u_fifo (
		.i_clk(i_wb_clk),
		.i_rst(i_reset),
		.i_data(fifo_in_data),
		.i_addr(fifo_in_addr),
		.i_sel(fifo_in_sel),
		.i_we(fifo_in_we),
		.i_valid(fifo_in_valid),
		.o_data(fifo_out_data),
		.o_addr(fifo_out_addr),
		.o_sel(fifo_out_sel),
		.o_valid(fifo_out_valid),
		.o_empty(fifo_out_empty),
		.o_almost_full(fifo_almost_full),
		.o_full(fifo_full)
	);

	assign o_wb_stall = fifo_almost_full;

endmodule

module fifo #(
		parameter	AW=32,
				DW=32,
				LGFIFO = 5
	) (
		input	wire			i_clk,
		input	wire			i_rst,
		input	wire	[(DW-1):0]	i_data,
		input	wire	[(AW-1):0]	i_addr,
		input	wire	[(DW/8-1):0]	i_sel,
		input	wire			i_we,
		input	wire			i_valid,
		output	wire	[(DW-1):0]	o_data,
		output	wire	[(AW-1):0]	o_addr,
		output	wire	[(DW/8-1):0]	o_sel,
		output	wire			o_valid,
		output	wire			o_empty,
		output	wire			o_almost_full,
		output	wire			o_full
	);

	reg	[(DW-1):0]	ram[2**LGFIFO-1:0];
	reg	[AW-1:0]	ram_addr[2**LGFIFO-1:0];
	reg	[(DW/8-1):0]	ram_sel[2**LGFIFO-1:0];
	reg	[LGFIFO-1:0]	wr_ptr;
	reg	[LGFIFO-1:0]	rd_ptr;
	reg	[LGFIFO:0]	depth;

	always @(posedge i_clk or posedge i_rst)
	begin
		if (i_rst)
		begin
			wr_ptr <= 0;
			rd_ptr <= 0;
			depth <= 0;
		end
		else
		begin
			if (i_valid && !o_full)
			begin
				ram[wr_ptr] <= i_data;
				ram_addr[wr_ptr] <= i_addr;
				ram_sel[wr_ptr] <= i_sel;
				wr_ptr <= wr_ptr + 1;
				depth <= depth + 1;
			end
			if (o_valid && !o_empty)
			begin
				rd_ptr <= rd_ptr + 1;
				depth <= depth - 1;
			end
		end
	end

	assign o_data = ram[rd_ptr];
	assign o_addr = ram_addr[rd_ptr];
	assign o_sel = ram_sel[rd_ptr];
	assign o_valid = (depth > 0);
	assign o_empty = (depth == 0);
	assign o_almost_full = (depth >= 2**LGFIFO - 2);
	assign o_full = (depth == 2**LGFIFO);

endmodule
