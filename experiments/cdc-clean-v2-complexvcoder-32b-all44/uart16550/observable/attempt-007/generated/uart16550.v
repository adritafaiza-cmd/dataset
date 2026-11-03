module uart_top (
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire [4:0]  wb_adr_i,
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

    // Internal signals
    reg [31:0] uart_ctrl_reg;
    reg [31:0] uart_stat_reg;
    reg [31:0] uart_tx_data_reg;
    reg [31:0] uart_rx_data_reg;
    reg [31:0] uart_divisor_reg;
    reg [31:0] uart_modem_ctrl_reg;
    reg [31:0] uart_line_ctrl_reg;
    reg [31:0] uart_fifo_ctrl_reg;
    reg [31:0] uart_fifo_stat_reg;
    reg [31:0] uart_irq_reg;
    wire       uart_tx_empty;
    wire       uart_rx_full;
    reg [31:0] uart_modem_stat_reg;

    // Wishbone slave interface
    uart_wb_slave wb_slave (
        .wb_clk_i            (wb_clk_i),
        .wb_rst_i            (wb_rst_i),
        .wb_adr_i            (wb_adr_i),
        .wb_dat_i            (wb_dat_i),
        .wb_dat_o            (wb_dat_o),
        .wb_we_i             (wb_we_i),
        .wb_stb_i            (wb_stb_i),
        .wb_cyc_i            (wb_cyc_i),
        .wb_ack_o            (wb_ack_o),
        .wb_sel_i            (wb_sel_i),
        .uart_ctrl_reg       (uart_ctrl_reg),
        .uart_stat_reg       (uart_stat_reg),
        .uart_tx_data_reg    (uart_tx_data_reg),
        .uart_rx_data_reg    (uart_rx_data_reg),
        .uart_divisor_reg    (uart_divisor_reg),
        .uart_modem_ctrl_reg (uart_modem_ctrl_reg),
        .uart_line_ctrl_reg  (uart_line_ctrl_reg),
        .uart_fifo_ctrl_reg  (uart_fifo_ctrl_reg),
        .uart_fifo_stat_reg  (uart_fifo_stat_reg),
        .uart_irq_reg        (uart_irq_reg)
    );

    // UART transmitter
    uart_tx tx (
        .wb_clk_i            (wb_clk_i),
        .wb_rst_i            (wb_rst_i),
        .uart_tx_data_reg    (uart_tx_data_reg),
        .uart_line_ctrl_reg  (uart_line_ctrl_reg),
        .uart_divisor_reg    (uart_divisor_reg),
        .stx_pad_o           (stx_pad_o),
        .uart_tx_empty       (uart_tx_empty)
    );

    // UART receiver
    uart_rx rx (
        .wb_clk_i            (wb_clk_i),
        .wb_rst_i            (wb_rst_i),
        .srx_pad_i           (srx_pad_i),
        .uart_rx_data_reg    (uart_rx_data_reg),
        .uart_line_ctrl_reg  (uart_line_ctrl_reg),
        .uart_divisor_reg    (uart_divisor_reg),
        .uart_fifo_ctrl_reg  (uart_fifo_ctrl_reg),
        .uart_fifo_stat_reg  (uart_fifo_stat_reg),
        .uart_rx_full        (uart_rx_full)
    );

    // UART modem
    uart_modem modem (
        .wb_clk_i            (wb_clk_i),
        .wb_rst_i            (wb_rst_i),
        .uart_modem_ctrl_reg (uart_modem_ctrl_reg),
        .rts_pad_o           (rts_pad_o),
        .cts_pad_i           (cts_pad_i),
        .dtr_pad_o           (dtr_pad_o),
        .dsr_pad_i           (dsr_pad_i),
        .ri_pad_i            (ri_pad_i),
        .dcd_pad_i           (dcd_pad_i),
        .uart_modem_stat_reg (uart_modem_stat_reg)
    );

    // UART interrupt
    uart_irq irq (
        .wb_clk_i            (wb_clk_i),
        .wb_rst_i            (wb_rst_i),
        .uart_stat_reg       (uart_stat_reg),
        .uart_irq_reg        (uart_irq_reg),
        .int_o               (int_o)
    );

    // Update status registers
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            uart_stat_reg <= 32'b0;
        end else begin
            uart_stat_reg[0] <= uart_tx_empty; // THRE (Transmit Holding Register Empty)
            uart_stat_reg[1] <= uart_rx_full;  // RDRF (Receive Data Register Full)
            uart_stat_reg[6] <= uart_modem_stat_reg[6]; // CTS
            uart_stat_reg[7] <= uart_modem_stat_reg[7]; // DSR
            uart_stat_reg[8] <= uart_modem_stat_reg[8]; // RI
            uart_stat_reg[9] <= uart_modem_stat_reg[9]; // DCD
        end
    end

endmodule

module uart_wb_slave (
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire [4:0]  wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output wire [31:0] wb_dat_o,
    input  wire        wb_we_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    output wire        wb_ack_o,
    input  wire [3:0]  wb_sel_i,
    inout  wire [31:0] uart_ctrl_reg,
    inout  wire [31:0] uart_stat_reg,
    inout  wire [31:0] uart_tx_data_reg,
    inout  wire [31:0] uart_rx_data_reg,
    inout  wire [31:0] uart_divisor_reg,
    inout  wire [31:0] uart_modem_ctrl_reg,
    inout  wire [31:0] uart_line_ctrl_reg,
    inout  wire [31:0] uart_fifo_ctrl_reg,
    inout  wire [31:0] uart_fifo_stat_reg,
    inout  wire [31:0] uart_irq_reg
);

    reg [31:0] wb_dat_o_reg;
    reg        wb_ack_o_reg;

    assign wb_dat_o = wb_dat_o_reg;
    assign wb_ack_o = wb_ack_o_reg;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_ack_o_reg <= 1'b0;
        end else begin
            wb_ack_o_reg <= wb_stb_i & wb_cyc_i;
        end
    end

    always @(posedge wb_clk_i) begin
        if (wb_stb_i & wb_cyc_i) begin
            case (wb_adr_i)
                5'b00000: begin // RBR/THR
                    if (wb_we_i) uart_tx_data_reg <= wb_dat_i;
                    else wb_dat_o_reg <= uart_rx_data_reg;
                end
                5'b00001: begin // IER
                    if (wb_we_i) uart_irq_reg <= wb_dat_i;
                    else wb_dat_o_reg <= uart_irq_reg;
                end
                5'b00010: begin // IIR
                    wb_dat_o_reg <= 32'b10000000000000000000000000000010; // Fixed value for IIR
                end
                5'b00011: begin // LCR
                    if (wb_we_i) uart_line_ctrl_reg <= wb_dat_i;
                    else wb_dat_o_reg <= uart_line_ctrl_reg;
                end
                5'b00100: begin // MCR
                    if (wb_we_i) uart_modem_ctrl_reg <= wb_dat_i;
                    else wb_dat_o_reg <= uart_modem_ctrl_reg;
                end
                5'b00101: begin // LSR
                    wb_dat_o_reg <= uart_stat_reg;
                end
                5'b00110: begin // MSR
                    wb_dat_o_reg <= uart_modem_stat_reg;
                end
                5'b00111: begin // SCR
                    if (wb_we_i) uart_ctrl_reg <= wb_dat_i;
                    else wb_dat_o_reg <= uart_ctrl_reg;
                end
                5'b01000: begin // DLL
                    if (wb_we_i) uart_divisor_reg[7:0] <= wb_dat_i[7:0];
                    else wb_dat_o_reg <= {24'b0, uart_divisor_reg[7:0]};
                end
                5'b01001: begin // DLM
                    if (wb_we_i) uart_divisor_reg[15:8] <= wb_dat_i[7:0];
                    else wb_dat_o_reg <= {24'b0, uart_divisor_reg[15:8]};
                end
                5'b10000: begin // FCR
                    if (wb_we_i) uart_fifo_ctrl_reg <= wb_dat_i;
                    else wb_dat_o_reg <= uart_fifo_ctrl_reg;
                end
                5'b10001: begin // FSR
                    wb_dat_o_reg <= uart_fifo_stat_reg;
                end
                default: begin
                    wb_dat_o_reg <= 32'b0;
                end
            endcase
        end
    end

endmodule

module uart_tx (
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire [31:0] uart_tx_data_reg,
    input  wire [31:0] uart_line_ctrl_reg,
    input  wire [31:0] uart_divisor_reg,
    output wire        stx_pad_o,
    output wire        uart_tx_empty
);

    reg [7:0]  tx_fifo [0:15];
    reg [3:0]  tx_fifo_head;
    reg [3:0]  tx_fifo_tail;
    reg        tx_fifo_empty;
    reg        tx_fifo_full;
    reg [7:0]  tx_shift_reg;
    reg [15:0] tx_bit_cnt;
    reg [15:0] tx_div_cnt;

    assign uart_tx_empty = tx_fifo_empty;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_head <= 4'b0;
            tx_fifo_tail <= 4'b0;
            tx_fifo_empty <= 1'b1;
            tx_fifo_full <= 1'b0;
        end else begin
            if (wb_we_i & (uart_line_ctrl_reg[0] & uart_tx_data_reg[0])) begin
                if (!tx_fifo_full) begin
                    tx_fifo[tx_fifo_head] <= uart_tx_data_reg[7:0];
                    tx_fifo_head <= tx_fifo_head + 1;
                    tx_fifo_empty <= 1'b0;
                    if (tx_fifo_head == tx_fifo_tail + 1)
                        tx_fifo_full <= 1'b1;
                end
            end
            if (tx_bit_cnt == 0) begin
                if (!tx_fifo_empty) begin
                    tx_shift_reg <= {1'b1, tx_fifo[tx_fifo_tail], 1'b0}; // Start bit, data, stop bit
                    tx_fifo_tail <= tx_fifo_tail + 1;
                    if (tx_fifo_head == tx_fifo_tail)
                        tx_fifo_empty <= 1'b1;
                    tx_fifo_full <= 1'b0;
                    tx_bit_cnt <= 16'd10; // 8 data bits + 1 start bit + 1 stop bit
                end
            end else begin
                tx_bit_cnt <= tx_bit_cnt - 1;
            end
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_div_cnt <= 16'd0;
            stx_pad_o <= 1'b1;
        end else begin
            if (tx_bit_cnt > 0) begin
                if (tx_div_cnt == uart_divisor_reg[15:0] - 1'b1) begin
                    tx_div_cnt <= 16'd0;
                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b1};
                    stx_pad_o <= tx_shift_reg[0];
                end else begin
                    tx_div_cnt <= tx_div_cnt + 1'b1;
                end
            end else begin
                stx_pad_o <= 1'b1;
            end
        end
    end

endmodule

module uart_rx (
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire        srx_pad_i,
    output wire [31:0] uart_rx_data_reg,
    input  wire [31:0] uart_line_ctrl_reg,
    input  wire [31:0] uart_divisor_reg,
    input  wire [31:0] uart_fifo_ctrl_reg,
    output wire [31:0] uart_fifo_stat_reg,
    output wire        uart_rx_full
);

    reg [7:0]  rx_fifo [0:15];
    reg [3:0]  rx_fifo_head;
    reg [3:0]  rx_fifo_tail;
    reg        rx_fifo_empty;
    reg        rx_fifo_full;
    reg [7:0]  rx_shift_reg;
    reg [15:0] rx_bit_cnt;
    reg [15:0] rx_div_cnt;
    reg        rx_sample;
    reg        rx_start;
    reg        rx_stop;

    assign uart_rx_full = rx_fifo_full;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_fifo_head <= 4'b0;
            rx_fifo_tail <= 4'b0;
            rx_fifo_empty <= 1'b1;
            rx_fifo_full <= 1'b0;
            rx_bit_cnt <= 16'd0;
            rx_div_cnt <= 16'd0;
            rx_sample <= 1'b1;
            rx_start <= 1'b0;
            rx_stop <= 1'b0;
        end else begin
            if (rx_div_cnt == uart_divisor_reg[15:0] - 1'b1) begin
                rx_div_cnt <= 16'd0;
                if (rx_start) begin
                    rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                    rx_bit_cnt <= rx_bit_cnt + 1'b1;
                    if (rx_bit_cnt == 8) begin
                        rx_fifo[rx_fifo_head] <= rx_shift_reg;
                        rx_fifo_head <= rx_fifo_head + 1;
                        rx_fifo_empty <= 1'b0;
                        if (rx_fifo_head == rx_fifo_tail + 1)
                            rx_fifo_full <= 1'b1;
                        rx_start <= 1'b0;
                    end
                end else begin
                    if (srx_pad_i == 1'b0) begin
                        rx_start <= 1'b1;
                        rx_bit_cnt <= 16'd0;
                    end
                end
            end else begin
                rx_div_cnt <= rx_div_cnt + 1'b1;
            end
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            uart_fifo_stat_reg <= 32'b0;
        end else begin
            uart_fifo_stat_reg[0] <= rx_fifo_empty; // RFE (Receive FIFO Empty)
            uart_fifo_stat_reg[1] <= rx_fifo_full;  // RFF (Receive FIFO Full)
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            uart_rx_data_reg <= 32'b0;
        end else begin
            if (wb_we_i & (uart_line_ctrl_reg[1] & !rx_fifo_empty)) begin
                uart_rx_data_reg <= {24'b0, rx_fifo[rx_fifo_tail]};
                rx_fifo_tail <= rx_fifo_tail + 1;
                if (rx_fifo_head == rx_fifo_tail)
                    rx_fifo_empty <= 1'b1;
                rx_fifo_full <= 1'b0;
            end
        end
    end

endmodule

module uart_modem (
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire [31:0] uart_modem_ctrl_reg,
    output wire        rts_pad_o,
    input  wire        cts_pad_i,
    output wire        dtr_pad_o,
    input  wire        dsr_pad_i,
    input  wire        ri_pad_i,
    input  wire        dcd_pad_i,
    output wire [31:0] uart_modem_stat_reg
);

    assign rts_pad_o = uart_modem_ctrl_reg[1];
    assign dtr_pad_o = uart_modem_ctrl_reg[0];

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            uart_modem_stat_reg <= 32'b0;
        end else begin
            uart_modem_stat_reg[4] <= cts_pad_i;
            uart_modem_stat_reg[5] <= dsr_pad_i;
            uart_modem_stat_reg[6] <= ri_pad_i;
            uart_modem_stat_reg[7] <= dcd_pad_i;
        end
    end

endmodule

module uart_irq (
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire [31:0] uart_stat_reg,
    input  wire [31:0] uart_irq_reg,
    output wire        int_o
);

    reg irq_asserted;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            irq_asserted <= 1'b0;
        end else begin
            irq_asserted <= (uart_irq_reg[0] & ~uart_stat_reg[0]) | // THRE
                           (uart_irq_reg[1] & ~uart_stat_reg[1]) | // RDRF
                           (uart_irq_reg[6] & uart_stat_reg[6]) |  // CTS
                           (uart_irq_reg[7] & uart_stat_reg[7]) |  // DSR
                           (uart_irq_reg[8] & uart_stat_reg[8]) |  // RI
                           (uart_irq_reg[9] & uart_stat_reg[9]);   // DCD
        end
    end

    assign int_o = irq_asserted;

endmodule
