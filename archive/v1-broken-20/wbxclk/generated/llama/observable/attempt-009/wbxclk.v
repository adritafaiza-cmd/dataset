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

	reg	[2**LGFIFO-1:0]	fifo_count;
	reg	[2**LGFIFO-1:0]	fifo_head, fifo_tail;

	wire			fifo_empty;
	wire			fifo_full;

	assign	fifo_empty = (fifo_count == 0);
	assign	fifo_full = (fifo_count == (1 << LGFIFO));

	assign	o_wb_stall = ~fifo_empty;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else if (i_wb_cyc && i_wb_stb && ~o_wb_stall) begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else if (~i_wb_cyc || ~i_wb_stb) begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end
	end

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_head <= 0;
			fifo_tail <= 0;
			fifo_count <= 0;
		end else if (i_wb_cyc && i_wb_stb && ~fifo_full) begin
			fifo_addr[fifo_head] <= i_wb_addr;
			fifo_data[fifo_head] <= i_wb_data;
			fifo_sel[fifo_head] <= i_wb_sel;
			fifo_we[fifo_head] <= i_wb_we;
			fifo_cyc[fifo_head] <= i_wb_cyc;
			fifo_stb[fifo_head] <= i_wb_stb;
			fifo_head <= (fifo_head + 1) % (1 << LGFIFO);
			fifo_count <= fifo_count + 1;
		end else if (~i_wb_cyc || ~i_wb_stb || fifo_full) begin
			fifo_head <= fifo_head;
			fifo_tail <= fifo_tail;
			fifo_count <= fifo_count;
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else if (~fifo_empty && ~i_xclk_stall) begin
			o_xclk_cyc <= fifo_cyc[fifo_tail];
			o_xclk_stb <= fifo_stb[fifo_tail];
			o_xclk_we <= fifo_we[fifo_tail];
			o_xclk_addr <= fifo_addr[fifo_tail];
			o_xclk_data <= fifo_data[fifo_tail];
			o_xclk_sel <= fifo_sel[fifo_tail];
			fifo_tail <= (fifo_tail + 1) % (1 << LGFIFO);
			fifo_count <= fifo_count - 1;
		end else if (fifo_empty || i_xclk_stall) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else if (i_xclk_ack) begin
			o_wb_ack <= 1;
			o_wb_data <= i_xclk_data;
			o_wb_err <= i_xclk_err;
		end else if (~i_xclk_ack) begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end
	end

endmodule
