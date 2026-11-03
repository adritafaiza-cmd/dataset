module uart_top (
	input wb_clk_i,
	input wb_rst_i,
	input [7:0] wb_adr_i,
	input [31:0] wb_dat_i,
	output [31:0] wb_dat_o,
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

reg wb_ack_o_reg;
reg [31:0] wb_dat_o_reg;

wire rst_sync_wb;
wire rst_sync_uart;
wire [3:0] tx_data_wb;
wire tx_valid_wb;
wire tx_ready_uart;
wire [3:0] tx_data_uart;
wire tx_valid_uart;
wire [3:0] rx_data_uart;
wire rx_valid_uart;
wire [15:0] baud_rate_uart;
wire modem_rts_wb;
wire modem_dtr_wb;
wire modem_cts_wb;
wire modem_dsr_wb;
wire modem_ri_wb;
wire modem_dcd_wb;

cdc_reset_sync cdc_reset_sync_inst (
	.wb_clk_i(wb_clk_i),
	.wb_rst_i(wb_rst_i),
	.uart_clk_i(wb_clk_i), // Assuming UART clock is the same as Wishbone clock for simplicity
	.rst_sync_o_wb(rst_sync_wb),
	.rst_sync_o_uart(rst_sync_uart)
);

cdc_data_sync cdc_data_sync_inst (
	.wb_clk_i(wb_clk_i),
	.uart_clk_i(wb_clk_i), // Assuming UART clock is the same as Wishbone clock for simplicity
	.rst_i(rst_sync_wb),
	.tx_data_i(tx_data_wb),
	.tx_valid_i(tx_valid_wb),
	.tx_ready_o(tx_ready_uart),
	.tx_data_o(tx_data_uart),
	.tx_valid_o(tx_valid_uart)
);

wishbone_slave wb_slave_inst (
	.wb_clk_i(wb_clk_i),
	.wb_rst_i(rst_sync_wb),
	.wb_adr_i(wb_adr_i),
	.wb_dat_i(wb_dat_i),
	.wb_dat_o(wb_dat_o_reg),
	.wb_we_i(wb_we_i),
	.wb_stb_i(wb_stb_i),
	.wb_cyc_i(wb_cyc_i),
	.wb_ack_o(wb_ack_o_reg),
	.wb_sel_i(wb_sel_i),
	.baud_rate_o(baud_rate_uart),
	.tx_data_o(tx_data_wb),
	.tx_valid_o(tx_valid_wb),
	.rx_data_i(rx_data_uart),
	.rx_valid_i(rx_valid_uart),
	.rts_o(modem_rts_wb),
	.cts_i(modem_cts_wb),
	.dtr_o(modem_dtr_wb),
	.dsr_i(modem_dsr_wb),
	.ri_i(modem_ri_wb),
	.dcd_i(modem_dcd_wb)
);

uart_core uart_core_inst (
	.clk_i(wb_clk_i),
	.rst_i(rst_sync_uart),
	.baud_rate_i(baud_rate_uart),
	.tx_data_i(tx_data_uart),
	.tx_valid_i(tx_valid_uart),
	.tx_ready_o(tx_ready_uart),
	.rx_data_o(rx_data_uart),
	.rx_valid_o(rx_valid_uart),
	.int_o(int_o),
	.stx_pad_o(stx_pad_o),
	.srx_pad_i(srx_pad_i)
);

modem_control modem_control_inst (
	.clk_i(wb_clk_i),
	.rst_i(rst_sync_uart),
	.rts_o(rts_pad_o),
	.cts_i(cts_pad_i),
	.dtr_o(dtr_pad_o),
	.dsr_i(dsr_pad_i),
	.ri_i(ri_pad_i),
	.dcd_i(dcd_pad_i),
	.rts_i(modem_rts_wb),
	.cts_o(modem_cts_wb),
	.dtr_i(modem_dtr_wb),
	.dsr_o(modem_dsr_wb),
	.ri_o(modem_ri_wb),
	.dcd_o(modem_dcd_wb)
);

assign wb_dat_o = wb_dat_o_reg;
assign wb_ack_o = wb_ack_o_reg;

endmodule

module cdc_reset_sync (
	input wb_clk_i,
	input uart_clk_i,
	input wb_rst_i,
	output rst_sync_o_wb,
	output rst_sync_o_uart
);

reg [1:0] rst_sync_wb_reg;
reg [1:0] rst_sync_uart_reg;

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		rst_sync_wb_reg <= 2'b11;
	end else begin
		rst_sync_wb_reg <= {rst_sync_wb_reg[0], rst_sync_uart_reg[1]};
	end
end

always @(posedge uart_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		rst_sync_uart_reg <= 2'b11;
	end else begin
		rst_sync_uart_reg <= {rst_sync_uart_reg[0], rst_sync_wb_reg[1]};
	end
end

assign rst_sync_o_wb = rst_sync_wb_reg[1];
assign rst_sync_o_uart = rst_sync_uart_reg[1];

endmodule

module cdc_data_sync (
	input wb_clk_i,
	input uart_clk_i,
	input rst_i,
	input [3:0] tx_data_i,
	input tx_valid_i,
	output tx_ready_o,
	output [3:0] tx_data_o,
	output tx_valid_o
);

reg [3:0] tx_data_uart_reg;
reg tx_valid_uart_reg;
reg tx_ready_wb_reg;

always @(posedge wb_clk_i or posedge rst_i) begin
	if (rst_i) begin
		tx_ready_wb_reg <= 1'b0;
	end else begin
		tx_ready_wb_reg <= tx_valid_uart_reg & ~tx_valid_i;
	end
end

always @(posedge uart_clk_i or posedge rst_i) begin
	if (rst_i) begin
		tx_data_uart_reg <= 4'b0;
		tx_valid_uart_reg <= 1'b0;
	end else begin
		if (tx_ready_wb_reg) begin
			tx_data_uart_reg <= tx_data_i;
			tx_valid_uart_reg <= tx_valid_i;
		end
	end
end

assign tx_ready_o = tx_ready_wb_reg;
assign tx_data_o = tx_data_uart_reg;
assign tx_valid_o = tx_valid_uart_reg;

endmodule

module wishbone_slave (
	input wb_clk_i,
	input wb_rst_i,
	input [7:0] wb_adr_i,
	input [31:0] wb_dat_i,
	output reg [31:0] wb_dat_o,
	input wb_we_i,
	input wb_stb_i,
	input wb_cyc_i,
	output reg wb_ack_o,
	input [3:0] wb_sel_i,
	output reg [15:0] baud_rate_o,
	output reg [3:0] tx_data_o,
	output reg tx_valid_o,
	input [3:0] rx_data_i,
	input rx_valid_i,
	output reg rts_o,
	input cts_i,
	output reg dtr_o,
	input dsr_i,
	input ri_i,
	input dcd_i
);

reg [31:0] uart_regs [0:15];

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		wb_dat_o <= 32'b0;
		wb_ack_o <= 1'b0;
		baud_rate_o <= 16'd12; // Default baud rate divisor
		tx_data_o <= 4'b0;
		tx_valid_o <= 1'b0;
		rts_o <= 1'b0;
		dtr_o <= 1'b0;
	end else begin
		wb_ack_o <= wb_stb_i & wb_cyc_i;

		if (wb_stb_i & wb_cyc_i) begin
			if (wb_we_i) begin
				case (wb_adr_i)
					8'h00: uart_regs[0] <= wb_dat_i;
					8'h01: uart_regs[1] <= wb_dat_i;
					8'h02: uart_regs[2] <= wb_dat_i;
					8'h03: uart_regs[3] <= wb_dat_i;
					8'h04: uart_regs[4] <= wb_dat_i;
					8'h05: uart_regs[5] <= wb_dat_i;
					8'h06: uart_regs[6] <= wb_dat_i;
					8'h07: uart_regs[7] <= wb_dat_i;
					8'h08: uart_regs[8] <= wb_dat_i;
					8'h09: uart_regs[9] <= wb_dat_i;
					8'h0A: uart_regs[10] <= wb_dat_i;
					8'h0B: uart_regs[11] <= wb_dat_i;
					8'h0C: begin
						baud_rate_o <= wb_dat_i[15:0];
					end
					8'h0D: uart_regs[13] <= wb_dat_i;
					8'h0E: begin
						tx_data_o <= wb_dat_i[3:0];
						tx_valid_o <= 1'b1;
					end
					8'h0F: begin
						rts_o <= wb_dat_i[0];
						dtr_o <= wb_dat_i[1];
					end
					default: wb_dat_o <= 32'b0;
				endcase
			end else begin
				case (wb_adr_i)
					8'h00: wb_dat_o <= uart_regs[0];
					8'h01: wb_dat_o <= uart_regs[1];
					8'h02: wb_dat_o <= uart_regs[2];
					8'h03: wb_dat_o <= uart_regs[3];
					8'h04: wb_dat_o <= uart_regs[4];
					8'h05: wb_dat_o <= uart_regs[5];
					8'h06: wb_dat_o <= uart_regs[6];
					8'h07: wb_dat_o <= uart_regs[7];
					8'h08: wb_dat_o <= uart_regs[8];
					8'h09: wb_dat_o <= uart_regs[9];
					8'h0A: wb_dat_o <= uart_regs[10];
					8'h0B: wb_dat_o <= uart_regs[11];
					8'h0C: wb_dat_o <= {16'b0, baud_rate_o};
					8'h0D: wb_dat_o <= uart_regs[13];
					8'h0E: wb_dat_o <= {28'b0, rx_data_i};
					8'h0F: wb_dat_o <= {30'b0, cts_i, dsr_i, ri_i, dcd_i};
					default: wb_dat_o <= 32'b0;
				endcase
			end
		end else begin
			wb_ack_o <= 1'b0;
		end

		if (tx_valid_o) begin
			tx_valid_o <= 1'b0;
		end

		if (rx_valid_i) begin
			uart_regs[14] <= {28'b0, rx_data_i};
			uart_regs[15] <= {30'b0, cts_i, dsr_i, ri_i, dcd_i};
		end
	end
end

endmodule

module uart_core (
	input clk_i,
	input rst_i,
	input [15:0] baud_rate_i,
	input [3:0] tx_data_i,
	input tx_valid_i,
	output tx_ready_o,
	output [3:0] rx_data_o,
	output rx_valid_o,
	output int_o,
	output stx_pad_o,
	input srx_pad_i
);

reg [3:0] tx_data_reg;
reg tx_valid_reg;
reg tx_ready_reg;
reg [15:0] baud_counter;
reg [15:0] baud_divider;
reg [15:0] baud_divider_reg;
reg tx_bit_counter;
reg [3:0] tx_shift_reg;
reg tx_shift_reg_empty;
reg rx_bit_counter;
reg [3:0] rx_shift_reg;
reg rx_shift_reg_full;
reg rx_data_valid;
reg rx_data_valid_reg;

always @(posedge clk_i or posedge rst_i) begin
	if (rst_i) begin
		tx_data_reg <= 4'b0;
		tx_valid_reg <= 1'b0;
		tx_ready_reg <= 1'b1;
		baud_counter <= 16'b0;
		baud_divider_reg <= 16'd12; // Default baud rate divisor
		tx_bit_counter <= 4'b0;
		tx_shift_reg <= 4'b0;
		tx_shift_reg_empty <= 1'b1;
		rx_bit_counter <= 4'b0;
		rx_shift_reg <= 4'b0;
		rx_shift_reg_full <= 1'b0;
		rx_data_valid <= 1'b0;
		rx_data_valid_reg <= 1'b0;
	end else begin
		if (tx_valid_i && tx_ready_reg) begin
			tx_data_reg <= tx_data_i;
			tx_valid_reg <= 1'b1;
			tx_ready_reg <= 1'b0;
			tx_shift_reg <= {tx_data_reg, 1'b0}; // Start bit
			tx_shift_reg_empty <= 1'b0;
			tx_bit_counter <= 4'b0;
		end

		if (tx_valid_reg) begin
			if (baud_counter == baud_divider_reg) begin
				baud_counter <= 16'b0;
				if (tx_bit_counter < 5) begin
					stx_pad_o <= tx_shift_reg[0];
					tx_shift_reg <= {1'b1, tx_shift_reg[3:1]};
					tx_bit_counter <= tx_bit_counter + 1;
				end else begin
					tx_valid_reg <= 1'b0;
					tx_ready_reg <= 1'b1;
				end
			end else begin
				baud_counter <= baud_counter + 1;
			end
		end else begin
			stx_pad_o <= 1'b1; // Idle state
		end

		baud_divider_reg <= baud_rate_i;

		if (srx_pad_i == 1'b0 && !rx_shift_reg_full) begin
			if (baud_counter == baud_divider_reg) begin
				baud_counter <= 16'b0;
				if (rx_bit_counter < 5) begin
					if (rx_bit_counter == 0) begin
						rx_shift_reg <= {srx_pad_i, rx_shift_reg[3:1]};
					end else begin
						rx_shift_reg <= {rx_shift_reg[3], srx_pad_i, rx_shift_reg[2:1]};
					end
					rx_bit_counter <= rx_bit_counter + 1;
				end else begin
					rx_shift_reg_full <= 1'b1;
					rx_data_valid <= 1'b1;
				end
			end else begin
				baud_counter <= baud_counter + 1;
			end
		end else if (rx_shift_reg_full && !rx_data_valid_reg) begin
			rx_data_valid_reg <= 1'b1;
			rx_data_valid <= 1'b0;
		end else if (rx_data_valid_reg) begin
			rx_data_valid_reg <= 1'b0;
			rx_shift_reg_full <= 1'b0;
			rx_bit_counter <= 4'b0;
		end
	end
end

assign tx_ready_o = tx_ready_reg;
assign rx_data_o = rx_shift_reg[3:0];
assign rx_valid_o = rx_data_valid_reg;
assign int_o = rx_data_valid_reg; // Simplified interrupt signal

endmodule

module modem_control (
	input clk_i,
	input rst_i,
	output rts_o,
	input cts_i,
	output dtr_o,
	input dsr_i,
	input ri_i,
	input dcd_i,
	input rts_i,
	output cts_o,
	input dtr_i,
	output dsr_o,
	output ri_o,
	output dcd_o
);

reg rts_reg;
reg dtr_reg;

always @(posedge clk_i or posedge rst_i) begin
	if (rst_i) begin
		rts_reg <= 1'b0;
		dtr_reg <= 1'b0;
	end else begin
		rts_reg <= rts_i;
		dtr_reg <= dtr_i;
	end
end

assign rts_o = rts_reg;
assign dtr_o = dtr_reg;
assign cts_o = cts_i;
assign dsr_o = dsr_i;
assign ri_o = ri_i;
assign dcd_o = dcd_i;

endmodule
