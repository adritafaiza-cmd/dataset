module uart_top (
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire [3:0] wb_adr_i,
	input wire [7:0] wb_dat_i,
	output reg [7:0] wb_dat_o,
	input wire wb_we_i,
	input wire wb_stb_i,
	input wire wb_cyc_i,
	output reg wb_ack_o,
	input wire wb_sel_i,
	output reg int_o,
	output reg stx_pad_o,
	input wire srx_pad_i,
	output reg rts_pad_o,
	input wire cts_pad_i,
	output reg dtr_pad_o,
	input wire dsr_pad_i,
	input wire ri_pad_i,
	input wire dcd_pad_i
);

reg [7:0] tx_data;
reg tx_ready;
reg [7:0] rx_data;
reg rx_valid;

wire tx_clk = wb_clk_i; // Assuming tx_clk is the same as wb_clk_i for simplicity
wire rx_clk = wb_clk_i; // Assuming rx_clk is the same as wb_clk_i for simplicity

wishbone_slave wb_slave_inst (
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
	.tx_data(tx_data),
	.tx_ready(tx_ready),
	.rx_data(rx_data),
	.rx_valid(rx_valid)
);

uart_transmitter tx_inst (
	.wb_clk_i(wb_clk_i),
	.wb_rst_i(wb_rst_i),
	.tx_clk(tx_clk),
	.stx_pad_o(stx_pad_o),
	.tx_data(tx_data),
	.tx_ready(tx_ready)
);

uart_receiver rx_inst (
	.wb_clk_i(wb_clk_i),
	.wb_rst_i(wb_rst_i),
	.rx_clk(rx_clk),
	.srx_pad_i(srx_pad_i),
	.rx_data(rx_data),
	.rx_valid(rx_valid)
);

modem_control modem_ctrl_inst (
	.wb_clk_i(wb_clk_i),
	.wb_rst_i(wb_rst_i),
	.rts_pad_o(rts_pad_o),
	.dtr_pad_o(dtr_pad_o),
	.cts_pad_i(cts_pad_i),
	.dsr_pad_i(dsr_pad_i),
	.ri_pad_i(ri_pad_i),
	.dcd_pad_i(dcd_pad_i)
);

interrupt_controller int_ctrl_inst (
	.wb_clk_i(wb_clk_i),
	.wb_rst_i(wb_rst_i),
	.tx_ready(tx_ready),
	.rx_valid(rx_valid),
	.int_o(int_o)
);

endmodule

module wishbone_slave (
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire [3:0] wb_adr_i,
	input wire [7:0] wb_dat_i,
	output reg [7:0] wb_dat_o,
	input wire wb_we_i,
	input wire wb_stb_i,
	input wire wb_cyc_i,
	output reg wb_ack_o,
	input wire wb_sel_i,
	output reg [7:0] tx_data,
	input wire tx_ready,
	input wire [7:0] rx_data,
	input wire rx_valid
);

reg [7:0] rhr; // Receiver Holding Register
reg [7:0] thr; // Transmitter Holding Register
reg [7:0] ier; // Interrupt Enable Register
reg [7:0] iir; // Interrupt Identification Register
reg [7:0] fcr; // FIFO Control Register
reg [7:0] lcr; // Line Control Register
reg [7:0] mcr; // Modem Control Register
reg [7:0] lsr; // Line Status Register
reg [7:0] msr; // Modem Status Register
reg [7:0] scr; // Scratch Register

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		rhr <= 8'b0;
		thr <= 8'b0;
		ier <= 8'b0;
		iir <= 8'b1; // Set bit 0 to indicate no interrupt pending
		fcr <= 8'b0;
		lcr <= 8'b0;
		mcr <= 8'b0;
		lsr <= 8'b0;
		msr <= 8'b0;
		scr <= 8'b0;
	end else if (wb_cyc_i && wb_stb_i && wb_sel_i) begin
		if (wb_we_i) begin
			case (wb_adr_i)
				4'h0: thr <= wb_dat_i;
				4'h1: ier <= wb_dat_i;
				4'h2: fcr <= wb_dat_i;
				4'h3: lcr <= wb_dat_i;
				4'h4: mcr <= wb_dat_i;
				4'h7: scr <= wb_dat_i;
				default: ;
			endcase
		end else begin
			case (wb_adr_i)
				4'h0: wb_dat_o <= rhr;
				4'h1: wb_dat_o <= iir;
				4'h2: wb_dat_o <= fcr;
				4'h3: wb_dat_o <= lcr;
				4'h4: wb_dat_o <= mcr;
				4'h5: wb_dat_o <= lsr;
				4'h6: wb_dat_o <= msr;
				4'h7: wb_dat_o <= scr;
				default: wb_dat_o <= 8'b0;
			endcase
		end
		wb_ack_o <= 1'b1;
	end else begin
		wb_ack_o <= 1'b0;
	end
end

assign tx_data = thr;

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		lsr[5] <= 1'b0; // Clear THRE
	end else if (tx_ready) begin
		lsr[5] <= 1'b1; // Set THRE
	end
end

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		lsr[0] <= 1'b0; // Clear DR
	end else if (rx_valid) begin
		lsr[0] <= 1'b1; // Set DR
	end
end

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		rhr <= 8'b0;
	end else if (rx_valid) begin
		rhr <= rx_data;
	end
end

endmodule

module uart_transmitter (
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire tx_clk,
	output reg stx_pad_o,
	input wire [7:0] tx_data,
	output reg tx_ready
);

reg [3:0] bit_cnt;
reg [7:0] tx_shift_reg;
reg tx_start;
reg tx_busy;

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		bit_cnt <= 4'd0;
		tx_shift_reg <= 8'b0;
		tx_start <= 1'b0;
		tx_busy <= 1'b0;
		stx_pad_o <= 1'b1; // Idle state
		tx_ready <= 1'b1;
	end else begin
		if (tx_start && !tx_busy) begin
			tx_busy <= 1'b1;
			tx_ready <= 1'b0;
			tx_shift_reg <= {1'b0, tx_data, 1'b1}; // Start bit, data, stop bit
			bit_cnt <= 4'd0;
			stx_pad_o <= tx_shift_reg[0];
		end else if (tx_busy) begin
			bit_cnt <= bit_cnt + 1;
			stx_pad_o <= tx_shift_reg[0];
			tx_shift_reg <= {1'b1, tx_shift_reg[7:1]};
			if (bit_cnt == 4'd9) begin // 8 data bits + 1 stop bit
				tx_busy <= 1'b0;
				tx_ready <= 1'b1;
			end
		end
	end
end

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		tx_start <= 1'b0;
	end else if (tx_ready && !tx_busy) begin
		tx_start <= 1'b1;
	end else begin
		tx_start <= 1'b0;
	end
end

endmodule

module uart_receiver (
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire rx_clk,
	input wire srx_pad_i,
	output reg [7:0] rx_data,
	output reg rx_valid
);

reg [3:0] bit_cnt;
reg [7:0] rx_shift_reg;
reg rx_start;
reg rx_busy;

always @(posedge rx_clk or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		bit_cnt <= 4'd0;
		rx_shift_reg <= 8'b0;
		rx_start <= 1'b0;
		rx_busy <= 1'b0;
		rx_data <= 8'b0;
		rx_valid <= 1'b0;
	end else begin
		if (!rx_busy && !srx_pad_i) begin // Start bit detection
			rx_busy <= 1'b1;
			bit_cnt <= 4'd0;
			rx_start <= 1'b1;
		end else if (rx_busy) begin
			if (rx_start) begin
				rx_start <= 1'b0;
			end else begin
				bit_cnt <= bit_cnt + 1;
				rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
				if (bit_cnt == 4'd8) begin // 8 data bits
					rx_data <= rx_shift_reg;
					rx_valid <= 1'b1;
				end else if (bit_cnt == 4'd9) begin // Stop bit
					rx_busy <= 1'b0;
					rx_valid <= 1'b0;
				end
			end
		end
	end
end

endmodule

module modem_control (
	input wire wb_clk_i,
	input wire wb_rst_i,
	output reg rts_pad_o,
	output reg dtr_pad_o,
	input wire cts_pad_i,
	input wire dsr_pad_i,
	input wire ri_pad_i,
	input wire dcd_pad_i
);

reg [7:0] mcr;
reg [7:0] msr;

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		mcr <= 8'b0;
		msr <= 8'b0;
		rts_pad_o <= 1'b1;
		dtr_pad_o <= 1'b1;
	end else begin
		mcr <= mcr; // Placeholder for MCR register writes
		dtr_pad_o <= mcr[0];
		rts_pad_o <= mcr[1];
		msr[4] <= cts_pad_i;
		msr[5] <= dsr_pad_i;
		msr[6] <= ri_pad_i;
		msr[7] <= dcd_pad_i;
	end
end

endmodule

module interrupt_controller (
	input wire wb_clk_i,
	input wire wb_rst_i,
	input wire tx_ready,
	input wire rx_valid,
	output reg int_o
);

reg [7:0] ier; // Interrupt Enable Register
reg [7:0] iir; // Interrupt Identification Register

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if (wb_rst_i) begin
		iir <= 8'b1; // Set bit 0 to indicate no interrupt pending
		int_o <= 1'b0;
	end else begin
		if (rx_valid && ier[0]) begin
			iir <= 8'b4; // Set bit 2 to indicate received data available
			int_o <= 1'b1;
		end else if (tx_ready && ier[1]) begin
			iir <= 8'b2; // Set bit 1 to indicate transmitter holding register empty
			int_o <= 1'b1;
		end else begin
			iir <= 8'b1; // No interrupt pending
			int_o <= 1'b0;
		end
	end
end

endmodule
