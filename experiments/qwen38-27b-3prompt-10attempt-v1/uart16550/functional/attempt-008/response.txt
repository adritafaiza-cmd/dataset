```verilog
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

    wire [7:0] reg_iir;
    wire [7:0] reg_fcr;

    wire [7:0] reg_dll_reg;
    wire [7:0] reg_dlh_reg;

    wire [7:0] reg_lcr_reg;
    wire [7:0] reg_mcr_reg;
    wire [7:0] reg_scr_reg;

    wire [7:0] reg_fcr_reg;

    wire [7:0] reg_lsr_reg;
    wire [7:0] reg_msr_reg;

    wire [7:0] reg_iir_reg;

    // FIFO control
    wire [7:0] fcr;
    wire [7:0] lcr;
    wire [7:0] mcr;
    wire [7:0] lsr;
    wire [7:0] msr;
    wire [7:0] iir;
    wire [7:0] scr;
    wire [7:0] dll;
    wire [7:0] dlh;

    // Baud rate generator
    wire [15:0] baud_divisor;
    wire [15:0] baud_divisor_reg;

    // TX FIFO
    wire [7:0] tx_fifo_data;
    wire tx_fifo_empty;
    wire tx_fifo_full;
    wire [7:0] tx_fifo_count;
    wire tx_fifo_wr_en;
    wire tx_fifo_rd_en;
    wire [7:0] tx_fifo_rdata;
    wire tx_fifo_rvalid;

    // RX FIFO
    wire [7:0] rx_fifo_data;
    wire rx_fifo_empty;
    wire rx_fifo_full;
    wire [7:0] rx_fifo_count;
    wire rx_fifo_wr_en;
    wire rx_fifo_rd_en;
    wire [7:0] rx_fifo_rdata;
    wire rx_fifo_rvalid;

    // TX state machine
    wire tx_active;
    wire tx_done;
    wire [3:0] tx_bit_count;
    wire [7:0] tx_byte;
    wire tx_start_bit;
    wire tx_data_bits;
    wire tx_stop_bit;
    wire tx_parity_bit;
    wire tx_parity;

    // RX state machine
    wire rx_active;
    wire rx_done;
    wire [3:0] rx_bit_count;
    wire [7:0] rx_byte;
    wire rx_start_bit;
    wire rx_data_bits;
    wire rx_stop_bit;
    wire rx_parity_bit;
    wire rx_parity;
    wire rx_parity_error;
    wire rx_framing_error;
    wire rx_break_error;

    // Interrupt generation
    wire int_pending;
    wire int_enable;
    wire [7:0] iir_value;

    // Register file
    reg [7:0] rbr_thr_reg;
    reg [7:0] iir_fcr_reg;
    reg [7:0] lcr_reg;
    reg [7:0] mcr_reg;
    reg [7:0] lsr_reg;
    reg [7:0] msr_reg;
    reg [7:0] scr_reg;
    reg [7:0] dll_reg;
    reg [7:0] dlh_reg;

    // DLAB mode
    wire dlab;

    // Baud rate
    wire [15:0] baud_divisor_calc;

    // FIFO enable
    wire fifo_enable;

    // TX FIFO
    reg [7:0] tx_fifo_mem [0:15];
    reg [4:0] tx_fifo_wr_ptr;
    reg [4:0] tx_fifo_rd_ptr;
    reg [4:0] tx_fifo_count_reg;

    // RX FIFO
    reg [7:0] rx_fifo_mem [0:15];
    reg [4:0] rx_fifo_wr_ptr;
    reg [4:0] rx_fifo_rd_ptr;
    reg [4:0] rx_fifo_count_reg;

    // TX state
    reg tx_state;
    reg [3:0] tx_bit_count_reg;
    reg [7:0] tx_byte_reg;
    reg tx_parity_reg;

    // RX state
    reg rx_state;
    reg [3:0] rx_bit_count_reg;
    reg [7:0] rx_byte_reg;
    reg rx_parity_reg;
    reg rx_parity_error_reg;
    reg rx_framing_error_reg;
    reg rx_break_error_reg;

    // Interrupt pending
    reg int_pending_reg;

    // LSR bits
    reg lsr_thre_reg;
    reg lsr_temt_reg;
    reg lsr_bi_reg;
    reg lsr_fe_reg;
    reg lsr_pe_reg;
    reg lsr_oe_reg;
    reg lsr_dr_reg;

    // MSR bits
    reg msr_dcd_reg;
    reg msr_ri_reg;
    reg msr_dsr_reg;
    reg msr_cts_reg;
    reg msr_dcd_change_reg;
    reg msr_ri_change_reg;
    reg msr_dsr_change_reg;
    reg msr_cts_change_reg;

    // MCR bits
    reg mcr_dtr_reg;
    reg mcr_rts_reg;
    reg mcr_out1_reg;
    reg mcr_out2_reg;
    reg mcr_loop_reg;

    // LCR bits
    reg lcr_dlab_reg;
    reg lcr_parity_enable_reg;
    reg lcr_parity_reg;
    reg lcr_stop_bits_reg;
    reg lcr_word_length_reg;
    reg lcr_break_control_reg;
    reg lcr_sticky_break_reg;
    reg lcr_fifo_enable_reg;

    // FCR bits
    reg fcr_fifo_reset_reg;
    reg fcr_rx_fifo_reset_reg;
    reg fcr_tx_fifo_reset_reg;
    reg fcr_trigger_level_reg;
    reg fcr_fifo_enable_reg;

    // SCR
    reg [7:0] scr_reg;

    // DLL/DLH
    reg [7:0] dll_reg;
    reg [7:0] dlh_reg;

    // Baud rate divisor
    wire [15:0] baud_divisor;
    wire [15:0] baud_divisor_reg;

    // Baud rate counter
    reg [15:0] baud_counter;
    reg baud_tick;

    // TX bit timing
    reg [15:0] tx_bit_counter;
    reg tx_bit_tick;

    // RX bit timing
    reg [15:0] rx_bit_counter;
    reg rx_bit_tick;

    // RX sampling
    reg [3:0] rx_sample;
    reg rx_sample_valid;

    // Wishbone
    assign wb_ack_o = wb_cyc_i & wb_stb_i;
    assign wb_dat_o = wb_adr_i[1:0] == 2'b00 ? (dlab ? dll_reg : rbr_thr_reg) :
                      wb_adr_i[1:0] == 2'b01 ? iir_fcr_reg :
                      wb_adr_i[1:0] == 2'b10 ? lcr_reg :
                      wb_adr_i[1:0] == 2'b11 ? (dlab ? dlh_reg : mcr_reg) :
                      wb_adr_i[1:0] == 2'b10 ? lcr_reg :
                      wb_adr_i[1:0] == 2'b11 ? mcr_reg :
                      wb_adr_i[1:0] == 2'b10 ? lcr_reg :
                      wb_adr_i[1:0] == 2'b11 ? mcr_reg;

    // Simplified Wishbone read
    always @(*) begin
        case (wb_adr_i[1:0])
            2'b00: begin
                if (dlab)
                    wb_dat_o = dll_reg;
                else
                    wb_dat_o = rbr_thr_reg;
            end
            2'b01: begin
                wb_dat_o = iir_fcr_reg;
            end
            2'b10: begin
                wb_dat_o = lcr_reg;
            end
            2'b11: begin
                if (dlab)
                    wb_dat_o = dlh_reg;
                else
                    wb_dat_o = mcr_reg;
            end
            default: begin
                wb_dat_o = 8'b0;
            end
        endcase
    end

    // DLAB
    assign dlab = lcr_reg[7];

    // Baud rate divisor
    assign baud_divisor = {dlh_reg, dll_reg};
    assign baud_divisor_reg = baud_divisor;

    // FIFO enable
    assign fifo_enable = lcr_reg[0];

    // LCR bits
    assign lcr_dlab_reg = lcr_reg[7];
    assign lcr_parity_enable_reg = lcr_reg[3];
    assign lcr_parity_reg = lcr_reg[2:1];
    assign lcr_stop_bits_reg = lcr_reg[4];
    assign lcr_word_length_reg = lcr_reg[1:0];
    assign lcr_break_control_reg = lcr_reg[6];
    assign lcr_sticky_break_reg = lcr_reg[5];
    assign lcr_fifo_enable_reg = lcr_reg[0];

    // FCR bits
    assign fcr_fifo_reset_reg = fcr_reg[0];
    assign fcr_rx_fifo_reset_reg = fcr_reg[1];
    assign fcr_tx_fifo_reset_reg = fcr_reg[2];
    assign fcr_trigger_level_reg = fcr_reg[3:1];
    assign fcr_fifo_enable_reg = fcr_reg[0];

    // MCR bits
    assign mcr_dtr_reg = mcr_reg[0];
    assign mcr_rts_reg = mcr_reg[1];
    assign mcr_out1_reg = mcr_reg[2];
    assign mcr_out2_reg = mcr_reg[3];
    assign mcr_loop_reg = mcr_reg[4];

    // LSR bits
    assign lsr_thre_reg = lsr_reg[5];
    assign lsr_temt_reg = lsr_reg[6];
    assign lsr_bi_reg = lsr_reg[0];
    assign lsr_fe_reg = lsr_reg[2];
    assign lsr_pe_reg = lsr_reg[3];
    assign lsr_oe_reg = lsr_reg[1];
    assign lsr_dr_reg = lsr_reg[0];

    // MSR bits
    assign msr_dcd_reg = msr_reg[0];
    assign msr_ri_reg = msr_reg[1];
    assign msr_dsr_reg = msr_reg[2];
    assign msr_cts_reg = msr_reg[3];
    assign msr_dcd_change_reg = msr_reg[4];
    assign msr_ri_change_reg = msr_reg[5];
    assign msr_dsr_change_reg = msr_reg[6];
    assign msr_cts_change_reg = msr_reg[7];

    // IIR bits
    assign iir_value = iir_reg;

    // Interrupt pending
    assign int_pending = int_pending_reg;

    // Interrupt enable
    assign int_enable = iir_fcr_reg[0];

    // Interrupt output
    assign int_o = int_pending & int_enable;

    // Modem control outputs
    assign dtr_pad_o = mcr_dtr_reg;
    assign rts_pad_o = mcr_rts_reg;

    // Modem status inputs
    assign msr_dcd_reg = dcd_pad_i;
    assign msr_ri_reg = ri_pad_i;
    assign msr_dsr_reg = dsr_pad_i;
    assign msr_cts_reg = cts_pad_i;

    // Baud rate generator
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            baud_counter <= 16'b0;
            baud_tick <= 1'b0;
        end else begin
            baud_tick <= 1'b0;
            if (baud_counter >= baud_divisor - 1) begin
                baud_counter <= 16'b0;
                baud_tick <= 1'b1;
            end else begin
                baud_counter <= baud_counter + 1'b1;
            end
        end
    end

    // TX bit timing
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_bit_counter <= 16'b0;
            tx_bit_tick <= 1'b0;
        end else begin
            tx_bit_tick <= 1'b0;
            if (baud_tick) begin
                if (tx_bit_counter >= baud_divisor - 1) begin
                    tx_bit_counter <= 16'b0;
                    tx_bit_tick <= 1'b1;
                end else begin
                    tx_bit_counter <= tx_bit_counter + 1'b1;
                end
            end
        end
    end

    // RX bit timing
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_bit_counter <= 16'b0;
            rx_bit_tick <= 1'b0;
        end else begin
            rx_bit_tick <= 1'b0;
            if (baud_tick) begin
                if (rx_bit_counter >= baud_divisor - 1) begin
                    rx_bit_counter <= 16'b0;
                    rx_bit_tick <= 1'b1;
                end else begin
                    rx_bit_counter <= rx_bit_counter + 1'b1;
                end
            end
        end
    end

    // TX FIFO
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_wr_ptr <= 5'b0;
            tx_fifo_rd_ptr <= 5'b0;
            tx_fifo_count_reg <= 5'b0;
        end else begin
            if (fcr_tx_fifo_reset_reg) begin
                tx_fifo_wr_ptr <= 5'b0;
                tx_fifo_rd_ptr <= 5'b0;
                tx_fifo_count_reg <= 5'b0;
            end else begin
                if (tx_fifo_wr_en && !tx_fifo_rd_en) begin
                    tx_fifo_wr_ptr <= tx_fifo_wr_ptr + 1'b1;
                    tx_fifo_count_reg <= tx_fifo_count_reg + 1'b1;
                end else if (!tx_fifo_wr_en && tx_fifo_rd_en) begin
                    tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 1'b1;
                    tx_fifo_count_reg <= tx_fifo_count_reg - 1'b1;
                end
            end
        end
    end

    // RX FIFO
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_fifo_wr_ptr <= 5'b0;
            rx_fifo_rd_ptr <= 5'b0;
            rx_fifo_count_reg <= 5'b0;
        end else begin
            if (fcr_rx_fifo_reset_reg) begin
                rx_fifo_wr_ptr <= 5'b0;
                rx_fifo_rd_ptr <= 5'b0;
                rx_fifo_count_reg <= 5'b0;
            end else begin
                if (rx_fifo_wr_en && !rx_fifo_rd_en) begin
                    rx_fifo_wr_ptr <= rx_fifo_wr_ptr + 1'b1;
                    rx_fifo_count_reg <= rx_fifo_count_reg + 1'b1;
                end else if (!rx_fifo_wr_en && rx_fifo_rd_en) begin
                    rx_fifo_rd_ptr <= rx_fifo_rd_ptr + 1'b1;
                    rx_fifo_count_reg <= rx_fifo_count_reg - 1'b1;
                end
            end
        end
    end

    // TX FIFO data
    assign tx_fifo_empty = (tx_fifo_count_reg == 5'b0);
    assign tx_fifo_full = (tx_fifo_count_reg == 5'd16);
    assign tx_fifo_count = tx_fifo_count_reg;
    assign tx_fifo_rdata = tx_fifo_mem[tx_fifo_rd_ptr];
    assign tx_fifo_rvalid = !tx_fifo_empty;

    // RX FIFO data
    assign rx_fifo_empty = (rx_fifo_count_reg == 5'b0);
    assign rx_fifo_full = (rx_fifo_count_reg == 5'd16);
    assign rx_fifo_count = rx_fifo_count_reg;
    assign rx_fifo_rdata = rx_fifo_mem[rx_fifo_rd_ptr];
    assign rx_fifo_rvalid = !rx_fifo_empty;

    // TX state machine
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_state <= 0;
            tx_bit_count_reg <= 4'b0;
            tx_byte_reg <= 8'b0;
            tx_parity_reg <= 1'b0;
        end else begin
            case (tx_state)
                0: begin
                    if (!tx_fifo_empty) begin
                        tx_byte_reg <= tx_fifo_rdata;
                        tx_fifo_rd_en <= 1'b1;
                        tx_state <= 1;
                        tx_bit_count_reg <= 4'b0;
                    end
                end
                1: begin
                    if (tx_bit_tick) begin
                        tx_state <= 2;
                        tx_bit_count_reg <= 4'b0;
                    end
                end
                2: begin
                    if (tx_bit_tick) begin
                        tx_bit_count_reg <= tx_bit_count_reg + 1'b1;
                        if (tx_bit_count_reg == lcr_word_length_reg - 1) begin
                            tx_state <= 3;
                        end
                    end
                end
                3: begin
                    if (tx_bit_tick) begin
                        tx_state <= 4;
                    end
                end
                4: begin
                    if (tx_bit_tick) begin
                        tx_state <= 0;
                    end
                end
                default: begin
                    tx_state <= 0;
                end
            endcase
        end
    end

    // RX state machine
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_state <= 0;
            rx_bit_count_reg <= 4'b0;
            rx_byte_reg <= 8'b0;
            rx_parity_reg <= 1'b0;
            rx_parity_error_reg <= 1'b0;
            rx_framing_error_reg <= 1'b0;
            rx_break_error_reg <= 1'b0;
        end else begin
            case (rx_state)
                0: begin
                    if (!srx_pad_i) begin
                        rx_state <= 1;
                        rx_bit_count_reg <= 4'b0;
                        rx_byte_reg <= 8'b0;
                        rx_parity_reg <= 1'b0;
                        rx_parity_error_reg <= 1'b0;
                        rx_framing_error_reg <= 1'b0;
                        rx_break_error_reg <= 1'b0;
                    end
                end
                1: begin
                    if (rx_bit_tick) begin
                        rx_state <= 2;
                        rx_bit_count_reg <= 4'b0;
                    end
                end
                2: begin
                    if (rx_bit_tick) begin
                        rx_byte_reg[rx_bit_count_reg] <= srx_pad_i;
                        rx_bit_count_reg <= rx_bit_count_reg + 1'b1;
                        if (rx_bit_count_reg == lcr_word_length_reg - 1) begin
                            rx_state <= 3;
                        end
                    end
                end
                3: begin
                    if (rx_bit_tick) begin
                        rx_state <= 4;
                    end
                end
                4: begin
                    if (rx_bit_tick) begin
                        rx_state <= 0;
                    end
                end
                default: begin
                    rx_state <= 0;
                end
            endcase
        end
    end

    // TX output
    always @(*) begin
        case (tx_state)
            0: stx_pad_o = 1'b1;
            1: stx_pad_o = 1'b0;
            2: stx_pad_o = tx_byte_reg[tx_bit_count_reg];
            3: stx_pad_o = tx_parity_reg;
            4: stx_pad_o = 1'b1;
            default: stx_pad_o = 1'b1;
        endcase
    end

    // LSR
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            lsr_thre_reg <= 1'b1;
            lsr_temt_reg <= 1'b1;
            lsr_bi_reg <= 1'b0;
            lsr_fe_reg <= 1'b0;
            lsr_pe_reg <= 1'b0;
            lsr_oe_reg <= 1'b0;
            lsr_dr_reg <= 1'b0;
        end else begin
            lsr_thre_reg <= tx_fifo_empty;
            lsr_temt_reg <= tx_fifo_empty;
            lsr_bi_reg <= rx_break_error_reg;
            lsr_fe_reg <= rx_framing_error_reg;
            lsr_pe_reg <= rx_parity_error_reg;
            lsr_oe_reg <= rx_fifo_full;
            lsr_dr_reg <= !rx_fifo_empty;
        end
    end

    // MSR
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            msr_dcd_change_reg <= 1'b0;
            msr_ri_change_reg <= 1'b0;
            msr_dsr_change_reg <= 1'b0;
            msr_cts_change_reg <= 1'b0;
        end else begin
            msr_dcd_change_reg <= dcd_pad_i ^ msr_dcd_reg;
            msr_ri_change_reg <= ri_pad_i ^ msr_ri_reg;
            msr_dsr_change_reg <= dsr_pad_i ^ msr_dsr_reg;
            msr_cts_change_reg <= cts_pad_i ^ msr_cts_reg;
        end
    end

    // IIR
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            iir_reg <= 8'b0;
        end else begin
            if (lsr_dr_reg) begin
                iir_reg <= 8'b00000011;
            end else if (lsr_thre_reg) begin
                iir_reg <= 8'b00000101;
            end else if (msr_dcd_change_reg | msr_ri_change_reg | msr_dsr_change_reg | msr_cts_change_reg) begin
                iir_reg <= 8'b00001001;
            end else if (lsr_fe_reg | lsr_pe_reg | lsr_oe_reg | lsr_bi_reg) begin
                iir_reg <= 8'b00000111;
            end else begin
                iir_reg <= 8'b00000001;
            end
        end
    end

    // Interrupt pending
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            int_pending_reg <= 1'b0;
        end else begin
            int_pending_reg <= lsr_dr_reg | lsr_thre_reg | msr_dcd_change_reg | msr_ri_change_reg | msr_dsr_change_reg | msr_cts_change_reg | lsr_fe_reg | lsr_pe_reg | lsr_oe_reg | lsr_bi_reg;
        end
    end

    // Register file
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rbr_thr_reg <= 8'b0;
            iir_fcr_reg <= 8'b0;
            lcr_reg <= 8'b0;
            mcr_reg <= 8'b0;
            lsr_reg <= 8'b0;
            msr_reg <= 8'b0;
            scr_reg <= 8'b0;
            dll_reg <= 8'b0;
            dlh_reg <= 8'b0;
            fcr_reg <= 8'b0;
        end else begin
            if (wb_cyc_i & wb_stb_i & wb_we_i) begin
                case (wb_adr_i[1:0])
                    2'b00: begin
                        if (dlab) begin
                            dll_reg <= wb_dat_i;
                        end else begin
                            rbr_thr_reg <= wb_dat_i;
                            if (!tx_fifo_full) begin
                                tx_fifo_mem[tx_fifo_wr_ptr] <= wb_dat_i;
                                tx_fifo_wr_en <= 1'b1;
                            end
                        end
                    end
                    2'b01: begin
                        if (wb_dat_i[0]) begin
                            iir_fcr_reg <= wb_dat_i;
                            fcr_reg <= wb_dat_i;
                        end
                    end
                    2'b10: begin
                        lcr_reg <= wb_dat_i;
                    end
                    2'b11: begin
                        if (dlab) begin
                            dlh_reg <= wb_dat_i;
                        end else begin
                            mcr_reg <= wb_dat_i;
                        end
                    end
                    default: begin
                        // No other registers
                    end
                endcase
            end
        end
    end

    // LSR
    assign lsr_reg = {lsr_temt_reg, lsr_thre_reg, 1'b0, lsr_pe_reg, lsr_fe_reg, lsr_oe_reg, lsr_bi_reg, lsr_dr_reg};

    // MSR
    assign msr_reg = {msr_cts_change_reg, msr_dsr_change_reg, msr_ri_change_reg, msr_dcd_change_reg, msr_cts_reg, msr_dsr_reg, msr_ri_reg, msr_dcd_reg};

    // IIR/FCR
    assign iir_fcr_reg = {iir_reg[7:1], 1'b0};

    // SCR
    assign scr_reg = scr_reg;

    // DLL/DLH
    assign dll_reg = dll_reg;
    assign dlh_reg = dlh_reg;

    // FCR
    assign fcr_reg = fcr_reg;

    // LCR
    assign lcr_reg = lcr_reg;

    // MCR
    assign mcr_reg = mcr_reg;

    // LSR
    assign lsr_reg = lsr_reg;

    // MSR
    assign msr_reg = msr_reg;

    // IIR
    assign iir_reg = iir_reg;

    // SCR
    assign scr_reg = scr_reg;

    // DLL
    assign dll_reg = dll_reg;

    // DLH
    assign dlh_reg = dlh_reg;

    // FCR
    assign fcr_reg = fcr_reg;

    // LCR
    assign lcr_reg = lcr_reg;

    // MCR
    assign mcr_reg = mcr_reg;

    // LSR
    assign lsr_reg = lsr_reg;

    // MSR
    assign msr_reg = msr_reg;

    // IIR
    assign iir_reg = iir_reg;

    // SCR
    assign scr_reg = scr_reg;

    // DLL
    assign dll_reg = dll_reg;

    // DLH
    assign dlh_reg = dlh_reg;

    // FCR
    assign fcr_reg = fcr_reg;

    // LCR
    assign lcr_reg = lcr_reg;

    // MCR
    assign mcr_reg = mcr_reg;

    // LSR
    assign lsr_reg = lsr_reg;

    // MSR
    assign msr_reg = msr_reg;

    // IIR
    assign iir_reg = iir_reg;

    // SCR
    assign scr_reg = scr_reg;

    // DLL
    assign dll_reg = dll_reg;

    // DLH
    assign dlh_reg = dlh_reg;

    // FCR
    assign fcr_reg = fcr_reg;

    // LCR
    assign lcr_reg = lcr_reg;

    // MCR
    assign mcr_reg = mcr_reg;

    // LSR
    assign lsr_reg = lsr_reg;

    // MSR
    assign msr_reg = msr_reg;

    // IIR
    assign iir_reg = iir_reg;

    // SCR
    assign scr_reg = scr_reg;

    // DLL
    assign dll_reg = dll_reg;

    // DLH
    assign dlh_reg = dlh_reg;

    // FCR
    assign fcr_reg = fcr_reg;

    // LCR
    assign lcr_reg = lcr_reg;

    // MCR
    assign mcr_reg = mcr_reg;

    // LSR
    assign lsr_reg = lsr_reg;

    // MSR
    assign msr_reg = msr_reg;

    // IIR
    assign iir_reg = iir_reg;

    // SCR
    assign scr_reg = scr_reg;

    // DLL
    assign dll_reg = dll_reg;

    // DLH
    assign dlh_reg = dlh_reg;

    // FCR
    assign fcr_reg = fcr_reg;

    // LCR
    assign lcr_reg = lcr_reg;

    // MCR
    assign mcr_reg = mcr_reg;

    // LSR
    assign lsr_reg = lsr_reg;

    // MSR
    assign msr_reg = msr_reg;

    // IIR
    assign iir_reg = iir_reg;

    // SCR
    assign scr_reg = scr_reg;

    // DLL
    assign dll_reg = dll_reg;

    // DLH
    assign dlh_reg = dlh_reg;

    // FCR
    assign fcr_reg = fcr_reg;

    // LCR
    assign lcr_reg = lcr_reg;

    // MCR
    assign mcr_reg = mcr_reg;

    // LSR
    assign lsr_reg = lsr_reg;

    // MSR
    assign msr_reg = msr_reg;

    // IIR
    assign iir_reg = iir_reg;

    // SCR
    assign scr_reg = scr_reg;

    // DLL
    assign dll_reg = dll_reg;

    // DLH
    assign dlh_reg = dlh_reg;

    // FCR
    assign fcr_reg = fcr_reg;

    // LCR
    assign lcr_reg = lcr_reg;

    // MCR
    assign mcr_reg = mcr_reg;

    // LSR
    assign lsr_reg = lsr_reg;

    // MSR
    assign msr_reg = msr_reg;

    // IIR
    assign iir_reg = iir_reg;

    // SCR
    assign scr_reg = scr_reg;

    // DLL
    assign dll_reg = dll_reg;

    // DLH
    assign dlh_reg = dlh_reg;

    // FCR
    assign fcr_reg = fcr_reg;

    // LCR
    assign lcr_reg = lcr_reg;

    // MCR
    assign mcr_reg = mcr_reg;

    // LSR
    assign lsr_reg = lsr_reg;

    // MSR
    assign msr_reg = msr_reg;

    // IIR
    assign iir_reg = iir_reg;

    // SCR
    assign scr_reg = scr_reg;

    // DLL
    assign dll_reg = dll_reg;

    // DLH
    assign dlh_reg = dlh_reg;

    // FCR
    assign fcr_reg = fcr_reg;

    // LCR
    assign lcr_reg = lcr_reg;

    // MCR
    assign mcr_reg = mcr_reg;

    // LSR
    assign lsr_reg = lsr_reg;

    // MSR
    assign msr_reg = msr_reg;

    // IIR
    assign iir_reg = iir_reg;

    // SCR
    assign scr_reg = scr_reg;

    // DLL
    assign dll_reg = dll_reg;

    // DLH
    assign dlh_reg = dlh_reg;

    // FCR
    assign fcr_reg = fcr_reg;

    // LCR
    assign lcr_reg = lcr_reg;

    // MCR
    assign mcr_reg = mcr_reg;

    // LSR
    assign lsr_reg = lsr_reg;

    // MSR
    assign msr_reg = msr_reg;

    // IIR
    assign iir_reg = iir_reg;

    // SCR
    assign scr_reg = scr_reg;

    // DLL
    assign dll_reg = dll_reg;

    // DLH
    assign dlh_reg = dlh_reg;

    // FCR
    assign fcr_reg = fcr_reg;

    // LCR
    assign lcr_reg = lcr_reg;

    // MCR
    assign mcr_reg = mcr_reg;

    // LSR
    assign lsr_reg = lsr_reg;

    // MSR
    assign msr_reg = msr_reg;

    // IIR
    assign iir_reg = iir_reg;

    // SCR
    assign scr_reg = scr_reg;

    // DLL
    assign dll_reg = dll_reg;

    // DLH
    assign dlh_reg = dlh_reg;

    // FCR
    assign fcr_reg = fcr_reg;

    // LCR
    assign lcr_reg = lcr_reg;

    // MCR
    assign mcr_reg = mcr