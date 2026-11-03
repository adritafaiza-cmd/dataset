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

	// FIFO for Wishbone to XCLK domain crossing
	reg [AW-1:0]	fifo_addr [0:(1<<LGFIFO)-1];
	reg [DW-1:0]	fifo_data [0:(1<<LGFIFO)-1];
	reg [(DW/8-1):0] fifo_sel [0:(1<<LGFIFO)-1];
	reg		fifo_we [0:(1<<LGFIFO)-1];
	reg [LGFIFO:0]	wr_ptr, rd_ptr;
	reg [LGFIFO:0]	fifo_count;

	// FIFO control signals
	wire		fifo_full, fifo_empty, fifo_almost_full;

	// FIFO full and empty flags
	assign fifo_full = (fifo_count == (1<<LGFIFO));
	assign fifo_empty = (fifo_count == 0);
	assign fifo_almost_full = (fifo_count >= (1<<LGFIFO) - 2);

	// FIFO write pointer
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wr_ptr <= 0;
		end else if (i_wb_cyc && i_wb_stb && !fifo_full) begin
			wr_ptr <= wr_ptr + 1;
		end
	end

	// FIFO read pointer
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rd_ptr <= 0;
		end else if (o_xclk_stb && !i_xclk_stall && !fifo_empty) begin
			rd_ptr <= rd_ptr + 1;
		end
	end

	// FIFO count
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_count <= 0;
		end else begin
			if (i_wb_cyc && i_wb_stb && !fifo_full) begin
				fifo_count <= fifo_count + 1;
			end
			if (o_xclk_stb && !i_xclk_stall && !fifo_empty) begin
				fifo_count <= fifo_count - 1;
			end
		end
	end

	// FIFO write
	always @(posedge i_wb_clk) begin
		if (i_wb_cyc && i_wb_stb && !fifo_full) begin
			fifo_addr[wr_ptr] <= i_wb_addr;
			fifo_data[wr_ptr] <= i_wb_data;
			fifo_sel[wr_ptr] <= i_wb_sel;
			fifo_we[wr_ptr] <= i_wb_we;
		end
	end

	// FIFO read
	always @(posedge i_xclk_clk) begin
		if (o_xclk_stb && !i_xclk_stall && !fifo_empty) begin
			o_xclk_addr <= fifo_addr[rd_ptr];
			o_xclk_data <= fifo_data[rd_ptr];
			o_xclk_sel <= fifo_sel[rd_ptr];
			o_xclk_we <= fifo_we[rd_ptr];
		end
	end

	// Output signals
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_stall <= 0;
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else begin
			o_wb_stall <= fifo_almost_full;
			if (i_xclk_ack) begin
				o_wb_ack <= 1;
				o_wb_data <= i_xclk_data;
				o_wb_err <= i_xclk_err;
			end else begin
				o_wb_ack <= 0;
				o_wb_data <= 0;
				o_wb_err <= 0;
			end
		end
	end

	// XCLK output signals
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
		end else begin
			o_xclk_cyc <= !fifo_empty;
			o_xclk_stb <= !fifo_empty && !i_xclk_stall;
		end
	end

endmodule
