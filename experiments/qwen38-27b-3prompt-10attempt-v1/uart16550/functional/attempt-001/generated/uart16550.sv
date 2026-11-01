module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // Wishbone signals
    input  wire wb_clk_i;
    input  wire wb_rst_i;
    input  wire [7:0] wb_adr_i;
    input  wire [7:0] wb_dat_i;
    output reg  [7:0] wb_dat_o;
    input  wire wb_we_i;
    input  wire wb_stb_i;
    input  wire wb_cyc_i;
    output reg  wb_ack_o;
    input  wire [3:0] wb_sel_i;

    // UART signals
    output reg  int_o;
    output reg  stx_pad_o;
    input  wire srx_pad_i;
    output reg  rts_pad_o;
    input  wire cts_pad_i;
    output reg  dtr_pad_o;
    input  wire dsr_pad_i;
    input  wire ri_pad_i;
    input  wire dcd_pad_i;

    // Internal signals
    reg [7:0] rbr_thr;      // Receive Buffer Register / Transmit Holding Register
    reg [7:0] ier;          // Interrupt Enable Register
    reg [7:0] iir;          // Interrupt Identification Register
    reg [7:0] lcr;          // Line Control Register
    reg [7:0] mcr;          // Modem Control Register
    reg [7:0] lsr;          // Line Status Register
    reg [7:0] msr;          // Modem Status Register
    reg [7:0] scr;          // Scratch Register
    reg [7:0] fcr;          // FIFO Control Register
    reg [7:0] lcr_divisor_l; // Divisor Latch Low
    reg [7:0] lcr_divisor_h; // Divisor Latch High

    // FIFO signals
    reg [7:0] rx_fifo [0:14];
    reg [3:0] rx_fifo_wr_ptr;
    reg [3:0] rx_fifo_rd_ptr;
    reg [3:0] rx_fifo_count;

    reg [7:0] tx_fifo [0:14];
    reg [3:0] tx_fifo_wr_ptr;
    reg [3:0] tx_fifo_rd_ptr;
    reg [3:0] tx_fifo_count;

    // Baud rate generator
    reg [15:0] baud_divisor;
    reg [15:0] baud_counter;
    reg baud_tick;

    // Transmitter state machine
    reg tx_active;
    reg [3:0] tx_bit_count;
    reg [7:0] tx_shift_reg;
    reg tx_start_sent;

    // Receiver state machine
    reg rx_active;
    reg [3:0] rx_bit_count;
    reg [7:0] rx_shift_reg;
    reg rx_start_detected;
    reg [1:0] rx_sync;

    // Interrupt signals
    wire rx_data_available;
    wire rx_timeout;
    wire tx_holding_empty;
    wire tx_fifo_empty;
    wire line_status;
    wire modem_status;

    // FIFO enable
    wire fifo_enabled = (fcr[0] == 1'b1);

    // DLAB bit
    wire dlab = lcr[7];

    // Parity settings
    wire parity_enable = lcr[3];
    wire parity_type = lcr[2:1]; // 00: even, 01: odd, 10: space, 11: mark
    wire parity_sticky = lcr[4];

    // Word length
    wire [1:0] word_length = lcr[1:0];

    // Stop bits
    wire stop_bit_2 = lcr[4];

    // Break interrupt enable
    wire break_int_enable = ier[5];

    // Modem interrupt enable
    wire modem_int_enable = ier[6];

    // Transmitter empty interrupt enable
    wire tx_empty_int_enable = ier[7];

    // Receive data interrupt enable
    wire rx_data_int_enable = ier[0];

    // Receive timeout interrupt enable
    wire rx_timeout_int_enable = ier[1];

    // Line status interrupt enable
    wire line_status_int_enable = ier[3];

    // Calculate baud divisor
    always @(*) begin
        if (dlab) begin
            baud_divisor = {lcr_divisor_h, lcr_divisor_l};
        end else begin
            baud_divisor = 16'd0;
        end
    end

    // Baud rate generator
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            baud_counter <= 16'd0;
            baud_tick <= 1'b0;
        end else begin
            if (baud_counter >= baud_divisor - 1) begin
                baud_counter <= 16'd0;
                baud_tick <= 1'b1;
            end else begin
                baud_counter <= baud_counter + 1'b1;
                baud_tick <= 1'b0;
            end
        end
    end

    // Transmitter logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_active <= 1'b0;
            tx_bit_count <= 4'd0;
            tx_shift_reg <= 8'd0;
            tx_start_sent <= 1'b0;
            stx_pad_o <= 1'b1;
        end else if (baud_tick) begin
            if (!tx_active) begin
                if (tx_fifo_count > 0) begin
                    tx_active <= 1'b1;
                    tx_bit_count <= 4'd0;
                    tx_shift_reg <= tx_fifo[tx_fifo_rd_ptr];
                    tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 1'b1;
                    tx_fifo_count <= tx_fifo_count - 1'b1;
                    tx_start_sent <= 1'b0;
                    stx_pad_o <= 1'b0; // Start bit
                end
            end else begin
                case (tx_bit_count)
                    4'd0: begin
                        // Start bit already sent, send data bit 0
                        tx_shift_reg <= {tx_shift_reg[0], 1'b0};
                        stx_pad_o <= tx_shift_reg[0];
                        tx_bit_count <= 4'd1;
                    end
                    4'd1: begin
                        tx_shift_reg <= {tx_shift_reg[0], 1'b0};
                        stx_pad_o <= tx_shift_reg[0];
                        tx_bit_count <= 4'd2;
                    end
                    4'd2: begin
                        tx_shift_reg <= {tx_shift_reg[0], 1'b0};
                        stx_pad_o <= tx_shift_reg[0];
                        tx_bit_count <= 4'd3;
                    end
                    4'd3: begin
                        tx_shift_reg <= {tx_shift_reg[0], 1'b0};
                        stx_pad_o <= tx_shift_reg[0];
                        tx_bit_count <= 4'd4;
                    end
                    4'd4: begin
                        tx_shift_reg <= {tx_shift_reg[0], 1'b0};
                        stx_pad_o <= tx_shift_reg[0];
                        tx_bit_count <= 4'd5;
                    end
                    4'd5: begin
                        tx_shift_reg <= {tx_shift_reg[0], 1'b0};
                        stx_pad_o <= tx_shift_reg[0];
                        tx_bit_count <= 4'd6;
                    end
                    4'd6: begin
                        tx_shift_reg <= {tx_shift_reg[0], 1'b0};
                        stx_pad_o <= tx_shift_reg[0];
                        tx_bit_count <= 4'd7;
                    end
                    4'd7: begin
                        tx_shift_reg <= {tx_shift_reg[0], 1'b0};
                        stx_pad_o <= tx_shift_reg[0];
                        tx_bit_count <= 4'd8;
                    end
                    4'd8: begin
                        // Parity bit
                        if (parity_enable) begin
                            case (parity_type)
                                2'b00: begin // Even
                                    tx_shift_reg <= {tx_shift_reg[0], 1'b0};
                                    stx_pad_o <= tx_shift_reg[0];
                                end
                                2'b01: begin // Odd
                                    tx_shift_reg <= {tx_shift_reg[0], 1'b0};
                                    stx_pad_o <= tx_shift_reg[0];
                                end
                                2'b10: begin // Space
                                    tx_shift_reg <= {tx_shift_reg[0], 1'b0};
                                    stx_pad_o <= 1'b0;
                                end
                                2'b11: begin // Mark
                                    tx_shift_reg <= {tx_shift_reg[0], 1'b0};
                                    stx_pad_o <= 1'b1;
                                end
                            endcase
                        end else begin
                            tx_shift_reg <= {tx_shift_reg[0], 1'b0};
                            stx_pad_o <= 1'b1;
                        end
                        tx_bit_count <= 4'd9;
                    end
                    4'd9: begin
                        // Stop bit 1
                        stx_pad_o <= 1'b1;
                        tx_bit_count <= 4'd10;
                    end
                    4'd10: begin
                        if (stop_bit_2) begin
                            // Stop bit 2
                            stx_pad_o <= 1'b1;
                            tx_bit_count <= 4'd11;
                        end else begin
                            tx_active <= 1'b0;
                            stx_pad_o <= 1'b1;
                        end
                    end
                    4'd11: begin
                        tx_active <= 1'b0;
                        stx_pad_o <= 1'b1;
                    end
                    default: begin
                        tx_active <= 1'b0;
                        stx_pad_o <= 1'b1;
                    end
                endcase
            end
        end
    end

    // Receiver logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_active <= 1'b0;
            rx_bit_count <= 4'd0;
            rx_shift_reg <= 8'd0;
            rx_start_detected <= 1'b0;
            rx_sync <= 2'b00;
        end else begin
            rx_sync <= {rx_sync[0], srx_pad_i};
            
            if (!rx_active) begin
                if (rx_sync == 2'b10) begin // Falling edge detected
                    rx_active <= 1'b1;
                    rx_bit_count <= 4'd0;
                    rx_start_detected <= 1'b1;
                end
            end else if (baud_tick) begin
                case (rx_bit_count)
                    4'd0: begin
                        // Sample start bit
                        rx_bit_count <= 4'd1;
                    end
                    4'd1: begin
                        rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                        rx_bit_count <= 4'd2;
                    end
                    4'd2: begin
                        rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                        rx_bit_count <= 4'd3;
                    end
                    4'd3: begin
                        rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                        rx_bit_count <= 4'd4;
                    end
                    4'd4: begin
                        rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                        rx_bit_count <= 4'd5;
                    end
                    4'd5: begin
                        rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                        rx_bit_count <= 4'd6;
                    end
                    4'd6: begin
                        rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                        rx_bit_count <= 4'd7;
                    end
                    4'd7: begin
                        rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                        rx_bit_count <= 4'd8;
                    end
                    4'd8: begin
                        // Parity bit
                        rx_bit_count <= 4'd9;
                    end
                    4'd9: begin
                        // Stop bit 1
                        if (srx_pad_i == 1'b1) begin
                            if (stop_bit_2) begin
                                rx_bit_count <= 4'd10;
                            end else begin
                                // Store received data
                                if (fifo_enabled) begin
                                    rx_fifo[rx_fifo_wr_ptr] <= rx_shift_reg[7:0];
                                    rx_fifo_wr_ptr <= rx_fifo_wr_ptr + 1'b1;
                                    rx_fifo_count <= rx_fifo_count + 1'b1;
                                end else begin
                                    rbr_thr <= rx_shift_reg[7:0];
                                end
                                rx_active <= 1'b0;
                                rx_start_detected <= 1'b0;
                            end
                        end else begin
                            // Framing error
                            rx_active <= 1'b0;
                            rx_start_detected <= 1'b0;
                        end
                    end
                    4'd10: begin
                        // Stop bit 2
                        if (srx_pad_i == 1'b1) begin
                            // Store received data
                            if (fifo_enabled) begin
                                rx_fifo[rx_fifo_wr_ptr] <= rx_shift_reg[7:0];
                                rx_fifo_wr_ptr <= rx_fifo_wr_ptr + 1'b1;
                                rx_fifo_count <= rx_fifo_count + 1'b1;
                            end else begin
                                rbr_thr <= rx_shift_reg[7:0];
                            end
                            rx_active <= 1'b0;
                            rx_start_detected <= 1'b0;
                        end else begin
                            // Framing error
                            rx_active <= 1'b0;
                            rx_start_detected <= 1'b0;
                        end
                    end
                    default: begin
                        rx_active <= 1'b0;
                        rx_start_detected <= 1'b0;
                    end
                endcase
            end
        end
    end

    // FIFO control
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_fifo_wr_ptr <= 4'd0;
            rx_fifo_rd_ptr <= 4'd0;
            rx_fifo_count <= 4'd0;
            tx_fifo_wr_ptr <= 4'd0;
            tx_fifo_rd_ptr <= 4'd0;
            tx_fifo_count <= 4'd0;
        end else begin
            // RX FIFO
            if (fcr[2]) begin // RX FIFO reset
                rx_fifo_wr_ptr <= 4'd0;
                rx_fifo_rd_ptr <= 4'd0;
                rx_fifo_count <= 4'd0;
            end else begin
                // Read from RX FIFO
                if (wb_cyc_i && wb_stb_i && !wb_we_i && wb_adr_i[1:0] == 2'b00 && rx_fifo_count > 0) begin
                    rx_fifo_rd_ptr <= rx_fifo_rd_ptr + 1'b1;
                    rx_fifo_count <= rx_fifo_count - 1'b1;
                end
            end
            
            // TX FIFO
            if (fcr[2]) begin // TX FIFO reset
                tx_fifo_wr_ptr <= 4'd0;
                tx_fifo_rd_ptr <= 4'd0;
                tx_fifo_count <= 4'd0;
            end else begin
                // Write to TX FIFO
                if (wb_cyc_i && wb_stb_i && wb_we_i && wb_adr_i[1:0] == 2'b00 && !dlab && tx_fifo_count < 15) begin
                    tx_fifo[tx_fifo_wr_ptr] <= wb_dat_i;
                    tx_fifo_wr_ptr <= tx_fifo_wr_ptr + 1'b1;
                    tx_fifo_count <= tx_fifo_count + 1'b1;
                end
            end
        end
    end

    // Interrupt logic
    assign rx_data_available = (fifo_enabled && rx_fifo_count > 0) || (!fifo_enabled && lsr[0]);
    assign rx_timeout = 1'b0; // Simplified, no timeout implemented
    assign tx_holding_empty = (fifo_enabled && tx_fifo_count == 0) || (!fifo_enabled && !tx_active);
    assign tx_fifo_empty = (fifo_enabled && tx_fifo_count == 0 && !tx_active) || (!fifo_enabled && !tx_active);
    assign line_status = lsr[6] | lsr[5] | lsr[4] | lsr[2]; // Break, parity, framing, data ready
    assign modem_status = msr[7] | msr[6] | msr[5] | msr[4]; // DCD, RI, DSR, CTS changes

    always @(*) begin
        if (rx_data_available && rx_data_int_enable) begin
            iir = 8'h04; // Receive data available
        end else if (rx_timeout && rx_timeout_int_enable) begin
            iir = 8'h06; // Receive timeout
        end else if (tx_holding_empty && tx_empty_int_enable) begin
            iir = 8'h02; // Transmitter holding register empty
        end else if (line_status && line_status_int_enable) begin
            iir = 8'h01; // Line status
        end else if (modem_status && modem_int_enable) begin
            iir = 8'h00; // Modem status
        end else begin
            iir = 8'h01; // No interrupt
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            int_o <= 1'b0;
        end else begin
            int_o <= (iir[0] == 1'b0) && (iir[6] == 1'b0); // Interrupt pending
        end
    end

    // Line Status Register
    always @(*) begin
        lsr = 8'h00;
        lsr[0] = (fifo_enabled && rx_fifo_count > 0) || (!fifo_enabled && rbr_thr != 8'd0); // Data ready
        lsr[1] = 1'b0; // Overrun error
        lsr[2] = 1'b0; // Parity error
        lsr[3] = 1'b0; // Framing error
        lsr[4] = 1'b0; // Break interrupt
        lsr[5] = (fifo_enabled && tx_fifo_count == 0) || (!fifo_enabled && !tx_active); // Transmitter holding register empty
        lsr[6] = (fifo_enabled && tx_fifo_count == 0 && !tx_active) || (!fifo_enabled && !tx_active); // Transmitter empty
        lsr[7] = 1'b0; // FIFO error
    end

    // Modem Status Register
    always @(*) begin
        msr = 8'h00;
        msr[0] = dcd_pad_i; // DCD
        msr[1] = dsr_pad_i; // DSR
        msr[2] = ~ri_pad_i; // RI (active low)
        msr[3] = ~cts_pad_i; // CTS (active low)
        msr[4] = 1'b0; // DCD change
        msr[5] = 1'b0; // RI change
        msr[6] = 1'b0; // DSR change
        msr[7] = 1'b0; // CTS change
    end

    // Modem Control Register
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            mcr <= 8'h00;
            rts_pad_o <= 1'b0;
            dtr_pad_o <= 1'b0;
        end else if (wb_cyc_i && wb_stb_i && wb_we_i && wb_adr_i[1:0] == 2'b01) begin
            mcr <= wb_dat_i;
            rts_pad_o <= wb_dat_i[1];
            dtr_pad_o <= wb_dat_i[0];
        end
    end

    // Wishbone slave interface
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_dat_o <= 8'h00;
            wb_ack_o <= 1'b0;
            rbr_thr <= 8'h00;
            ier <= 8'h00;
            lcr <= 8'h03;
            scr <= 8'h00;
            fcr <= 8'h00;
            lcr_divisor_l <= 8'h00;
            lcr_divisor_h <= 8'h00;
        end else begin
            wb_ack_o <= 1'b0;
            
            if (wb_cyc_i && wb_stb_i) begin
                wb_ack_o <= 1'b1;
                
                if (wb_we_i) begin
                    case (wb_adr_i[1:0])
                        2'b00: begin
                            if (dlab) begin
                                lcr_divisor_l <= wb_dat_i;
                            end else begin
                                if (fifo_enabled) begin
                                    // Write to TX FIFO
                                end else begin
                                    rbr_thr <= wb_dat_i;
                                end
                            end
                        end
                        2'b01: begin
                            if (dlab) begin
                                lcr_divisor_h <= wb_dat_i;
                            end else begin
                                ier <= wb_dat_i;
                            end
                        end
                        2'b10: begin
                            lcr <= wb_dat_i;
                        end
                        2'b11: begin
                            if (dlab) begin
                                // Not used
                            end else begin
                                fcr <= wb_dat_i;
                            end
                        end
                    endcase
                end else begin
                    case (wb_adr_i[1:0])
                        2'b00: begin
                            if (dlab) begin
                                wb_dat_o <= lcr_divisor_l;
                            end else begin
                                if (fifo_enabled) begin
                                    wb_dat_o <= rx_fifo[rx_fifo_rd_ptr];
                                end else begin
                                    wb_dat_o <= rbr_thr;
                                end
                            end
                        end
                        2'b01: begin
                            if (dlab) begin
                                wb_dat_o <= lcr_divisor_h;
                            end else begin
                                wb_dat_o <= iir;
                            end
                        end
                        2'b10: begin
                            wb_dat_o <= lcr;
                        end
                        2'b11: begin
                            if (dlab) begin
                                wb_dat_o <= 8'h00;
                            end else begin
                                wb_dat_o <= mcr;
                            end
                        end
                    endcase
                end
            end
        end
    end

    // Additional register reads
    always @(*) begin
        case (wb_adr_i[1:0])
            2'b00: begin
                if (dlab) begin
                    wb_dat_o <= lcr_divisor_l;
                end else begin
                    if (fifo_enabled) begin
                        wb_dat_o <= rx_fifo[rx_fifo_rd_ptr];
                    end else begin
                        wb_dat_o <= rbr_thr;
                    end
                end
            end
            2'b01: begin
                if (dlab) begin
                    wb_dat_o <= lcr_divisor_h;
                end else begin
                    wb_dat_o <= iir;
                end
            end
            2'b10: begin
                wb_dat_o <= lcr;
            end
            2'b11: begin
                if (dlab) begin
                    wb_dat_o <= 8'h00;
                end else begin
                    wb_dat_o <= mcr;
                end
            end
        endcase
    end

endmodule
