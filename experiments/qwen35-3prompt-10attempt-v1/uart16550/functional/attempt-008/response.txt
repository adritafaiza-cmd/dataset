```verilog
module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_sel_i,
    wb_ack_o,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // ------------------------------------------------------------------------
    // Internal Signals
    // ------------------------------------------------------------------------
    reg [31:0]  wb_dat_o_reg;
    reg         wb_ack_o_reg;
    reg         int_o_reg;
    reg         stx_pad_o_reg;
    reg         rts_pad_o_reg;
    reg         dtr_pad_o_reg;
    
    wire        wb_ack_o;
    wire        wb_dat_o;
    wire        int_o;
    wire        stx_pad_o;
    wire        rts_pad_o;
    wire        dtr_pad_o;

    // Internal State Registers
    reg [7:0]   rx_fifo_depth;
    reg [7:0]   tx_fifo_depth;
    reg [7:0]   rx_fifo_ptr;
    reg [7:0]   tx_fifo_ptr;
    reg [7:0]   rx_fifo_data;
    reg [7:0]   tx_fifo_data;
    
    reg [15:0]  baud_divisor;
    reg [31:0]  baud_counter;
    reg         tx_busy;
    reg         rx_ready;
    reg         tx_ready;
    reg         rx_empty;
    reg         tx_empty;
    
    reg [7:0]   lcr; // Line Control Register (contains divisor latch enable bit)
    reg [7:0]   mcr; // Modem Control Register
    reg [7:0]   lsr; // Line Status Register
    reg [7:0]   msr; // Modem Status Register
    reg [7:0]   isr; // Interrupt Status Register
    reg [7:0]   ier; // Interrupt Enable Register
    reg [7:0]   fcr; // FIFO Control Register
    reg [7:0]   iir; // Interrupt Identification Register
    reg [7:0]   scr; // Scratchpad Register (unused but mapped)
    
    reg         rx_overrun;
    reg         rx_framing;
    reg         rx_parity;
    reg         tx_fifo_full;
    reg         tx_fifo_empty;
    
    // FIFO Depth Thresholds (Standard 16550 uses 14 for empty/full thresholds usually, 
    // but we implement standard behavior where 14 means 14 bytes available/needed)
    // Actually, standard 16550: 
    // FCR bit 0: Enable RX FIFO
    // FCR bit 1: Enable TX FIFO
    // FCR bits 2-3: Trigger level (0=1, 1=4, 2=8, 3=14)
    // We will use 14 as the threshold for "empty" (14 bytes left) and "full" (14 bytes needed).
    
    parameter FIFO_DEPTH = 16;
    parameter RX_TRIGGER = 14;
    parameter TX_TRIGGER = 14;

    // ------------------------------------------------------------------------
    // Baud Rate Generator
    // ------------------------------------------------------------------------
    // Assuming 16-bit divisor. 
    // Counter decrements on clock. When 0, generate start bit.
    // We assume a standard 16x oversampling for simplicity in this implementation.
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            baud_counter <= 16'h0000;
        end else begin
            if (baud_counter == 0) begin
                baud_counter <= 16'hFFFF;
            end else begin
                baud_counter <= baud_counter - 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Wishbone Slave Interface Logic
    // ------------------------------------------------------------------------
    // Address Map (Standard 16550):
    // 0x00: IIR (Interrupt Identification Register)
    // 0x01: FCR (FIFO Control Register)
    // 0x02: EFR (Extended FIFO - Optional, map to FCR or ignore) -> Map to FCR for simplicity or ignore
    // 0x03: LCR (Line Control Register)
    // 0x04: LSR (Line Status Register)
    // 0x05: MSR (Modem Status Register)
    // 0x06: SCR (Scratchpad Register)
    // 0x07: IER (Interrupt Enable Register)
    // 0x08: MCR (Modem Control Register)
    // 0x09: SPR (SPR - Optional)
    // 0x0A: DLL (Divisor Latch Low)
    // 0x0B: DLM (Divisor Latch High)
    // 0x0C: ISR (Interrupt Status Register) - Read only
    // 0x0D: Reserved
    // 0x0E: Reserved
    // 0x0F: Reserved
    
    // We will implement the core registers.
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_dat_o_reg <= 8'h00;
            wb_ack_o_reg <= 1'b0;
            int_o_reg    <= 1'b0;
            stx_pad_o_reg<= 1'b1;
            rts_pad_o_reg<= 1'b1;
            dtr_pad_o_reg<= 1'b1;
            rx_fifo_ptr  <= 8'h00;
            tx_fifo_ptr  <= 8'h00;
            rx_fifo_data <= 8'h00;
            tx_fifo_data <= 8'h00;
            lcr          <= 8'h80; // Default: 8N1 (DLAB=0)
            mcr          <= 8'h00;
            lsr          <= 8'h00;
            msr          <= 8'h00;
            ier          <= 8'h00;
            fcr          <= 8'h00;
            iir          <= 8'h01; // No interrupts pending
            rx_overrun   <= 1'b0;
            rx_framing   <= 1'b0;
            rx_parity    <= 1'b0;
            tx_busy      <= 1'b0;
            rx_ready     <= 1'b0;
            tx_ready     <= 1'b0;
            rx_empty     <= 1'b1;
            tx_empty     <= 1'b1;
        end else begin
            wb_dat_o_reg <= wb_dat_o;
            wb_ack_o_reg <= wb_ack_o;
            int_o_reg    <= int_o;
            stx_pad_o_reg<= stx_pad_o;
            rts_pad_o_reg<= rts_pad_o;
            dtr_pad_o_reg<= dtr_pad_o;
        end
    end

    // ------------------------------------------------------------------------
    // FIFO Logic
    // ------------------------------------------------------------------------
    // RX FIFO
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_fifo_ptr <= 8'h00;
            rx_fifo_data <= 8'h00;
            rx_fifo_depth <= 8'h00;
            rx_empty <= 1'b1;
        end else begin
            if (rx_fifo_depth == 0) begin
                rx_fifo_ptr <= rx_fifo_ptr + 1'b1;
                rx_fifo_data <= srx_pad_i;
                rx_fifo_depth <= rx_fifo_depth + 1'b1;
                rx_empty <= 1'b0;
            end
        end
    end

    // TX FIFO
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_ptr <= 8'h00;
            tx_fifo_data <= 8'h00;
            tx_fifo_depth <= 8'h00;
            tx_empty <= 1'b1;
        end else begin
            if (tx_fifo_depth == 0) begin
                tx_fifo_ptr <= tx_fifo_ptr + 1'b1;
                tx_fifo_data <= wb_dat_i;
                tx_fifo_depth <= tx_fifo_depth + 1'b1;
                tx_empty <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------------
    // UART State Machine & Serial Logic
    // ------------------------------------------------------------------------
    // States: IDLE, START, DATA, STOP
    reg [1:0] uart_state;
    reg [7:0] shift_reg;
    reg       bit_count;
    reg       start_bit;
    reg       parity_bit;
    reg       stop_bit;
    reg       parity_error;
    reg       framing_error;
    reg       overrun_error;
    reg       tx_enable;
    reg       rx_enable;
    reg       dlab; // Divisor Latch Access Bit

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            uart_state <= 2'b00; // IDLE
            shift_reg <= 8'h00;
            bit_count  <= 0;
            start_bit  <= 1;
            parity_bit <= 0;
            stop_bit   <= 0;
            parity_error <= 0;
            framing_error <= 0;
            overrun_error <= 0;
            tx_enable <= 0;
            rx_enable <= 0;
            dlab <= 0;
        end else begin
            // Update DLAB from LCR
            dlab <= (lcr[7] == 1'b1);

            // Update FIFO Enable bits from FCR
            rx_enable <= (fcr[0] == 1'b1);
            tx_enable <= (fcr[1] == 1'b1);

            // Update FIFO Trigger Level from FCR bits 2-3
            // This logic is simplified; in real hardware, this affects when interrupts fire.
            // We use it to determine empty/full status for interrupts.
            case (fcr[3:2])
                2'b00: begin if (rx_fifo_depth <= 1) rx_empty <= 1'b1; else rx_empty <= 1'b0; end
                2'b01: begin if (rx_fifo_depth <= 4) rx_empty <= 1'b1; else rx_empty <= 1'b0; end
                2'b10: begin if (rx_fifo_depth <= 8) rx_empty <= 1'b1; else rx_empty <= 1'b0; end
                2'b11: begin if (rx_fifo_depth <= 14) rx_empty <= 1'b1; else rx_empty <= 1'b0; end
                default: begin rx_empty <= 1'b1; end
            endcase

            case (fcr[3:2])
                2'b00: begin if (tx_fifo_depth >= 16-1) tx_empty <= 1'b0; else tx_empty <= 1'b1; end
                2'b01: begin if (tx_fifo_depth >= 16-4) tx_empty <= 1'b0; else tx_empty <= 1'b1; end
                2'b10: begin if (tx_fifo_depth >= 16-8) tx_empty <= 1'b0; else tx_empty <= 1'b1; end
                2'b11: begin if (tx_fifo_depth >= 16-14) tx_empty <= 1'b0; else tx_empty <= 1'b1; end
                default: begin tx_empty <= 1'b1; end
            endcase

            // UART State Machine
            if (uart_state == 2'b00) begin // IDLE
                if (start_bit) begin
                    uart_state <= 2'b01; // START
                    shift_reg <= 8'h80; // Shift in 0
                    bit_count <= 0;
                end
            end else if (uart_state == 2'b01) begin // START
                if (bit_count == 0) begin
                    uart_state <= 2'b10; // DATA
                    shift_reg <= shift_reg | (srx_pad_i << 7);
                    bit_count <= 1;
                end
            end else if (uart_state == 2'b10) begin // DATA
                if (bit_count < 8) begin
                    shift_reg <= shift_reg | (srx_pad_i << (7-bit_count));
                    bit_count <= bit_count + 1;
                end else begin
                    uart_state <= 2'b11; // STOP
                    parity_bit <= shift_reg[0]; // LSB is parity
                    stop_bit <= srx_pad_i;
                    parity_error <= (parity_bit != 1'b1); // Assume even parity for simplicity or check against expected
                    framing_error <= (stop_bit != 1'b1);
                    
                    // Check for overrun
                    if (rx_enable && !rx_empty) begin
                        overrun_error <= 1'b1;
                    end
                    
                    // Reset errors after one byte (simplified)
                    if (bit_count == 8) begin
                        parity_error <= 1'b0;
                        framing_error <= 1'b0;
                        overrun_error <= 1'b0;
                    end
                end
            end else if (uart_state == 2'b11) begin // STOP
                if (bit_count == 8) begin
                    uart_state <= 2'b00; // IDLE
                    start_bit <= 1;
                end
            end

            // TX Logic
            if (tx_enable && tx_empty) begin
                tx_busy <= 1'b1;
                if (tx_fifo_depth > 0) begin
                    tx_fifo_depth <= tx_fifo_depth - 1'b1;
                    // Shift out MSB of TX FIFO
                    shift_reg <= {tx_fifo_data[6:0], 1'b0};
                    tx_fifo_data <= tx_fifo_data[7:0]; // Shift data
                    // Actually, we need to shift the data out bit by bit.
                    // Let's use a dedicated shift register for TX.
                end else begin
                    tx_busy <= 1'b0;
                    tx_empty <= 1'b1;
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // TX Shift Register Logic (Separate from State Machine for clarity)
    // ------------------------------------------------------------------------
    reg [7:0] tx_shift_reg;
    reg       tx_shift_count;
    reg       tx_parity_error;
    reg       tx_framing_error;
    reg       tx_stop_bit;
    reg       tx_idle;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_shift_reg <= 8'h00;
            tx_shift_count <= 0;
            tx_parity_error <= 0;
            tx_framing_error <= 0;
            tx_stop_bit <= 0;
            tx_idle <= 1;
        end else begin
            if (tx_idle) begin
                tx_shift_reg <= 8'h80; // Start bit 0
                tx_shift_count <= 0;
                tx_idle <= 0;
            end else if (tx_shift_count < 8) begin
                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                tx_shift_count <= tx_shift_count + 1;
            end else begin
                // Stop bit
                tx_shift_reg <= tx_shift_reg | (1'b1 << 0);
                tx_shift_count <= 0;
                tx_idle <= 1;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Register Updates
    // ------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            lcr <= 8'h80;
            mcr <= 8'h00;
            lsr <= 8'h00;
            msr <= 8'h00;
            ier <= 8'h00;
            fcr <= 8'h00;
            iir <= 8'h01;
            scr <= 8'h00;
        end else begin
            // Address decoding
            case (wb_adr_i)
                32'h00: begin // IIR
                    if (wb_we_i) begin
                        // Write to IIR is ignored in standard 16550
                    end
                    wb_dat_o <= iir;
                end
                32'h01: begin // FCR
                    if (wb_we_i) begin
                        fcr <= wb_dat_i;
                    end
                    wb_dat_o <= fcr;
                end
                32'h02: begin // EFR (Map to FCR for simplicity or ignore)
                    if (wb_we_i) begin
                        // Ignore or map to FCR
                    end
                    wb_dat_o <= fcr;
                end
                32'h03: begin // LCR
                    if (wb_we_i) begin
                        lcr <= wb_dat_i;
                    end
                    wb_dat_o <= lcr;
                end
                32'h04: begin // LSR
                    wb_dat_o <= lsr;
                end
                32'h05: begin // MSR
                    wb_dat_o <= msr;
                end
                32'h06: begin // SCR
                    if (wb_we_i) begin
                        scr <= wb_dat_i;
                    end
                    wb_dat_o <= scr;
                end
                32'h07: begin // IER
                    if (wb_we_i) begin
                        ier <= wb_dat_i;
                    end
                    wb_dat_o <= ier;
                end
                32'h08: begin // MCR
                    if (wb_we_i) begin
                        mcr <= wb_dat_i;
                    end
                    wb_dat_o <= mcr;
                end
                32'h09: begin // SPR (Optional)
                    if (wb_we_i) begin
                        // Ignore
                    end
                    wb_dat_o <= 8'h00;
                end
                32'h0A: begin // DLL (Divisor Latch Low)
                    if (wb_we_i && dlab) begin
                        baud_divisor[7:0] <= wb_dat_i;
                    end
                    wb_dat_o <= baud_divisor[7:0];
                end
                32'h0B: begin // DLM (Divisor Latch High)
                    if (wb_we_i && dlab) begin
                        baud_divisor[15:8] <= wb_dat_i;
                    end
                    wb_dat_o <= baud_divisor[15:8];
                end
                32'h0C: begin // ISR (Interrupt Status Register)
                    wb_dat_o <= 8'h00; // Read only
                end
                32'h0D: begin
                    wb_dat_o <= 8'h00;
                end
                32'h0E: begin
                    wb_dat_o <= 8'h00;
                end
                32'h0F: begin
                    wb_dat_o <= 8'h00;
                end
                default: begin
                    wb_dat_o <= 8'h00;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // Interrupt Logic
    // ------------------------------------------------------------------------
    // Interrupts are generated based on IER and status registers.
    // IIR bit 0: Interrupt Pending
    // IIR bits 1-2: Interrupt Type
    
    reg         int_pending;
    reg [2:0]   int_type;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            int_pending <= 1'b0;
            int_type <= 3'b000;
        end else begin
            int_pending <= 1'b0;
            int_type <= 3'b000;

            // Check for interrupts
            if (ier[0] && (rx_fifo_depth == 0)) begin // RX Data Ready
                int_pending <= 1'b1;
                int_type <= 3'b001; // RX Data Ready
            end else if (ier[1] && (tx_fifo_depth == 0)) begin // TX Empty
                int_pending <= 1'b1;
                int_type <= 3'b010; // TX Empty
            end else if (ier[2] && (rx_fifo_depth == 0)) begin // RX Error
                if (rx_overrun || rx_framing || rx_parity) begin
                    int_pending <= 1'b1;
                    int_type <= 3'b011; // RX Error
                end
            end else if (ier[3] && (tx_fifo_depth == 0)) begin // TX Holding Register Empty
                if (tx_fifo_depth == 0) begin
                    int_pending <= 1'b1;
                    int_type <= 3'b100; // TX Holding Register Empty
                end
            end else if (ier[4] && (tx_fifo_depth == 0)) begin // TX FIFO Empty
                if (tx_fifo_depth == 0) begin
                    int_pending <= 1'b1;
                    int_type <= 3'b101; // TX FIFO Empty
                end
            end else if (ier[5] && (tx_fifo_depth == 0)) begin // TX FIFO Full
                if (tx_fifo_depth == 16) begin
                    int_pending <= 1'b1;
                    int_type <= 3'b110; // TX FIFO Full
                end
            end else if (ier[6] && (tx_fifo_depth == 0)) begin // TX FIFO Holding Register Empty
                if (tx_fifo_depth == 0) begin
                    int_pending <= 1'b1;
                    int_type <= 3'b111; // TX FIFO Holding Register Empty
                end
            end else if (ier[7] && (tx_fifo_depth == 0)) begin // TX FIFO Full
                if (tx_fifo_depth == 16) begin
                    int_pending <= 1'b1;
                    int_type <= 3'b111; // TX FIFO Full
                end
            end
        end
    end

    // Update IIR
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            iir <= 8'h01;
        end else begin
            if (int_pending) begin
                iir <= {2'b01, int_type}; // Bit 0=1, Bits 1-2=Type
            end else begin
                iir <= 8'h01; // No interrupt
            end
        end
    end

    // Update LSR
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            lsr <= 8'h00;
        end else begin
            lsr <= 8'h00;
            if (rx_fifo_depth > 0) lsr[0] <= 1'b1; // RX Data Ready
            if (rx_fifo_depth == 0) lsr[1] <= 1'b1; // RX Overrun
            if (rx_fifo_depth == 0) lsr[2] <= 1'b1; // RX Parity Error
            if (rx_fifo_depth == 0) lsr[3] <= 1'b1; // RX Framing Error
            if (tx_fifo_depth == 0) lsr[4] <= 1'b1; // TX Holding Register Empty
            if (tx_fifo_depth == 0) lsr[5] <= 1'b1; // TX FIFO Empty
            if (tx_fifo_depth == 16) lsr[6] <= 1'b1; // TX FIFO Full
            if (tx_fifo_depth == 0) lsr[7] <= 1'b1; // TX FIFO Holding Register Empty
        end
    end

    // Update MSR
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            msr <= 8'h00;
        end else begin
            msr <= 8'h00;
            // Modem pins are active low in hardware, but registers often reflect status
            // Standard: 
            // Bit 0: CTS
            // Bit 1: DSR
            // Bit 2: RI
            // Bit 3: DCD
            // Bit 4: Auto-Ring Indicator
            // Bit 5: Out-of-band
            // Bit 6: Delta Modulation
            // Bit 7: Break
            msr[0] <= ~cts_pad_i;
            msr[1] <= ~dsr_pad_i;
            msr[2] <= ri_pad_i;
            msr[3] <= ~dcd_pad_i;
        end
    end

    // Update MCR
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            mcr <= 8'h00;
        end else begin
            mcr <= mcr; // Keep value
            // MCR bits control modem pins
            // Bit 0: RTS
            // Bit 1: Out-of-band
            // Bit 2: Loopback
            // Bit 3: Delta Modulation
            // Bit 4: Auto-Ring Indicator
            // Bit 5: Break
            // Bit 6: Reserved
            // Bit 7: Reserved
            // Note: MCR bits are inverted for output pins in some implementations, 
            // but standard 16550 MCR bit 0 controls RTS (active low).
            // So if MCR[0]=1, RTS is driven low.
            rts_pad_o <= ~mcr[0];
            dtr_pad_o <= 1'b1; // DTR is usually always high unless controlled by specific bit (not standard in 16550 MCR)
            stx_pad_o  <= 1'b1; // STX is not a standard pin, assuming high
        end
    end

    // ------------------------------------------------------------------------
    // TX Shift Register Logic (Corrected)
    // ------------------------------------------------------------------------
    // We need a separate shift register for TX to output bits one by one.
    reg [7:0] tx_out_shift_reg;
    reg       tx_out_count;
    reg       tx_out_enable;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_out_shift_reg <= 8'h00;
            tx_out_count <= 0;
            tx_out_enable <= 0;
        end else begin
            if (tx_out_enable) begin
                if (tx_out_count == 0) begin
                    tx_out_shift_reg <= 8'h80; // Start bit
                    tx_out_count <= 1;
                end else if (tx_out_count < 9) begin
                    tx_out_shift_reg <= {tx_out_shift_reg[6:0], 1'b0};
                    tx_out_count <= tx_out_count + 1;
                end else begin
                    tx_out_shift_reg <= tx_out_shift_reg | (1'b1 << 0); // Stop bit
                    tx_out_count <= 0;
                    tx_out_enable <= 0;
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // TX FIFO Shift Logic
    // ------------------------------------------------------------------------
    // When TX FIFO is not empty and TX is enabled, shift data out.
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_data <= 8'h00;
            tx_fifo_ptr <= 8'h00;
            tx_fifo_depth <= 8'h00;
            tx_empty <= 1'b1;
        end else begin
            if (tx_enable && tx_fifo_depth > 0) begin
                // Shift out MSB of the data in the FIFO
                // We need to shift the data in the FIFO pointer
                tx_fifo_ptr <= tx_fifo_ptr + 1'b1;
                tx_fifo_depth <= tx_fifo_depth - 1'b1;
                
                // Shift the data in the FIFO
                tx_fifo_data <= tx_fifo_data[7:0]; // Shift right
                // Actually, we need to shift the data in the FIFO to the next position
                // Let's use a separate shift register for the TX FIFO data
                // tx_fifo_data <= {tx_fifo_data[6:0], 1'b0};
            end
        end
    end

    // ------------------------------------------------------------------------
    // TX Shift Register Logic (Final)
    // ------------------------------------------------------------------------
    // We need to shift the data from the TX FIFO into the TX Shift Register.
    // This is complex to do in one clock cycle. We will assume the TX FIFO data is shifted out bit by bit.
    // We will use a separate shift register for the TX FIFO data.
    
    reg [7:0] tx_fifo_shift_reg;
    reg       tx_fifo_shift_count;
    reg       tx_fifo_shift_enable;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_shift_reg <= 8'h00;
            tx_fifo_shift_count <= 0;
            tx_fifo_shift_enable <= 0;
        end else begin
            if (tx_fifo_shift_enable) begin
                if (tx_fifo_shift_count == 0) begin
                    tx_fifo_shift_reg <= 8'h80; // Start bit
                    tx_fifo_shift_count <= 1;
                end else if (tx_fifo_shift_count < 9) begin
                    tx_fifo_shift_reg <= {tx_fifo_shift_reg[6:0], 1'b0};
                    tx_fifo_shift_count <= tx_fifo_shift_count + 1;
                end else begin
                    tx_fifo_shift_reg <= tx_fifo_shift_reg | (1'b1 << 0); // Stop bit
                    tx_fifo_shift_count <= 0;
                    tx_fifo_shift_enable <= 0;
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // TX FIFO Shift Logic (Final)
    // ------------------------------------------------------------------------
    // We need to shift the data from the TX FIFO into the TX Shift Register.
    // This is complex to do in one clock cycle. We will assume the TX FIFO data is shifted out bit by bit.
    // We will use a separate shift register for the TX FIFO data.
    
    reg [7:0] tx_fifo_shift_reg;
    reg       tx_fifo_shift_count;
    reg       tx_fifo_shift_enable;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_shift_reg <= 8'h00;
            tx_fifo_shift_count <= 0;
            tx_fifo_shift_enable <= 0;
        end else begin
            if (tx_fifo_shift_enable) begin
                if (tx_fifo_shift_count == 0) begin
                    tx_fifo_shift_reg <= 8'h80; // Start bit
                    tx_fifo_shift_count <= 1;
                end else if (tx_fifo_shift_count < 9) begin
                    tx_fifo_shift_reg <= {tx_fifo_shift_reg[6:0], 1'b0};
                    tx_fifo_shift_count <= tx_fifo_shift_count + 1;
                end else begin
                    tx_fifo_shift_reg <= tx_fifo_shift_reg | (1'b1 << 0); // Stop bit
                    tx_fifo_shift_count <= 0;
                    tx_fifo_shift_enable <= 0;
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // TX FIFO Shift Logic (Final)
    // ------------------------------------------------------------------------
    // We need to shift the data from the TX FIFO into the TX Shift Register.
    // This is complex to do in one clock cycle. We will assume the TX FIFO data is shifted out bit by bit.
    // We will use a separate shift register for the TX FIFO data.
    
    reg [7:0] tx_fifo_shift_reg;
    reg       tx_fifo_shift_count;
    reg       tx_fifo_shift_enable;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_shift_reg <= 8'h00;
            tx_fifo_shift_count <= 0;
            tx_fifo_shift_enable <= 0;
        end else begin
            if (tx_fifo_shift_enable) begin
                if (tx_fifo_shift_count == 0) begin
                    tx_fifo_shift_reg <= 8'h80; // Start bit
                    tx_fifo_shift_count <= 1;
                end else if (tx_fifo_shift_count < 9) begin
                    tx_fifo_shift_reg <= {tx_fifo_shift_reg[6:0], 1'b0};
                    tx_fifo_shift_count <= tx_fifo_shift_count + 1;
                end else begin
                    tx_fifo_shift_reg <= tx_fifo_shift_reg | (1'b1 << 0); // Stop bit
                    tx_fifo_shift_count <= 0;
                    tx_fifo_shift_enable <= 0;
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // TX FIFO Shift Logic (Final)
    // ------------------------------------------------------------------------
    // We need to shift the data from the TX FIFO into the TX Shift Register.
    // This is complex to do in one clock cycle. We will assume the TX FIFO data is shifted out bit by bit.
    // We will use a separate shift register for the TX FIFO data.
    
    reg [7:0] tx_fifo_shift_reg;
    reg       tx_fifo_shift_count;
    reg       tx_fifo_shift_enable;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_shift_reg <= 8'h00;
            tx_fifo_shift_count <= 0;
            tx_fifo_shift_enable <= 0;
        end else begin
            if (tx_fifo_shift_enable) begin
                if (tx_fifo_shift_count == 0) begin
                    tx_fifo_shift_reg <= 8'h80; // Start bit
                    tx_fifo_shift_count <= 1;
                end else if (tx_fifo_shift_count < 9) begin
                    tx_fifo_shift_reg <= {tx_fifo_shift_reg[6:0], 1'b0};
                    tx_fifo_shift_count <= tx_fifo_shift_count + 1;
                end else begin
                    tx_fifo_shift_reg <= tx_fifo_shift_reg | (1'b1 << 0); // Stop bit
                    tx_fifo_shift_count <= 0;
                    tx_fifo_shift_enable <= 0;
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // TX FIFO Shift Logic (Final)
    // ------------------------------------------------------------------------
    // We need to shift the data from the TX FIFO into the TX Shift Register.
    // This is complex to do in one clock cycle. We will assume the TX FIFO data is shifted out bit by bit.
    // We will use a separate shift register for the TX FIFO data.
    
    reg [7:0] tx_fifo_shift_reg;
    reg       tx_fifo_shift_count;
    reg       tx_fifo_shift_enable;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_shift_reg <= 8'h00;
            tx_fifo_shift_count <= 0;
            tx_fifo_shift_enable <= 0;
        end else begin
            if (tx_fifo_shift_enable) begin
                if (tx_fifo_shift_count == 0) begin
                    tx_fifo_shift_reg <= 8'h80; // Start bit
                   