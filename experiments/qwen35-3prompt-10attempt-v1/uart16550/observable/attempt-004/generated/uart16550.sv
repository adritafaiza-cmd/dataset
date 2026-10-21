```verilog
`timescale 1ns / 1ps

module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // ------------------------------------------------------------------
    // Parameters
    // ------------------------------------------------------------------
    parameter WB_ADDR_WIDTH = 16;
    parameter WB_DATA_WIDTH = 32;
    parameter UART_BAUD_RATE = 9600;
    parameter UART_CLK_FREQ = 50_000_000;
    parameter UART_DIVIDER = UART_CLK_FREQ / (16 * UART_BAUD_RATE);
    
    // Register Map (16-bit address space)
    // 0x00: RBR (Receive Buffer Register) - Read only
    // 0x01: THR (Transmit Holding Register) - Write only
    // 0x02: IER (Interrupt Enable Register)
    // 0x03: IIR (Interrupt Identification Register) - Read only
    // 0x04: LCR (Line Control Register)
    // 0x05: MCR (Modem Control Register)
    // 0x06: LSR (Line Status Register) - Read only
    // 0x07: MSR (Modem Status Register) - Read only
    // 0x08: SCR (Scratch Register) - Read/Write
    // 0x0F: DRQ (DMA Request) - Read only (not implemented in this basic version)

    // ------------------------------------------------------------------
    // Internal Signals
    // ------------------------------------------------------------------
    reg [WB_DATA_WIDTH-1:0] reg_rbr;
    reg [WB_DATA_WIDTH-1:0] reg_thr;
    reg [WB_DATA_WIDTH-1:0] reg_ier;
    reg [WB_DATA_WIDTH-1:0] reg_lcr;
    reg [WB_DATA_WIDTH-1:0] reg_mcr;
    reg [WB_DATA_WIDTH-1:0] reg_scr;
    
    wire [WB_DATA_WIDTH-1:0] reg_lsr;
    wire [WB_DATA_WIDTH-1:0] reg_msr;
    wire [WB_DATA_WIDTH-1:0] reg_iir;

    reg tx_enable;
    reg tx_data;
    reg tx_shift;
    reg tx_done;
    reg rx_enable;
    reg rx_data;
    reg rx_shift;
    reg rx_done;
    
    reg [3:0] tx_count;
    reg [3:0] rx_count;
    reg tx_busy;
    reg rx_busy;
    
    reg [31:0] baud_divider;
    reg [31:0] baud_counter;
    reg [31:0] baud_reload;
    
    reg [3:0] parity; // 0: None, 1: Odd, 2: Even
    reg [3:0] stop_bits; // 0: 1, 1: 1.5, 2: 2
    reg [3:0] data_bits; // 5, 6, 7, 8
    
    reg [31:0] rx_fifo;
    reg [3:0] rx_fifo_ptr;
    reg [3:0] rx_fifo_count;
    
    reg [31:0] tx_fifo;
    reg [3:0] tx_fifo_ptr;
    reg [3:0] tx_fifo_count;

    // ------------------------------------------------------------------
    // Baud Rate Generator
    // ------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            baud_counter <= 0;
            baud_reload <= UART_DIVIDER;
        end else begin
            if (baud_counter == baud_reload) begin
                baud_counter <= 0;
                baud_divider <= 1'b1;
            end else begin
                baud_counter <= baud_counter + 1'b1;
                baud_divider <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------
    // UART State Machine & Logic
    // ------------------------------------------------------------------
    reg [3:0] state; // 0: Idle, 1: TX Shift, 2: RX Shift
    reg [3:0] parity_bit;
    reg [3:0] stop_bit_count;
    reg [3:0] rx_bit_count;
    reg [3:0] tx_bit_count;
    reg [3:0] rx_data_reg;
    reg [3:0] tx_data_reg;
    reg [3:0] parity_calc;
    reg [3:0] stop_bits_reg;
    reg [3:0] data_bits_reg;
    reg [3:0] parity_mode; // 0: None, 1: Odd, 2: Even

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            state <= 0;
            tx_count <= 0;
            rx_count <= 0;
            tx_busy <= 0;
            rx_busy <= 0;
            tx_fifo_count <= 0;
            rx_fifo_count <= 0;
            tx_fifo_ptr <= 0;
            rx_fifo_ptr <= 0;
            tx_enable <= 0;
            rx_enable <= 0;
            parity <= 0;
            stop_bits <= 0;
            data_bits <= 0;
            parity_calc <= 0;
            stop_bits_reg <= 0;
            data_bits_reg <= 0;
            parity_mode <= 0;
            rx_bit_count <= 0;
            tx_bit_count <= 0;
            rx_data_reg <= 0;
            tx_data_reg <= 0;
            int_o <= 0;
        end else begin
            // Update configuration registers
            parity_mode <= reg_lcr[0]; // Bit 0: Parity Enable
            stop_bits_reg <= reg_lcr[1:2]; // Bits 1-2: Stop Bits
            data_bits_reg <= reg_lcr[3:6]; // Bits 3-6: Data Bits
            parity_calc <= reg_lcr[7]; // Bit 7: Parity Type (0: Odd, 1: Even)

            // Update Modem Control
            rts_pad_o <= reg_mcr[0]; // Bit 0: RTS
            dtr_pad_o <= reg_mcr[1]; // Bit 1: DTR
            // Bits 2-7: Reserved/Other control signals

            // Update Interrupt Enable
            rx_enable <= reg_ier[0]; // Bit 0: RX Enable
            tx_enable <= reg_ier[1]; // Bit 1: TX Enable

            // Update FIFO pointers
            tx_fifo_ptr <= tx_fifo_ptr;
            rx_fifo_ptr <= rx_fifo_ptr;

            // Update Status Registers
            reg_lsr[0] <= rx_busy; // Bit 0: RX Ready
            reg_lsr[1] <= tx_busy; // Bit 1: TX Empty
            reg_lsr[2] <= 1'b0; // Bit 2: Error (Break)
            reg_lsr[3] <= 1'b0; // Bit 3: Error (Overrun)
            reg_lsr[4] <= 1'b0; // Bit 4: Error (Framing)
            reg_lsr[5] <= 1'b0; // Bit 5: Error (Parity)
            reg_lsr[6] <= 1'b0; // Bit 6: TX Holding Register Empty
            reg_lsr[7] <= 1'b0; // Bit 7: TX Shift Register Empty

            reg_msr[0] <= cts_pad_i; // Bit 0: CTS
            reg_msr[1] <= dsr_pad_i; // Bit 1: DSR
            reg_msr[2] <= ri_pad_i;  // Bit 2: RI
            reg_msr[3] <= dcd_pad_i; // Bit 3: DCD
            reg_msr[4:7] <= 4'b0;    // Bits 4-7: Reserved

            reg_iir[0] <= 1'b0; // Bit 0: Interrupt Pending
            reg_iir[1] <= 1'b0; // Bit 1: Interrupt ID (0: None, 1: RX, 2: TX, 3: RX+TX)
            reg_iir[2] <= 1'b0; // Bit 2: Interrupt Enable
            reg_iir[3] <= 1'b0; // Bit 3: Interrupt Mask

            // Update FIFO counts
            tx_fifo_count <= tx_fifo_count;
            rx_fifo_count <= rx_fifo_count;

            // Update Interrupt Output
            int_o <= 1'b0;
            if (rx_enable && rx_fifo_count > 0) begin
                int_o <= 1'b1;
                reg_iir[0] <= 1'b1;
                reg_iir[1] <= 1'b1;
            end else if (tx_enable && tx_fifo_count == 0) begin
                int_o <= 1'b1;
                reg_iir[0] <= 1'b1;
                reg_iir[1] <= 2'b01; // TX Interrupt
            end else if (rx_enable && rx_fifo_count == 0 && tx_enable && tx_fifo_count == 0) begin
                int_o <= 1'b1;
                reg_iir[0] <= 1'b1;
                reg_iir[1] <= 2'b10; // No Interrupt
            end

            // ------------------------------------------------------------------
            // Transmit Logic
            // ------------------------------------------------------------------
            if (tx_enable && tx_fifo_count > 0) begin
                if (tx_fifo_count == 1) begin
                    tx_data_reg <= tx_fifo[tx_fifo_ptr];
                    tx_bit_count <= 0;
                    tx_busy <= 1;
                    tx_fifo_count <= tx_fifo_count - 1;
                    tx_fifo_ptr <= tx_fifo_ptr + 1;
                end

                if (tx_bit_count < data_bits_reg) begin
                    tx_data <= tx_data_reg[tx_bit_count];
                    tx_shift <= tx_shift | (tx_data ? 1 : 0);
                    tx_bit_count <= tx_bit_count + 1;
                end else if (tx_bit_count == data_bits_reg) begin
                    // Parity bit
                    parity_bit <= parity_calc;
                    tx_data <= parity_bit;
                    tx_shift <= tx_shift | (parity_bit ? 1 : 0);
                    tx_bit_count <= tx_bit_count + 1;
                end else if (tx_bit_count == data_bits_reg + 1) begin
                    // Stop bits
                    tx_data <= 1'b0;
                    tx_shift <= tx_shift | (1'b0 ? 1 : 0);
                    tx_bit_count <= tx_bit_count + 1;
                    stop_bit_count <= 0;
                end

                if (tx_bit_count == data_bits_reg + 1 + stop_bits_reg) begin
                    tx_busy <= 0;
                    tx_count <= 0;
                    tx_shift <= 0;
                    tx_bit_count <= 0;
                    parity_calc <= 0;
                    stop_bit_count <= 0;
                end
            end

            // ------------------------------------------------------------------
            // Receive Logic
            // ------------------------------------------------------------------
            if (rx_enable && srx_pad_i) begin
                if (rx_bit_count < 8) begin
                    rx_data_reg <= {rx_data_reg[6:0], srx_pad_i};
                    rx_bit_count <= rx_bit_count + 1;
                end else if (rx_bit_count == 8) begin
                    // Parity check
                    parity_bit <= parity_calc;
                    if (parity_mode == 2'b01) begin // Odd
                        if (parity_bit != parity_calc) begin
                            reg_lsr[5] <= 1'b1; // Parity Error
                        end
                    end else if (parity_mode == 2'b10) begin // Even
                        if (parity_bit == parity_calc) begin
                            reg_lsr[5] <= 1'b1; // Parity Error
                        end
                    end
                    rx_data_reg <= rx_data_reg;
                    rx_bit_count <= 0;
                end

                if (rx_bit_count == 8 + stop_bits_reg) begin
                    rx_busy <= 0;
                    rx_count <= 0;
                    rx_shift <= 0;
                    rx_bit_count <= 0;
                    parity_calc <= 0;
                    stop_bit_count <= 0;
                    
                    // Add to FIFO
                    if (rx_fifo_count < 16) begin
                        rx_fifo[rx_fifo_ptr] <= rx_data_reg;
                        rx_fifo_ptr <= rx_fifo_ptr + 1;
                        rx_fifo_count <= rx_fifo_count + 1;
                    end
                end
            end

            // ------------------------------------------------------------------
            // Parity Calculation
            // ------------------------------------------------------------------
            if (tx_enable && tx_fifo_count > 0) begin
                if (tx_bit_count < data_bits_reg) begin
                    parity_calc <= parity_calc ^ tx_data_reg[tx_bit_count];
                end
            end

            // ------------------------------------------------------------------
            // Wishbone Interface
            // ------------------------------------------------------------------
            wb_dat_o <= 32'b0;
            wb_ack_o <= 1'b0;
            wb_sel_i <= 0;

            if (wb_cyc_i && wb_stb_i) begin
                case (wb_adr_i)
                    16'h00: begin // RBR
                        wb_dat_o <= reg_rbr;
                        wb_ack_o <= 1'b1;
                        wb_sel_i <= 1;
                    end
                    16'h01: begin // THR
                        if (wb_we_i) begin
                            reg_thr <= wb_dat_i;
                            if (tx_fifo_count < 16) begin
                                tx_fifo[tx_fifo_ptr] <= wb_dat_i;
                                tx_fifo_ptr <= tx_fifo_ptr + 1;
                                tx_fifo_count <= tx_fifo_count + 1;
                            end
                        end
                        wb_ack_o <= 1'b1;
                        wb_sel_i <= 2;
                    end
                    16'h02: begin // IER
                        reg_ier <= wb_dat_i;
                        wb_ack_o <= 1'b1;
                        wb_sel_i <= 3;
                    end
                    16'h03: begin // IIR
                        wb_dat_o <= reg_iir;
                        wb_ack_o <= 1'b1;
                        wb_sel_i <= 4;
                    end
                    16'h04: begin // LCR
                        reg_lcr <= wb_dat_i;
                        wb_ack_o <= 1'b1;
                        wb_sel_i <= 5;
                    end
                    16'h05: begin // MCR
                        reg_mcr <= wb_dat_i;
                        wb_ack_o <= 1'b1;
                        wb_sel_i <= 6;
                    end
                    16'h06: begin // LSR
                        wb_dat_o <= reg_lsr;
                        wb_ack_o <= 1'b1;
                        wb_sel_i <= 7;
                    end
                    16'h07: begin // MSR
                        wb_dat_o <= reg_msr;
                        wb_ack_o <= 1'b1;
                        wb_sel_i <= 8;
                    end
                    16'h08: begin // SCR
                        reg_scr <= wb_dat_i;
                        wb_ack_o <= 1'b1;
                        wb_sel_i <= 9;
                    end
                    default: begin
                        wb_ack_o <= 1'b1;
                        wb_sel_i <= 10;
                    end
                endcase
            end

            // ------------------------------------------------------------------
            // Output Signals
            // ------------------------------------------------------------------
            stx_pad_o <= tx_enable && tx_fifo_count > 0;
            int_o <= int_o;

        end
    end

    // ------------------------------------------------------------------
    // Parity Calculation Logic
    // ------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            parity_calc <= 0;
        end else begin
            if (tx_enable && tx_fifo_count > 0) begin
                if (tx_bit_count < data_bits_reg) begin
                    parity_calc <= parity_calc ^ tx_data_reg[tx_bit_count];
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // FIFO Logic
    // ------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_count <= 0;
            rx_fifo_count <= 0;
            tx_fifo_ptr <= 0;
            rx_fifo_ptr <= 0;
        end else begin
            if (tx_enable && tx_fifo_count > 0) begin
                if (tx_fifo_count == 1) begin
                    tx_data_reg <= tx_fifo[tx_fifo_ptr];
                    tx_bit_count <= 0;
                    tx_busy <= 1;
                    tx_fifo_count <= tx_fifo_count - 1;
                    tx_fifo_ptr <= tx_fifo_ptr + 1;
                end
            end
            if (rx_enable && srx_pad_i) begin
                if (rx_bit_count == 8 + stop_bits_reg) begin
                    if (rx_fifo_count < 16) begin
                        rx_fifo[rx_fifo_ptr] <= rx_data_reg;
                        rx_fifo_ptr <= rx_fifo_ptr + 1;
                        rx_fifo_count <= rx_fifo_count + 1;
                    end
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // Reset Logic
    // ------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            reg_rbr <= 32'b0;
            reg_thr <= 32'b0;
            reg_ier <= 32'b0;
            reg_lcr <= 32'b0;
            reg_mcr <= 32'b0;
            reg_scr <= 32'b0;
            tx_enable <= 0;
            rx_enable <= 0;
            tx_busy <= 0;
            rx_busy <= 0;
            tx_fifo_count <= 0;
            rx_fifo_count <= 0;
            tx_fifo_ptr <= 0;
            rx_fifo_ptr <= 0;
            tx_data_reg <= 0;
            rx_data_reg <= 0;
            tx_bit_count <= 0;
            rx_bit_count <= 0;
            parity_calc <= 0;
            parity_bit <= 0;
            stop_bit_count <= 0;
            stop_bits_reg <= 0;
            data_bits_reg <= 0;
            parity_mode <= 0;
            int_o <= 0;
        end
    end

endmodule
```<|im_end|>
