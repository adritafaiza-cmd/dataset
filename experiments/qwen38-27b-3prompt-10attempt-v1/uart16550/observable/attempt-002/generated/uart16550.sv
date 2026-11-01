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

    // Wishbone register file
    reg [7:0] rbr_thr;      // 0x00: Receive Buffer / Transmit Holding Register
    reg [7:0] ier;          // 0x01: Interrupt Enable Register
    reg [7:0] iir_fcr;      // 0x02: Interrupt ID / FIFO Control Register
    reg [7:0] lcr;          // 0x03: Line Control Register
    reg [7:0] mcr;          // 0x04: Modem Control Register
    reg [7:0] lsr;          // 0x05: Line Status Register
    reg [7:0] msr;          // 0x06: Modem Status Register
    reg [7:0] scr;          // 0x07: Scratch Register
    reg [7:0] dll;          // 0x00: Divisor Latch Low (when DLAB=1)
    reg [7:0] dlm;          // 0x01: Divisor Latch High (when DLAB=1)
    reg [7:0] mcr_ext;      // 0x08: Extended Modem Control Register (for 16550)
    reg [7:0] isr;          // 0x09: Interrupt Set Register (for 16550)

    // FIFOs
    reg [7:0] rx_fifo [0:15];
    reg [3:0] rx_fifo_wr_ptr;
    reg [3:0] rx_fifo_rd_ptr;
    reg [3:0] rx_fifo_count;

    reg [7:0] tx_fifo [0:15];
    reg [3:0] tx_fifo_wr_ptr;
    reg [3:0] tx_fifo_rd_ptr;
    reg [3:0] tx_fifo_count;

    // UART state
    reg [15:0] baud_divider;
    reg [15:0] baud_counter;
    reg        tx_active;
    reg [3:0]  tx_bit_count;
    reg [7:0]  tx_shift_reg;
    reg        tx_start_bit;
    reg        tx_stop_bit;
    reg        tx_parity_bit;
    reg        tx_parity;
    reg        tx_parity_error;

    reg        rx_active;
    reg [3:0]  rx_bit_count;
    reg [7:0]  rx_shift_reg;
    reg        rx_start_bit;
    reg        rx_stop_bit;
    reg        rx_parity_bit;
    reg        rx_parity;
    reg        rx_parity_error;
    reg        rx_frame_error;
    reg        rx_break_error;
    reg        rx_overrun_error;

    // Modem signals
    reg        rts_int;
    reg        dtr_int;
    reg        loopback;

    // Interrupts
    reg        int_rx_data;
    reg        int_rx_timeout;
    reg        int_tx_empty;
    reg        int_tx_holding;
    reg        int_line_status;
    reg        int_modem_status;

    // Wishbone
    reg        wb_ack_int;
    reg [31:0] wb_dat_int;

    // DLAB
    wire dlab = lcr[7];

    // Parity settings
    wire parity_enable = lcr[0];
    wire parity_odd = lcr[1];
    wire parity_sticky = lcr[2];
    wire parity_type = lcr[3:2]; // 00: even, 01: odd, 10: space, 11: mark
    wire stop_bits_2 = lcr[4];
    wire break_enable = lcr[6];
    wire send_break = lcr[5];

    // FIFO control
    wire fifo_enable = iir_fcr[0];
    wire fifo_reset_rx = iir_fcr[4];
    wire fifo_reset_tx = iir_fcr[5];
    wire [1:0] fifo_trigger_level = iir_fcr[7:6];

    // Interrupt enables
    wire ier_rx_data = ier[0];
    wire ier_tx_holding = ier[1];
    wire ier_line_status = ier[2];
    wire ier_modem_status = ier[3];

    // LSR bits
    wire lsr_dr = (rx_fifo_count > 0);
    wire lsr_oe = rx_overrun_error;
    wire lsr_pe = rx_parity_error;
    wire lsr_fe = rx_frame_error;
    wire lsr_bi = rx_break_error;
    wire lsr_thre = (tx_fifo_count == 0);
    wire lsr_temt = (tx_fifo_count == 0) && !tx_active;
    wire lsr_err = lsr_oe | lsr_pe | lsr_fe | lsr_bi;

    // MSR bits
    wire msr_dcd = dcd_pad_i;
    wire msr_ri = ri_pad_i;
    wire msr_dsr = dsr_pad_i;
    wire msr_cts = cts_pad_i;
    wire msr_dcd_change = msr_dcd ^ msr_dcd_reg;
    wire msr_ri_change = msr_ri ^ msr_ri_reg;
    wire msr_dsr_change = msr_dsr ^ msr_dsr_reg;
    wire msr_cts_change = msr_cts ^ msr_cts_reg;

    reg msr_dcd_reg, msr_ri_reg, msr_dsr_reg, msr_cts_reg;

    // Interrupt ID
    reg [3:0] int_id;
    reg [3:0] int_priority;

    // Baud rate calculation
    wire [15:0] baud_div = {dlm, dll};

    // Parity calculation
    function [7:0] calc_parity;
        input [7:0] data;
        input odd;
        input space;
        input mark;
        reg [7:0] sum;
        begin
            sum = 0;
            if (space)
                calc_parity = 0;
            else if (mark)
                calc_parity = 1;
            else begin
                sum = data[0] ^ data[1] ^ data[2] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7];
                if (odd)
                    calc_parity = ~sum;
                else
                    calc_parity = sum;
            end
        end
    endfunction

    // Wishbone address decode
    wire [2:0] wb_addr = wb_adr_i[2:0];
    wire wb_read = wb_cyc_i && wb_stb_i && !wb_we_i;
    wire wb_write = wb_cyc_i && wb_stb_i && wb_we_i;

    // FIFO trigger levels
    wire [3:0] rx_trigger = fifo_trigger_level[1:0];
    wire [3:0] tx_trigger = fifo_trigger_level[1:0];

    // Interrupt generation
    assign int_rx_data = (rx_fifo_count >= rx_trigger) && ier_rx_data;
    assign int_tx_holding = (tx_fifo_count < tx_trigger) && ier_tx_holding;
    assign int_line_status = lsr_err && ier_line_status;
    assign int_modem_status = (msr_dcd_change | msr_ri_change | msr_dsr_change | msr_cts_change) && ier_modem_status;

    // Interrupt priority
    always @(*) begin
        if (int_rx_data) begin
            int_id = 4'd0;
            int_priority = 4'd0;
        end else if (int_line_status) begin
            int_id = 4'd6;
            int_priority = 4'd1;
        end else if (int_tx_holding) begin
            int_id = 4'd5;
            int_priority = 4'd2;
        end else if (int_modem_status) begin
            int_id = 4'd4;
            int_priority = 4'd3;
        end else begin
            int_id = 4'd1;
            int_priority = 4'd4;
        end
    end

    assign int_o = int_rx_data | int_line_status | int_tx_holding | int_modem_status;

    // Modem control
    assign rts_pad_o = loopback ? cts_pad_i : rts_int;
    assign dtr_pad_o = loopback ? dsr_pad_i : dtr_int;

    // UART transmit
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_active <= 1'b0;
            tx_bit_count <= 4'd0;
            tx_shift_reg <= 8'd0;
            tx_start_bit <= 1'b0;
            tx_stop_bit <= 1'b0;
            tx_parity_bit <= 1'b0;
            tx_parity <= 1'b0;
            tx_parity_error <= 1'b0;
            stx_pad_o <= 1'b1;
        end else begin
            if (send_break) begin
                tx_active <= 1'b1;
                tx_bit_count <= 4'd0;
                tx_shift_reg <= 8'd0;
                tx_start_bit <= 1'b0;
                tx_stop_bit <= 1'b0;
                tx_parity_bit <= 1'b0;
                tx_parity <= 1'b0;
                tx_parity_error <= 1'b0;
                stx_pad_o <= 1'b0;
            end else if (tx_active) begin
                if (baud_counter == 16'd0) begin
                    baud_counter <= baud_div - 16'd1;
                    case (tx_bit_count)
                        4'd0: begin
                            // Start bit
                            tx_start_bit <= 1'b0;
                            stx_pad_o <= 1'b0;
                            tx_bit_count <= 4'd1;
                        end
                        4'd1: begin
                            // Data bit 0
                            tx_shift_reg <= tx_shift_reg;
                            stx_pad_o <= tx_shift_reg[0];
                            tx_bit_count <= 4'd2;
                        end
                        4'd2: begin
                            // Data bit 1
                            stx_pad_o <= tx_shift_reg[1];
                            tx_bit_count <= 4'd3;
                        end
                        4'd3: begin
                            // Data bit 2
                            stx_pad_o <= tx_shift_reg[2];
                            tx_bit_count <= 4'd4;
                        end
                        4'd4: begin
                            // Data bit 3
                            stx_pad_o <= tx_shift_reg[3];
                            tx_bit_count <= 4'd5;
                        end
                        4'd5: begin
                            // Data bit 4
                            stx_pad_o <= tx_shift_reg[4];
                            tx_bit_count <= 4'd6;
                        end
                        4'd6: begin
                            // Data bit 5
                            stx_pad_o <= tx_shift_reg[5];
                            tx_bit_count <= 4'd7;
                        end
                        4'd7: begin
                            // Data bit 6
                            stx_pad_o <= tx_shift_reg[6];
                            tx_bit_count <= 4'd8;
                        end
                        4'd8: begin
                            // Data bit 7
                            stx_pad_o <= tx_shift_reg[7];
                            tx_bit_count <= 4'd9;
                        end
                        4'd9: begin
                            // Parity bit
                            if (parity_enable) begin
                                tx_parity_bit <= calc_parity(tx_shift_reg, parity_odd, (parity_type == 2'b10), (parity_type == 2'b11));
                                stx_pad_o <= tx_parity_bit;
                            end else begin
                                stx_pad_o <= 1'b1;
                            end
                            tx_bit_count <= 4'd10;
                        end
                        4'd10: begin
                            // Stop bit 1
                            tx_stop_bit <= 1'b1;
                            stx_pad_o <= 1'b1;
                            if (stop_bits_2)
                                tx_bit_count <= 4'd11;
                            else
                                tx_bit_count <= 4'd12;
                        end
                        4'd11: begin
                            // Stop bit 2
                            stx_pad_o <= 1'b1;
                            tx_bit_count <= 4'd12;
                        end
                        4'd12: begin
                            // End of transmission
                            tx_active <= 1'b0;
                            stx_pad_o <= 1'b1;
                            tx_bit_count <= 4'd0;
                        end
                        default: begin
                            tx_active <= 1'b0;
                            stx_pad_o <= 1'b1;
                            tx_bit_count <= 4'd0;
                        end
                    endcase
                end else begin
                    baud_counter <= baud_counter - 16'd1;
                end
            end else begin
                // Check if we can start a new transmission
                if (tx_fifo_count > 0) begin
                    tx_active <= 1'b1;
                    tx_bit_count <= 4'd0;
                    tx_shift_reg <= tx_fifo[tx_fifo_rd_ptr];
                    tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 4'd1;
                    tx_fifo_count <= tx_fifo_count - 4'd1;
                    baud_counter <= baud_div - 16'd1;
                    stx_pad_o <= 1'b0;
                end else begin
                    stx_pad_o <= 1'b1;
                end
            end
        end
    end

    // UART receive
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_active <= 1'b0;
            rx_bit_count <= 4'd0;
            rx_shift_reg <= 8'd0;
            rx_start_bit <= 1'b0;
            rx_stop_bit <= 1'b0;
            rx_parity_bit <= 1'b0;
            rx_parity <= 1'b0;
            rx_parity_error <= 1'b0;
            rx_frame_error <= 1'b0;
            rx_break_error <= 1'b0;
            rx_overrun_error <= 1'b0;
        end else begin
            if (rx_active) begin
                if (baud_counter == 16'd0) begin
                    baud_counter <= baud_div - 16'd1;
                    case (rx_bit_count)
                        4'd0: begin
                            // Start bit
                            rx_start_bit <= srx_pad_i;
                            if (srx_pad_i) begin
                                // No start bit, abort
                                rx_active <= 1'b0;
                                rx_bit_count <= 4'd0;
                            end else begin
                                rx_bit_count <= 4'd1;
                            end
                        end
                        4'd1: begin
                            // Data bit 0
                            rx_shift_reg[0] <= srx_pad_i;
                            rx_bit_count <= 4'd2;
                        end
                        4'd2: begin
                            // Data bit 1
                            rx_shift_reg[1] <= srx_pad_i;
                            rx_bit_count <= 4'd3;
                        end
                        4'd3: begin
                            // Data bit 2
                            rx_shift_reg[2] <= srx_pad_i;
                            rx_bit_count <= 4'd4;
                        end
                        4'd4: begin
                            // Data bit 3
                            rx_shift_reg[3] <= srx_pad_i;
                            rx_bit_count <= 4'd5;
                        end
                        4'd5: begin
                            // Data bit 4
                            rx_shift_reg[4] <= srx_pad_i;
                            rx_bit_count <= 4'd6;
                        end
                        4'd6: begin
                            // Data bit 5
                            rx_shift_reg[5] <= srx_pad_i;
                            rx_bit_count <= 4'd7;
                        end
                        4'd7: begin
                            // Data bit 6
                            rx_shift_reg[6] <= srx_pad_i;
                            rx_bit_count <= 4'd8;
                        end
                        4'd8: begin
                            // Data bit 7
                            rx_shift_reg[7] <= srx_pad_i;
                            rx_bit_count <= 4'd9;
                        end
                        4'd9: begin
                            // Parity bit
                            if (parity_enable) begin
                                rx_parity_bit <= srx_pad_i;
                                rx_parity <= calc_parity(rx_shift_reg, parity_odd, (parity_type == 2'b10), (parity_type == 2'b11));
                                rx_parity_error <= (srx_pad_i != rx_parity);
                            end else begin
                                rx_parity_error <= 1'b0;
                            end
                            rx_bit_count <= 4'd10;
                        end
                        4'd10: begin
                            // Stop bit 1
                            rx_stop_bit <= srx_pad_i;
                            if (!srx_pad_i)
                                rx_frame_error <= 1'b1;
                            else
                                rx_frame_error <= 1'b0;
                            if (stop_bits_2)
                                rx_bit_count <= 4'd11;
                            else
                                rx_bit_count <= 4'd12;
                        end
                        4'd11: begin
                            // Stop bit 2
                            if (!srx_pad_i)
                                rx_frame_error <= 1'b1;
                            rx_bit_count <= 4'd12;
                        end
                        4'd12: begin
                            // End of reception
                            rx_active <= 1'b0;
                            rx_bit_count <= 4'd0;
                            // Store in FIFO
                            if (rx_fifo_count < 4'd16) begin
                                rx_fifo[rx_fifo_wr_ptr] <= rx_shift_reg;
                                rx_fifo_wr_ptr <= rx_fifo_wr_ptr + 4'd1;
                                rx_fifo_count <= rx_fifo_count + 4'd1;
                            end else begin
                                rx_overrun_error <= 1'b1;
                            end
                        end
                        default: begin
                            rx_active <= 1'b0;
                            rx_bit_count <= 4'd0;
                        end
                    endcase
                end else begin
                    baud_counter <= baud_counter - 16'd1;
                end
            end else begin
                // Check for start bit
                if (!srx_pad_i) begin
                    rx_active <= 1'b1;
                    rx_bit_count <= 4'd0;
                    baud_counter <= baud_div - 16'd1;
                end
            end
        end
    end

    // FIFO reset
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_fifo_wr_ptr <= 4'd0;
            rx_fifo_rd_ptr <= 4'd0;
            rx_fifo_count <= 4'd0;
            tx_fifo_wr_ptr <= 4'd0;
            tx_fifo_rd_ptr <= 4'd0;
            tx_fifo_count <= 4'd0;
        end else begin
            if (fifo_reset_rx) begin
                rx_fifo_wr_ptr <= 4'd0;
                rx_fifo_rd_ptr <= 4'd0;
                rx_fifo_count <= 4'd0;
            end
            if (fifo_reset_tx) begin
                tx_fifo_wr_ptr <= 4'd0;
                tx_fifo_rd_ptr <= 4'd0;
                tx_fifo_count <= 4'd0;
            end
        end
    end

    // Modem status change detection
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            msr_dcd_reg <= 1'b0;
            msr_ri_reg <= 1'b0;
            msr_dsr_reg <= 1'b0;
            msr_cts_reg <= 1'b0;
        end else begin
            msr_dcd_reg <= dcd_pad_i;
            msr_ri_reg <= ri_pad_i;
            msr_dsr_reg <= dsr_pad_i;
            msr_cts_reg <= cts_pad_i;
        end
    end

    // Wishbone register access
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rbr_thr <= 8'd0;
            ier <= 8'd0;
            iir_fcr <= 8'd1;
            lcr <= 8'd0;
            mcr <= 8'd0;
            lsr <= 8'd0;
            msr <= 8'd0;
            scr <= 8'd0;
            dll <= 8'd0;
            dlm <= 8'd0;
            mcr_ext <= 8'd0;
            isr <= 8'd0;
            rts_int <= 1'b0;
            dtr_int <= 1'b0;
            loopback <= 1'b0;
            wb_ack_int <= 1'b0;
            wb_dat_int <= 32'd0;
        end else begin
            wb_ack_int <= 1'b0;
            if (wb_write) begin
                case (wb_addr)
                    3'd0: begin
                        if (dlab)
                            dll <= wb_dat_i[7:0];
                        else
                            rbr_thr <= wb_dat_i[7:0];
                        // Write to THR
                        if (!dlab && tx_fifo_count < 4'd16) begin
                            tx_fifo[tx_fifo_wr_ptr] <= wb_dat_i[7:0];
                            tx_fifo_wr_ptr <= tx_fifo_wr_ptr + 4'd1;
                            tx_fifo_count <= tx_fifo_count + 4'd1;
                        end
                    end
                    3'd1: begin
                        if (dlab)
                            dlm <= wb_dat_i[7:0];
                        else
                            ier <= wb_dat_i[7:0];
                    end
                    3'd2: begin
                        iir_fcr <= wb_dat_i[7:0];
                    end
                    3'd3: begin
                        lcr <= wb_dat_i[7:0];
                    end
                    3'd4: begin
                        mcr <= wb_dat_i[7:0];
                        rts_int <= mcr[1];
                        dtr_int <= mcr[0];
                        loopback <= mcr[4];
                    end
                    3'd5: begin
                        // LSR is read-only, but writing clears some bits
                        if (wb_dat_i[0])
                            rx_overrun_error <= 1'b0;
                        if (wb_dat_i[1])
                            rx_parity_error <= 1'b0;
                        if (wb_dat_i[2])
                            rx_frame_error <= 1'b0;
                        if (wb_dat_i[3])
                            rx_break_error <= 1'b0;
                    end
                    3'd6: begin
                        // MSR is read-only
                    end
                    3'd7: begin
                        scr <= wb_dat_i[7:0];
                    end
                    3'd8: begin
                        mcr_ext <= wb_dat_i[7:0];
                    end
                    3'd9: begin
                        isr <= wb_dat_i[7:0];
                    end
                    default: begin
                    end
                endcase
                wb_ack_int <= 1'b1;
            end else if (wb_read) begin
                case (wb_addr)
                    3'd0: begin
                        if (dlab)
                            wb_dat_int <= {24'd0, dll};
                        else
                            wb_dat_int <= {24'd0, rbr_thr};
                    end
                    3'd1: begin
                        if (dlab)
                            wb_dat_int <= {24'd0, dlm};
                        else
                            wb_dat_int <= {24'd0, ier};
                    end
                    3'd2: begin
                        wb_dat_int <= {24'd0, iir_fcr};
                    end
                    3'd3: begin
                        wb_dat_int <= {24'd0, lcr};
                    end
                    3'd4: begin
                        wb_dat_int <= {24'd0, mcr};
                    end
                    3'd5: begin
                        wb_dat_int <= {24'd0, lsr};
                    end
                    3'd6: begin
                        wb_dat_int <= {24'd0, msr};
                    end
                    3'd7: begin
                        wb_dat_int <= {24'd0, scr};
                    end
                    3'd8: begin
                        wb_dat_int <= {24'd0, mcr_ext};
                    end
                    3'd9: begin
                        wb_dat_int <= {24'd0, isr};
                    end
                    default: begin
                        wb_dat_int <= 32'd0;
                    end
                endcase
                wb_ack_int <= 1'b1;
            end
        end
    end

    // Update LSR and MSR
    always @(*) begin
        lsr = {1'b0, lsr_temt, lsr_thre, lsr_err, lsr_bi, lsr_fe, lsr_pe, lsr_oe, lsr_dr};
        msr = {1'b0, msr_cts_change, msr_dsr_change, msr_ri_change, msr_dcd_change, msr_cts, msr_dsr, msr_ri, msr_dcd};
    end

    // Update IIR
    always @(*) begin
        if (int_rx_data)
            iir_fcr = {4'd0, 4'd0};
        else if (int_line_status)
            iir_fcr = {4'd0, 4'd6};
        else if (int_tx_holding)
            iir_fcr = {4'd0, 4'd5};
        else if (int_modem_status)
            iir_fcr = {4'd0, 4'd4};
        else
            iir_fcr = {4'd0, 4'd1};
    end

    assign wb_ack_o = wb_ack_int;
    assign wb_dat_o = wb_dat_int;

endmodule
