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

	// FIFOs
	reg	[AW+DW+DW/8+2:0]	fifo_in	[2**LGFIFO-1:0];
	reg	[DW+1:0]		fifo_out	[2**LGFIFO-1:0];
	reg	[(LGFIFO-1):0]	fifo_in_ptr, fifo_in_ptr_next, fifo_in_ptr_gray, fifo_in_ptr_gray_next;
	reg	[(LGFIFO-1):0]	fifo_out_ptr, fifo_out_ptr_next, fifo_out_ptr_gray, fifo_out_ptr_gray_next;
	wire				fifo_in_empty, fifo_in_full, fifo_out_empty, fifo_out_full;
	wire				fifo_in_almost_empty, fifo_in_almost_full, fifo_out_almost_empty, fifo_out_almost_full;

	// FIFO in
	always @(posedge i_wb_clk or posedge i_reset)
	begin
		if (i_reset) begin
			fifo_in_ptr	<= 0;
			fifo_in_ptr_gray	<= 0;
		end else begin
			fifo_in_ptr	<= fifo_in_ptr_next;
			fifo_in_ptr_gray	<= fifo_in_ptr_gray_next;
		end
	end

	always @(*)
	begin
		fifo_in_ptr_next	= fifo_in_ptr;
		fifo_in_ptr_gray_next	= fifo_in_ptr_gray;

		if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
			fifo_in_ptr_next	= fifo_in_ptr + 1;
			fifo_in_ptr_gray_next	= (fifo_in_ptr_gray + 1) % (2**LGFIFO);
		end
	end

	always @(posedge i_wb_clk or posedge i_reset)
	begin
		if (i_reset) begin
			fifo_in	<= '{default:0};
		end else if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
			fifo_in[fifo_in_ptr]	<= {i_wb_addr, i_wb_data, i_wb_sel, i_wb_we};
		end
	end

	assign fifo_in_empty	= (fifo_in_ptr == fifo_out_ptr);
	assign fifo_in_full	= (fifo_in_ptr_gray == (fifo_out_ptr_gray + (2**LGFIFO-1)) % (2**LGFIFO));
	assign fifo_in_almost_empty	= (fifo_in_ptr == (fifo_out_ptr + 2) % (2**LGFIFO));
	assign fifo_in_almost_full	= (fifo_in_ptr_gray == (fifo_out_ptr_gray + (2**LGFIFO-2)) % (2**LGFIFO));

	// FIFO out
	always @(posedge i_xclk_clk or posedge i_reset)
	begin
		if (i_reset) begin
			fifo_out_ptr	<= 0;
			fifo_out_ptr_gray	<= 0;
		end else begin
			fifo_out_ptr	<= fifo_out_ptr_next;
			fifo_out_ptr_gray	<= fifo_out_ptr_gray_next;
		end
	end

	always @(*)
	begin
		fifo_out_ptr_next	= fifo_out_ptr;
		fifo_out_ptr_gray_next	= fifo_out_ptr_gray;

		if (i_xclk_ack && !fifo_out_empty) begin
			fifo_out_ptr_next	= fifo_out_ptr + 1;
			fifo_out_ptr_gray_next	= (fifo_out_ptr_gray + 1) % (2**LGFIFO);
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset)
	begin
		if (i_reset) begin
			fifo_out	<= '{default:0};
		end else if (!fifo_in_empty && !i_xclk_stall) begin
			fifo_out[fifo_out_ptr]	<= {i_xclk_data, i_xclk_err};
		end
	end

	assign fifo_out_empty	= (fifo_out_ptr == fifo_in_ptr);
	assign fifo_out_full	= (fifo_out_ptr_gray == (fifo_in_ptr_gray + (2**LGFIFO-1)) % (2**LGFIFO));
	assign fifo_out_almost_empty	= (fifo_out_ptr == (fifo_in_ptr + 2) % (2**LGFIFO));
	assign fifo_out_almost_full	= (fifo_out_ptr_gray == (fifo_in_ptr_gray + (2**LGFIFO-2)) % (2**LGFIFO));

	// Wishbone in
	always @(posedge i_wb_clk or posedge i_reset)
	begin
		if (i_reset) begin
			o_wb_ack	<= 0;
			o_wb_data	<= 0;
			o_wb_err	<= 0;
		end else begin
			if (!fifo_out_empty) begin
				o_wb_ack	<= 1;
				o_wb_data	<= fifo_out[fifo_out_ptr][DW-1:0];
				o_wb_err	<= fifo_out[fifo_out_ptr][DW];
			end else begin
				o_wb_ack	<= 0;
				o_wb_data	<= 0;
				o_wb_err	<= 0;
			end
		end
	end

	assign o_wb_stall	= fifo_in_full;

	// Wishbone out
	always @(posedge i_xclk_clk or posedge i_reset)
	begin
		if (i_reset) begin
			o_xclk_cyc	<= 0;
			o_xclk_stb	<= 0;
			o_xclk_we	<= 0;
			o_xclk_addr	<= 0;
			o_xclk_data	<= 0;
			o_xclk_sel	<= 0;
		end else begin
			if (!fifo_in_empty && !i_xclk_stall) begin
				o_xclk_cyc	<= 1;
				o_xclk_stb	<= 1;
				o_xclk_we	<= fifo_in[fifo_in_ptr][AW+DW+DW/8+1];
				o_xclk_addr	<= fifo_in[fifo_in_ptr][AW+DW+DW/8:DW+DW/8];
				o_xclk_data	<= fifo_in[fifo_in_ptr][DW+DW/8-1:DW/8];
				o_xclk_sel	<= fifo_in[fifo_in_ptr][DW/8-1:0];
			end else begin
				o_xclk_cyc	<= 0;
				o_xclk_stb	<= 0;
				o_xclk_we	<= 0;
				o_xclk_addr	<= 0;
				o_xclk_data	<= 0;
				o_xclk_sel	<= 0;
			end
		end
	end

endmodule
