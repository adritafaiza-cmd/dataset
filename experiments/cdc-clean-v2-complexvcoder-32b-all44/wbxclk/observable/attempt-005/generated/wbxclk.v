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
	wire xclk_reset;
	wire wb_reset;
	wire [(AW + DW + DW/8 + 1 + 1)-1:0] req_fifo_dout;
	wire req_fifo_empty;
	wire [(DW + 1 + 1)-1:0] resp_fifo_dout;
	wire resp_fifo_empty;

	// Reset synchronization
	sync_ff wb_reset_sync (
		.clk(i_xclk_clk),
		.async_in(i_reset),
		.sync_out(xclk_reset)
	);

	sync_ff xclk_reset_sync (
		.clk(i_wb_clk),
		.async_in(xclk_reset),
		.sync_out(wb_reset)
	);

	// Request FIFO
	fifo #(
		.WIDTH(AW + DW + DW/8 + 1 + 1),
		.LOG_DEPTH(LGFIFO)
	) req_fifo (
		.clk_wr(i_wb_clk),
		.rst_wr(wb_reset),
		.wr_en(i_wb_cyc & i_wb_stb),
		.din({i_wb_addr, i_wb_data, i_wb_sel, i_wb_we, i_wb_stb}),
		.clk_rd(i_xclk_clk),
		.rst_rd(xclk_reset),
		.rd_en(o_xclk_cyc & o_xclk_stb & i_xclk_ack),
		.dout(req_fifo_dout),
		.empty(req_fifo_empty)
	);

	// Response FIFO
	fifo #(
		.WIDTH(DW + 1 + 1),
		.LOG_DEPTH(LGFIFO)
	) resp_fifo (
		.clk_wr(i_xclk_clk),
		.rst_wr(xclk_reset),
		.wr_en(i_xclk_ack),
		.din({i_xclk_data, i_xclk_err, i_xclk_ack}),
		.clk_rd(i_wb_clk),
		.rst_rd(wb_reset),
		.rd_en(o_wb_cyc & o_wb_stb & o_wb_ack),
		.dout(resp_fifo_dout),
		.empty(resp_fifo_empty)
	);

	// Backpressure signal
	assign o_wb_stall = req_fifo_empty;

	// Output assignments for xclk side
	always @(posedge i_xclk_clk or posedge xclk_reset) begin
		if (xclk_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			o_xclk_cyc <= req_fifo_dout[AW + DW + DW/8 + 1 + 1 - 1];
			o_xclk_stb <= req_fifo_dout[AW + DW + DW/8 + 1 + 1 - 1 - 1];
			o_xclk_we <= req_fifo_dout[AW + DW + DW/8 + 1 + 1 - 1 - 1 - 1];
			o_xclk_addr <= req_fifo_dout[(AW + DW + DW/8 + 1 + 1)-1:AW + DW + DW/8 + 1];
			o_xclk_data <= req_fifo_dout[AW + DW + DW/8 + 1 + 1 - AW - DW - DW/8 - 1 - 1:AW + DW + DW/8 + 1 - AW - DW - DW/8 - 1];
			o_xclk_sel <= req_fifo_dout[AW + DW + DW/8 + 1 + 1 - AW - DW - DW/8 - 1:AW + DW + DW/8 + 1 - AW - DW - DW/8 - 1 - DW/8];
		end
	end

	// Output assignments for wb side
	always @(posedge i_wb_clk or posedge wb_reset) begin
		if (wb_reset) begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else if (i_xclk_ack) begin
			o_wb_ack <= resp_fifo_dout[DW + 1 + 1 - 1];
			o_wb_data <= resp_fifo_dout[DW + 1 + 1 - 1 - DW - 1:0];
			o_wb_err <= resp_fifo_dout[DW + 1 + 1 - 1 - DW];
		end
	end

endmodule

module sync_ff (
		input	wire clk,
		input	wire async_in,
		output	reg sync_out
	);

	reg ff1, ff2;

	always @(posedge clk) begin
		ff1 <= async_in;
		ff2 <= ff1;
	end

	assign sync_out = ff2;

endmodule

module fifo #(
		parameter WIDTH = 1,
				LOG_DEPTH = 1
	) (
		input	wire clk_wr, rst_wr,
		input	wire wr_en,
		input	wire [WIDTH-1:0] din,
		input	wire clk_rd, rst_rd,
		input	wire rd_en,
		output	reg [WIDTH-1:0] dout,
		output	reg empty
	);

	localparam DEPTH = 1 << LOG_DEPTH;
	reg [WIDTH-1:0] mem [DEPTH-1:0];
	reg [LOG_DEPTH-1:0] wr_ptr, rd_ptr;
	reg full_reg;

	// Write pointer and memory update
	always @(posedge clk_wr or posedge rst_wr) begin
		if (rst_wr) begin
			wr_ptr <= 0;
			full_reg <= 0;
		end else if (wr_en && !full_reg) begin
			mem[wr_ptr] <= din;
			wr_ptr <= wr_ptr + 1;
			full_reg <= (wr_ptr == rd_ptr - 1) || (wr_ptr == DEPTH - 1 && rd_ptr == 0);
		end
	end

	// Read pointer and memory read
	always @(posedge clk_rd or posedge rst_rd) begin
		if (rst_rd) begin
			rd_ptr <= 0;
			dout <= 0;
			empty <= 1;
		end else if (rd_en && !empty) begin
			dout <= mem[rd_ptr];
			rd_ptr <= rd_ptr + 1;
			empty <= (wr_ptr == rd_ptr);
		end
	end

endmodule
