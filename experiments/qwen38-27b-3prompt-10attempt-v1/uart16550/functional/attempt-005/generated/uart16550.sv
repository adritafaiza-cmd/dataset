module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // Wishbone signals
    input  wb_clk_i;
    input  wb_rst_i;
    input  [7:0] wb_adr_i;
    input  [7:0] wb_dat_i;
    output [7:0] wb_dat_o;
    input  wb_we_i;
    input  wb_stb_i;
    input  wb_cyc_i;
    output wb_ack_o;
    input  [3:0] wb_sel_i;

    // Interrupt
    output int_o;

    // UART pins
    output stx_pad_o;
    input  srx_pad_i;

    // Modem control
    output rts_pad_o;
    input  cts_pad_i;
    output dtr_pad_o;
    input  dsr_pad_i;
    input  ri_pad_i;
    input  dcd_pad_i;

    // Internal signals
    wire [7:0] reg_rbr_thr;
    wire [7:0] reg_iir_fcr;
    wire [7:0] reg_lcr;
    wire [7:0] reg_mcr;
    wire [7:0] reg_lsr;
    wire [7:0] reg_msr;
    wire [7:0] reg_scr;
    wire [7:0] reg_dll;
    wire [7:0] reg_dlh;

    wire [7:0] reg_divisor;
    wire [7:0] reg_divisor_l;
    wire [7:0] reg_divisor_h;

    wire [7:0] reg_fcr;
    wire [7:0] reg_iir;

    wire [7:0] reg_lcr;
    wire [7:0] reg_mcr;
    wire [7:0] reg_lsr;
    wire [7:0] reg_msr;
    wire [7:0] reg_scr;

    // FIFO control
    wire fifo_enable;
    wire fifo_reset_rx;
    wire fifo_reset_tx;
    wire [1:0] fifo_trigger_level;

    // Baud rate generator
    wire [15:0] baud_divisor;
    wire [15:0] baud_divisor_l;
    wire [15:0] baud_divisor_h;

    // TX logic
    wire tx_enable;
    wire [7:0] tx_data;
    wire tx_start;
    wire tx_done;
    wire tx_busy;

    // RX logic
    wire rx_start;
    wire rx_done;
    wire [7:0] rx_data;
    wire rx_error;
    wire rx_break;
    wire rx_overrun;
    wire rx_parity_error;
    wire rx_fifo_full;
    wire rx_fifo_empty;
    wire [7:0] rx_fifo_data;
    wire rx_fifo_valid;

    // Interrupt logic
    wire int_pending;
    wire [3:0] int_source;

    // Register address decode
    wire [2:0] reg_addr;
    wire is_dll_dlh;

    assign reg_addr = wb_adr_i[2:0];
    assign is_dll_dlh = (reg_lcr[7] == 1'b1);

    // Baud rate divisor
    assign baud_divisor = {reg_dlh, reg_dll};
    assign baud_divisor_l = reg_dll;
    assign baud_divisor_h = reg_dlh;

    // FIFO control
    assign fifo_enable = reg_fcr[0];
    assign fifo_reset_rx = reg_fcr[1];
    assign fifo_reset_tx = reg_fcr[2];
    assign fifo_trigger_level = reg_fcr[3:2];

    // LCR bits
    wire lcr_word_length = reg_lcr[1:0];
    wire lcr_stop_bits = reg_lcr[2];
    wire lcr_parity_enable = reg_lcr[3];
    wire lcr_parity_sticky = reg_lcr[4];
    wire lcr_parity_type = reg_lcr[5];
    wire lcr_break_control = reg_lcr[6];
    wire lcr_dll_dlh = reg_lcr[7];

    // MCR bits
    wire mcr_dtr = reg_mcr[0];
    wire mcr_rts = reg_mcr[1];
    wire mcr_out2 = reg_mcr[2];
    wire mcr_out1 = reg_mcr[3];
    wire mcr_loop = reg_mcr[4];

    // LSR bits
    wire lsr_thr_empty = reg_lsr[0];
    wire lsr_tx_holding = reg_lsr[1];
    wire lsr_break_error = reg_lsr[2];
    wire lsr_parity_error = reg_lsr[3];
    wire lsr_framing_error = reg_lsr[4];
    wire lsr_overrun_error = reg_lsr[5];
    wire lsr_data_ready = reg_lsr[0];
    wire lsr_fifo_error = reg_lsr[6];
    wire lsr_fifo_data_available = reg_lsr[7];

    // MSR bits
    wire msr_cts = reg_msr[0];
    wire msr_dsr = reg_msr[1];
    wire msr_ri = reg_msr[2];
    wire msr_dcd = reg_msr[3];
    wire msr_cts_change = reg_msr[4];
    wire msr_dsr_change = reg_msr[5];
    wire msr_ri_change = reg_msr[6];
    wire msr_dcd_change = reg_msr[7];

    // IIR bits
    wire iir_no_interrupt = reg_iir[0];
    wire iir_interrupt_id = reg_iir[3:1];
    wire iir_fifo_enabled = reg_iir[6];
    wire iir_fifo_trigger_level = reg_iir[7:6];

    // Interrupt sources
    wire int_data_ready;
    wire int_thr_empty;
    wire int_line_status;
    wire int_modem_status;

    assign int_data_ready = lsr_data_ready;
    assign int_thr_empty = lsr_thr_empty;
    assign int_line_status = lsr_break_error | lsr_parity_error | lsr_framing_error | lsr_overrun_error;
    assign int_modem_status = msr_cts_change | msr_dsr_change | msr_ri_change | msr_dcd_change;

    // Interrupt priority
    wire [3:0] int_priority;
    assign int_priority = {
        int_modem_status,
        int_line_status,
        int_thr_empty,
        int_data_ready
    };

    assign int_pending = int_data_ready | int_thr_empty | int_line_status | int_modem_status;

    // IIR value
    reg [3:0] iir_reg;
    always @(*) begin
        if (!int_pending) begin
            iir_reg = 4'b1000; // No interrupt
        end else if (int_data_ready) begin
            iir_reg = 4'b0001; // Data ready
        end else if (int_thr_empty) begin
            iir_reg = 4'b0010; // THR empty
        end else if (int_line_status) begin
            iir_reg = 4'b0011; // Line status
        end else if (int_modem_status) begin
            iir_reg = 4'b0100; // Modem status
        end else begin
            iir_reg = 4'b1000;
        end
    end

    // IIR register
    assign reg_iir = {iir_reg[3:1], 1'b0, iir_reg[0], 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};

    // FCR register
    assign reg_fcr = {1'b0, 1'b0, fifo_reset_tx, fifo_reset_rx, fifo_enable, 1'b0, 1'b0, 1'b0};

    // LCR register
    assign reg_lcr = {lcr_dll_dlh, lcr_break_control, lcr_parity_type, lcr_parity_sticky, lcr_parity_enable, lcr_stop_bits, lcr_word_length[1:0]};

    // MCR register
    assign reg_mcr = {1'b0, 1'b0, 1'b0, 1'b0, mcr_loop, mcr_out1, mcr_out2, mcr_rts, mcr_dtr};

    // LSR register
    assign reg_lsr = {lsr_fifo_data_available, lsr_fifo_error, lsr_overrun_error, lsr_framing_error, lsr_parity_error, lsr_break_error, lsr_tx_holding, lsr_thr_empty};

    // MSR register
    assign reg_msr = {msr_dcd_change, msr_ri_change, msr_dsr_change, msr_cts_change, msr_dcd, msr_ri, msr_dsr, msr_cts};

    // SCR register
    reg [7:0] scr_reg;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            scr_reg <= 8'h00;
        end else if (wb_stb_i && wb_cyc_i && wb_we_i && (reg_addr == 3'b111)) begin
            scr_reg <= wb_dat_i;
        end
    end
    assign reg_scr = scr_reg;

    // DLL and DLH registers
    reg [7:0] dll_reg;
    reg [7:0] dlh_reg;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            dll_reg <= 8'h00;
            dlh_reg <= 8'h00;
        end else if (wb_stb_i && wb_cyc_i && wb_we_i) begin
            if (is_dll_dlh) begin
                if (reg_addr == 3'b000) begin
                    dll_reg <= wb_dat_i;
                end else if (reg_addr == 3'b001) begin
                    dlh_reg <= wb_dat_i;
                end
            end
        end
    end
    assign reg_dll = dll_reg;
    assign reg_dlh = dlh_reg;

    // RBR/THR register
    reg [7:0] thr_reg;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            thr_reg <= 8'h00;
        end else if (wb_stb_i && wb_cyc_i && wb_we_i && (reg_addr == 3'b000) && !is_dll_dlh) begin
            thr_reg <= wb_dat_i;
        end
    end
    assign reg_rbr_thr = thr_reg;

    // IIR/FCR register
    reg [7:0] fcr_reg;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            fcr_reg <= 8'h00;
        end else if (wb_stb_i && wb_cyc_i && wb_we_i && (reg_addr == 3'b001)) begin
            fcr_reg <= wb_dat_i;
        end
    end
    assign reg_fcr = fcr_reg;

    // LCR register
    reg [7:0] lcr_reg;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            lcr_reg <= 8'h03; // 8N1
        end else if (wb_stb_i && wb_cyc_i && wb_we_i && (reg_addr == 3'b010)) begin
            lcr_reg <= wb_dat_i;
        end
    end
    assign reg_lcr = lcr_reg;

    // MCR register
    reg [7:0] mcr_reg;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            mcr_reg <= 8'h00;
        end else if (wb_stb_i && wb_cyc_i && wb_we_i && (reg_addr == 3'b011)) begin
            mcr_reg <= wb_dat_i;
        end
    end
    assign reg_mcr = mcr_reg;

    // LSR register
    reg [7:0] lsr_reg;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            lsr_reg <= 8'h60; // THR empty, TX holding
        end else begin
            lsr_reg <= {
                lsr_fifo_data_available,
                lsr_fifo_error,
                lsr_overrun_error,
                lsr_framing_error,
                lsr_parity_error,
                lsr_break_error,
                lsr_tx_holding,
                lsr_thr_empty
            };
        end
    end
    assign reg_lsr = lsr_reg;

    // MSR register
    reg [7:0] msr_reg;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            msr_reg <= 8'h00;
        end else begin
            msr_reg <= {
                msr_dcd_change,
                msr_ri_change,
                msr_dsr_change,
                msr_cts_change,
                msr_dcd,
                msr_ri,
                msr_dsr,
                msr_cts
            };
        end
    end
    assign reg_msr = msr_reg;

    // Wishbone read data
    reg [7:0] wb_dat_o_reg;
    always @(*) begin
        case (reg_addr)
            3'b000: begin
                if (is_dll_dlh) begin
                    wb_dat_o_reg = reg_dll;
                end else begin
                    wb_dat_o_reg = reg_rbr_thr;
                end
            end
            3'b001: begin
                if (is_dll_dlh) begin
                    wb_dat_o_reg = reg_dlh;
                end else begin
                    wb_dat_o_reg = reg_iir_fcr;
                end
            end
            3'b010: wb_dat_o_reg = reg_lcr;
            3'b011: wb_dat_o_reg = reg_mcr;
            3'b100: wb_dat_o_reg = reg_lsr;
            3'b101: wb_dat_o_reg = reg_msr;
            3'b110: wb_dat_o_reg = reg_scr;
            3'b111: wb_dat_o_reg = reg_scr;
            default: wb_dat_o_reg = 8'h00;
        endcase
    end
    assign wb_dat_o = wb_dat_o_reg;

    // Wishbone ACK
    assign wb_ack_o = wb_stb_i && wb_cyc_i;

    // Interrupt output
    assign int_o = int_pending;

    // Modem control outputs
    assign dtr_pad_o = mcr_dtr;
    assign rts_pad_o = mcr_rts;

    // Modem status inputs
    assign msr_cts = cts_pad_i;
    assign msr_dsr = dsr_pad_i;
    assign msr_ri = ri_pad_i;
    assign msr_dcd = dcd_pad_i;

    // Modem status change detection
    reg [3:0] msr_prev;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            msr_prev <= 4'b0000;
        end else begin
            msr_prev <= {msr_dcd, msr_ri, msr_dsr, msr_cts};
        end
    end

    assign msr_cts_change = (msr_cts != msr_prev[0]);
    assign msr_dsr_change = (msr_dsr != msr_prev[1]);
    assign msr_ri_change = (msr_ri != msr_prev[2]);
    assign msr_dcd_change = (msr_dcd != msr_prev[3]);

    // TX logic
    reg tx_active;
    reg [7:0] tx_shift_reg;
    reg [3:0] tx_bit_count;
    reg tx_parity_bit;
    reg [15:0] tx_baud_counter;
    reg [15:0] tx_baud_divisor_reg;

    assign tx_enable = !tx_active;
    assign tx_data = thr_reg;
    assign tx_start = tx_enable && (thr_reg != 8'h00 || 1'b1); // Always ready to transmit
    assign tx_done = tx_active && (tx_bit_count == 4'd0);
    assign tx_busy = tx_active;

    // Calculate baud divisor
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_baud_divisor_reg <= 16'd1;
        end else begin
            tx_baud_divisor_reg <= (baud_divisor == 16'd0) ? 16'd1 : baud_divisor;
        end
    end

    // TX state machine
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_active <= 1'b0;
            tx_shift_reg <= 8'h00;
            tx_bit_count <= 4'd0;
            tx_parity_bit <= 1'b0;
            tx_baud_counter <= 16'd0;
            stx_pad_o <= 1'b1;
        end else begin
            if (!tx_active) begin
                // Start transmission
                if (tx_enable) begin
                    tx_active <= 1'b1;
                    tx_shift_reg <= thr_reg;
                    tx_bit_count <= 4'd11; // Start bit + 8 data + parity + stop
                    tx_baud_counter <= 16'd0;
                    stx_pad_o <= 1'b0; // Start bit
                end
            end else begin
                // Baud rate counter
                if (tx_baud_counter >= tx_baud_divisor_reg - 1) begin
                    tx_baud_counter <= 16'd0;
                    // Shift out next bit
                    case (tx_bit_count)
                        4'd11: begin
                            // Start bit already sent, send data bit 0
                            tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
                            tx_bit_count <= 4'd10;
                        end
                        4'd10: begin
                            tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
                            tx_bit_count <= 4'd9;
                        end
                        4'd9: begin
                            tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
                            tx_bit_count <= 4'd8;
                        end
                        4'd8: begin
                            tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
                            tx_bit_count <= 4'd7;
                        end
                        4'd7: begin
                            tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
                            tx_bit_count <= 4'd6;
                        end
                        4'd6: begin
                            tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
                            tx_bit_count <= 4'd5;
                        end
                        4'd5: begin
                            tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
                            tx_bit_count <= 4'd4;
                        end
                        4'd4: begin
                            tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
                            tx_bit_count <= 4'd3;
                        end
                        4'd3: begin
                            // Parity bit
                            if (lcr_parity_enable) begin
                                tx_shift_reg <= {tx_parity_bit, tx_shift_reg[7:1]};
                            end else begin
                                tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
                            end
                            tx_bit_count <= 4'd2;
                        end
                        4'd2: begin
                            // Stop bit
                            tx_shift_reg <= {1'b1, tx_shift_reg[7:1]};
                            tx_bit_count <= 4'd1;
                        end
                        4'd1: begin
                            // End of transmission
                            tx_active <= 1'b0;
                            tx_bit_count <= 4'd0;
                            stx_pad_o <= 1'b1;
                        end
                        default: begin
                            tx_bit_count <= 4'd0;
                        end
                    endcase
                    stx_pad_o <= tx_shift_reg[0];
                end else begin
                    tx_baud_counter <= tx_baud_counter + 1'b1;
                end
            end
        end
    end

    // Parity calculation
    always @(*) begin
        if (lcr_parity_enable) begin
            if (lcr_parity_type == 2'b00) begin
                // Even parity
                tx_parity_bit = ^tx_shift_reg;
            end else if (lcr_parity_type == 2'b01) begin
                // Odd parity
                tx_parity_bit = ~^tx_shift_reg;
            end else if (lcr_parity_type == 2'b10) begin
                // Mark parity
                tx_parity_bit = 1'b1;
            end else begin
                // Space parity
                tx_parity_bit = 1'b0;
            end
        end else begin
            tx_parity_bit = 1'b0;
        end
    end

    // RX logic
    reg rx_active;
    reg [7:0] rx_shift_reg;
    reg [3:0] rx_bit_count;
    reg rx_parity_bit;
    reg [15:0] rx_baud_counter;
    reg [15:0] rx_baud_divisor_reg;
    reg rx_start_bit;
    reg rx_data_bit;
    reg rx_parity_error_reg;
    reg rx_framing_error_reg;
    reg rx_overrun_error_reg;
    reg rx_break_error_reg;
    reg rx_data_ready_reg;

    assign rx_start = !rx_active && (srx_pad_i == 1'b0);
    assign rx_done = rx_active && (rx_bit_count == 4'd0);
    assign rx_error = rx_parity_error_reg | rx_framing_error_reg | rx_overrun_error_reg | rx_break_error_reg;
    assign rx_break = rx_break_error_reg;
    assign rx_overrun = rx_overrun_error_reg;
    assign rx_parity_error = rx_parity_error_reg;
    assign rx_fifo_full = 1'b0;
    assign rx_fifo_empty = 1'b1;
    assign rx_fifo_data = rx_shift_reg;
    assign rx_fifo_valid = rx_data_ready_reg;

    // Calculate baud divisor
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_baud_divisor_reg <= 16'd1;
        end else begin
            rx_baud_divisor_reg <= (baud_divisor == 16'd0) ? 16'd1 : baud_divisor;
        end
    end

    // RX state machine
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_active <= 1'b0;
            rx_shift_reg <= 8'h00;
            rx_bit_count <= 4'd0;
            rx_parity_bit <= 1'b0;
            rx_baud_counter <= 16'd0;
            rx_start_bit <= 1'b0;
            rx_data_bit <= 1'b0;
            rx_parity_error_reg <= 1'b0;
            rx_framing_error_reg <= 1'b0;
            rx_overrun_error_reg <= 1'b0;
            rx_break_error_reg <= 1'b0;
            rx_data_ready_reg <= 1'b0;
        end else begin
            if (!rx_active) begin
                // Detect start bit
                if (srx_pad_i == 1'b0) begin
                    rx_active <= 1'b1;
                    rx_shift_reg <= 8'h00;
                    rx_bit_count <= 4'd11; // Start bit + 8 data + parity + stop
                    rx_baud_counter <= 16'd0;
                    rx_start_bit <= 1'b0;
                    rx_data_bit <= 1'b0;
                    rx_parity_error_reg <= 1'b0;
                    rx_framing_error_reg <= 1'b0;
                    rx_overrun_error_reg <= 1'b0;
                    rx_break_error_reg <= 1'b0;
                    rx_data_ready_reg <= 1'b0;
                end
            end else begin
                // Baud rate counter
                if (rx_baud_counter >= rx_baud_divisor_reg - 1) begin
                    rx_baud_counter <= 16'd0;
                    // Sample bit
                    case (rx_bit_count)
                        4'd11: begin
                            // Start bit
                            if (srx_pad_i == 1'b1) begin
                                // Invalid start bit, abort
                                rx_active <= 1'b0;
                                rx_bit_count <= 4'd0;
                            end else begin
                                rx_bit_count <= 4'd10;
                            end
                        end
                        4'd10: begin
                            // Data bit 0
                            rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                            rx_bit_count <= 4'd9;
                        end
                        4'd9: begin
                            // Data bit 1
                            rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                            rx_bit_count <= 4'd8;
                        end
                        4'd8: begin
                            // Data bit 2
                            rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                            rx_bit_count <= 4'd7;
                        end
                        4'd7: begin
                            // Data bit 3
                            rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                            rx_bit_count <= 4'd6;
                        end
                        4'd6: begin
                            // Data bit 4
                            rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                            rx_bit_count <= 4'd5;
                        end
                        4'd5: begin
                            // Data bit 5
                            rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                            rx_bit_count <= 4'd4;
                        end
                        4'd4: begin
                            // Data bit 6
                            rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                            rx_bit_count <= 4'd3;
                        end
                        4'd3: begin
                            // Data bit 7
                            rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                            rx_bit_count <= 4'd2;
                        end
                        4'd2: begin
                            // Parity bit
                            if (lcr_parity_enable) begin
                                rx_parity_bit <= srx_pad_i;
                                // Check parity
                                if (lcr_parity_type == 2'b00) begin
                                    // Even parity
                                    if (srx_pad_i != ^rx_shift_reg) begin
                                        rx_parity_error_reg <= 1'b1;
                                    end
                                end else if (lcr_parity_type == 2'b01) begin
                                    // Odd parity
                                    if (srx_pad_i == ^rx_shift_reg) begin
                                        rx_parity_error_reg <= 1'b1;
                                    end
                                end
                            end
                            rx_bit_count <= 4'd1;
                        end
                        4'd1: begin
                            // Stop bit
                            if (srx_pad_i == 1'b0) begin
                                rx_framing_error_reg <= 1'b1;
                            end
                            rx_active <= 1'b0;
                            rx_bit_count <= 4'd0;
                            rx_data_ready_reg <= 1'b1;
                        end
                        default: begin
                            rx_bit_count <= 4'd0;
                        end
                    endcase
                end else begin
                    rx_baud_counter <= rx_baud_counter + 1'b1;
                end
            end
        end
    end

    // LSR updates
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            lsr_reg <= 8'h60;
        end else begin
            lsr_reg <= {
                rx_data_ready_reg,
                1'b0,
                rx_overrun_error_reg,
                rx_framing_error_reg,
                rx_parity_error_reg,
                rx_break_error_reg,
                !tx_active,
                !tx_active
            };
        end
    end

    // Clear errors on read
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_parity_error_reg <= 1'b0;
            rx_framing_error_reg <= 1'b0;
            rx_overrun_error_reg <= 1'b0;
            rx_break_error_reg <= 1'b0;
            rx_data_ready_reg <= 1'b0;
        end else if (wb_stb_i && wb_cyc_i && !wb_we_i && (reg_addr == 3'b100)) begin
            // Read LSR clears errors
            rx_parity_error_reg <= 1'b0;
            rx_framing_error_reg <= 1'b0;
            rx_overrun_error_reg <= 1'b0;
            rx_break_error_reg <= 1'b0;
            rx_data_ready_reg <= 1'b0;
        end
    end

    // Clear MSR changes on read
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            msr_reg <= 8'h00;
        end else if (wb_stb_i && wb_cyc_i && !wb_we_i && (reg_addr == 3'b101)) begin
            // Read MSR clears change bits
            msr_reg <= {
                1'b0,
                1'b0,
                1'b0,
                1'b0,
                msr_dcd,
                msr_ri,
                msr_dsr,
                msr_cts
            };
        end else begin
            msr_reg <= {
                msr_dcd_change,
                msr_ri_change,
                msr_dsr_change,
                msr_cts_change,
                msr_dcd,
                msr_ri,
                msr_dsr,
                msr_cts
            };
        end
    end

endmodule
