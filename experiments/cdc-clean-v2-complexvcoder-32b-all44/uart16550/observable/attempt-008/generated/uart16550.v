module uart_top (
	input  wire        wb_clk_i,
	input  wire        wb_rst_i,
	input  wire [7:0]  wb_adr_i,
	input  wire [31:0] wb_dat_i,
	output wire [31:0] wb_dat_o,
	input  wire        wb_we_i,
	input  wire        wb_stb_i,
	input  wire        wb_cyc_i,
	output wire        wb_ack_o,
	input  wire [3:0]  wb_sel_i,
	output wire        int_o,
	output wire        stx_pad_o,
	input  wire        srx_pad_i,
	output wire        rts_pad_o,
	input  wire        cts_pad_i,
	output wire        dtr_pad_o,
	input  wire        dsr_pad_i,
	input  wire        ri_pad_i,
	input  wire        dcd_pad_i
);

reg [31:0] wb_dat_o_reg;
wire [7:0] tx_data_o;
wire       tx_start_o;
wire       tx_ready_i;
wire [7:0] rx_data_i;
wire       rx_ready_o;
wire       rx_full_i;
wire       int_clear_i;
wire       int_status_o;

// Wishbone Register Bank
wishbone_register_bank wb_reg_bank (
	.clk_i       (wb_clk_i),
	.rst_i       (wb_rst_i),
	.adr_i       (wb_adr_i),
	.dat_i       (wb_dat_i),
	.dat_o       (wb_dat_o_reg),
	.we_i        (wb_we_i),
	.stb_i       (wb_stb_i),
	.cyc_i       (wb_cyc_i),
	.ack_o       (wb_ack_o),
	.sel_i       (wb_sel_i),
	.tx_data_o   (tx_data_o),
	.tx_start_o  (tx_start_o),
	.tx_ready_i  (tx_ready_i),
	.rx_data_i   (rx_data_i),
	.rx_ready_o  (rx_ready_o),
	.rx_full_i   (rx_full_i),
	.int_clear_i (int_clear_i),
	.int_status_o(int_status_o)
);

// UART Transmitter
uart_transmitter tx (
	.clk_i   (wb_clk_i),
	.rst_i   (wb_rst_i),
	.data_i  (tx_data_o),
	.start_i (tx_start_o),
	.ready_o (tx_ready_i),
	.tx_o    (stx_pad_o)
);

// UART Receiver
uart_receiver rx (
	.clk_i   (wb_clk_i),
	.rst_i   (wb_rst_i),
	.rx_i    (srx_pad_i),
	.data_o  (rx_data_i),
	.ready_i (rx_ready_o),
	.full_o  (rx_full_i)
);

// Modem Status
modem_status modem_stat (
	.clk_i (wb_clk_i),
	.rst_i (wb_rst_i),
	.cts_i (cts_pad_i),
	.dsr_i (dsr_pad_i),
	.ri_i  (ri_pad_i),
	.dcd_i (dcd_pad_i),
	.rts_o (rts_pad_o),
	.dtr_o (dtr_pad_o)
);

// Interrupt Controller
interrupt_controller int_ctrl (
	.clk_i      (wb_clk_i),
	.rst_i      (wb_rst_i),
	.clear_i    (int_clear_i),
	.status_o   (int_status_o),
	.int_o      (int_o)
);

assign wb_dat_o = wb_dat_o_reg;

endmodule

// Wishbone Register Bank
module wishbone_register_bank (
	input  wire        clk_i,
	input  wire        rst_i,
	input  wire [7:0]  adr_i,
	input  wire [31:0] dat_i,
	output wire [31:0] dat_o,
	input  wire        we_i,
	input  wire        stb_i,
	input  wire        cyc_i,
	output wire        ack_o,
	input  wire [3:0]  sel_i,
	output wire [7:0]  tx_data_o,
	output wire        tx_start_o,
	input  wire        tx_ready_i,
	input  wire [7:0]  rx_data_i,
	output wire        rx_ready_o,
	output wire        rx_full_i,
	input  wire        int_clear_i,
	output wire        int_status_o
);

reg [31:0] registers [0:15]; // Assuming 16 registers for UART
reg [31:0] dat_o_reg;
reg        ack_o_reg;

// UART Register Addresses
parameter RX_BUFFER = 8'h00;
parameter TX_HOLDING = 8'h00;
parameter INT_ENABLE = 8'h01;
parameter INT_ID_FIFO = 8'h02;
parameter FIFO_CTRL = 8'h02;
parameter LINE_CTRL = 8'h03;
parameter MODEM_CTRL = 8'h04;
parameter LINE_STATUS = 8'h05;
parameter MODEM_STATUS = 8'h06;
parameter SCRATCH = 8'h07;

reg [7:0] tx_data_o_reg;
reg       tx_start_o_reg;
reg       rx_ready_o_reg;
reg       rx_full_o_reg;
reg       int_status_o_reg;

always @(posedge clk_i or posedge rst_i) begin
	if (rst_i) begin
		dat_o_reg <= 32'h0;
		ack_o_reg <= 1'b0;
		tx_data_o_reg <= 8'h0;
		tx_start_o_reg <= 1'b0;
		rx_ready_o_reg <= 1'b0;
		rx_full_o_reg <= 1'b0;
		int_status_o_reg <= 1'b0;
	end else begin
		ack_o_reg <= cyc_i & stb_i;
		dat_o_reg <= 32'h0;

		if (cyc_i & stb_i) begin
			if (we_i) begin
				case (adr_i)
					TX_HOLDING: begin
						tx_data_o_reg <= dat_i[7:0];
						tx_start_o_reg <= 1'b1;
					end
					INT_ENABLE: begin
						registers[adr_i] <= dat_i;
					end
					FIFO_CTRL: begin
						registers[adr_i] <= dat_i;
					end
					LINE_CTRL: begin
						registers[adr_i] <= dat_i;
					end
					MODEM_CTRL: begin
						registers[adr_i] <= dat_i;
					end
					SCRATCH: begin
						registers[adr_i] <= dat_i;
					end
				endcase
			end else begin
				case (adr_i)
					RX_BUFFER: begin
						dat_o_reg <= {24'h0, rx_data_i};
						rx_ready_o_reg <= 1'b1;
					end
					INT_ID_FIFO: begin
						dat_o_reg <= registers[adr_i];
					end
					INT_ENABLE: begin
						dat_o_reg <= registers[adr_i];
					end
					FIFO_CTRL: begin
						dat_o_reg <= registers[adr_i];
					end
					LINE_CTRL: begin
						dat_o_reg <= registers[adr_i];
					end
					MODEM_STATUS: begin
						dat_o_reg <= registers[adr_i];
					end
					LINE_STATUS: begin
						dat_o_reg <= registers[adr_i];
					end
					SCRATCH: begin
						dat_o_reg <= registers[adr_i];
					end
				endcase
			end
		end

		if (tx_ready_i) begin
			tx_start_o_reg <= 1'b0;
		end

		if (int_clear_i) begin
			int_status_o_reg <= 1'b0;
		end else begin
			int_status_o_reg <= int_status_o_reg | int_status_o;
		end
	end
end

assign dat_o = dat_o_reg;
assign ack_o = ack_o_reg;
assign tx_data_o = tx_data_o_reg;
assign tx_start_o = tx_start_o_reg;
assign rx_ready_o = rx_ready_o_reg;
assign rx_full_o = rx_full_o_reg;
assign int_status_o = int_status_o_reg;

endmodule

// UART Transmitter
module uart_transmitter (
	input  wire clk_i,
	input  wire rst_i,
	input  wire [7:0] data_i,
	input  wire start_i,
	output wire ready_o,
	output wire tx_o
);

reg [3:0] bit_cnt;
reg [7:0] data_reg;
reg       shift_reg;
reg       tx_o_reg;
reg       ready_o_reg;

always @(posedge clk_i or posedge rst_i) begin
	if (rst_i) begin
		bit_cnt <= 4'h0;
		data_reg <= 8'h0;
		shift_reg <= 1'b1; // Idle state, line high
		tx_o_reg <= 1'b1;
		ready_o_reg <= 1'b1;
	end else begin
		if (start_i && ready_o_reg) begin
			data_reg <= data_i;
			shift_reg <= 1'b0; // Start bit
			bit_cnt <= 4'h0;
			tx_o_reg <= 1'b0;
			ready_o_reg <= 1'b0;
		end else if (!shift_reg) begin
			if (bit_cnt < 8) begin
				shift_reg <= data_reg[0];
				data_reg <= {data_reg[6:0], 1'b0};
				bit_cnt <= bit_cnt + 1;
			end else if (bit_cnt == 8) begin
				shift_reg <= 1'b1; // Stop bit
				bit_cnt <= bit_cnt + 1;
			end else begin
				shift_reg <= 1'b1; // Idle state, line high
				tx_o_reg <= 1'b1;
				ready_o_reg <= 1'b1;
			end
		end
	end
end

assign tx_o = tx_o_reg;
assign ready_o = ready_o_reg;

endmodule

// UART Receiver
module uart_receiver (
	input  wire clk_i,
	input  wire rst_i,
	input  wire rx_i,
	output wire [7:0] data_o,
	input  wire ready_i,
	output wire full_o
);

reg [3:0] bit_cnt;
reg [7:0] data_reg;
reg       shift_reg;
reg       full_o_reg;
reg [7:0] rx_buffer;

always @(posedge clk_i or posedge rst_i) begin
	if (rst_i) begin
		bit_cnt <= 4'h0;
		data_reg <= 8'h0;
		shift_reg <= 1'b1; // Idle state, line high
		full_o_reg <= 1'b0;
		rx_buffer <= 8'h0;
	end else begin
		if (!rx_i && shift_reg) begin // Start bit detected
			bit_cnt <= 4'h0;
			shift_reg <= 1'b0;
			full_o_reg <= 1'b0;
		end else if (!shift_reg) begin
			if (bit_cnt < 8) begin
				data_reg <= {data_reg[6:0], rx_i};
				bit_cnt <= bit_cnt + 1;
			end else if (bit_cnt == 8) begin
				if (ready_i) begin
					rx_buffer <= data_reg;
					full_o_reg <= 1'b0;
				end else begin
					full_o_reg <= 1'b1;
				end
				shift_reg <= rx_i; // Wait for stop bit
			end else begin
				shift_reg <= rx_i; // Idle state, line high
			end
		end
	end
end

assign data_o = rx_buffer;
assign full_o = full_o_reg;

endmodule

// Modem Status
module modem_status (
	input  wire clk_i,
	input  wire rst_i,
	input  wire cts_i,
	input  wire dsr_i,
	input  wire ri_i,
	input  wire dcd_i,
	output wire rts_o,
	output wire dtr_o
);

reg rts_o_reg;
reg dtr_o_reg;

always @(posedge clk_i or posedge rst_i) begin
	if (rst_i) begin
		rts_o_reg <= 1'b0;
		dtr_o_reg <= 1'b0;
	end else begin
		// Simple logic for RTS and DTR, can be modified as per UART configuration
		rts_o_reg <= cts_i;
		dtr_o_reg <= 1'b1; // Always set DTR high for simplicity
	end
end

assign rts_o = rts_o_reg;
assign dtr_o = dtr_o_reg;

endmodule

// Interrupt Controller
module interrupt_controller (
	input  wire clk_i,
	input  wire rst_i,
	input  wire clear_i,
	input  wire status_o,
	output wire int_o
);

reg int_o_reg;

always @(posedge clk_i or posedge rst_i) begin
	if (rst_i) begin
		int_o_reg <= 1'b0;
	end else begin
		if (clear_i) begin
			int_o_reg <= 1'b0;
		end else if (status_o) begin
			int_o_reg <= 1'b1;
		end
	end
end

assign int_o = int_o_reg;

endmodule
