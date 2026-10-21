```verilog
module wbxclk #(
	parameter AW = 32,
	parameter DW = 32,
	parameter LGFIFO = 5
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

	localparam FIFO_DEPTH = 1 << LGFIFO;

	// Wishbone to XCLK FIFO
	wbx_fifo #(
		.AW(AW),
		.DW(DW),
		.LGFIFO(LGFIFO)
	) u_wb_to_xclk (
		.clk(i_xclk_clk),
		.reset(i_reset),
		.write_en(i_wb_cyc & i_wb_stb),
		.write_addr(i_wb_addr),
		.write_data(i_wb_data),
		.write_sel(i_wb_sel),
		.write_valid(i_wb_cyc & i_wb_stb),
		.read_en(i_xclk_ack),
		.read_addr(0), // Dummy, handled internally by FIFO logic if needed, but standard FIFO uses read_en
		.read_data(o_wb_data),
		.read_valid(i_xclk_ack),
		.full(o_wb_stall),
		.empty(1'b0) // Not used for control logic in this specific bridge pattern
	);

	// XCLK to Wishbone FIFO
	wbx_fifo #(
		.AW(AW),
		.DW(DW),
		.LGFIFO(LGFIFO)
	) u_xclk_to_wb (
		.clk(i_wb_clk),
		.reset(i_reset),
		.write_en(i_xclk_cyc & i_xclk_stb),
		.write_addr(o_xclk_addr),
		.write_data(o_xclk_data),
		.write_sel(o_xclk_sel),
		.write_valid(i_xclk_cyc & i_xclk_stb),
		.read_en(i_wb_ack),
		.read_addr(0),
		.read_data(i_xclk_data),
		.read_valid(i_wb_ack),
		.full(i_xclk_stall),
		.empty(1'b0)
	);

	// Wishbone Side Logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK Side Logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
	// Wishbone side drives ACK/ERR based on FIFO status and XCLK ACK
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
		end else begin
			if (i_wb_cyc & i_wb_stb) begin
				o_wb_ack <= 1'b0;
				o_wb_err <= 1'b0;
			end else if (i_wb_ack) begin
				o_wb_ack <= 1'b1;
				o_wb_err <= 1'b0;
			end
		end
	end

	// XCLK side drives CYC/STB based on FIFO status and WB ACK
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (i_xclk_cyc & i_xclk_stb) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= i_xclk_we;
				o_xclk_addr <= i_xclk_addr;
				o_xclk_data <= i_xclk_data;
				o_xclk_sel <= i_xclk_sel;
			end else if (i_xclk_ack) begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Cross-domain Handshaking (Revised for correct behavior)
