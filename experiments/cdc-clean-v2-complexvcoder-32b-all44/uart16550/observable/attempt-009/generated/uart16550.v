module uart16550 (
	wb_clk_i,
	wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i,
	int_o,
	stx_pad_o, srx_pad_i,
	rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

	input wb_clk_i;
	input wb_rst_i;
	input [2:0] wb_adr_i;
	input [7:0] wb_dat_i;
	output [7:0] wb_dat_o;
	input wb_we_i;
	input wb_stb_i;
	input wb_cyc_i;
	output wb_ack_o;
	input [3:0] wb_sel_i;

	output int_o;

	output stx_pad_o;
	input srx_pad_i;

	output rts_pad_o;
	input cts_pad_i;
	output dtr_pad_o;
	input dsr_pad_i;
	input ri_pad_i;
	input dcd_pad_i;

	// Internal signals
	wire [7:0] rx_data;
	wire tx_ready;
	wire [7:0] tx_data;
	wire rx_ready;
	wire [15:0] baud_divisor;
	wire [7:0] line_control;
	wire [7:0] modem_control;
	wire [7:0] modem_status;
	wire [7:0] line_status;
	wire [7:0] ier;
	wire [7:0] iir;
	wire baud_clk;

	// Instantiate the Wishbone interface
	uart_wishbone_interface wishbone_if (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_adr_i(wb_adr_i),
		.wb_dat_i(wb_dat_i),
		.wb_dat_o(wb_dat_o),
		.wb_we_i(wb_we_i),
		.wb_stb_i(wb_stb_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_ack_o(wb_ack_o),
		.wb_sel_i(wb_sel_i),
		.rx_data(rx_data),
		.tx_ready(tx_ready),
		.tx_data(tx_data),
		.rx_ready(rx_ready),
		.int_o(int_o),
		.baud_divisor(baud_divisor),
		.line_control(line_control),
		.modem_control(modem_control),
		.modem_status(modem_status),
		.line_status(line_status),
		.ier(ier),
		.iir(iir)
	);

	// Instantiate the UART core
	uart_core uart_core_inst (
		.clk(baud_clk),
		.rst(wb_rst_i),
		.rx_data(rx_data),
		.tx_ready(tx_ready),
		.tx_data(tx_data),
		.rx_ready(rx_ready),
		.stx_pad_o(stx_pad_o),
		.srx_pad_i(srx_pad_i),
		.line_control(line_control),
		.modem_control(modem_control),
		.modem_status(modem_status),
		.line_status(line_status),
		.ier(ier),
		.iir(iir)
	);

	// Instantiate the baud rate generator
	baud_rate_generator baud_gen (
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.baud_divisor(baud_divisor),
		.baud_clk(baud_clk)
	);

endmodule

module uart_wishbone_interface (
	input wb_clk_i,
	input wb_rst_i,
	input [2:0] wb_adr_i,
	input [7:0] wb_dat_i,
	output [7:0] wb_dat_o,
	input wb_we_i,
	input wb_stb_i,
	input wb_cyc_i,
	output wb_ack_o,
	input [3:0] wb_sel_i,
	output [7:0] rx_data,
	input tx_ready,
	input [7:0] tx_data,
	output rx_ready,
	output int_o,
	inout [15:0] baud_divisor,
	inout [7:0] line_control,
	inout [7:0] modem_control,
	inout [7:0] modem_status,
	inout [7:0] line_status,
	inout [7:0] ier,
	inout [7:0] iir
);

	reg [7:0] wb_dat_o_reg;
	reg wb_ack_o_reg;
	reg [15:0] baud_divisor_reg;
	reg [7:0] line_control_reg;
	reg [7:0] modem_control_reg;
	reg [7:0] modem_status_reg;
	reg [7:0] line_status_reg;
	reg [7:0] ier_reg;
	reg [7:0] iir_reg;

	assign wb_dat_o = wb_dat_o_reg;
	assign wb_ack_o = wb_ack_o_reg;
	assign baud_divisor = baud_divisor_reg;
	assign line_control = line_control_reg;
	assign modem_control = modem_control_reg;
	assign modem_status = modem_status_reg;
	assign line_status = line_status_reg;
	assign ier = ier_reg;
	assign iir = iir_reg;

	always @(posedge wb_clk_i or posedge wb_rst_i) begin
		if (wb_rst_i) begin
			wb_ack_o_reg <= 0;
			baud_divisor_reg <= 0;
			line_control_reg <= 0;
			modem_control_reg <= 0;
			modem_status_reg <= 0;
			line_status_reg <= 0;
			ier_reg <= 0;
			iir_reg <= 0;
		end else if (wb_cyc_i && wb_stb_i) begin
			wb_ack_o_reg <= 1;
			if (wb_we_i) begin
				case (wb_adr_i)
					3'b000: baud_divisor_reg[7:0] <= wb_dat_i;
					3'b001: baud_divisor_reg[15:8] <= wb_dat_i;
					3'b010: ier_reg <= wb_dat_i;
					3'b011: line_control_reg <= wb_dat_i;
					3'b100: modem_control_reg <= wb_dat_i;
					default: ;
				endcase
			end else begin
				case (wb_adr_i)
					3'b000: wb_dat_o_reg <= baud_divisor_reg[7:0];
					3'b001: wb_dat_o_reg <= baud_divisor_reg[15:8];
					3'b010: wb_dat_o_reg <= iir_reg;
					3'b011: wb_dat_o_reg <= line_status_reg;
					3'b100: wb_dat_o_reg <= modem_status_reg;
					3'b101: wb_dat_o_reg <= line_control_reg;
					3'b110: wb_dat_o_reg <= modem_control_reg;
					default: wb_dat_o_reg <= 8'b0;
				endcase
			end
		end else begin
			wb_ack_o_reg <= 0;
		end
	end

	assign int_o = (ier_reg & iir_reg) != 8'b00000000;
	assign rx_ready = 1'b1;

endmodule

module uart_core (
	input clk,
	input rst,
	output [7:0] rx_data,
	input tx_ready,
	input [7:0] tx_data,
	output rx_ready,
	output stx_pad_o,
	input srx_pad_i,
	input [7:0] line_control,
	input [7:0] modem_control,
	output [7:0] modem_status,
	output [7:0] line_status,
	input [7:0] ier,
	output [7:0] iir
);

	reg [7:0] rx_data_reg;
	reg [7:0] tx_data_reg;
	reg tx_ready_reg;
	reg rx_ready_reg;
	reg stx_pad_o_reg;
	reg srx_pad_i_reg;
	reg [7:0] line_control_reg;
	reg [7:0] modem_control_reg;
	reg [7:0] modem_status_reg;
	reg [7:0] line_status_reg;
	reg [7:0] iir_reg;

	assign rx_data = rx_data_reg;
	assign rx_ready = rx_ready_reg;
	assign stx_pad_o = stx_pad_o_reg;

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			rx_data_reg <= 8'b0;
			tx_data_reg <= 8'b0;
			tx_ready_reg <= 1'b0;
			rx_ready_reg <= 1'b0;
			stx_pad_o_reg <= 1'b1;
			srx_pad_i_reg <= 1'b0;
			line_control_reg <= 8'b0;
			modem_control_reg <= 8'b0;
			modem_status_reg <= 8'b0;
			line_status_reg <= 8'b0;
			iir_reg <= 8'b0;
		end else begin
			// Transmission logic
			if (tx_ready && tx_ready_reg) begin
				stx_pad_o_reg <= tx_data[0];
				tx_data_reg <= {tx_data_reg[6:0], tx_data[7]};
				tx_ready_reg <= 0;
			end else if (tx_ready) begin
				stx_pad_o_reg <= tx_data[0];
				tx_data_reg <= tx_data;
				tx_ready_reg <= 1;
			end else begin
				tx_ready_reg <= 0;
			end

			// Reception logic
			srx_pad_i_reg <= srx_pad_i;
			if (srx_pad_i_reg != srx_pad_i) begin
				rx_data_reg <= {rx_data_reg[6:0], srx_pad_i};
				rx_ready_reg <= 1;
			end else begin
				rx_ready_reg <= 0;
			end

			// Modem and Line control/status
			line_control_reg <= line_control;
			modem_control_reg <= modem_control;
			modem_status_reg <= {dsr_pad_i, 1'b0, ri_pad_i, 1'b0, dcd_pad_i, cts_pad_i, 1'b0, 1'b0};
			line_status_reg <= {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, rx_ready_reg};

			// Interrupt identification
			if (rx_ready_reg)
				iir_reg <= 8'b10000001; // Receive data available
			else if (tx_ready_reg)
				iir_reg <= 8'b10000010; // Transmit holding register empty
			else
				iir_reg <= 8'b00000001; // No interrupt
		end
	end

endmodule

module baud_rate_generator (
	input clk,
	input rst,
	input [15:0] baud_divisor,
	output baud_clk
);

	reg [15:0] baud_divisor_reg;
	reg baud_clk_reg;
	reg [15:0] counter;

	assign baud_clk = baud_clk_reg;

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			baud_divisor_reg <= 16'd0;
			baud_clk_reg <= 1'b0;
			counter <= 16'd0;
		end else begin
			baud_divisor_reg <= baud_divisor;
			if (counter == baud_divisor_reg - 1) begin
				baud_clk_reg <= ~baud_clk_reg;
				counter <= 16'd0;
			end else begin
				counter <= counter + 1;
			end
		end
	end

endmodule
