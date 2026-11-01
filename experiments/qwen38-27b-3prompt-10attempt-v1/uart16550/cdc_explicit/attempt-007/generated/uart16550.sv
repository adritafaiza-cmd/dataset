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
    wire [7:0] reg_iir;
    wire [7:0] reg_lcr;
    wire [7:0] reg_mcr;
    wire [7:0] reg_lsr;
    wire [7:0] reg_msr;
    wire [7:0] reg_scr;
    wire [7:0] reg_dll;
    wire [7:0] reg_dlh;
    wire [7:0] reg_fcr;
    wire [7:0] reg_ier;
    wire [7:0] reg_lcr_reg;
    wire [7:0] reg_mcr_reg;
    wire [7:0] reg_scr_reg;
    wire [7:0] reg_dll_reg;
    wire [7:0] reg_dlh_reg;
    wire [7:0] reg_fcr_reg;
    wire [7:0] reg_ier_reg;

    // FIFO control signals
    wire fifo_rst;
    wire fifo_rx_en;
    wire fifo_tx_en;
    wire fifo_rx_trig;
    wire fifo_tx_trig;
    wire [7:0] fifo_rx_data;
    wire fifo_rx_empty;
    wire fifo_rx_full;
    wire fifo_rx_overrun;
    wire fifo_rx_par_err;
    wire fifo_rx_break_err;
    wire fifo_rx_fram_err;
    wire fifo_tx_empty;
    wire fifo_tx_full;
    wire fifo_tx_overrun;
    wire fifo_tx_par_err;
    wire fifo_tx_break_err;
    wire fifo_tx_fram_err;

    // Baud rate generator
    wire [15:0] baud_div;
    wire baud_tick;

    // TX logic
    wire tx_start;
    wire tx_done;
    wire tx_busy;
    wire [7:0] tx_data;
    wire tx_par_err;
    wire tx_break_err;
    wire tx_fram_err;

    // RX logic
    wire rx_start;
    wire rx_done;
    wire rx_busy;
    wire [7:0] rx_data;
    wire rx_par_err;
    wire rx_break_err;
    wire rx_fram_err;
    wire rx_overrun;

    // Interrupt generation
    wire int_rx_data_avail;
    wire int_rx_line_status;
    wire int_tx_holdr_empty;
    wire int_modem_status;
    wire int_enabled;
    wire int_pending;

    // Register file
    reg [7:0] rbr_thr_reg;
    reg [7:0] iir_reg;
    reg [7:0] lcr_reg;
    reg [7:0] mcr_reg;
    reg [7:0] lsr_reg;
    reg [7:0] msr_reg;
    reg [7:0] scr_reg;
    reg [7:0] dll_reg;
    reg [7:0] dlh_reg;
    reg [7:0] fcr_reg;
    reg [7:0] ier_reg;

    // DLAB bit
    wire dlab = lcr_reg[7];

    // Baud divisor
    assign baud_div = {dlh_reg, dll_reg};

    // FIFO control
    assign fifo_rst = fcr_reg[0];
    assign fifo_rx_en = fcr_reg[1];
    assign fifo_tx_en = fcr_reg[2];
    assign fifo_rx_trig = fcr_reg[3:4];
    assign fifo_tx_trig = fcr_reg[5:6];

    // LCR bits
    wire lcr_word_len = lcr_reg[1:0];
    wire lcr_stop_bits = lcr_reg[2];
    wire lcr_parity_en = lcr_reg[3];
    wire lcr_parity_type = lcr_reg[4];
    wire lcr_parity_sticky = lcr_reg[5];
    wire lcr_break_ctrl = lcr_reg[6];

    // MCR bits
    wire mcr_dtr = mcr_reg[0];
    wire mcr_rts = mcr_reg[1];
    wire mcr_out1 = mcr_reg[2];
    wire mcr_out2 = mcr_reg[3];
    wire mcr_loop = mcr_reg[4];

    // MSR bits
    wire msr_dcd = dcd_pad_i;
    wire msr_ri = ri_pad_i;
    wire msr_dsr = dsr_pad_i;
    wire msr_cts = cts_pad_i;

    // LSR bits
    wire lsr_thr_empty = fifo_tx_empty;
    wire lsr_tx_holdr_empty = fifo_tx_empty;
    wire lsr_break_err = rx_break_err;
    wire lsr_par_err = rx_par_err;
    wire lsr_fram_err = rx_fram_err;
    wire lsr_overrun = rx_overrun;
    wire lsr_data_avail = ~fifo_rx_empty;

    // IER bits
    wire ier_rx_data_avail = ier_reg[0];
    wire ier_tx_holdr_empty = ier_reg[1];
    wire ier_rx_line_status = ier_reg[2];
    wire ier_modem_status = ier_reg[3];

    // Interrupt sources
    assign int_rx_data_avail = lsr_data_avail;
    assign int_rx_line_status = lsr_break_err | lsr_par_err | lsr_fram_err | lsr_overrun;
    assign int_tx_holdr_empty = lsr_tx_holdr_empty;
    assign int_modem_status = msr_dcd | msr_ri | msr_dsr | msr_cts;

    // Interrupt enable
    assign int_enabled = ier_rx_data_avail | ier_tx_holdr_empty | ier_rx_line_status | ier_modem_status;

    // Interrupt pending
    assign int_pending = (ier_rx_data_avail & int_rx_data_avail) |
                         (ier_tx_holdr_empty & int_tx_holdr_empty) |
                         (ier_rx_line_status & int_rx_line_status) |
                         (ier_modem_status & int_modem_status);

    assign int_o = int_pending;

    // IIR value
    reg [7:0] iir_value;
    always @(*) begin
        if (int_rx_line_status) begin
            iir_value = 8'b0000_0001; // Line status interrupt
        end else if (int_rx_data_avail) begin
            iir_value = 8'b0000_0000; // Data available
        end else if (int_tx_holdr_empty) begin
            iir_value = 8'b0000_0010; // TX holdr empty
        end else if (int_modem_status) begin
            iir_value = 8'b0000_0100; // Modem status
        end else begin
            iir_value = 8'b0000_0101; // No interrupt
        end
    end

    // Register read mux
    reg [7:0] read_data;
    always @(*) begin
        if (dlab) begin
            if (wb_adr_i[1:0] == 2'b00) begin
                read_data = dll_reg;
            end else if (wb_adr_i[1:0] == 2'b01) begin
                read_data = dlh_reg;
            end else begin
                read_data = 8'b0;
            end
        end else begin
            case (wb_adr_i[1:0])
                2'b00: read_data = fifo_rx_empty ? 8'b0 : fifo_rx_data;
                2'b01: read_data = iir_value;
                2'b10: read_data = lcr_reg;
                2'b11: read_data = mcr_reg;
            endcase
            if (wb_adr_i[1:0] == 2'b00 && ~fifo_rx_empty) begin
                read_data = fifo_rx_data;
            end
        end
        if (wb_adr_i[1:0] == 2'b00 && dlab) begin
            read_data = dll_reg;
        end
        if (wb_adr_i[1:0] == 2'b01 && dlab) begin
            read_data = dlh_reg;
        end
        if (wb_adr_i[1:0] == 2'b10 && dlab) begin
            read_data = 8'b0;
        end
        if (wb_adr_i[1:0] == 2'b11 && dlab) begin
            read_data = 8'b0;
        end
        if (wb_adr_i[1:0] == 2'b00 && !dlab) begin
            read_data = fifo_rx_empty ? 8'b0 : fifo_rx_data;
        end
        if (wb_adr_i[1:0] == 2'b01 && !dlab) begin
            read_data = iir_value;
        end
        if (wb_adr_i[1:0] == 2'b10 && !dlab) begin
            read_data = lcr_reg;
        end
        if (wb_adr_i[1:0] == 2'b11 && !dlab) begin
            read_data = mcr_reg;
        end
        if (wb_adr_i[1:0] == 2'b00 && !dlab && wb_adr_i[2] == 1'b1) begin
            read_data = lsr_reg;
        end
        if (wb_adr_i[1:0] == 2'b01 && !dlab && wb_adr_i[2] == 1'b1) begin
            read_data = msr_reg;
        end
        if (wb_adr_i[1:0] == 2'b10 && !dlab && wb_adr_i[2] == 1'b1) begin
            read_data = scr_reg;
        end
        if (wb_adr_i[1:0] == 2'b11 && !dlab && wb_adr_i[2] == 1'b1) begin
            read_data = 8'b0;
        end
    end

    // Simplified register read
    always @(*) begin
        if (dlab) begin
            case (wb_adr_i[1:0])
                2'b00: read_data = dll_reg;
                2'b01: read_data = dlh_reg;
                default: read_data = 8'b0;
            endcase
        end else begin
            case (wb_adr_i[2:0])
                3'b000: read_data = fifo_rx_empty ? 8'b0 : fifo_rx_data;
                3'b001: read_data = iir_value;
                3'b010: read_data = lcr_reg;
                3'b011: read_data = mcr_reg;
                3'b100: read_data = lsr_reg;
                3'b101: read_data = msr_reg;
                3'b110: read_data = scr_reg;
                default: read_data = 8'b0;
            endcase
        end
    end

    assign wb_dat_o = read_data;

    // Register write
    reg [7:0] write_data;
    always @(*) begin
        write_data = wb_dat_i;
    end

    // Wishbone ACK
    assign wb_ack_o = wb_cyc_i & wb_stb_i;

    // Register file update
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rbr_thr_reg <= 8'b0;
            iir_reg <= 8'b0;
            lcr_reg <= 8'b0;
            mcr_reg <= 8'b0;
            lsr_reg <= 8'b0;
            msr_reg <= 8'b0;
            scr_reg <= 8'b0;
            dll_reg <= 8'b0;
            dlh_reg <= 8'b0;
            fcr_reg <= 8'b0;
            ier_reg <= 8'b0;
        end else if (wb_cyc_i & wb_stb_i & wb_we_i) begin
            if (dlab) begin
                case (wb_adr_i[1:0])
                    2'b00: dll_reg <= wb_dat_i;
                    2'b01: dlh_reg <= wb_dat_i;
                    default: ;
                endcase
            end else begin
                case (wb_adr_i[2:0])
                    3'b000: rbr_thr_reg <= wb_dat_i;
                    3'b001: ier_reg <= wb_dat_i;
                    3'b010: lcr_reg <= wb_dat_i;
                    3'b011: mcr_reg <= wb_dat_i;
                    3'b100: ; // LSR read-only
                    3'b101: ; // MSR read-only
                    3'b110: scr_reg <= wb_dat_i;
                    default: ;
                endcase
            end
        end
    end

    // LSR update
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            lsr_reg <= 8'b0;
        end else begin
            lsr_reg[0] <= lsr_data_avail;
            lsr_reg[1] <= lsr_thr_empty;
            lsr_reg[2] <= lsr_tx_holdr_empty;
            lsr_reg[3] <= lsr_break_err;
            lsr_reg[4] <= lsr_par_err;
            lsr_reg[5] <= lsr_fram_err;
            lsr_reg[6] <= lsr_overrun;
            lsr_reg[7] <= 1'b0;
        end
    end

    // MSR update
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            msr_reg <= 8'b0;
        end else begin
            msr_reg[0] <= msr_dcd;
            msr_reg[1] <= msr_ri;
            msr_reg[2] <= msr_dsr;
            msr_reg[3] <= msr_cts;
            msr_reg[4] <= ~msr_dcd;
            msr_reg[5] <= ~msr_ri;
            msr_reg[6] <= ~msr_dsr;
            msr_reg[7] <= ~msr_cts;
        end
    end

    // Modem control outputs
    assign dtr_pad_o = mcr_dtr;
    assign rts_pad_o = mcr_rts;

    // TX data from register
    assign tx_data = rbr_thr_reg;

    // TX start when data written and FIFO enabled
    assign tx_start = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[2:0] == 3'b000) & !dlab & fifo_tx_en;

    // Baud rate generator
    reg [15:0] baud_counter;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            baud_counter <= 16'b0;
        end else if (baud_div != 16'b0) begin
            if (baud_counter >= baud_div - 1) begin
                baud_counter <= 16'b0;
            end else begin
                baud_counter <= baud_counter + 1;
            end
        end else begin
            baud_counter <= 16'b0;
        end
    end

    assign baud_tick = (baud_counter == baud_div - 1) & (baud_div != 16'b0);

    // TX state machine
    reg [3:0] tx_state;
    reg [7:0] tx_shift_reg;
    reg [3:0] tx_bit_count;
    reg tx_par_bit;
    reg tx_stop_bit;

    localparam TX_IDLE = 4'b0000;
    localparam TX_START = 4'b0001;
    localparam TX_DATA = 4'b0010;
    localparam TX_PARITY = 4'b0011;
    localparam TX_STOP = 4'b0100;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_state <= TX_IDLE;
            tx_shift_reg <= 8'b0;
            tx_bit_count <= 4'b0;
            tx_par_bit <= 1'b0;
            tx_stop_bit <= 1'b0;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    if (tx_start) begin
                        tx_state <= TX_START;
                        tx_shift_reg <= tx_data;
                        tx_bit_count <= 4'b0;
                    end
                end
                TX_START: begin
                    if (baud_tick) begin
                        tx_state <= TX_DATA;
                        tx_bit_count <= 4'b0;
                    end
                end
                TX_DATA: begin
                    if (baud_tick) begin
                        if (tx_bit_count == lcr_word_len - 1) begin
                            if (lcr_parity_en) begin
                                tx_state <= TX_PARITY;
                            end else begin
                                tx_state <= TX_STOP;
                            end
                        end else begin
                            tx_bit_count <= tx_bit_count + 1;
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        end
                    end
                end
                TX_PARITY: begin
                    if (baud_tick) begin
                        tx_state <= TX_STOP;
                    end
                end
                TX_STOP: begin
                    if (baud_tick) begin
                        if (lcr_stop_bits) begin
                            tx_state <= TX_STOP;
                        end else begin
                            tx_state <= TX_IDLE;
                        end
                    end
                end
                default: tx_state <= TX_IDLE;
            endcase
        end
    end

    // TX output
    always @(*) begin
        case (tx_state)
            TX_IDLE: stx_pad_o = 1'b1;
            TX_START: stx_pad_o = 1'b0;
            TX_DATA: stx_pad_o = tx_shift_reg[0];
            TX_PARITY: stx_pad_o = tx_par_bit;
            TX_STOP: stx_pad_o = 1'b1;
            default: stx_pad_o = 1'b1;
        endcase
    end

    // RX state machine
    reg [3:0] rx_state;
    reg [7:0] rx_shift_reg;
    reg [3:0] rx_bit_count;
    reg rx_par_bit;

    localparam RX_IDLE = 4'b0000;
    localparam RX_START = 4'b0001;
    localparam RX_DATA = 4'b0010;
    localparam RX_PARITY = 4'b0011;
    localparam RX_STOP = 4'b0100;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_state <= RX_IDLE;
            rx_shift_reg <= 8'b0;
            rx_bit_count <= 4'b0;
            rx_par_bit <= 1'b0;
        end else begin
            case (rx_state)
                RX_IDLE: begin
                    if (srx_pad_i == 1'b0) begin
                        rx_state <= RX_START;
                        rx_shift_reg <= 8'b0;
                        rx_bit_count <= 4'b0;
                    end
                end
                RX_START: begin
                    if (baud_tick) begin
                        if (srx_pad_i == 1'b0) begin
                            rx_state <= RX_DATA;
                            rx_bit_count <= 4'b0;
                        end else begin
                            rx_state <= RX_IDLE;
                        end
                    end
                end
                RX_DATA: begin
                    if (baud_tick) begin
                        if (rx_bit_count == lcr_word_len - 1) begin
                            if (lcr_parity_en) begin
                                rx_state <= RX_PARITY;
                            end else begin
                                rx_state <= RX_STOP;
                            end
                        end else begin
                            rx_bit_count <= rx_bit_count + 1;
                            rx_shift_reg <= {srx_pad_i, rx_shift_reg[7:1]};
                        end
                    end
                end
                RX_PARITY: begin
                    if (baud_tick) begin
                        rx_par_bit <= srx_pad_i;
                        rx_state <= RX_STOP;
                    end
                end
                RX_STOP: begin
                    if (baud_tick) begin
                        if (lcr_stop_bits) begin
                            rx_state <= RX_STOP;
                        end else begin
                            rx_state <= RX_IDLE;
                        end
                    end
                end
                default: rx_state <= RX_IDLE;
            endcase
        end
    end

    // RX done
    assign rx_done = (rx_state == RX_STOP) & baud_tick & ~lcr_stop_bits;

    // RX data
    assign rx_data = rx_shift_reg;

    // RX errors
    assign rx_par_err = 1'b0;
    assign rx_break_err = 1'b0;
    assign rx_fram_err = 1'b0;
    assign rx_overrun = 1'b0;

    // FIFO RX
    reg [7:0] rx_fifo [0:15];
    reg [4:0] rx_fifo_wr_ptr;
    reg [4:0] rx_fifo_rd_ptr;
    reg rx_fifo_overflow;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_fifo_wr_ptr <= 5'b0;
            rx_fifo_rd_ptr <= 5'b0;
            rx_fifo_overflow <= 1'b0;
        end else begin
            if (fifo_rst) begin
                rx_fifo_wr_ptr <= 5'b0;
                rx_fifo_rd_ptr <= 5'b0;
                rx_fifo_overflow <= 1'b0;
            end else begin
                if (rx_done) begin
                    if (rx_fifo_wr_ptr != rx_fifo_rd_ptr) begin
                        rx_fifo[rx_fifo_wr_ptr[3:0]] <= rx_data;
                        rx_fifo_wr_ptr <= rx_fifo_wr_ptr + 1;
                    end else begin
                        rx_fifo_overflow <= 1'b1;
                    end
                end
                if (wb_cyc_i & wb_stb_i & ~wb_we_i & (wb_adr_i[2:0] == 3'b000) & !dlab & ~fifo_rx_empty) begin
                    rx_fifo_rd_ptr <= rx_fifo_rd_ptr + 1;
                end
            end
        end
    end

    assign fifo_rx_empty = (rx_fifo_wr_ptr == rx_fifo_rd_ptr);
    assign fifo_rx_full = (rx_fifo_wr_ptr[4:1] == rx_fifo_rd_ptr[4:1]) & (rx_fifo_wr_ptr[0] != rx_fifo_rd_ptr[0]);
    assign fifo_rx_data = rx_fifo[rx_fifo_rd_ptr[3:0]];
    assign fifo_rx_overrun = rx_fifo_overflow;
    assign fifo_rx_par_err = rx_par_err;
    assign fifo_rx_break_err = rx_break_err;
    assign fifo_rx_fram_err = rx_fram_err;

    // FIFO TX
    reg [7:0] tx_fifo [0:15];
    reg [4:0] tx_fifo_wr_ptr;
    reg [4:0] tx_fifo_rd_ptr;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_wr_ptr <= 5'b0;
            tx_fifo_rd_ptr <= 5'b0;
        end else begin
            if (fifo_rst) begin
                tx_fifo_wr_ptr <= 5'b0;
                tx_fifo_rd_ptr <= 5'b0;
            end else begin
                if (tx_start) begin
                    tx_fifo[tx_fifo_wr_ptr[3:0]] <= tx_data;
                    tx_fifo_wr_ptr <= tx_fifo_wr_ptr + 1;
                end
                if (tx_state == TX_IDLE & ~fifo_tx_empty) begin
                    tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 1;
                end
            end
        end
    end

    assign fifo_tx_empty = (tx_fifo_wr_ptr == tx_fifo_rd_ptr);
    assign fifo_tx_full = (tx_fifo_wr_ptr[4:1] == tx_fifo_rd_ptr[4:1]) & (tx_fifo_wr_ptr[0] != tx_fifo_rd_ptr[0]);
    assign fifo_tx_data = tx_fifo[tx_fifo_rd_ptr[3:0]];
    assign fifo_tx_overrun = 1'b0;
    assign fifo_tx_par_err = 1'b0;
    assign fifo_tx_break_err = 1'b0;
    assign fifo_tx_fram_err = 1'b0;

    // Update tx_data from FIFO
    always @(*) begin
        if (fifo_tx_empty) begin
            tx_data = 8'b0;
        end else begin
            tx_data = fifo_tx_data;
        end
    end

endmodule
