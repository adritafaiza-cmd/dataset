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
	reg	[2**LGFIFO-1:0]	fifo_valid;
	reg	[2**LGFIFO-1:0]	fifo_empty;
	reg	[2**LGFIFO-1:0]	fifo_full;
	reg	[2**LGFIFO-1:0]	fifo_count;
	reg	[2**LGFIFO-1:0]	fifo_out;
	reg	[2**LGFIFO-1:0]	fifo_in;
	reg			fifo_push;
	reg			fifo_pop;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_data <= {DW{1'b0}};
			o_wb_err <= 1'b0;
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel <= {DW/8{1'b0}};
			fifo_valid <= {2**LGFIFO{1'b0}};
			fifo_empty <= {2**LGFIFO{1'b1}};
			fifo_full <= {2**LGFIFO{1'b0}};
			fifo_count <= {2**LGFIFO{1'b0}};
			fifo_out <= {2**LGFIFO{1'b0}};
			fifo_in <= {2**LGFIFO{1'b0}};
			fifo_push <= 1'b0;
			fifo_pop <= 1'b0;
		end else begin
			if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
				fifo_addr[fifo_in] <= i_wb_addr;
				fifo_data[fifo_in] <= i_wb_data;
				fifo_sel[fifo_in] <= i_wb_sel;
				fifo_we[fifo_in] <= i_wb_we;
				fifo_cyc[fifo_in] <= i_wb_cyc;
				fifo_stb[fifo_in] <= i_wb_stb;
				fifo_valid[fifo_in] <= 1'b1;
				fifo_empty[fifo_in] <= 1'b0;
				fifo_count[fifo_in] <= fifo_count[fifo_in] + 1'b1;
				fifo_in <= fifo_in + 1'b1;
				fifo_push <= 1'b1;
			end else begin
				fifo_push <= 1'b0;
			end

			if (i_xclk_ack && !fifo_empty[fifo_out]) begin
				o_wb_ack <= 1'b1;
				o_wb_data <= i_xclk_data;
				o_wb_err <= i_xclk_err;
				fifo_valid[fifo_out] <= 1'b0;
				fifo_empty[fifo_out] <= 1'b1;
				fifo_count[fifo_out] <= fifo_count[fifo_out] - 1'b1;
				fifo_out <= fifo_out + 1'b1;
				fifo_pop <= 1'b1;
			end else begin
				o_wb_ack <= 1'b0;
				fifo_pop <= 1'b0;
			end

			if (!i_xclk_stall && !fifo_empty[fifo_out]) begin
				o_xclk_cyc <= fifo_cyc[fifo_out];
				o_xclk_stb <= fifo_stb[fifo_out];
				o_xclk_we <= fifo_we[fifo_out];
				o_xclk_addr <= fifo_addr[fifo_out];
				o_xclk_data <= fifo_data[fifo_out];
				o_xclk_sel <= fifo_sel[fifo_out];
			end else begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= {AW{1'b0}};
				o_xclk_data <= {DW{1'b0}};
				o_xclk_sel <= {DW/8{1'b0}};
			end

			if (fifo_push && !fifo_full[fifo_in]) begin
				fifo_full[fifo_in] <= 1'b1;
			end else begin
				fifo_full[fifo_in] <= 1'b0;
			end

			if (fifo_pop && !fifo_empty[fifo_out]) begin
				fifo_empty[fifo_out] <= 1'b0;
			end else begin
				fifo_empty[fifo_out] <= 1'b1;
			end
		end
	end

	assign o_wb_stall = fifo_full[fifo_in];

endmodule
