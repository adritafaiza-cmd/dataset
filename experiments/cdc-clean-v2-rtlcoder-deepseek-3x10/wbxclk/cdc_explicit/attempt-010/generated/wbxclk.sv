Sure, here is the complete Verilog code for the pipelined Wishbone clock-domain bridge:

```
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

	// FIFO parameters
	localparam FIFO_AW = AW + LGFIFO;
	localparam FIFO_DW = DW + LGFIFO;

	// FIFO signals
	reg [FIFO_AW-1:0] fifo_waddr;
	reg [FIFO_AW-1:0] fifo_raddr;
	reg [FIFO_DW-1:0] fifo_wdata;
	wire [FIFO_DW-1:0] fifo_rdata;
	reg fifo_wren;
	wire fifo_rden;
	wire fifo_empty;
	wire fifo_full;

	// FIFO instantiation
	wbxclk_fifo #(
		.AW(FIFO_AW),
		.DW(FIFO_DW)
	) fifo (
		.i_wb_clk(i_wb_clk),
		.i_reset(i_reset),
		.i_wb_cyc(i_wb_cyc),
		.i_wb_stb(i_wb_stb),
		.i_wb_we(i_wb_we),
		.i_wb_addr(i_wb_addr),
		.i_wb_data(i_wb_data),
		.i_wb_sel(i_wb_sel),
		.o_wb_stall(o_wb_stall),
		.o_wb_ack(o_wb_ack),
		.o_wb_data(o_wb_data),
		.o_wb_err(o_wb_err),
		.i_xclk_clk(i_xclk_clk),
		.o_xclk_cyc(o_xclk_cyc),
		.o_xclk_stb(o_xclk_stb),
		.o_xclk_we(o_xclk_we),
		.o_xclk_addr(o_xclk_addr),
		.o_xclk_data(o_xclk_data),
		.o_xclk_sel(o_xclk_sel),
		.i_xclk_stall(i_xclk_stall),
		.i_xclk_ack(i_xclk_ack),
		.i_xclk_data(i_xclk_data),
		.i_xclk_err(i_xclk_err),
		.fifo_waddr(fifo_waddr),
		.fifo_raddr(fifo_raddr),
		.fifo_wdata(fifo_wdata),
		.fifo_rdata(fifo_rdata),
		.fifo_wren(fifo_wren),
		.fifo_rden(fifo_rden),
		.fifo_empty(fifo_empty),
		.fifo_full(fifo_full)
	);

	// FIFO write address logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_waddr <= 0;
		end else if (i_wb_cyc && i_wb_stb && !fifo_full) begin
			fifo_waddr <= fifo_waddr + 1;
		end
	end

	// FIFO read address logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_raddr <= 0;
		end else if (i_xclk_ack && !fifo_empty) begin
			fifo_raddr <= fifo_raddr + 1;
		end
	end

	// FIFO write data logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_wdata <= 0;
		end else if (i_wb_cyc && i_wb_stb && !fifo_full) begin
			fifo_wdata <= {i_wb_data, i_wb_sel};
		end
	end

	// FIFO write enable logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_wren <= 0;
		end else if (i_wb_cyc && i_wb_stb && !fifo_full) begin
			fifo_wren <= 1;
		end else begin
			fifo_wren <= 0;
		end
	end

	// FIFO read enable logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_rden <= 0;
		end else if (i_xclk_ack && !fifo_empty) begin
			fifo_rden <= 1;
		end else begin
			fifo_rden <= 0;
		end
	end

	// FIFO output logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			o_xclk_err <= 0;
		end else if (i_xclk_ack && !fifo_empty) begin
			o_xclk_cyc <= 1;
			o_xclk_stb <= 1;
			o_xclk_we <= fifo_rdata[DW+LGFIFO-1];
			o_xclk_addr <= fifo_rdata[AW+LGFIFO-1:LGFIFO];
			o_xclk_data <= fifo_rdata[DW-1:0];
			o_xclk_sel <= fifo_rdata[DW+LGFIFO-1:DW];
			o_xclk_err <= i_xclk_err;
		end else begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			o_xclk_err <= 0;
		end
	end

endmodule

module wbxclk_fifo #(
		parameter	AW=32,
				DW=32
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
		input	wire			i_xclk_err,
		input	wire	[(AW-1):0]	fifo_waddr,
		input	wire	[(AW-1):0]	fifo_raddr,
		input	wire	[(DW+LGFIFO-1):0]	fifo_wdata,
		output	wire	[(DW+LGFIFO-1):0]	fifo_rdata,
		input	wire			fifo_wren,
		input	wire			fifo_rden,
		output	wire			fifo_empty,
		output	wire			fifo_full
	);

	// FIFO parameters
	localparam FIFO_AW = AW + LGFIFO;
	localparam FIFO_DW = DW + LGFIFO;

	// FIFO signals
	reg [FIFO_AW-1:0] fifo_waddr;
	reg [FIFO_AW-1:0] fifo_raddr;
	reg [FIFO_DW-1:0] fifo_wdata;
	wire [FIFO_DW-1:0] fifo_rdata;
	reg fifo_wren;
	wire fifo_rden;
	wire fifo_empty;
	wire fifo_full;

	// FIFO instantiation
	wbxclk_fifo_core #(
		.AW(FIFO_AW),
		.DW(FIFO_DW)
	) fifo_core (
		.i_wb_clk(i_wb_clk),
		.i_reset(i_reset),
		.i_wb_cyc(i_wb_cyc),
		.i_wb_stb(i_wb_stb),
		.i_wb_we(i_wb_we),
		.i_wb_addr(i_wb_addr),
		.i_wb_data(i_wb_data),
		.i_wb_sel(i_wb_sel),
		.o_wb_stall(o_wb_stall),
		.o_wb_ack(o_wb_ack),
		.o_wb_data(o_wb_data),
		.o_wb_err(o_wb_err),
		.i_xclk_clk(i_xclk_clk),
		.o_xclk_cyc(o_xclk_cyc),
		.o_xclk_stb(o_xclk_stb),
		.o_xclk_we(o_xclk_we),
		.o_xclk_addr(o_xclk_addr),
		.o_xclk_data(o_xclk_data),
		.o_xclk_sel(o_xclk_sel),
		.i_xclk_stall(i_xclk_stall),
		.i_xclk_ack(i_xclk_ack),
		.i_xclk_data(i_xclk_data),
		.i_xclk_err(i_xclk_err),
		.fifo_waddr(fifo_waddr),
		.fifo_raddr(fifo_raddr),
		.fifo_wdata(fifo_wdata),
		.fifo_rdata(fifo_rdata),
		.fifo_wren(fifo_wren),
		.fifo_rden(fifo_rden),
		.fifo_empty(fifo_empty),
		.fifo_full(fifo_full)
	);

	// FIFO write address logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_waddr <= 0;
		end else if (i_wb_cyc && i_wb_stb && !fifo_full) begin
			fifo_waddr <= fifo_waddr + 1;
		end
	end

	// FIFO read address logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_raddr <= 0;
		end else if (i_xclk_ack && !fifo_empty) begin
			fifo_raddr <= fifo_raddr + 1;
		end
	end

	// FIFO write data logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_wdata <= 0;
		end else if (i_wb_cyc && i_wb_stb && !fifo_full) begin
			fifo_wdata <= {i_wb_data, i_wb_sel};
		end
	end

	// FIFO write enable logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_wren <= 0;
		end else if (i_wb_cyc && i_wb_stb && !fifo_full) begin
			fifo_wren <= 1;
		end else begin
			fifo_wren <= 0;
		end
	end

	// FIFO read enable logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_rden <= 0;
		end else if (i_xclk_ack && !fifo_empty) begin
			fifo_rden <= 1;
		end else begin
			fifo_rden <= 0;
		end
	end

	// FIFO output logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			o_xclk_err <= 0;
		end else if (i_xclk_ack && !fifo_empty) begin
			o_xclk_cyc <= 1;
			o_xclk_stb <= 1;
			o_xclk_we <= fifo_rdata[DW+LGFIFO-1];
			o_xclk_addr <= fifo_rdata[AW+LGFIFO-1:LGFIFO];
			o_xclk_data <= fifo_rdata[DW-1:0];
			o_xclk_sel <= fifo_rdata[DW+LGFIFO-1:DW];
			o_xclk_err <= i_xclk_err;
		end else begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			o_xclk_err <= 0;
		end
	end

endmodule

module wbxclk_fifo_core #(
		parameter	AW=32,
				DW=32
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
		input	wire			i_xclk_err,
		input	wire	[(AW-1):0]	fifo_waddr,
		input	wire	[(AW-1):0]	fifo_raddr,
		input	wire	[(DW+LGFIFO-1):0]	fifo_wdata,
		output	wire	[(DW+LGFIFO-1):0]	fifo_rdata,
		input	wire			fifo_wren,
		input	wire			fifo_rden,
		output	wire			fifo_empty,
		output	wire			fifo_full
	);

	// FIFO parameters
	localparam FIFO_AW = AW + LGFIFO;
	localparam FIFO_DW = DW + LGFIFO;

	// FIFO signals
	reg [FIFO_AW-1:0] fifo_waddr;
	reg [FIFO_AW-1:0] fifo_raddr;
	reg [FIFO_DW-1:0] fifo_wdata;
	wire [FIFO_DW-1:0] fifo_rdata;
	reg fifo_wren;
	wire fifo_rden;
	wire fifo_empty;
	wire fifo_full;

	// FIFO instantiation
	wbxclk_fifo_core_core #(
		.AW(FIFO_AW),
		.DW(FIFO_DW)
	) fifo_core_core (
		.i_wb_clk(i_wb_clk),
		.i_reset(i_reset),
		.i_wb_cyc(i_wb_cyc),
		.i_wb_stb(i_wb_stb),
		.i_wb_we(i_wb_we),
		.i_wb_addr(i_wb_addr),
		.i_wb_data(i_wb_data),
		.i_wb_sel(i_wb_sel),
		.o_wb_stall(o_wb_stall),
		.o_wb_ack(o_wb_ack),
		.o_wb_data(o_wb_data),
		.o_wb_err(o_wb_err),
		.i_xclk_clk(i_xclk_clk),
		.o_xclk_cyc(o_xclk_cyc),
		.o_xclk_stb(o_xclk_stb),
		.o_xclk_we(o_xclk_we),
		.o_xclk_addr(o_xclk_addr),
		.o_xclk_data(o_xclk_data),
		.o_xclk_sel(o_xclk_sel),
		.i_xclk_stall(i_xclk_stall),
		.i_xclk_ack(i_xclk_ack),
		.i_xclk_data(i_xclk_data),
		.i_xclk_err(i_xclk_err),
		.fifo_waddr(fifo_waddr),
		.fifo_raddr(fifo_raddr),
		.fifo_wdata(fifo_wdata),
		.fifo_rdata(fifo_rdata),
		.fifo_wren(fifo_wren),
		.fifo_rden(fifo_rden),
		.fifo_empty(fifo_empty),
		.fifo_full(fifo_full)
	);

	// FIFO write address logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_waddr <= 0;
		end else if (i_wb_cyc && i_wb_stb && !fifo_full) begin
			fifo_waddr <= fifo_waddr + 1;
		end
	end

	// FIFO read address logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_raddr <= 0;
		end else if (i_xclk_ack && !fifo_empty) begin
			fifo_raddr <= fifo_raddr + 1;
		end
	end

	// FIFO write data logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_wdata <= 0;
		end else if (i_wb_cyc && i_wb_stb && !fifo_full) begin
			fifo_wdata <= {i_wb_data, i_wb_sel};
		end
	end

	// FIFO write enable logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_wren <= 0;
		end else if (i_wb_cyc && i_wb_stb && !fifo_full) begin
			fifo_wren <= 1;
		end else begin
			fifo_wren <= 0;
		end
	end

	// FIFO read enable logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_rden <= 0;
		end else if (i_xclk_ack && !fifo_empty) begin
			fifo_rden <= 1;
		end else begin
			fifo_rden <= 0;
		end
	end

	// FIFO output logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			o_xclk_err <= 0;
		end else if (i_xclk_ack && !fifo_empty) begin
			o_xclk_cyc <= 1;
			o_xclk_stb <= 1;
			o_xclk_we <= fifo_rdata[DW+LGFIFO-1];
			o_xclk_addr <= fifo_rdata[AW+LGFIFO-1:LGFIFO];
			o_xclk_data <= fifo_rdata[DW-1:0];
			o_xclk_sel <= fifo_rdata[DW+LGFIFO-1:DW];
			o_xclk_err <= i_xclk_err;
		end else begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			o_xclk_err <= 0;
		end
	end

endmodule

module wbxclk_fifo_core_core #(
		parameter	AW=32,
				DW=32
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
		input	wire			i_xclk_err,
		input	wire	[(AW-1):0]	fifo_waddr,
		input	wire	[(AW-1):0]	fifo_raddr,
		input	wire	[(DW+LGFIFO-1):0]	fifo_wdata,
		output	wire	[(DW+LGFIFO-1):0]	fifo_rdata,
		input	wire			fifo_wren,
		input	wire			fifo_rden,
		output	wire			fifo_empty,
		output	wire			fifo_full
	);

	// FIFO parameters
	localparam FIFO_AW = AW + LGFIFO;
	localparam FIFO_DW = DW + LGFIFO;

	// FIFO signals
	reg [FIFO_AW-1:0] fifo_waddr;
	reg [FIFO_AW-1:0] fifo_raddr;
	reg [FIFO_DW-1:0] fifo_wdata;
	wire [FIFO_DW-1:0] fifo_rdata;
	reg fifo_wren;
	wire fifo_rden;
	wire fifo_empty;
	wire fifo_full;

	// FIFO instantiation
	wbxclk_fifo_core_core_core #(
		.AW(FIFO_AW),
		.DW(FIFO_DW)
	) fifo_core_core_core (
		.i_wb_clk(i_wb_clk),
		.i_reset(i_reset),
		.i_wb_cyc(i_wb_cyc),
		.i_wb_stb(i_wb_stb),
		.i_wb_we(i_wb_we),
		.i_wb_addr(i_wb_addr),
		.i_wb_data(i_wb_data),
		.i_wb_sel(i_wb_sel),
		.o_wb_stall(o_wb_stall),
		.o_wb_ack(o_wb_ack),
		.o_wb_data(o_wb_data),
		.o_wb_err(o_wb_err),
		.i_xclk_clk(i_xclk_clk),
		.o_xclk_cyc(o_xclk_cyc),
		.o_xclk_stb(o_xclk_stb),
		.o_xclk_we(o_xclk_we),
		.o_xclk_addr(o_xclk_addr),
		.o_xclk_data(o_xclk_data),
		.o_xclk_sel(o_xclk_sel),
		.i_xclk_stall(i_xclk_stall),
		.i_xclk_ack(i_xclk_ack),
		.i_xclk_data(i_xclk_data),
		.i_xclk_err(i_xclk_err),
		.fifo_waddr(fifo_waddr),
		.fifo_raddr(fifo_raddr),
		.fifo_wdata(fifo_wdata),
		.fifo_rdata(fifo_rdata),
		.fifo_wren(fifo_wren),
		.fifo_rden(fifo_rden),
		.fifo_empty(fifo_empty),
		.fifo_full(fifo_full)
	);
