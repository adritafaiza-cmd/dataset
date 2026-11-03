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

reg fifo_wren;
reg fifo_rden;
reg fifo_empty_addr;
reg fifo_empty_data;
reg fifo_empty_ctrl;
reg fifo_ctrl_in;
reg fifo_ctrl_out;

fifo_async #(.AW(AW), .DW(DW), .LGFIFO(LGFIFO)) fifo_addr (
		.i_wb_clk(i_wb_clk),
		.i_reset(i_reset),
		.din(i_wb_addr),
		.wren(fifo_wren),
		.rdclk(i_xclk_clk),
		.rden(fifo_rden),
		.dout(o_xclk_addr),
		.empty(fifo_empty_addr)
	);

fifo_async #(.AW(AW), .DW(DW), .LGFIFO(LGFIFO)) fifo_data (
		.i_wb_clk(i_wb_clk),
		.i_reset(i_reset),
		.din(i_wb_data),
		.wren(fifo_wren),
		.rdclk(i_xclk_clk),
		.rden(fifo_rden),
		.dout(o_xclk_data),
		.empty(fifo_empty_data)
	);

fifo_async #(.AW(AW), .DW(1), .LGFIFO(LGFIFO)) fifo_ctrl (
		.i_wb_clk(i_wb_clk),
		.i_reset(i_reset),
		.din(fifo_ctrl_in),
		.wren(fifo_wren),
		.rdclk(i_xclk_clk),
		.rden(fifo_rden),
		.dout(fifo_ctrl_out),
		.empty(fifo_empty_ctrl)
	);

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset) begin
		o_wb_ack <= 0;
		o_wb_data <= 0;
		o_wb_err <= 0;
		fifo_wren <= 0;
		fifo_ctrl_in <= 0;
	end else begin
		fifo_wren <= i_wb_stb;
		fifo_ctrl_in <= i_wb_we;
		o_wb_ack <= i_xclk_ack;
		o_wb_data <= i_xclk_data;
		o_wb_err <= i_xclk_err;
	end
end

always @(posedge i_xclk_clk or posedge i_reset) begin
	if (i_reset) begin
		o_xclk_cyc <= 0;
		o_xclk_stb <= 0;
		o_xclk_we <= 0;
		o_xclk_sel <= 0;
		fifo_rden <= 0;
	end else begin
		o_xclk_cyc <= i_wb_cyc;
		o_xclk_stb <= ~fifo_empty_addr;
		o_xclk_we <= fifo_ctrl_out;
		o_xclk_sel <= i_wb_sel;
		fifo_rden <= i_xclk_ack;
	end
end

assign o_wb_stall = fifo_empty_addr;

endmodule

module fifo_async #(
		parameter	AW=32,
				DW=32,
				LGFIFO = 5
	) (
		input	wire			i_wb_clk,
		input	wire			i_reset,
		input	wire	[(DW-1):0]	din,
		input	wire			wren,
		input	wire			rdclk,
		input	wire			rden,
		output	reg	[(DW-1):0]	dout,
		output	reg			empty
	);

reg [(DW-1):0] mem [0:(1<<LGFIFO)-1];
reg [(LGFIFO-1):0] wptr, rptr;
reg [(LGFIFO-1):0] wptr_gray, rptr_gray, rptr_gray_sync;

always @(posedge i_wb_clk or posedge i_reset) begin
	if (i_reset) begin
		wptr <= 0;
		wptr_gray <= 0;
	end else if (wren) begin
		mem[wptr] <= din;
		wptr <= wptr + 1;
		wptr_gray <= wptr ^ (wptr >> 1);
	end
end

always @(posedge rdclk or posedge i_reset) begin
	if (i_reset) begin
		rptr <= 0;
		rptr_gray <= 0;
		rptr_gray_sync <= 0;
		empty <= 1;
	end else begin
		rptr_gray_sync <= rptr_gray;
		if (rden && ~empty) begin
			rptr <= rptr + 1;
			rptr_gray <= rptr ^ (rptr >> 1);
		end
		empty <= (wptr_gray_sync == rptr_gray);
	end
end

always @(posedge rdclk or posedge i_reset) begin
	if (i_reset)
		dout <= 0;
	else if (rden && ~empty)
		dout <= mem[rptr];
end

endmodule
