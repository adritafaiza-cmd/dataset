module uart_top (
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
	output int_o,
	output stx_pad_o,
	input srx_pad_i,
	output rts_pad_o,
	input cts_pad_i,
	output dtr_pad_o,
	input dsr_pad_i,
	input ri_pad_i,
	input dcd_pad_i
);

reg [7:0] wb_dat_o_reg;
reg wb_ack_o_reg;

wire [7:0] tx_data;
wire tx_valid;
wire tx_ready;
wire [7:0] rx_data;
wire rx_valid;
wire rx_ready;
wire rx_int;
wire tx_int;

// Wishbone Slave
wishbone_slave wb_slave (
	.wb_clk_i(wb_clk_i),
	.wb_rst_i(wb_rst_i),
	.wb_adr_i(wb_adr_i),
	.wb_dat_i(wb_dat_i),
	.wb_dat_o(wb_dat_o_reg),
	.wb_we_i(wb_we_i),
	.wb_stb_i(wb_stb_i),
	.wb_cyc_i(wb_cyc_i),
	.wb_ack_o(wb_ack_o_reg),
	.wb_sel_i(wb_sel_i),
	.tx_data(tx_data),
	.tx_valid(tx_valid),
	.tx_ready(tx_ready),
	.rx_data(rx_data),
	.rx_valid(rx_valid),
	.rx_ready(rx_ready)
);

// UART Transmitter
uart_transmitter uart_tx (
	.tx_clk(wb_clk_i),
	.tx_rst(wb_rst_i),
	.tx_data(tx_data),
	.tx_valid(tx_valid),
	.tx_ready(tx_ready),
	.stx_pad_o(stx_pad_o)
);

// UART Receiver
uart_receiver uart_rx (
	.rx_clk(wb_clk_i),
	.rx_rst(wb_rst_i),
	.rx_data(rx_data),
	.rx_valid(rx_valid),
	.rx_ready(rx_ready),
	.srx_pad_i(srx_pad_i),
	.rx_int(rx_int)
);

// Modem Control
modem_control modem_ctrl (
	.wb_clk_i(wb_clk_i),
	.wb_rst_i(wb_rst_i),
	.dtr_pad_o(dtr_pad_o),
	.rts_pad_o(rts_pad_o),
	.cts_pad_i(cts_pad_i),
	.dsr_pad_i(dsr_pad_i),
	.ri_pad_i(ri_pad_i),
	.dcd_pad_i(dcd_pad_i)
);

// Interrupt Control
interrupt_control int_ctrl (
	.wb_clk_i(wb_clk_i),
	.wb_rst_i(wb_rst_i),
	.int_o(int_o),
	.rx_int(rx_int),
	.tx_int(tx_int)
);

assign wb_dat_o = wb_dat_o_reg;
assign wb_ack_o = wb_ack_o_reg;

endmodule

// Wishbone Slave Module
module wishbone_slave (
	input wb_clk_i,
	input wb_rst_i,
	input [2:0] wb_adr_i,
	input [7:0] wb_dat_i,
	output reg [7:0] wb_dat_o,
	input wb_we_i,
	input wb_stb_i,
	input wb_cyc_i,
	output reg wb_ack_o,
	input [3:0] wb_sel_i,
	output reg [7:0] tx_data,
	output reg tx_valid,
	input tx_ready,
	input [7:0] rx_data,
	input rx_valid,
	output reg rx_ready
);

reg [7:0] thr; // Transmit Holding Register
reg [7:0] rbr; // Receive Buffer Register
reg [7:0] iir; // Interrupt Identification Register
reg [7:0] lcr; // Line Control Register
reg [7:0] mcr; // Modem Control Register
reg [7:0] lsr; // Line Status Register
reg [7:0] msr; // Modem Status Register

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		wb_dat_o <= 8'b0;
		wb_ack_o <= 1'b0;
		tx_data <= 8'b0;
		tx_valid <= 1'b0;
		rx_ready <= 1'b0;
		thr <= 8'b0;
		rbr <= 8'b0;
		iir <= 8'b01000001; // No interrupt pending
		lcr <= 8'b0;
		mcr <= 8'b0;
		lsr <= 8'b0;
		msr <= 8'b0;
	end else if (wb_cyc_i && wb_stb_i) begin
		wb_ack_o <= 1'b1;
		if (wb_we_i && wb_sel_i[0]) begin
			case (wb_adr_i)
				3'b000: thr <= wb_dat_i; // THR
				3'b001: iir <= wb_dat_i; // IIR (read-only, write ignored)
				3'b010: lcr <= wb_dat_i; // LCR
				3'b011: mcr <= wb_dat_i; // MCR
				3'b100: lsr <= wb_dat_i; // LSR (read-only, write ignored)
				3'b101: msr <= wb_dat_i; // MSR (read-only, write ignored)
				default: wb_dat_o <= 8'b0;
			endcase
		end else begin
			case (wb_adr_i)
				3'b000: wb_dat_o <= thr; // THR (write-only, read ignored)
				3'b001: wb_dat_o <= iir; // IIR
				3'b010: wb_dat_o <= lcr; // LCR
				3'b011: wb_dat_o <= mcr; // MCR
				3'b100: wb_dat_o <= lsr; // LSR
				3'b101: wb_dat_o <= msr; // MSR
				3'b110: wb_dat_o <= rbr; // RBR
				default: wb_dat_o <= 8'b0;
			endcase
		end
	end else begin
		wb_ack_o <= 1'b0;
	end
end

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		tx_data <= 8'b0;
		tx_valid <= 1'b0;
	end else begin
		if (tx_ready && tx_valid) begin
			tx_valid <= 1'b0;
		end else if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0] && wb_adr_i == 3'b000) begin
			tx_data <= wb_dat_i;
			tx_valid <= 1'b1;
		end
	end
end

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		rx_ready <= 1'b0;
	end else begin
		if (rx_valid && rx_ready) begin
			rx_ready <= 1'b0;
		end else if (wb_cyc_i && wb_stb_i && wb_sel_i[0] && wb_adr_i == 3'b110) begin
			rx_ready <= 1'b1;
		end
	end
end

endmodule

// UART Transmitter Module
module uart_transmitter (
	input tx_clk,
	input tx_rst,
	input [7:0] tx_data,
	input tx_valid,
	output reg tx_ready,
	output stx_pad_o
);

reg [3:0] bit_count;
reg [7:0] tx_shift_reg;
reg tx_state;
reg tx_shift_reg_valid;

always @(posedge tx_clk or posedge tx_rst) begin
	if (tx_rst) begin
		tx_ready <= 1'b1;
		tx_shift_reg <= 8'b0;
		bit_count <= 4'b0;
		tx_state <= 1'b0;
		tx_shift_reg_valid <= 1'b0;
		stx_pad_o <= 1'b1;
	end else begin
		if (tx_ready && tx_valid) begin
			tx_ready <= 1'b0;
			tx_shift_reg <= {tx_data, 1'b0}; // Start bit
			bit_count <= 4'b0;
			tx_state <= 1'b1;
			tx_shift_reg_valid <= 1'b1;
			stx_pad_o <= 1'b0;
		end else if (tx_state) begin
			stx_pad_o <= tx_shift_reg[0];
			tx_shift_reg <= {1'b1, tx_shift_reg[7:1]};
			if (bit_count == 4'b1000) begin
				tx_state <= 1'b0;
				tx_ready <= 1'b1;
			end else begin
				bit_count <= bit_count + 1;
			end
		end
	end
end

endmodule

// UART Receiver Module
module uart_receiver (
	input rx_clk,
	input rx_rst,
	output reg [7:0] rx_data,
	output reg rx_valid,
	input rx_ready,
	input srx_pad_i,
	output rx_int
);

reg [3:0] bit_count;
reg [7:0] rx_shift_reg;
reg rx_state;
reg rx_edge;
reg rx_edge_reg;
reg [1:0] rx_sample;
reg [2:0] rx_sample_cnt;

always @(posedge rx_clk or posedge rx_rst) begin
	if (rx_rst) begin
		rx_data <= 8'b0;
		rx_valid <= 1'b0;
		rx_shift_reg <= 8'b0;
		bit_count <= 4'b0;
		rx_state <= 1'b0;
		rx_edge <= 1'b0;
		rx_edge_reg <= 1'b0;
		rx_sample <= 2'b0;
		rx_sample_cnt <= 3'b0;
		rx_int <= 1'b0;
	end else begin
		rx_edge_reg <= rx_edge;
		if (rx_edge && !rx_edge_reg) begin
			rx_state <= 1'b1;
			bit_count <= 4'b0;
			rx_sample_cnt <= 3'b0;
			rx_sample <= 2'b0;
		end else if (rx_state) begin
			if (rx_sample_cnt == 3'b100) begin
				rx_sample_cnt <= 3'b0;
				if (bit_count < 4'b1000) begin
					rx_shift_reg <= {rx_sample[0], rx_shift_reg[7:1]};
					bit_count <= bit_count + 1;
				end else begin
					rx_state <= 1'b0;
					rx_valid <= 1'b1;
					rx_data <= rx_shift_reg;
					rx_int <= 1'b1;
				end
			end else begin
				rx_sample_cnt <= rx_sample_cnt + 1;
				rx_sample <= {rx_sample[0], srx_pad_i};
			end
		end
		if (rx_ready && rx_valid) begin
			rx_valid <= 1'b0;
			rx_int <= 1'b0;
		end
	end
end

always @(posedge rx_clk or posedge rx_rst) begin
	if (rx_rst) begin
		rx_edge <= 1'b0;
	end else begin
		rx_edge <= srx_pad_i ^ rx_edge_reg;
	end
end

endmodule

// Modem Control Module
module modem_control (
	input wb_clk_i,
	input wb_rst_i,
	output reg dtr_pad_o,
	output reg rts_pad_o,
	input cts_pad_i,
	input dsr_pad_i,
	input ri_pad_i,
	input dcd_pad_i
);

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		dtr_pad_o <= 1'b0;
		rts_pad_o <= 1'b0;
	end else begin
		// Modem control logic here
		// For simplicity, just pass through DTR and RTS
		dtr_pad_o <= dtr_pad_o;
		rts_pad_o <= rts_pad_o;
	end
end

endmodule

// Interrupt Control Module
module interrupt_control (
	input wb_clk_i,
	input wb_rst_i,
	output reg int_o,
	input rx_int,
	input tx_int
);

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		int_o <= 1'b0;
	end else begin
		int_o <= rx_int | tx_int;
	end
end

endmodule
