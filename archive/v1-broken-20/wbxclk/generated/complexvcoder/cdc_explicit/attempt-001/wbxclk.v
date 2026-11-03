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

	// Internal signals
	wire wb_to_xclk_valid;
	wire wb_to_xclk_ready;
	wire wb_to_xclk_cyc;
	wire wb_to_xclk_stb;
	wire wb_to_xclk_we;
	wire [(AW-1):0] wb_to_xclk_addr;
	wire [(DW-1):0] wb_to_xclk_data;
	wire [(DW/8-1):0] wb_to_xclk_sel;
	wire wb_to_xclk_err;

	wire xclk_to_wb_valid;
	wire xclk_to_wb_ready;
	wire xclk_to_wb_cyc;
	wire xclk_to_wb_stb;
	wire xclk_to_wb_we;
	wire [(AW-1):0] xclk_to_wb_addr;
	wire [(DW-1):0] xclk_to_wb_data;
	wire xclk_to_wb_err;

	// FIFOs for data transfer
	fifo #(.WIDTH(DW), .DEPTH(1<<LGFIFO)) wb_to_xclk_fifo (
		.clk(i_wb_clk),
		.reset(i_reset),
		.wdata(i_wb_data),
		.wen(wb_to_xclk_valid),
		.wfull(o_wb_stall),
		.rrdy(wb_to_xclk_ready),
		.rdata(wb_to_xclk_data),
		.ren(xclk_to_wb_valid),
		.rempty(xclk_to_wb_ready)
	);

	fifo #(.WIDTH(AW), .DEPTH(1<<LGFIFO)) wb_to_xclk_addr_fifo (
		.clk(i_wb_clk),
		.reset(i_reset),
		.wdata(i_wb_addr),
		.wen(wb_to_xclk_valid),
		.wfull(o_wb_stall),
		.rrdy(wb_to_xclk_ready),
		.rdata(wb_to_xclk_addr),
		.ren(xclk_to_wb_valid),
		.rempty(xclk_to_wb_ready)
	);

	fifo #(.WIDTH(DW/8), .DEPTH(1<<LGFIFO)) wb_to_xclk_sel_fifo (
		.clk(i_wb_clk),
		.reset(i_reset),
		.wdata(i_wb_sel),
		.wen(wb_to_xclk_valid),
		.wfull(o_wb_stall),
		.rrdy(wb_to_xclk_ready),
		.rdata(wb_to_xclk_sel),
		.ren(xclk_to_wb_valid),
		.rempty(xclk_to_wb_ready)
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) wb_to_xclk_cyc_fifo (
		.clk(i_wb_clk),
		.reset(i_reset),
		.wdata(i_wb_cyc),
		.wen(wb_to_xclk_valid),
		.wfull(o_wb_stall),
		.rrdy(wb_to_xclk_ready),
		.rdata(wb_to_xclk_cyc),
		.ren(xclk_to_wb_valid),
		.rempty(xclk_to_wb_ready)
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) wb_to_xclk_stb_fifo (
		.clk(i_wb_clk),
		.reset(i_reset),
		.wdata(i_wb_stb),
		.wen(wb_to_xclk_valid),
		.wfull(o_wb_stall),
		.rrdy(wb_to_xclk_ready),
		.rdata(wb_to_xclk_stb),
		.ren(xclk_to_wb_valid),
		.rempty(xclk_to_wb_ready)
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) wb_to_xclk_we_fifo (
		.clk(i_wb_clk),
		.reset(i_reset),
		.wdata(i_wb_we),
		.wen(wb_to_xclk_valid),
		.wfull(o_wb_stall),
		.rrdy(wb_to_xclk_ready),
		.rdata(wb_to_xclk_we),
		.ren(xclk_to_wb_valid),
		.rempty(xclk_to_wb_ready)
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) xclk_to_wb_valid_fifo (
		.clk(i_xclk_clk),
		.reset(i_reset),
		.wdata(xclk_to_wb_valid),
		.wen(i_xclk_ack),
		.wfull(),
		.rrdy(xclk_to_wb_ready),
		.rdata(wb_to_xclk_ready),
		.ren(),
		.rempty()
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) xclk_to_wb_cyc_fifo (
		.clk(i_xclk_clk),
		.reset(i_reset),
		.wdata(xclk_to_wb_cyc),
		.wen(i_xclk_ack),
		.wfull(),
		.rrdy(xclk_to_wb_ready),
		.rdata(wb_to_xclk_cyc),
		.ren(),
		.rempty()
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) xclk_to_wb_stb_fifo (
		.clk(i_xclk_clk),
		.reset(i_reset),
		.wdata(xclk_to_wb_stb),
		.wen(i_xclk_ack),
		.wfull(),
		.rrdy(xclk_to_wb_ready),
		.rdata(wb_to_xclk_stb),
		.ren(),
		.rempty()
	);

	fifo #(.WIDTH(1), .DEPTH(1<<LGFIFO)) xclk_to_wb_we_fifo (
		.clk(i_xclk_clk),
		.reset(i_reset),
		.wdata(xclk_to_wb_we),
		.wen(i_xclk_ack),
		.wfull(),
		.rrdy(xclk_to_wb_ready),
		.rdata(wb_to_xclk_we),
		.ren(),
		.rempty()
	);

	fifo #(.WIDTH(DW), .DEPTH(1<<LGFIFO)) xclk_to_wb_data_fifo (
		.clk(i_xclk_clk),
		.reset(i_reset),
		.wdata(i_xclk_data),
		.wen(i_xclk_ack),
		.wfull(),
		.rrdy(xclk_to_wb_ready),
		.rdata(wb_to_xclk_data),
		.ren(),
		.rempty()
	);

	fifo #(.WIDTH(AW), .DEPTH(1<<LGFIFO)) xclk_to_wb_addr_fifo (
		.clk(i_xclk_clk),
		.reset(i_reset),
		.wdata(i_xclk_addr),
		.wen(i_xclk_ack),
		.wfull(),
		.rrdy(xclk_to_wb_ready),
		.rdata(wb_to_xclk_addr),
		.ren(),
		.rempty()
	);

	fifo #(.WIDTH(DW/8), .DEPTH(1<<LGFIFO)) xclk_to_wb_sel_fifo (
		.clk(i_xclk_clk),
		.reset(i_reset),
		.wdata(i_xclk_sel),
		.wen(i_xclk_ack),
		.wfull(),
		.rrdy(xclk_to_wb_ready),
		.rdata(wb_to_xclk_sel),
		.ren(),
		.rempty()
	);

	// Control logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_err <= 0;
		end else begin
			o_wb_ack <= xclk_to_wb_valid;
			o_wb_err <= i_xclk_err;
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
		end else begin
			o_xclk_cyc <= wb_to_xclk_cyc;
			o_xclk_stb <= wb_to_xclk_stb;
			o_xclk_we <= wb_to_xclk_we;
			o_xclk_addr <= wb_to_xclk_addr;
			o_xclk_data <= wb_to_xclk_data;
			o_xclk_sel <= wb_to_xclk_sel;
		end
	end

	// Staging logic
	always @(posedge i_wb_clk) begin
		if (wb_to_xclk_valid && wb_to_xclk_ready) begin
			wb_to_xclk_valid <= 0;
		end else if (i_wb_cyc && i_wb_stb) begin
			wb_to_xclk_valid <= 1;
		end

		if (xclk_to_wb_ready) begin
			wb_to_xclk_ready <= 0;
		end else if (i_xclk_ack) begin
			wb_to_xclk_ready <= 1;
		end
	end

	always @(posedge i_xclk_clk) begin
		if (xclk_to_wb_valid && xclk_to_wb_ready) begin
			xclk_to_wb_valid <= 0;
		end else if (i_wb_cyc && i_wb_stb) begin
			xclk_to_wb_valid <= 1;
		end

		if (wb_to_xclk_ready) begin
			xclk_to_wb_ready <= 0;
		end else if (i_wb_ack) begin
			xclk_to_wb_ready <= 1;
		end
	end

endmodule
