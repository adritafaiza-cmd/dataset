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

	// FIFO for Wishbone to XCLK domain
	reg [(AW-1):0]	fifo_addr [0:(1<<LGFIFO)-1];
	reg [(DW-1):0]	fifo_data [0:(1<<LGFIFO)-1];
	reg [(DW/8-1):0]	fifo_sel [0:(1<<LGFIFO)-1];
	reg			fifo_we [0:(1<<LGFIFO)-1];
	reg [(LGFIFO-1):0]	fifo_wr_ptr, fifo_rd_ptr;
	reg [(LGFIFO):0]	fifo_count;

	// FIFO control signals
	wire fifo_full, fifo_empty, fifo_almost_full;

	assign fifo_full = (fifo_count == (1<<LGFIFO));
	assign fifo_empty = (fifo_count == 0);
	assign fifo_almost_full = (fifo_count >= (1<<LGFIFO) - 2);

	// FIFO write logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_wr_ptr <= 0;
			fifo_count <= 0;
		end else if (i_wb_cyc && i_wb_stb && !fifo_full) begin
			fifo_addr[fifo_wr_ptr] <= i_wb_addr;
			fifo_data[fifo_wr_ptr] <= i_wb_data;
			fifo_sel[fifo_wr_ptr] <= i_wb_sel;
			fifo_we[fifo_wr_ptr] <= i_wb_we;
			fifo_wr_ptr <= fifo_wr_ptr + 1;
			fifo_count <= fifo_count + 1;
		end
	end

	// FIFO read logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_rd_ptr <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else if (i_xclk_ack && !fifo_empty) begin
			fifo_rd_ptr <= fifo_rd_ptr + 1;
			fifo_count <= fifo_count - 1;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
		end else if (!fifo_empty && !i_xclk_stall) begin
			o_xclk_cyc <= 1;
			o_xclk_stb <= 1;
			o_xclk_we <= fifo_we[fifo_rd_ptr];
			o_xclk_addr <= fifo_addr[fifo_rd_ptr];
			o_xclk_data <= fifo_data[fifo_rd_ptr];
			o_xclk_sel <= fifo_sel[fifo_rd_ptr];
		end
	end

	// Backpressure signal
	assign o_wb_stall = fifo_almost_full;

	// Response handling
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_err <= 0;
			o_wb_data <= 0;
		end else if (i_xclk_ack) begin
			o_wb_ack <= 1;
			o_wb_err <= i_xclk_err;
			o_wb_data <= i_xclk_data;
		end else begin
			o_wb_ack <= 0;
			o_wb_err <= 0;
		end
	end

endmodule
