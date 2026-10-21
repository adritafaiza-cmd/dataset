```verilog
`timescale 1ns / 1ps

module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // ---------------------------------------------------------------------------
    // Parameters
    // ---------------------------------------------------------------------------
    parameter WB_ADDR_WIDTH = 16;
    parameter WB_DATA_WIDTH = 32;
    parameter BAUD_RATE_DIV = 16; // Simplified divisor for simulation speed; adjust for real use
    parameter TX_FIFO_DEPTH = 16;
    parameter RX_FIFO_DEPTH = 16;

    // ---------------------------------------------------------------------------
    // Internal Signals
    // ---------------------------------------------------------------------------
    reg [WB_ADDR_WIDTH-1:0] wb_adr_reg;
    reg [WB_DATA_WIDTH-1:0] wb_dat_in;
    reg [WB_DATA_WIDTH-1:0] wb_dat_out;
    reg wb_we_reg;
    reg wb_stb_reg;
    reg wb_cyc_reg;
    reg wb_sel_reg;
    reg wb_ack_reg;
    
    reg int_reg;
    reg stx_pad_reg;
    reg srx_pad_reg;
    reg rts_pad_reg;
    reg cts_pad_reg;
    reg dtr_pad_reg;
    reg dsr_pad_reg;
    reg ri_pad_reg;
    reg dcd_pad_reg;

    // UART State Machine
    reg [3:0] uart_state;
    reg [7:0] baud_divider;
    reg baud_tick;
    reg tx_idle;
    reg rx_idle;
    reg rx_start_detected;
    reg rx_bit_count;
    reg rx_data_valid;
    reg [7:0] rx_data;
    reg rx_error; // Framing/Parity error flag

    // FIFOs
    reg [TX_FIFO_DEPTH-1:0] tx_fifo;
    reg [TX_FIFO_DEPTH-1:0] tx_fifo_ptr;
    reg [TX_FIFO_DEPTH-1:0] tx_fifo_tail;
    reg tx_fifo_empty;
    reg tx_fifo_full;
    reg tx_fifo_read_en;
    reg tx_fifo_write_en;

    reg [RX_FIFO_DEPTH-1:0] rx_fifo;
    reg [RX_FIFO_DEPTH-1:0] rx_fifo_ptr;
    reg [RX_FIFO_DEPTH-1:0] rx_fifo_tail;
    reg rx_fifo_empty;
    reg rx_fifo_full;
    reg rx_fifo_read_en;
    reg rx_fifo_write_en;

    // Control Registers (16-bit address space)
    // 0x00: Control Register (CR)
    // 0x01: Interrupt Enable Register (IER)
    // 0x02: Interrupt Identification Register (IIR)
    // 0x03: FIFO Control Register (FCR)
    // 0x04: Line Control Register (LCR)
    // 0x05: Modem Control Register (MCR)
    // 0x06: Line Status Register (LSR)
    // 0x07: Modem Status Register (MSR)
    // 0x08: Receive Data Register (RDR)
    // 0x09: Transmit Holding Register (THR)
    // 0x0A: IER (Read-only copy)
    // 0x0B: IIR (Read-only copy)
    // 0x0C: LSR (Read-only copy)
    // 0x0D: MSR (Read-only copy)
    // 0x0E: FCR (Read-only copy)
    // 0x0F: Reserved

    reg [7:0] cr_reg;
    reg [7:0] ier_reg;
    reg [7:0] iir_reg;
    reg [7:0] fcr_reg;
    reg [7:0] lcr_reg;
    reg [7:0] mcr_reg;
    reg [7:0] lsr_reg;
    reg [7:0] msr_reg;
    reg [7:0] rdr_reg;
    reg [7:0] thr_reg;

    // ---------------------------------------------------------------------------
    // Wishbone Interface Logic
    // ---------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_adr_reg <= 0;
            wb_dat_in <= 0;
            wb_dat_out <= 0;
            wb_we_reg <= 0;
            wb_stb_reg <= 0;
            wb_cyc_reg <= 0;
            wb_sel_reg <= 0;
            wb_ack_reg <= 0;
        end else begin
            wb_adr_reg <= wb_adr_i;
            wb_dat_in <= wb_dat_i;
            wb_dat_out <= wb_dat_o;
            wb_we_reg <= wb_we_i;
            wb_stb_reg <= wb_stb_i;
            wb_cyc_reg <= wb_cyc_i;
            wb_sel_reg <= wb_sel_i;
            wb_ack_reg <= wb_ack_o;
        end
    end

    // ---------------------------------------------------------------------------
    // UART State Machine & Timing
    // ---------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            uart_state <= 0;
            baud_divider <= 0;
            baud_tick <= 0;
            tx_idle <= 1;
            rx_idle <= 1;
            rx_start_detected <= 0;
            rx_bit_count <= 0;
            rx_data_valid <= 0;
            rx_error <= 0;
            int_reg <= 0;
            stx_pad_reg <= 1;
            rts_pad_reg <= 1;
            dtr_pad_reg <= 1;
        end else begin
            // Baud Rate Generator
            baud_tick <= baud_tick ^ 1'b1;
            if (baud_tick) begin
                if (baud_divider == 0) begin
                    baud_divider <= 0;
                end else begin
                    baud_divider <= baud_divider - 1;
                end
            end

            // State Machine
            case (uart_state)
                0: begin // Idle
                    if (baud_tick) begin
                        if (baud_divider == 0) begin
                            baud_divider <= 0;
                            tx_idle <= 1;
                            stx_pad_reg <= 1;
                            // Check for new data in THR
                            if (tx_fifo_empty == 0 && thr_reg == 0) begin
                                // Data available in FIFO, move to THR
                                // Actually, THR is just the output of FIFO. 
                                // If FIFO is not empty, THR gets data.
                                // If FIFO is empty, THR is 0.
                                // We need to check if we should start transmission.
                                // Simplified: If FIFO has data, start TX.
                                if (tx_fifo_empty == 0) begin
                                    tx_idle <= 0;
                                    stx_pad_reg <= 0;
                                    uart_state <= 1;
                                end
                            end
                        end
                    end
                end
                1: begin // Transmitting Start Bit
                    if (baud_tick) begin
                        if (baud_divider == 0) begin
                            baud_divider <= 0;
                            stx_pad_reg <= 0; // Start bit low
                            uart_state <= 2;
                        end
                    end
                end
                2: begin // Transmitting Data Bits
                    if (baud_tick) begin
                        if (baud_divider == 0) begin
                            baud_divider <= 0;
                            stx_pad_reg <= thr_reg[0]; // Data bit
                            if (rx_bit_count == 0) begin
                                rx_start_detected <= 1;
                                rx_bit_count <= 1;
                            end
                            uart_state <= 3;
                        end
                    end
                end
                3: begin // Transmitting Stop Bit
                    if (baud_tick) begin
                        if (baud_divider == 0) begin
                            baud_divider <= 0;
                            stx_pad_reg <= 1; // Stop bit high
                            tx_idle <= 1;
                            uart_state <= 0;
                        end
                    end
                end
            endcase

            // RX State Machine
            if (rx_start_detected) begin
                if (baud_tick) begin
                    if (rx_bit_count == 0) begin
                        // Start bit detected, now sampling data
                        rx_bit_count <= 1;
                        rx_data <= srx_pad_i; // Sample start bit (usually ignored)
                    end else if (rx_bit_count == 8) begin
                        // Sample stop bit
                        rx_data_valid <= 1;
                        rx_error <= 0; // Assume no error for simplicity unless parity is implemented
                        rx_start_detected <= 0;
                        rx_bit_count <= 0;
                        // Check FIFO full before writing
                        if (rx_fifo_full == 0) begin
                            rx_fifo[rx_fifo_ptr] <= rx_data;
                            rx_fifo_ptr <= rx_fifo_ptr + 1;
                            if (rx_fifo_ptr == RX_FIFO_DEPTH) rx_fifo_ptr <= 0;
                        end
                        // Check for RX interrupt
                        if (ier_reg[0] == 1) begin
                            int_reg <= 1;
                        end
                    end else begin
                        // Sample data bit
                        rx_data <= {rx_data[6:0], srx_pad_i};
                        rx_bit_count <= rx_bit_count + 1;
                    end
                end
            end else begin
                rx_start_detected <= 0;
                rx_bit_count <= 0;
                rx_data_valid <= 0;
                rx_error <= 0;
            end
        end
    end

    // ---------------------------------------------------------------------------
    // FIFO Logic
    // ---------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_ptr <= 0;
            tx_fifo_tail <= 0;
            tx_fifo_empty <= 1;
            tx_fifo_full <= 0;
            rx_fifo_ptr <= 0;
            rx_fifo_tail <= 0;
            rx_fifo_empty <= 1;
            rx_fifo_full <= 0;
        end else begin
            // TX FIFO
            tx_fifo_empty <= (tx_fifo_ptr == tx_fifo_tail);
            tx_fifo_full <= (tx_fifo_ptr == (tx_fifo_tail + TX_FIFO_DEPTH) - 1);
            
            if (tx_fifo_write_en) begin
                tx_fifo[tx_fifo_ptr] <= wb_dat_in[7:0];
                tx_fifo_ptr <= tx_fifo_ptr + 1;
                if (tx_fifo_ptr == TX_FIFO_DEPTH) tx_fifo_ptr <= 0;
            end
            
            if (tx_fifo_read_en) begin
                tx_fifo_tail <= tx_fifo_tail + 1;
                if (tx_fifo_tail == TX_FIFO_DEPTH) tx_fifo_tail <= 0;
            end

            // RX FIFO
            rx_fifo_empty <= (rx_fifo_ptr == rx_fifo_tail);
            rx_fifo_full <= (rx_fifo_ptr == (rx_fifo_tail + RX_FIFO_DEPTH) - 1);

            if (rx_fifo_write_en) begin
                rx_fifo[rx_fifo_ptr] <= wb_dat_in[7:0];
                rx_fifo_ptr <= rx_fifo_ptr + 1;
                if (rx_fifo_ptr == RX_FIFO_DEPTH) rx_fifo_ptr <= 0;
            end

            if (rx_fifo_read_en) begin
                rx_fifo_tail <= rx_fifo_tail + 1;
                if (rx_fifo_tail == RX_FIFO_DEPTH) rx_fifo_tail <= 0;
            end
        end
    end

    // ---------------------------------------------------------------------------
    // Register Logic
    // ---------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            cr_reg <= 0;
            ier_reg <= 0;
            iir_reg <= 0;
            fcr_reg <= 0;
            lcr_reg <= 0;
            mcr_reg <= 0;
            lsr_reg <= 0;
            msr_reg <= 0;
            rdr_reg <= 0;
            thr_reg <= 0;
        end else begin
            // Write Logic
            if (wb_stb_reg && wb_cyc_reg && wb_we_reg) begin
                case (wb_adr_reg)
                    8'h00: cr_reg <= wb_dat_in[7:0];
                    8'h01: ier_reg <= wb_dat_in[7:0];
                    8'h02: iir_reg <= wb_dat_in[7:0];
                    8'h03: fcr_reg <= wb_dat_in[7:0];
                    8'h04: lcr_reg <= wb_dat_in[7:0];
                    8'h05: mcr_reg <= wb_dat_in[7:0];
                    8'h06: lsr_reg <= wb_dat_in[7:0];
                    8'h07: msr_reg <= wb_dat_in[7:0];
                    8'h08: rdr_reg <= wb_dat_in[7:0];
                    8'h09: thr_reg <= wb_dat_in[7:0];
                    default: ;
                endcase
            end

            // Read Logic
            case (wb_adr_reg)
                8'h00: wb_dat_out <= {cr_reg, 24'h0};
                8'h01: wb_dat_out <= {ier_reg, 24'h0};
                8'h02: wb_dat_out <= {iir_reg, 24'h0};
                8'h03: wb_dat_out <= {fcr_reg, 24'h0};
                8'h04: wb_dat_out <= {lcr_reg, 24'h0};
                8'h05: wb_dat_out <= {mcr_reg, 24'h0};
                8'h06: wb_dat_out <= {lsr_reg, 24'h0};
                8'h07: wb_dat_out <= {msr_reg, 24'h0};
                8'h08: wb_dat_out <= {rdr_reg, 24'h0};
                8'h09: wb_dat_out <= {thr_reg, 24'h0};
                default: wb_dat_out <= 0;
            endcase
        end
    end

    // ---------------------------------------------------------------------------
    // Register Update Logic (State Machine Driven)
    // ---------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            // Reset values
            iir_reg <= 0;
            lsr_reg <= 0;
            msr_reg <= 0;
            rdr_reg <= 0;
            int_reg <= 0;
        end else begin
            // IIR (Interrupt Identification Register)
            // Bit 0: Interrupt Pending
            // Bit 1: Interrupt Type
            // Bit 2: FIFO Status
            // Bit 3: FIFO Empty
            // Bit 4: FIFO Full
            // Bit 5: Reserved
            // Bit 6: Reserved
            // Bit 7: Reserved
            
            reg iir_val;
            reg iir_pending;
            reg iir_type;
            reg iir_fifo_status;
            reg iir_fifo_empty;
            reg iir_fifo_full;

            // Determine Interrupt Pending
            iir_pending <= 0;
            if (ier_reg[0] == 1) begin // RX Enable
                if (rx_fifo_empty == 0) iir_pending <= 1;
                if (rx_fifo_full == 1) iir_pending <= 1;
            end
            if (ier_reg[1] == 1) begin // TX Enable
                if (tx_fifo_empty == 1) iir_pending <= 1;
            end
            if (ier_reg[2] == 1) begin // RX Data Available
                if (rx_fifo_empty == 0) iir_pending <= 1;
            end
            if (ier_reg[3] == 1) begin // TX Holding Register Empty
                if (tx_fifo_empty == 1) iir_pending <= 1;
            end

            // Determine Interrupt Type
            iir_type <= 0;
            if (iir_pending) begin
                if (ier_reg[0] == 1) begin
                    if (rx_fifo_full == 1) iir_type <= 1; // RX FIFO Full
                    else if (rx_fifo_empty == 0) iir_type <= 2; // RX Data Available
                    else iir_type <= 3; // RX FIFO Empty
                end else if (ier_reg[1] == 1) begin
                    if (tx_fifo_empty == 1) iir_type <= 4; // TX Holding Register Empty
                    else iir_type <= 5; // TX FIFO Empty
                end else if (ier_reg[2] == 1) begin
                    if (rx_fifo_empty == 0) iir_type <= 6; // RX Data Available
                    else iir_type <= 7; // RX FIFO Empty
                end else if (ier_reg[3] == 1) begin
                    if (tx_fifo_empty == 1) iir_type <= 8; // TX Holding Register Empty
                    else iir_type <= 9; // TX FIFO Empty
                end
            end

            // FIFO Status
            iir_fifo_status <= 0;
            if (fcr_reg[0] == 1) begin // Enable RX FIFO
                if (rx_fifo_empty == 0) iir_fifo_status <= 1;
                if (rx_fifo_full == 1) iir_fifo_status <= 2;
                if (rx_fifo_empty == 1) iir_fifo_status <= 3;
            end
            if (fcr_reg[1] == 1) begin // Enable TX FIFO
                if (tx_fifo_empty == 0) iir_fifo_status <= 1;
                if (tx_fifo_full == 1) iir_fifo_status <= 2;
                if (tx_fifo_empty == 1) iir_fifo_status <= 3;
            end

            // FIFO Empty/Full
            iir_fifo_empty <= (fcr_reg[0] == 1 && rx_fifo_empty == 1) || (fcr_reg[1] == 1 && tx_fifo_empty == 1);
            iir_fifo_full <= (fcr_reg[0] == 1 && rx_fifo_full == 1) || (fcr_reg[1] == 1 && tx_fifo_full == 1);

            // Update IIR
            iir_reg <= {iir_pending, iir_type, iir_fifo_status, iir_fifo_empty, iir_fifo_full, 3'b000};

            // LSR (Line Status Register)
            lsr_reg <= {
                (tx_fifo_empty == 1) ? 1'b1 : 1'b0, // Bit 0: THR Empty
                (rx_fifo_empty == 1) ? 1'b1 : 1'b0, // Bit 1: RDR Empty
                1'b0, // Bit 2: Receiver Error (Simplified)
                1'b0, // Bit 3: Break Interrupt
                1'b0, // Bit 4: Overrun Error
                1'b0, // Bit 5: Parity Error
                1'b0, // Bit 6: Framing Error
                1'b0  // Bit 7: Transmitter Holding Register Empty (Duplicate of Bit 0)
            };

            // MSR (Modem Status Register)
            msr_reg <= {
                cts_pad_i, // Bit 0: CTS
                dcd_pad_i, // Bit 1: DCD
                dsr_pad_i, // Bit 2: DSR
                ri_pad_i,  // Bit 3: RI
                1'b0,      // Bit 4: Out 1
                1'b0,      // Bit 5: Out 2
                1'b0,      // Bit 6: Out 3
                1'b0       // Bit 7: Out 4
            };

            // RDR (Receive Data Register)
            if (rx_fifo_empty == 0) begin
                rdr_reg <= rx_fifo[rx_fifo_tail];
                // Auto-read if enabled in FCR
                if (fcr_reg[2] == 1) begin
                    rx_fifo_read_en <= 1;
                end
            end else begin
                rdr_reg <= 0;
            end

            // THR (Transmit Holding Register)
            if (tx_fifo_empty == 1) begin
                thr_reg <= 0;
            end else begin
                thr_reg <= tx_fifo[tx_fifo_tail];
            end

            // INT (Interrupt Output)
            int_reg <= iir_pending;
        end
    end

    // ---------------------------------------------------------------------------
    // Pad Outputs
    // ---------------------------------------------------------------------------
    assign stx_pad_o = stx_pad_reg;
    assign rts_pad_o = mcr_reg[0]; // RTS
    assign dtr_pad_o = mcr_reg[1]; // DTR
    assign cts_pad_i = msr_reg[0]; // CTS
    assign dsr_pad_i = msr_reg[2]; // DSR
    assign ri_pad_i = msr_reg[3];  // RI
    assign dcd_pad_i = msr_reg[1]; // DCD

    // ---------------------------------------------------------------------------
    // Wishbone Acknowledge
    // ---------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_ack_reg <= 0;
        end else begin
            wb_ack_reg <= wb_stb_reg && wb_cyc_reg;
        end
    end

endmodule
```<|im_end|>
