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

reg [31:0] wb_dat_o_reg;
reg wb_ack_o_reg;
reg [7:0] tx_data;
reg tx_strobe;
wire tx_ready;
reg [7:0] rx_data;
reg rx_strobe;
wire rx_ready;

// UART Clock and Reset Synchronization
reg uart_clk;
reg uart_rst;

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i)
		uart_clk <= 0;
	else
		uart_clk <= wb_clk_i;
end

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i)
		uart_rst <= 1;
	else
		uart_rst <= wb_rst_i;
end

// Wishbone Slave Interface
wire [31:0] wb_dat_o_wb_slave;
wire wb_ack_o_wb_slave;
wire [7:0] tx_data_wb_slave;
wire tx_strobe_wb_slave;
wire tx_ready_wb_slave;
wire [7:0] rx_data_wb_slave;
wire rx_strobe_wb_slave;
wire rx_ready_wb_slave;

wishbone_slave wb_slave_inst (
	.clk(wb_clk_i),
	.rst(wb_rst_i),
	.adr_i(wb_adr_i),
	.dat_i(wb_dat_i),
	.dat_o(wb_dat_o_wb_slave),
	.we_i(wb_we_i),
	.stb_i(wb_stb_i),
	.cyc_i(wb_cyc_i),
	.ack_o(wb_ack_o_wb_slave),
	.sel_i(wb_sel_i),
	.tx_data(tx_data_wb_slave),
	.tx_strobe(tx_strobe_wb_slave),
	.tx_ready(tx_ready_wb_slave),
	.rx_data(rx_data_wb_slave),
	.rx_strobe(rx_strobe_wb_slave),
	.rx_ready(rx_ready_wb_slave)
);

// UART Transmitter
uart_transmitter tx_inst (
	.clk(uart_clk),
	.rst(uart_rst),
	.data_i(tx_data),
	.strobe_i(tx_strobe),
	.ready_o(tx_ready),
	.stx_o(stx_pad_o)
);

// UART Receiver
uart_receiver rx_inst (
	.clk(uart_clk),
	.rst(uart_rst),
	.srx_i(srx_pad_i),
	.data_o(rx_data),
	.strobe_o(rx_strobe),
	.ready_i(rx_ready)
);

// Modem Controller
modem_controller modem_ctrl_inst (
	.clk(wb_clk_i),
	.rst(wb_rst_i),
	.dtr_o(dtr_pad_o),
	.rts_o(rts_pad_o),
	.cts_i(cts_pad_i),
	.dsr_i(dsr_pad_i),
	.ri_i(ri_pad_i),
	.dcd_i(dcd_pad_i)
);

// Internal Signal Connections
assign tx_data = tx_data_wb_slave;
assign tx_strobe = tx_strobe_wb_slave;
assign wb_dat_o = wb_dat_o_wb_slave;
assign wb_ack_o = wb_ack_o_wb_slave;
assign rx_ready = rx_ready_wb_slave;

// Interrupt Output
assign int_o = 0; // Placeholder for interrupt logic

endmodule

module wishbone_slave (
	input clk,
	input rst,
	input [7:0] adr_i,
	input [31:0] dat_i,
	output reg [31:0] dat_o,
	input we_i,
	input stb_i,
	input cyc_i,
	output reg ack_o,
	input [3:0] sel_i,
	output reg [7:0] tx_data,
	output reg tx_strobe,
	input tx_ready,
	input [7:0] rx_data,
	input rx_strobe,
	output reg rx_ready
);

reg [31:0] registers [0:15]; // 16 registers for 16550 UART

always @(posedge clk or posedge rst) begin
	if (rst) begin
		dat_o <= 0;
		ack_o <= 0;
		tx_data <= 0;
		tx_strobe <= 0;
		rx_ready <= 0;
	end else begin
		dat_o <= 0;
		ack_o <= 0;
		tx_strobe <= 0;
		if (cyc_i && stb_i) begin
			if (we_i) begin
				if (sel_i[0]) registers[adr_i][7:0] <= dat_i[7:0];
				if (sel_i[1]) registers[adr_i][15:8] <= dat_i[15:8];
				if (sel_i[2]) registers[adr_i][23:16] <= dat_i[23:16];
				if (sel_i[3]) registers[adr_i][31:24] <= dat_i[31:24];
				ack_o <= 1;
			end else begin
				dat_o <= registers[adr_i];
				ack_o <= 1;
			end
		end
		if (adr_i == 0 && we_i && sel_i[0]) begin // Transmit Holding Register
			tx_data <= dat_i[7:0];
			tx_strobe <= 1;
		end
		if (adr_i == 1 && !we_i) begin // Interrupt Enable Register
			dat_o <= {24'b0, registers[adr_i][7:0]};
		end
		if (adr_i == 2 && !we_i) begin // Interrupt Identification Register
			dat_o <= {24'b0, registers[adr_i][7:0]};
		end
		if (adr_i == 3 && !we_i) begin // FIFO Control Register
			dat_o <= {24'b0, registers[adr_i][7:0]};
		end
		if (adr_i == 4 && !we_i) begin // Line Control Register
			dat_o <= {24'b0, registers[adr_i][7:0]};
		end
		if (adr_i == 5 && !we_i) begin // Modem Control Register
			dat_o <= {24'b0, registers[adr_i][7:0]};
		end
		if (adr_i == 6 && !we_i) begin // Line Status Register
			dat_o <= {24'b0, registers[adr_i][7:0]};
		end
		if (adr_i == 7 && !we_i) begin // Modem Status Register
			dat_o <= {24'b0, registers[adr_i][7:0]};
		end
		if (adr_i == 8 && !we_i) begin // Scratch Register
			dat_o <= {24'b0, registers[adr_i][7:0]};
		end
		if (adr_i == 9 && !we_i) begin // Divisor Latch LSB
			dat_o <= {24'b0, registers[adr_i][7:0]};
		end
		if (adr_i == 10 && !we_i) begin // Divisor Latch MSB
			dat_o <= {24'b0, registers[adr_i][7:0]};
		end
		if (adr_i == 1 && we_i && sel_i[0]) begin // Interrupt Enable Register
			registers[adr_i][7:0] <= dat_i[7:0];
		end
		if (adr_i == 2 && we_i && sel_i[0]) begin // FIFO Control Register
			registers[adr_i][7:0] <= dat_i[7:0];
		end
		if (adr_i == 3 && we_i && sel_i[0]) begin // Line Control Register
			registers[adr_i][7:0] <= dat_i[7:0];
		end
		if (adr_i == 4 && we_i && sel_i[0]) begin // Modem Control Register
			registers[adr_i][7:0] <= dat_i[7:0];
		end
		if (adr_i == 8 && we_i && sel_i[0]) begin // Scratch Register
			registers[adr_i][7:0] <= dat_i[7:0];
		end
		if (adr_i == 9 && we_i && sel_i[0]) begin // Divisor Latch LSB
			registers[adr_i][7:0] <= dat_i[7:0];
		end
		if (adr_i == 10 && we_i && sel_i[0]) begin // Divisor Latch MSB
			registers[adr_i][7:0] <= dat_i[7:0];
		end
		if (adr_i == 0 && !we_i) begin // Receiver Buffer Register
			dat_o <= {24'b0, rx_data};
			rx_ready <= 1;
		end
	end
end

endmodule

module uart_transmitter (
	input clk,
	input rst,
	input [7:0] data_i,
	input strobe_i,
	output reg ready_o,
	output reg stx_o
);

reg [3:0] bit_cnt;
reg [7:0] data_reg;
reg start_tx;
reg [15:0] baud_cnt;
reg [15:0] baud_rate;

always @(posedge clk or posedge rst) begin
	if (rst) begin
		bit_cnt <= 0;
		data_reg <= 0;
		start_tx <= 0;
		baud_cnt <= 0;
		baud_rate <= 16'd10416; // 9600 baud rate for 50MHz clock
		ready_o <= 1;
		stx_o <= 1;
	end else begin
		if (strobe_i && ready_o) begin
			data_reg <= data_i;
			start_tx <= 1;
			ready_o <= 0;
		end
		if (start_tx) begin
			if (baud_cnt < baud_rate) begin
				baud_cnt <= baud_cnt + 1;
			end else begin
				baud_cnt <= 0;
				if (bit_cnt == 0) begin
					stx_o <= 0; // Start bit
					bit_cnt <= bit_cnt + 1;
				end else if (bit_cnt < 9) begin
					stx_o <= data_reg[bit_cnt-1];
					bit_cnt <= bit_cnt + 1;
				end else begin
					stx_o <= 1; // Stop bit
					bit_cnt <= 0;
					start_tx <= 0;
					ready_o <= 1;
				end
			end
		end
	end
end

endmodule

module uart_receiver (
	input clk,
	input rst,
	input srx_i,
	output reg [7:0] data_o,
	output reg strobe_o,
	input ready_i
);

reg [3:0] bit_cnt;
reg [15:0] baud_cnt;
reg [15:0] baud_rate;
reg sample;
reg [7:0] data_reg;

always @(posedge clk or posedge rst) begin
	if (rst) begin
		bit_cnt <= 0;
		baud_cnt <= 0;
		baud_rate <= 16'd10416; // 9600 baud rate for 50MHz clock
		sample <= 0;
		data_reg <= 0;
		data_o <= 0;
		strobe_o <= 0;
	end else begin
		if (baud_cnt < baud_rate) begin
			baud_cnt <= baud_cnt + 1;
		end else begin
			baud_cnt <= 0;
			sample <= srx_i;
			if (srx_i == 0 && bit_cnt == 0) begin // Start bit detection
				bit_cnt <= bit_cnt + 1;
			end else if (bit_cnt > 0 && bit_cnt < 9) begin
				data_reg[bit_cnt-1] <= sample;
				bit_cnt <= bit_cnt + 1;
			end else if (bit_cnt == 9 && sample == 1) begin // Stop bit detection
				data_o <= data_reg;
				strobe_o <= ready_i;
				bit_cnt <= 0;
			end
		end
	end
end

endmodule

module modem_controller (
	input clk,
	input rst,
	output reg dtr_o,
	output reg rts_o,
	input cts_i,
	input dsr_i,
	input ri_i,
	input dcd_i
);

reg [7:0] modem_control;

always @(posedge clk or posedge rst) begin
	if (rst) begin
		dtr_o <= 0;
		rts_o <= 0;
		modem_control <= 0;
	end else begin
		// Modem Control Register
		if (modem_control[6]) dtr_o <= 1;
		else dtr_o <= 0;
		if (modem_control[1]) rts_o <= 1;
		else rts_o <= 0;
	end
end

endmodule
