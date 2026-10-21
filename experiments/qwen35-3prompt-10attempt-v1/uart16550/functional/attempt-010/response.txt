```verilog
module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_sel_i,
    wb_ack_o,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // Wishbone Interface
    input wb_clk_i;
    input wb_rst_i;
    input [15:0] wb_adr_i;
    input [7:0] wb_dat_i;
    output reg [7:0] wb_dat_o;
    input wb_we_i;
    input wb_stb_i;
    input wb_cyc_i;
    input [3:0] wb_sel_i;
    output wb_ack_o;

    // Modem Control Inputs
    input cts_pad_i;
    input dsr_pad_i;
    input ri_pad_i;
    input dcd_pad_i;

    // Modem Status Outputs
    output stx_pad_o;
    output rts_pad_o;
    output dtr_pad_o;

    // Interrupt Output
    output int_o;

    // Internal Signals
    reg [7:0] wb_dat_o_reg;
    reg wb_ack_o_reg;
    reg int_o_reg;
    reg stx_pad_o_reg;
    reg rts_pad_o_reg;
    reg dtr_pad_o_reg;

    // FIFO Signals
    reg [7:0] fifo_data;
    reg [3:0] fifo_count;
    reg fifo_full;
    reg fifo_empty;
    reg [7:0] fifo_ptr_wr;
    reg [7:0] fifo_ptr_rd;
    reg fifo_we;
    reg fifo_re;

    // Baud Rate Generator Signals
    reg [15:0] baud_divider;
    reg [15:0] baud_counter;
    reg baud_overflow;
    reg [7:0] baud_divisor;
    reg baud_enable;

    // Register Map (16-bit address space)
    // 0x0000-0x000F: IER (Interrupt Enable Register)
    // 0x0010-0x001F: IIR (Interrupt Identification Register)
    // 0x0020-0x002F: FCR (FIFO Control Register)
    // 0x0030-0x003F: LCR (Line Control Register)
    // 0x0040-0x004F: MCR (Modem Control Register)
    // 0x0050-0x005F: LSR (Line Status Register)
    // 0x0060-0x006F: MSR (Modem Status Register)
    // 0x0070-0x007F: SCR (Scratch Register)
    // 0x0080-0x00FF: Data Register (Read/Write)

    // Internal Registers
    reg [7:0] reg_ier;
    reg [7:0] reg_iir;
    reg [7:0] reg_fcr;
    reg [7:0] reg_lcr;
    reg [7:0] reg_mcr;
    reg [7:0] reg_lsr;
    reg [7:0] reg_msr;
    reg [7:0] reg_scr;
    reg [7:0] reg_data;

    // Baud Rate Configuration (Default 9600 @ 16MHz)
    parameter BAUD_DIVISOR = 16_000_000 / 9600; // 1666

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_dat_o_reg <= 8'h00;
            wb_ack_o_reg <= 1'b0;
            int_o_reg <= 1'b0;
            stx_pad_o_reg <= 1'b1;
            rts_pad_o_reg <= 1'b1;
            dtr_pad_o_reg <= 1'b1;
            
            fifo_count <= 4'd0;
            fifo_ptr_wr <= 8'd0;
            fifo_ptr_rd <= 8'd0;
            fifo_full <= 1'b0;
            fifo_empty <= 1'b1;
            baud_counter <= 16'd0;
            baud_overflow <= 1'b0;
            baud_enable <= 1'b0;
            
            reg_ier <= 8'h00;
            reg_iir <= 8'h06;
            reg_fcr <= 8'h01;
            reg_lcr <= 8'h83;
            reg_mcr <= 8'h0B;
            reg_lsr <= 8'h00;
            reg_msr <= 8'h00;
            reg_scr <= 8'h00;
            reg_data <= 8'h00;
        end else begin
            wb_dat_o_reg <= wb_dat_o_reg;
            wb_ack_o_reg <= wb_ack_o_reg;
            int_o_reg <= int_o_reg;
            stx_pad_o_reg <= stx_pad_o_reg;
            rts_pad_o_reg <= rts_pad_o_reg;
            dtr_pad_o_reg <= dtr_pad_o_reg;
        end
    end

    // Baud Rate Generator
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            baud_counter <= 16'd0;
            baud_overflow <= 1'b0;
            baud_enable <= 1'b0;
        end else begin
            if (baud_enable) begin
                baud_counter <= baud_counter + 1'b1;
                if (baud_counter >= BAUD_DIVISOR) begin
                    baud_counter <= 16'd0;
                    baud_overflow <= 1'b1;
                end
            end else begin
                baud_counter <= 16'd0;
                baud_overflow <= 1'b0;
            end
        end
    end

    // FIFO Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            fifo_count <= 4'd0;
            fifo_ptr_wr <= 8'd0;
            fifo_ptr_rd <= 8'd0;
            fifo_full <= 1'b0;
            fifo_empty <= 1'b1;
        end else begin
            fifo_full <= (fifo_count == 4'd16);
            fifo_empty <= (fifo_count == 4'd0);
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            fifo_we <= 1'b0;
            fifo_re <= 1'b0;
        end else begin
            fifo_we <= 1'b0;
            fifo_re <= 1'b0;
        end
    end

    // Wishbone Slave Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_ack_o_reg <= 1'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i) begin
                case (wb_sel_i)
                    4'd0: begin // IER
                        wb_dat_o_reg <= reg_ier;
                        wb_ack_o_reg <= 1'b1;
                    end
                    4'd1: begin // IIR
                        wb_dat_o_reg <= reg_iir;
                        wb_ack_o_reg <= 1'b1;
                    end
                    4'd2: begin // FCR
                        wb_dat_o_reg <= reg_fcr;
                        wb_ack_o_reg <= 1'b1;
                    end
                    4'd3: begin // LCR
                        wb_dat_o_reg <= reg_lcr;
                        wb_ack_o_reg <= 1'b1;
                    end
                    4'd4: begin // MCR
                        wb_dat_o_reg <= reg_mcr;
                        wb_ack_o_reg <= 1'b1;
                    end
                    4'd5: begin // LSR
                        wb_dat_o_reg <= reg_lsr;
                        wb_ack_o_reg <= 1'b1;
                    end
                    4'd6: begin // MSR
                        wb_dat_o_reg <= reg_msr;
                        wb_ack_o_reg <= 1'b1;
                    end
                    4'd7: begin // SCR
                        wb_dat_o_reg <= reg_scr;
                        wb_ack_o_reg <= 1'b1;
                    end
                    4'd8: begin // Data Register (Read)
                        wb_dat_o_reg <= reg_data;
                        wb_ack_o_reg <= 1'b1;
                    end
                    4'd9: begin // Data Register (Write)
                        reg_data <= wb_dat_i;
                        wb_ack_o_reg <= 1'b1;
                    end
                    default: begin
                        wb_dat_o_reg <= 8'h00;
                        wb_ack_o_reg <= 1'b1;
                    end
                endcase
            end else begin
                wb_ack_o_reg <= 1'b0;
            end
        end
    end

    // Register Update Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            reg_ier <= 8'h00;
            reg_iir <= 8'h06;
            reg_fcr <= 8'h01;
            reg_lcr <= 8'h83;
            reg_mcr <= 8'h0B;
            reg_lsr <= 8'h00;
            reg_msr <= 8'h00;
            reg_scr <= 8'h00;
        end else begin
            case (wb_sel_i)
                4'd0: reg_ier <= wb_dat_i;
                4'd1: reg_iir <= wb_dat_i;
                4'd2: reg_fcr <= wb_dat_i;
                4'd3: reg_lcr <= wb_dat_i;
                4'd4: reg_mcr <= wb_dat_i;
                4'd5: reg_lsr <= wb_dat_i;
                4'd6: reg_msr <= wb_dat_i;
                4'd7: reg_scr <= wb_dat_i;
                4'd8: begin
                    // Write to data register
                    if (!fifo_full) begin
                        fifo_we <= 1'b1;
                        fifo_data <= wb_dat_i;
                    end
                end
                default: begin
                    // No update
                end
            endcase
        end
    end

    // FIFO Write Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            fifo_ptr_wr <= 8'd0;
            fifo_count <= 4'd0;
        end else begin
            if (fifo_we) begin
                fifo_ptr_wr <= fifo_ptr_wr + 1'b1;
                fifo_count <= fifo_count + 1'b1;
            end
        end
    end

    // FIFO Read Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            fifo_ptr_rd <= 8'd0;
            fifo_count <= 4'd0;
        end else begin
            if (fifo_re) begin
                fifo_ptr_rd <= fifo_ptr_rd + 1'b1;
                fifo_count <= fifo_count - 1'b1;
            end
        end
    end

    // FIFO Control Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            fifo_re <= 1'b0;
        end else begin
            // Auto-reload when FIFO is not empty and interrupt enabled
            if (reg_ier[0] && !fifo_empty) begin
                fifo_re <= 1'b1;
            end else begin
                fifo_re <= 1'b0;
            end
        end
    end

    // Interrupt Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            int_o_reg <= 1'b0;
        end else begin
            // Check for interrupts
            reg int_flag = 1'b0;
            
            // RX FIFO not empty
            if (reg_ier[0] && !fifo_empty) begin
                int_flag = 1'b1;
            end
            // TX FIFO empty
            if (reg_ier[1] && fifo_count == 4'd0) begin
                int_flag = 1'b1;
            end
            // Modem status change
            if (reg_ier[2] && (reg_msr[6] || reg_msr[5] || reg_msr[4] || reg_msr[3])) begin
                int_flag = 1'b1;
            end
            // Overrun error
            if (reg_ier[3] && (reg_lsr[7])) begin
                int_flag = 1'b1;
            end

            if (int_flag) begin
                int_o_reg <= 1'b1;
            end else begin
                int_o_reg <= 1'b0;
            end
        end
    end

    // UART State Machine and Data Shift
    reg [7:0] shift_reg;
    reg [2:0] state; // 0: Idle, 1: Start, 2: Data, 3: Parity, 4: Stop
    reg [2:0] state_next;
    reg [7:0] parity_calc;
    reg [7:0] parity_expected;
    reg parity_error;
    reg [1:0] stop_bits;
    reg [1:0] stop_bits_count;
    reg [7:0] stop_bits_data;
    reg [7:0] stop_bits_data_reg;
    reg [7:0] stop_bits_data_reg_next;
    reg [7:0] stop_bits_data_reg_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop_bits_data_reg_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next;
    reg [7:0] stop