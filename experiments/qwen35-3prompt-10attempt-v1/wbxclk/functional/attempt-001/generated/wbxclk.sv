```verilog
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

	localparam	FIFO_DEPTH = 1 << LGFIFO;

	// Wishbone Side State Machine
	// States: IDLE, WAIT_XACK, WAIT_XERR
	localparam	IDLE = 2'b00,
				WAIT_XACK = 2'b01,
				WAIT_XERR = 2'b10;

	reg	[1:0]	wb_state;
	reg	[FIFO_DEPTH-1:0]	wb_fifo_wptr;
	reg	[FIFO_DEPTH-1:0]	wb_fifo_rptr;
	reg	[FIFO_DEPTH-1:0]	wb_fifo_count;
	reg	[AW-1:0]	wb_fifo_addr;
	reg	[DW-1:0]	wb_fifo_data;
	reg	[(DW/8)-1:0]	wb_fifo_sel;
	reg			wb_fifo_valid;
	reg			wb_fifo_cyc;
	reg			wb_fifo_stb;
	reg			wb_fifo_we;
	reg			wb_fifo_err;
	reg			wb_fifo_ack;
	reg			wb_fifo_stall;

	// XCLK Side State Machine
	// States: IDLE, WAIT_WACK, WAIT_WERR
	localparam	X_IDLE = 2'b00,
				X_WAIT_WACK = 2'b01,
				X_WAIT_WERR = 2'b10;

	reg	[1:0]	x_state;
	reg	[FIFO_DEPTH-1:0]	x_fifo_wptr;
	reg	[FIFO_DEPTH-1:0]	x_fifo_rptr;
	reg	[FIFO_DEPTH-1:0]	x_fifo_count;
	reg	[AW-1:0]	x_fifo_addr;
	reg	[DW-1:0]	x_fifo_data;
	reg	[(DW/8)-1:0]	x_fifo_sel;
	reg			x_fifo_valid;
	reg			x_fifo_cyc;
	reg			x_fifo_stb;
	reg			x_fifo_we;
	reg			x_fifo_err;
	reg			x_fifo_ack;
	reg			x_fifo_stall;

	// Wishbone Side Logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_state <= IDLE;
			wb_fifo_wptr <= '0;
			wb_fifo_rptr <= '0;
			wb_fifo_count <= '0;
			wb_fifo_addr <= '0;
			wb_fifo_data <= '0;
			wb_fifo_sel <= '0;
			wb_fifo_valid <= 1'b0;
			wb_fifo_cyc <= 1'b0;
			wb_fifo_stb <= 1'b0;
			wb_fifo_we <= 1'b0;
			wb_fifo_err <= 1'b0;
			wb_fifo_ack <= 1'b0;
			wb_fifo_stall <= 1'b0;
			o_wb_ack <= 1'b0;
			o_wb_err <= 1'b0;
			o_wb_data <= '0;
		end
		else begin
			// State Machine
			case (wb_state)
				IDLE: begin
					if (i_wb_cyc && i_wb_stb) begin
						// Check if FIFO is full
						if (wb_fifo_count == FIFO_DEPTH - 1) begin
							wb_fifo_stall <= 1'b1;
						end else begin
							wb_fifo_stall <= 1'b0;
							wb_fifo_cyc <= i_wb_cyc;
							wb_fifo_stb <= i_wb_stb;
							wb_fifo_we <= i_wb_we;
							wb_fifo_addr <= i_wb_addr;
							wb_fifo_data <= i_wb_data;
							wb_fifo_sel <= i_wb_sel;
							wb_fifo_valid <= 1'b1;
							wb_state <= WAIT_XACK;
						end
					end
				end

				WAIT_XACK: begin
					if (i_xclk_ack) begin
						wb_fifo_valid <= 1'b0;
						wb_fifo_cyc <= 1'b0;
						wb_fifo_stb <= 1'b0;
						wb_fifo_we <= 1'b0;
						wb_fifo_err <= i_xclk_err;
						wb_fifo_ack <= 1'b1;
						o_wb_err <= i_xclk_err;
						o_wb_data <= i_xclk_data;
						wb_state <= IDLE;
					end
				end

				WAIT_XERR: begin
					if (i_xclk_ack) begin
						wb_fifo_valid <= 1'b0;
						wb_fifo_cyc <= 1'b0;
						wb_fifo_stb <= 1'b0;
						wb_fifo_we <= 1'b0;
						wb_fifo_err <= i_xclk_err;
						wb_fifo_ack <= 1'b1;
						o_wb_err <= i_xclk_err;
						o_wb_data <= i_xclk_data;
						wb_state <= IDLE;
					end
				end
			endcase

			// FIFO Write Logic
			if (wb_fifo_valid) begin
				wb_fifo_wptr <= wb_fifo_wptr + 1'b1;
				wb_fifo_count <= wb_fifo_count + 1'b1;
				wb_fifo_addr[wb_fifo_wptr] <= wb_fifo_addr;
				wb_fifo_data[wb_fifo_wptr] <= wb_fifo_data;
				wb_fifo_sel[wb_fifo_wptr] <= wb_fifo_sel;
				wb_fifo_cyc[wb_fifo_wptr] <= wb_fifo_cyc;
				wb_fifo_stb[wb_fifo_wptr] <= wb_fifo_stb;
				wb_fifo_we[wb_fifo_wptr] <= wb_fifo_we;
				wb_fifo_err[wb_fifo_wptr] <= wb_fifo_err;
				wb_fifo_ack[wb_fifo_wptr] <= wb_fifo_ack;
			end

			// FIFO Read Logic
			if (wb_fifo_count > 0) begin
				wb_fifo_rptr <= wb_fifo_rptr + 1'b1;
				wb_fifo_count <= wb_fifo_count - 1'b1;
			end

			// Output Logic
			o_wb_stall <= wb_fifo_stall;
			o_wb_ack <= wb_fifo_ack;
		end
	end

	// XCLK Side Logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_state <= X_IDLE;
			x_fifo_wptr <= '0;
			x_fifo_rptr <= '0;
			x_fifo_count <= '0;
			x_fifo_addr <= '0;
			x_fifo_data <= '0;
			x_fifo_sel <= '0;
			x_fifo_valid <= 1'b0;
			x_fifo_cyc <= 1'b0;
			x_fifo_stb <= 1'b0;
			x_fifo_we <= 1'b0;
			x_fifo_err <= 1'b0;
			x_fifo_ack <= 1'b0;
			x_fifo_stall <= 1'b0;
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= '0;
			o_xclk_data <= '0;
			o_xclk_sel <= '0;
		end
		else begin
			// State Machine
			case (x_state)
				X_IDLE: begin
					if (wb_fifo_count > 0) begin
						// Check if FIFO is full
						if (x_fifo_count == FIFO_DEPTH - 1) begin
							x_fifo_stall <= 1'b1;
						end else begin
							x_fifo_stall <= 1'b0;
							x_fifo_cyc <= wb_fifo_cyc[wb_fifo_rptr];
							x_fifo_stb <= wb_fifo_stb[wb_fifo_rptr];
							x_fifo_we <= wb_fifo_we[wb_fifo_rptr];
							x_fifo_addr <= wb_fifo_addr[wb_fifo_rptr];
							x_fifo_data <= wb_fifo_data[wb_fifo_rptr];
							x_fifo_sel <= wb_fifo_sel[wb_fifo_rptr];
							x_fifo_valid <= 1'b1;
							x_state <= X_WAIT_WACK;
						end
					end
				end

				X_WAIT_WACK: begin
					if (i_wb_ack) begin
						x_fifo_valid <= 1'b0;
						x_fifo_cyc <= 1'b0;
						x_fifo_stb <= 1'b0;
						x_fifo_we <= 1'b0;
						x_fifo_err <= 1'b0;
						x_fifo_ack <= 1'b1;
						o_xclk_cyc <= 1'b0;
						o_xclk_stb <= 1'b0;
						o_xclk_we <= 1'b0;
						o_xclk_addr <= '0;
						o_xclk_data <= '0;
						o_xclk_sel <= '0;
						x_state <= X_IDLE;
					end
				end

				X_WAIT_WERR: begin
					if (i_wb_ack) begin
						x_fifo_valid <= 1'b0;
						x_fifo_cyc <= 1'b0;
						x_fifo_stb <= 1'b0;
						x_fifo_we <= 1'b0;
						x_fifo_err <= 1'b0;
						x_fifo_ack <= 1'b1;
						o_xclk_cyc <= 1'b0;
						o_xclk_stb <= 1'b0;
						o_xclk_we <= 1'b0;
						o_xclk_addr <= '0;
						o_xclk_data <= '0;
						o_xclk_sel <= '0;
						x_state <= X_IDLE;
					end
				end
			endcase

			// FIFO Write Logic
			if (x_fifo_valid) begin
				x_fifo_wptr <= x_fifo_wptr + 1'b1;
				x_fifo_count <= x_fifo_count + 1'b1;
				x_fifo_addr[x_fifo_wptr] <= x_fifo_addr;
				x_fifo_data[x_fifo_wptr] <= x_fifo_data;
				x_fifo_sel[x_fifo_wptr] <= x_fifo_sel;
				x_fifo_cyc[x_fifo_wptr] <= x_fifo_cyc;
				x_fifo_stb[x_fifo_wptr] <= x_fifo_stb;
				x_fifo_we[x_fifo_wptr] <= x_fifo_we;
				x_fifo_err[x_fifo_wptr] <= x_fifo_err;
				x_fifo_ack[x_fifo_wptr] <= x_fifo_ack;
			end

			// FIFO Read Logic
			if (x_fifo_count > 0) begin
				x_fifo_rptr <= x_fifo_rptr + 1'b1;
				x_fifo_count <= x_fifo_count - 1'b1;
			end

			// Output Logic
			o_xclk_cyc <= x_fifo_cyc;
			o_xclk_stb <= x_fifo_stb;
			o_xclk_we <= x_fifo_we;
			o_xclk_addr <= x_fifo_addr;
			o_xclk_data <= x_fifo_data;
			o_xclk_sel <= x_fifo_sel;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// XCLK Side: Stall if WB FIFO is full
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			x_fifo_stall <= 1'b0;
		end
		else begin
			x_fifo_stall <= (x_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
		end
	end

	// Cross-domain Handshaking Logic
	// Wishbone Side: Stall if XCLK FIFO is full
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_fifo_stall <= 1'b0;
		end
		else begin
			wb_fifo_stall <= (wb_fifo_count == FIFO_DEPTH - 1) ? 1'b1 : 1'b0;
	