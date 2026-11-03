module uart_top (
    input  wire wb_clk_i,
    input  wire wb_rst_i,
    input  wire [7:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    input  wire wb_we_i,
    input  wire wb_stb_i,
    input  wire wb_cyc_i,
    output reg wb_ack_o,
    input  wire [3:0] wb_sel_i,
    output reg int_o,
    output reg stx_pad_o,
    input  wire srx_pad_i,
    output reg rts_pad_o,
    input  wire cts_pad_i,
    output reg dtr_pad_o,
    input  wire dsr_pad_i,
    input  wire ri_pad_i,
    input  wire dcd_pad_i
);

    reg [7:0] rx_data;
    reg rx_full;
    reg tx_empty;
    reg rx_timeout;
    reg [15:0] divisor_latch;
    reg [7:0] line_control;
    reg [7:0] modem_control;
    reg [7:0] line_status;
    reg [7:0] modem_status;
    reg [7:0] scratch_pad;
    reg [7:0] tx_data;

    uart_wishbone_interface wb_if (
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
        .rx_full(rx_full),
        .tx_empty(tx_empty),
        .rx_timeout(rx_timeout),
        .int_o(int_o),
        .divisor_latch(divisor_latch),
        .line_control(line_control),
        .modem_control(modem_control),
        .line_status(line_status),
        .modem_status(modem_status),
        .scratch_pad(scratch_pad),
        .tx_data(tx_data)
    );

    uart_transmitter tx (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .tx_data(tx_data),
        .tx_empty(tx_empty),
        .line_control(line_control),
        .modem_control(modem_control),
        .stx_pad_o(stx_pad_o)
    );

    uart_receiver rx (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .srx_pad_i(srx_pad_i),
        .rx_data(rx_data),
        .rx_full(rx_full),
        .rx_timeout(rx_timeout),
        .line_control(line_control),
        .line_status(line_status)
    );

    modem_control_unit modem_ctrl (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .modem_control(modem_control),
        .rts_pad_o(rts_pad_o),
        .dtr_pad_o(dtr_pad_o),
        .dsr_pad_i(dsr_pad_i),
        .ri_pad_i(ri_pad_i),
        .dcd_pad_i(dcd_pad_i),
        .modem_status(modem_status)
    );

endmodule

module uart_wishbone_interface (
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire [7:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    input wire wb_we_i,
    input wire wb_stb_i,
    input wire wb_cyc_i,
    output reg wb_ack_o,
    input wire [3:0] wb_sel_i,
    input wire [7:0] rx_data,
    input wire rx_full,
    input wire tx_empty,
    input wire rx_timeout,
    output reg int_o,
    output reg [15:0] divisor_latch,
    output reg [7:0] line_control,
    output reg [7:0] modem_control,
    output reg [7:0] line_status,
    output reg [7:0] modem_status,
    output reg [7:0] scratch_pad,
    output reg [7:0] tx_data
);

    reg [7:0] thr; // Transmitter Holding Register
    reg [7:0] ier; // Interrupt Enable Register
    reg [7:0] fcr; // FIFO Control Register
    reg [7:0] lcr; // Line Control Register
    reg [7:0] mcr; // Modem Control Register
    reg [7:0] lsr; // Line Status Register
    reg [7:0] msr; // Modem Status Register
    reg [7:0] spr; // Scratch Pad Register

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_dat_o <= 32'b0;
            wb_ack_o <= 1'b0;
            int_o <= 1'b0;
            divisor_latch <= 16'b0;
            line_control <= 8'b0;
            modem_control <= 8'b0;
            line_status <= 8'b0;
            modem_status <= 8'b0;
            scratch_pad <= 8'b0;
            tx_data <= 8'b0;
        end else if (wb_cyc_i && wb_stb_i) begin
            wb_ack_o <= 1'b1;
            if (wb_we_i) begin
                case (wb_adr_i)
                    8'h00: begin // THR
                        if (lcr[7]) begin // Divisor Latch Access Bit
                            divisor_latch[7:0] <= wb_dat_i[7:0];
                        end else begin
                            tx_data <= wb_dat_i[7:0];
                        end
                    end
                    8'h01: begin // IER
                        if (lcr[7]) begin // Divisor Latch Access Bit
                            divisor_latch[15:8] <= wb_dat_i[7:0];
                        end else begin
                            ier <= wb_dat_i[7:0];
                        end
                    end
                    8'h02: begin // FCR
                        fcr <= wb_dat_i[7:0];
                    end
                    8'h03: begin // LCR
                        lcr <= wb_dat_i[7:0];
                    end
                    8'h04: begin // MCR
                        mcr <= wb_dat_i[7:0];
                    end
                    8'h07: begin // SPR
                        spr <= wb_dat_i[7:0];
                    end
                endcase
            end else begin
                wb_dat_o <= 32'b0;
                case (wb_adr_i)
                    8'h00: wb_dat_o[7:0] <= rx_data; // RBR
                    8'h01: wb_dat_o[7:0] <= ier; // IER
                    8'h02: wb_dat_o[7:0] <= fcr; // FCR
                    8'h03: wb_dat_o[7:0] <= lcr; // LCR
                    8'h04: wb_dat_o[7:0] <= mcr; // MCR
                    8'h05: wb_dat_o[7:0] <= lsr; // LSR
                    8'h06: wb_dat_o[7:0] <= msr; // MSR
                    8'h07: wb_dat_o[7:0] <= spr; // SPR
                endcase
            end
        end else begin
            wb_ack_o <= 1'b0;
        end
    end

    always @(*) begin
        int_o = 1'b0;
        if (ier[0] && lsr[0]) int_o = 1'b1; // Data Ready Interrupt
        if (ier[1] && lsr[6]) int_o = 1'b1; // Receiver Line Status Interrupt
        if (ier[2] && msr[0]) int_o = 1'b1; // Modem Status Interrupt
        if (ier[3] && lsr[5]) int_o = 1'b1; // Transmitter Holding Register Empty Interrupt
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            line_status <= 8'b0;
            modem_status <= 8'b0;
        end else begin
            // Update line_status based on rx_full, rx_timeout, etc.
            line_status <= {1'b0, rx_timeout, 1'b0, 1'b0, rx_full, 1'b0, 1'b0, tx_empty};
            // Update modem_status based on dsr_pad_i, ri_pad_i, dcd_pad_i
            modem_status <= {1'b0, dcd_pad_i, ri_pad_i, 1'b0, dsr_pad_i, mcr[0], mcr[1], 1'b0};
        end
    end

endmodule

module uart_transmitter (
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire [7:0] tx_data,
    output reg tx_empty,
    input wire [7:0] line_control,
    input wire [7:0] modem_control,
    output reg stx_pad_o
);

    reg [7:0] tx_fifo [0:15];
    reg [3:0] tx_fifo_wr_ptr;
    reg [3:0] tx_fifo_rd_ptr;
    reg tx_fifo_full;

    reg [15:0] bit_cnt;
    reg [7:0] tx_shift_reg;
    reg tx_shift_reg_empty;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_wr_ptr <= 4'b0;
            tx_fifo_rd_ptr <= 4'b0;
            tx_fifo_full <= 1'b0;
            tx_empty <= 1'b1;
        end else begin
            if (wb_stb_i && wb_we_i && !tx_fifo_full) begin
                tx_fifo[tx_fifo_wr_ptr] <= tx_data;
                tx_fifo_wr_ptr <= tx_fifo_wr_ptr + 1;
                if (tx_fifo_wr_ptr == tx_fifo_rd_ptr) begin
                    tx_fifo_full <= 1'b1;
                end
                tx_empty <= 1'b0;
            end
            if (tx_shift_reg_empty && !tx_fifo_empty) begin
                tx_shift_reg <= tx_fifo[tx_fifo_rd_ptr];
                tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 1;
                if (tx_fifo_wr_ptr == tx_fifo_rd_ptr) begin
                    tx_empty <= 1'b1;
                end
            end
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            bit_cnt <= 16'b0;
            tx_shift_reg_empty <= 1'b1;
            stx_pad_o <= 1'b1;
        end else begin
            if (tx_shift_reg_empty && !tx_fifo_empty) begin
                bit_cnt <= 16'(8 + line_control[1:0] + 1); // Start bit + data bits + stop bits
                tx_shift_reg_empty <= 1'b0;
                stx_pad_o <= 1'b0; // Start bit
            end else if (!tx_shift_reg_empty) begin
                bit_cnt <= bit_cnt - 1;
                stx_pad_o <= tx_shift_reg[0];
                tx_shift_reg <= {tx_shift_reg[6:0], 1'b1};
                if (bit_cnt == 16'b1) begin
                    tx_shift_reg_empty <= 1'b1;
                end
            end
        end
    end

endmodule

module uart_receiver (
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire srx_pad_i,
    output reg [7:0] rx_data,
    output reg rx_full,
    output reg rx_timeout,
    input wire [7:0] line_control,
    output reg [7:0] line_status
);

    reg [7:0] rx_fifo [0:15];
    reg [3:0] rx_fifo_wr_ptr;
    reg [3:0] rx_fifo_rd_ptr;
    reg rx_fifo_empty;

    reg [15:0] bit_cnt;
    reg [7:0] rx_shift_reg;
    reg rx_shift_reg_full;

    reg start_bit_detected;
    reg stop_bit_detected;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_fifo_wr_ptr <= 4'b0;
            rx_fifo_rd_ptr <= 4'b0;
            rx_fifo_empty <= 1'b1;
            rx_full <= 1'b0;
            rx_timeout <= 1'b0;
            start_bit_detected <= 1'b0;
            stop_bit_detected <= 1'b0;
        end else begin
            if (start_bit_detected && !stop_bit_detected) begin
                bit_cnt <= 16'(8 + line_control[1:0] + 1); // Start bit + data bits + stop bits
                rx_shift_reg_full <= 1'b0;
            end else if (!rx_shift_reg_full) begin
                bit_cnt <= bit_cnt - 1;
                rx_shift_reg <= {rx_shift_reg[6:0], srx_pad_i};
                if (bit_cnt == 16'b1) begin
                    rx_shift_reg_full <= 1'b1;
                    stop_bit_detected <= 1'b1;
                end
            end
            if (stop_bit_detected && !rx_fifo_full) begin
                rx_fifo[rx_fifo_wr_ptr] <= rx_shift_reg;
                rx_fifo_wr_ptr <= rx_fifo_wr_ptr + 1;
                if (rx_fifo_wr_ptr == rx_fifo_rd_ptr) begin
                    rx_fifo_full <= 1'b1;
                end
                stop_bit_detected <= 1'b0;
            end
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_data <= 8'b0;
        end else if (!rx_fifo_empty) begin
            rx_data <= rx_fifo[rx_fifo_rd_ptr];
            rx_fifo_rd_ptr <= rx_fifo_rd_ptr + 1;
            if (rx_fifo_wr_ptr == rx_fifo_rd_ptr) begin
                rx_fifo_empty <= 1'b1;
            end
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            start_bit_detected <= 1'b0;
        end else begin
            if (!srx_pad_i) begin // Detect start bit
                start_bit_detected <= 1'b1;
            end
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            line_status <= 8'b0;
            rx_timeout <= 1'b0;
        end else begin
            // Update line_status based on rx_full, rx_timeout, etc.
            line_status <= {1'b0, rx_timeout, 1'b0, 1'b0, rx_full, 1'b0, 1'b0, 1'b0};
            // Handle rx_timeout detection
            if (start_bit_detected && !stop_bit_detected && (bit_cnt == 16'b0)) begin
                rx_timeout <= 1'b1;
            end else begin
                rx_timeout <= 1'b0;
            end
        end
    end

endmodule

module modem_control_unit (
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire [7:0] modem_control,
    output reg rts_pad_o,
    output reg dtr_pad_o,
    input wire dsr_pad_i,
    input wire ri_pad_i,
    input wire dcd_pad_i,
    output reg [7:0] modem_status
);

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rts_pad_o <= 1'b0;
            dtr_pad_o <= 1'b0;
            modem_status <= 8'b0;
        end else begin
            rts_pad_o <= modem_control[1];
            dtr_pad_o <= modem_control[0];
            modem_status <= {1'b0, dcd_pad_i, ri_pad_i, 1'b0, dsr_pad_i, modem_control[0], modem_control[1], 1'b0};
        end
    end

endmodule
