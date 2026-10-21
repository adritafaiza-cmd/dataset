```verilog
`timescale 1ns/1ps

module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // -----------------------------------------------------------------------
    // Internal Clocks and Resets
    // -----------------------------------------------------------------------
    parameter WB_CLK_PERIOD_NS = 10; // 100 MHz Wishbone
    parameter RX_CLK_PERIOD_NS   = 100; // 1 MHz Baud (approx for 115200 @ 100MHz is 859ns, but we use a divider)
    // For 115200 baud at 100MHz: Divider = 100,000,000 / 115,200 = 868.05
    // We will implement a programmable baud rate generator.
    
    reg wb_clk;
    reg rx_clk;
    reg wb_rst_n;
    reg rx_rst_n;
    
    // CDC: Generate clocks and resets using standard synchronous logic
    // Wishbone domain
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        wb_clk <= wb_clk_i;
        wb_rst_n <= !wb_rst_i;
    end
    
    // RX domain (derived from wb_clk)
    // We use a counter to generate the baud clock. 
    // To ensure CDC safety, the baud clock is generated synchronously in the WB domain
    // and then used to drive the RX state machine synchronously.
    // However, for a true 16550 implementation, we need a high-frequency clock for the RX FIFO.
    // Strategy: Use the WB clock to drive a baud rate counter. When the counter overflows,
    // it triggers a "tick" in the RX domain. This avoids generating a separate asynchronous clock.
    // Alternatively, we can generate a fast clock (e.g., 16x baud) synchronously in WB domain
    // and use it for the RX FIFO.
    
    reg [15:0] baud_divider;
    reg [31:0] baud_counter;
    reg rx_tick;
    
    // Baud Rate Calculation: 
    // We assume the user programs the baud rate via register 0.
    // Formula: Baud = WB_CLK / (Baud_Reg + 1)
    // We need a clock that is an integer multiple of the baud rate for the RX FIFO.
    // Common practice: Use a 16x or 16.66x clock. 
    // Let's generate a "RX_CLK" which is 16 * Baud Rate.
    // Counter counts from 0 to (16 * (Baud_Reg + 1) - 1).
    
    // -----------------------------------------------------------------------
    // Wishbone Interface Signals
    // -----------------------------------------------------------------------
    reg [31:0] wb_dat_o_reg;
    reg wb_ack_o_reg;
    reg [3:0] wb_sel_o;
    
    // -----------------------------------------------------------------------
    // Internal Registers (Wishbone Domain)
    // -----------------------------------------------------------------------
    // 16550 Register Map (Standard):
    // 0x00: IER (Interrupt Enable Register)
    // 0x01: IIR (Interrupt Identification Register)
    // 0x02: FCR (FIFO Control Register)
    // 0x03: LCR (Line Control Register)
    // 0x04: MCR (Modem Control Register)
    // 0x05: LSR (Line Status Register)
    // 0x06: MSR (Modem Status Register)
    // 0x07: SCR (Scratch Register)
    // 0x08: DLL (Divisor Latch Low)
    // 0x09: DLM (Divisor Latch High)
    // 0x0A: ISR (Interrupt Status Register)
    // 0x0B: FCR (FIFO Control Register - sometimes mapped here too, but 0x02 is primary)
    // 0x0C: IIR (Interrupt Identification Register - sometimes mapped here too)
    
    // We will map:
    // 0x00: IER
    // 0x01: IIR
    // 0x02: FCR
    // 0x03: LCR
    // 0x04: MCR
    // 0x05: LSR
    // 0x06: MSR
    // 0x07: SCR
    // 0x08: DLL
    // 0x09: DLM
    // 0x0A: ISR
    
    reg [7:0] reg_ier;
    reg [7:0] reg_iir;
    reg [7:0] reg_fcr;
    reg [7:0] reg_lcr;
    reg [7:0] reg_mcr;
    reg [7:0] reg_lsr;
    reg [7:0] reg_msr;
    reg [7:0] reg_scr;
    reg [7:0] reg_dll;
    reg [7:0] reg_dlm;
    reg [7:0] reg_isr;
    
    // Baud Rate Divisor (16-bit)
    reg [15:0] baud_divisor_val;
    
    // FIFOs
    // TX FIFO: Depth 16
    // RX FIFO: Depth 16
    parameter FIFO_DEPTH = 16;
    parameter DATA_WIDTH = 8;
    
    // TX FIFO
    reg [DATA_WIDTH-1:0] tx_fifo_mem [FIFO_DEPTH-1:0];
    reg [3:0] tx_fifo_count;
    reg tx_fifo_full;
    reg tx_fifo_empty;
    reg tx_fifo_write_en;
    reg tx_fifo_read_en;
    
    // RX FIFO
    reg [DATA_WIDTH-1:0] rx_fifo_mem [FIFO_DEPTH-1:0];
    reg [3:0] rx_fifo_count;
    reg rx_fifo_full;
    reg rx_fifo_empty;
    reg rx_fifo_write_en;
    reg rx_fifo_read_en;
    
    // -----------------------------------------------------------------------
    // Modem Pins (Input/Output)
    // -----------------------------------------------------------------------
    // Inputs: CTS, DSR, RI, DCD
    // Outputs: STX, RTS, DTR
    // We will implement simple handshaking logic.
    // STX: Output, driven by TX FIFO empty (or software control)
    // RTS: Output, driven by MCR bit 6 (RTS)
    // DTR: Output, driven by MCR bit 5 (DTR)
    // CTS, DSR, RI, DCD: Inputs, used to generate interrupts
    
    // -----------------------------------------------------------------------
    // Interrupt Logic
    // -----------------------------------------------------------------------
    // int_o: Output interrupt signal
    // Generated based on IER and status registers
    
    // -----------------------------------------------------------------------
    // Wishbone Decoder and Data Path
    // -----------------------------------------------------------------------
    // Address decoding
    // We assume the module is mapped to a specific address range.
    // For simplicity, we decode based on the lower bits.
    // In a real system, the address would be aligned.
    // We will assume wb_adr_i[1:0] == 2'b00 for valid access.
    
    // -----------------------------------------------------------------------
    // Main Logic
    // -----------------------------------------------------------------------
    
    // 1. Clock Generation for RX Domain
    // We need a clock that is 16 * Baud Rate.
    // Baud Rate = WB_CLK / (baud_divisor_val + 1)
    // RX_CLK_PERIOD = 16 * (baud_divisor_val + 1) / WB_CLK_PERIOD
    // We count in the WB domain to generate a pulse every 16 * (div + 1) cycles.
    
    reg [31:0] rx_counter;
    reg rx_clk_pulse;
    
    // 2. State Machines for RX and TX
    
    // -----------------------------------------------------------------------
    // Wishbone Read/Write Logic
    // -----------------------------------------------------------------------
    reg wb_read;
    reg wb_write;
    reg wb_addr_valid;
    
    // -----------------------------------------------------------------------
    // Baud Rate Calculation
    // -----------------------------------------------------------------------
    // When DLM and DLL are written, we update the baud divisor.
    // This must be done carefully to avoid glitches.
    
    // -----------------------------------------------------------------------
    // RX FIFO Logic
    // -----------------------------------------------------------------------
    // Shift register for serial data
    reg [7:0] rx_shift_reg;
    reg rx_shift_reg_valid;
    reg rx_shift_reg_empty;
    
    // -----------------------------------------------------------------------
    // TX FIFO Logic
    // -----------------------------------------------------------------------
    // Shift register for serial data
    reg [7:0] tx_shift_reg;
    reg tx_shift_reg_valid;
    reg tx_shift_reg_empty;
    
    // -----------------------------------------------------------------------
    // Interrupt Generation
    // -----------------------------------------------------------------------
    // int_o is active high.
    
    // -----------------------------------------------------------------------
    // Output Assignments
    // -----------------------------------------------------------------------
    assign wb_dat_o = wb_read ? wb_dat_o_reg : 8'b0;
    assign wb_ack_o = wb_ack_o_reg;
    assign wb_sel_o = wb_sel_i; // Echo select for read
    
    assign stx_pad_o = tx_fifo_empty; // STX is active when TX is empty (or software controlled)
    assign rts_pad_o = reg_mcr[6];     // RTS
    assign dtr_pad_o = reg_mcr[5];     // DTR
    
    assign int_o = int_signal;
    
    // -----------------------------------------------------------------------
    // Internal Logic Implementation
    // -----------------------------------------------------------------------
    
    // Clock Generation
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_counter <= 32'd0;
            rx_clk_pulse <= 1'b0;
        end else begin
            if (rx_counter == (16 * (baud_divisor_val + 1) - 1)) begin
                rx_counter <= 32'd0;
                rx_clk_pulse <= 1'b1;
            end else begin
                rx_counter <= rx_counter + 1'b1;
            end
        end
    end
    
    // Baud Rate Register Update
    // Only update when DLM and DLL are written together (bit 7 of LCR is 1)
    // Or simply update whenever DLL/DLM are written if we assume the user knows the sequence.
    // Standard 16550: Write DLM, then DLL, or write both.
    // We will update the divisor whenever DLL or DLM is written.
    
    // -----------------------------------------------------------------------
    // RX Shift Register
    // -----------------------------------------------------------------------
    always @(posedge rx_clk_pulse or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_shift_reg <= 8'b0;
            rx_shift_reg_valid <= 1'b0;
            rx_shift_reg_empty <= 1'b1;
        end else begin
            if (rx_shift_reg_valid) begin
                rx_shift_reg <= {rx_shift_reg[6:0], srx_pad_i};
                rx_shift_reg_empty <= 1'b0;
            end else begin
                rx_shift_reg <= 8'b0;
                rx_shift_reg_valid <= 1'b0;
                rx_shift_reg_empty <= 1'b1;
            end
        end
    end
    
    // RX FIFO Write Enable
    // When shift register is valid, write to FIFO
    always @(posedge rx_clk_pulse or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_fifo_count <= 4'd0;
            rx_fifo_full <= 1'b0;
            rx_fifo_empty <= 1'b1;
        end else begin
            if (rx_shift_reg_valid && !rx_fifo_full) begin
                rx_fifo_count <= rx_fifo_count + 1'b1;
                rx_fifo_mem[rx_fifo_count - 1'b1] <= rx_shift_reg;
                rx_fifo_empty <= 1'b0;
            end else if (rx_fifo_count == 0) begin
                rx_fifo_empty <= 1'b1;
            end
        end
    end
    
    // RX FIFO Read Enable
    // Driven by Wishbone Read
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_dat_o_reg <= 8'b0;
            wb_ack_o_reg <= 1'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_read && wb_sel_i[0] == 1'b1) begin
                // Read from FIFO
                if (rx_fifo_empty) begin
                    wb_dat_o_reg <= 8'b0;
                    wb_ack_o_reg <= 1'b0;
                end else begin
                    wb_dat_o_reg <= rx_fifo_mem[rx_fifo_count - 1'b1];
                    wb_ack_o_reg <= 1'b1;
                    // Decrement count
                    if (rx_fifo_count == 1) begin
                        rx_fifo_count <= 4'd0;
                        rx_fifo_empty <= 1'b1;
                    end else begin
                        rx_fifo_count <= rx_fifo_count - 1'b1;
                    end
                end
            end else begin
                wb_ack_o_reg <= 1'b0;
            end
        end
    end
    
    // -----------------------------------------------------------------------
    // TX FIFO Logic
    // -----------------------------------------------------------------------
    // TX FIFO Write Enable
    // Driven by Wishbone Write
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_count <= 4'd0;
            tx_fifo_full <= 1'b0;
            tx_fifo_empty <= 1'b1;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0] == 1'b1) begin
                if (tx_fifo_full) begin
                    // FIFO full, ignore write
                end else begin
                    tx_fifo_count <= tx_fifo_count + 1'b1;
                    tx_fifo_mem[tx_fifo_count - 1'b1] <= wb_dat_i;
                    tx_fifo_empty <= 1'b0;
                end
            end else if (tx_fifo_count == 0) begin
                tx_fifo_empty <= 1'b1;
            end
        end
    end
    
    // TX Shift Register
    always @(posedge rx_clk_pulse or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_shift_reg <= 8'b0;
            tx_shift_reg_valid <= 1'b0;
            tx_shift_reg_empty <= 1'b1;
        end else begin
            if (tx_fifo_empty && tx_shift_reg_valid) begin
                // Shift out
                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                tx_shift_reg_valid <= 1'b0;
                tx_shift_reg_empty <= 1'b1;
            end else if (tx_fifo_empty && !tx_shift_reg_valid) begin
                // Load from FIFO
                if (tx_fifo_count > 0) begin
                    tx_shift_reg <= tx_fifo_mem[tx_fifo_count - 1'b1];
                    tx_shift_reg_valid <= 1'b1;
                    tx_shift_reg_empty <= 1'b0;
                end else begin
                    tx_shift_reg <= 8'b0;
                    tx_shift_reg_valid <= 1'b0;
                    tx_shift_reg_empty <= 1'b1;
                end
            end else begin
                // Shift in
                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                tx_shift_reg_valid <= 1'b1;
                tx_shift_reg_empty <= 1'b0;
            end
        end
    end
    
    // TX FIFO Read Enable (for shifting)
    // We need to enable shifting when the FIFO is not empty and the shift register is valid.
    // Actually, the shift register logic above handles the loading and shifting.
    // We need to ensure the shift register is loaded when the FIFO is not empty.
    // The logic above: if (tx_fifo_empty && !tx_shift_reg_valid) -> Load.
    // But if tx_fifo_empty is 0, we don't load.
    // We need to load when tx_fifo_count > 0 and tx_shift_reg_valid == 0.
    
    // Corrected TX Shift Register Logic
    always @(posedge rx_clk_pulse or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_shift_reg <= 8'b0;
            tx_shift_reg_valid <= 1'b0;
            tx_shift_reg_empty <= 1'b1;
        end else begin
            if (tx_shift_reg_valid) begin
                // Shift out
                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                tx_shift_reg_valid <= 1'b0;
                tx_shift_reg_empty <= 1'b1;
            end else begin
                // Check if we need to load
                if (tx_fifo_count > 0) begin
                    tx_shift_reg <= tx_fifo_mem[tx_fifo_count - 1'b1];
                    tx_shift_reg_valid <= 1'b1;
                    tx_shift_reg_empty <= 1'b0;
                end else begin
                    tx_shift_reg <= 8'b0;
                    tx_shift_reg_valid <= 1'b0;
                    tx_shift_reg_empty <= 1'b1;
                end
            end
        end
    end
    
    // -----------------------------------------------------------------------
    // Register Logic
    // -----------------------------------------------------------------------
    
    // IER (Interrupt Enable Register)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            reg_ier <= 8'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0] == 1'b1 && wb_adr_i == 32'h00) begin
                reg_ier <= wb_dat_i;
            end
        end
    end
    
    // IIR (Interrupt Identification Register)
    // Read-only
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_dat_o_reg <= 8'b0;
            wb_ack_o_reg <= 1'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_read && wb_sel_i[0] == 1'b1 && wb_adr_i == 32'h01) begin
                wb_dat_o_reg <= reg_iir;
                wb_ack_o_reg <= 1'b1;
            end else begin
                wb_ack_o_reg <= 1'b0;
            end
        end
    end
    
    // FCR (FIFO Control Register)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            reg_fcr <= 8'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0] == 1'b1 && wb_adr_i == 32'h02) begin
                reg_fcr <= wb_dat_i;
            end
        end
    end
    
    // LCR (Line Control Register)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            reg_lcr <= 8'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0] == 1'b1 && wb_adr_i == 32'h03) begin
                reg_lcr <= wb_dat_i;
            end
        end
    end
    
    // MCR (Modem Control Register)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            reg_mcr <= 8'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0] == 1'b1 && wb_adr_i == 32'h04) begin
                reg_mcr <= wb_dat_i;
            end
        end
    end
    
    // LSR (Line Status Register)
    // Read-only
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_dat_o_reg <= 8'b0;
            wb_ack_o_reg <= 1'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_read && wb_sel_i[0] == 1'b1 && wb_adr_i == 32'h05) begin
                wb_dat_o_reg <= reg_lsr;
                wb_ack_o_reg <= 1'b1;
            end else begin
                wb_ack_o_reg <= 1'b0;
            end
        end
    end
    
    // MSR (Modem Status Register)
    // Read-only
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_dat_o_reg <= 8'b0;
            wb_ack_o_reg <= 1'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_read && wb_sel_i[0] == 1'b1 && wb_adr_i == 32'h06) begin
                wb_dat_o_reg <= reg_msr;
                wb_ack_o_reg <= 1'b1;
            end else begin
                wb_ack_o_reg <= 1'b0;
            end
        end
    end
    
    // SCR (Scratch Register)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            reg_scr <= 8'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0] == 1'b1 && wb_adr_i == 32'h07) begin
                reg_scr <= wb_dat_i;
            end
        end
    end
    
    // DLL (Divisor Latch Low)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            reg_dll <= 8'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0] == 1'b1 && wb_adr_i == 32'h08) begin
                reg_dll <= wb_dat_i;
            end
        end
    end
    
    // DLM (Divisor Latch High)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            reg_dlm <= 8'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0] == 1'b1 && wb_adr_i == 32'h09) begin
                reg_dlm <= wb_dat_i;
            end
        end
    end
    
    // ISR (Interrupt Status Register)
    // Read-only
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_dat_o_reg <= 8'b0;
            wb_ack_o_reg <= 1'b0;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_read && wb_sel_i[0] == 1'b1 && wb_adr_i == 32'h0A) begin
                wb_dat_o_reg <= reg_isr;
                wb_ack_o_reg <= 1'b1;
            end else begin
                wb_ack_o_reg <= 1'b0;
            end
        end
    end
    
    // -----------------------------------------------------------------------
    // Interrupt Logic Implementation
    // -----------------------------------------------------------------------
    // Interrupts are generated based on IER and status.
    // We will generate an interrupt if any enabled interrupt occurs.
    
    // RX FIFO Full Interrupt (if enabled)
    // TX FIFO Empty Interrupt (if enabled)
    // RX Overrun (if enabled)
    // TX Holding Register Empty (if enabled)
    // Modem Status Changes (if enabled)
    
    // For simplicity, we will generate an interrupt if:
    // 1. RX FIFO is not empty and RX FIFO Full Interrupt is enabled.
    // 2. TX FIFO is empty and TX FIFO Empty Interrupt is enabled.
    // 3. Modem status changes (CTS, DSR, RI, DCD) and Modem Status Interrupt is enabled.
    
    // Note: In a real 16550, the IIR register indicates the type of interrupt.
    // We will update reg_iir based on the interrupt status.
    
    // Interrupt Status
    reg int_rx_fifo_full;
    reg int_tx_fifo_empty;
    reg int_modem_status;
    reg int_rx_overrun;
    reg int_tx_holding_empty;
    
    // Update Interrupt Status
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            int_rx_fifo_full <= 1'b0;
            int_tx_fifo_empty <= 1'b0;
            int_modem_status <= 1'b0;
            int_rx_overrun <= 1'b0;
            int_tx_holding_empty <= 1'b0;
            reg_iir <= 8'b0x01; // Default: No interrupts pending
        end else begin
            // RX FIFO Full
            if (rx_fifo_count == FIFO_DEPTH) begin
                int_rx_fifo_full <= 1'b1;
            end else begin
                int_rx_fifo_full <= 1'b0;
            end
            
            // TX FIFO Empty
            if (tx_fifo_count == 0) begin
                int_tx_fifo_empty <= 1'b1;
            end else begin
                int_tx_fifo_empty <= 1'b0;
            end
            
            // Modem Status Changes
            // We will check if any modem pin changed since the last read.
            // For simplicity, we will assume the modem status interrupt is enabled if bit 2 of IER is set.
            // We will update the MSR register and generate an interrupt if any pin changes.
            // This is a simplified implementation.
            // In a real implementation, we would store the previous MSR value and compare.
            // Here, we will just generate an interrupt if any modem pin is active.
            if (cts_pad_i || dsr_pad_i || ri_pad_i || dcd_pad_i) begin
                int_modem_status <= 1'b1;
            end else begin
                int_modem_status <= 1'b0;
            end
            
            // RX Overrun
            // If a byte is received while the shift register is busy (not empty) and the FIFO is full.
            // This is a simplified check.
            if (rx_shift_reg_valid && rx_fifo_full) begin
                int_rx_overrun <= 1'b1;
            end else begin
                int_rx_overrun <= 1'b0;
            end
            
            // TX Holding Register Empty
            // If the shift register is empty and the FIFO is not empty.
            if (tx_shift_reg_valid == 1'b0 && tx_fifo_count > 0) begin
                int_tx_holding_empty <= 1'b1;
            end else begin
                int_tx_holding_empty <= 1'b0;
            end
            
            // Update IIR
            // IIR[7:6] = 00: No interrupts pending
            // IIR[7:6] = 01: Interrupt pending (type depends on IIR[5:0])
            // IIR[7:6] = 10: Reserved
            // IIR[7:6] = 11: Interrupt pending (type depends on IIR[5:0])
            
            // We will use a simple priority encoder for the interrupt type.
            // 0: RX FIFO Full
            // 1: TX FIFO Empty
            // 2: Modem Status
            // 3: RX Overrun
            // 4: TX Holding Register Empty
            
            reg [3:0] int_type;
            reg int_pending;
            
            int_pending = int_rx_fifo_full | int_tx_fifo_empty | int_modem_status | int_rx_overrun | int_tx_holding_empty;
            
            if (!int_pending) begin
                reg_iir <= 8'b0x01; // No interrupts
            end else begin
                if (int_rx_fifo_full) begin
                    reg_iir <= 8'b0x06; // RX FIFO Full
                end else if (int_tx_fifo_empty) begin
                    reg_iir <= 8'b0x0E; // TX FIFO Empty
                end else if (int_modem_status) begin
                    reg_iir <= 8'b0x02; // Modem Status
                end else if (int_rx_overrun) begin
                    reg_iir <= 8'b0x04; // RX Overrun
                end else if (int_tx_holding_empty) begin
                    reg_iir <= 8'b0x0A; // TX Holding Register Empty
                end
            end
        end
    end
    
    // Generate Interrupt Signal
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            int_signal <= 1'b0;
        end else begin
            // Check if any enabled interrupt is pending
            if (reg_ier[0] && int_rx_fifo_full) begin
                int_signal <= 1'b1;
            end else if (reg_ier[1] && int_tx_fifo_empty) begin
                int_signal <= 1'b1;
            end else if (reg_ier[2] && int_modem_status) begin
                int_signal <= 1'b1;
            end else if (reg_ier[3] && int_rx_overrun) begin
                int_signal <= 1'b1;
            end else if (reg_ier[4] && int_tx_holding_empty) begin
                int_signal <= 1'b1;
            end else begin
                int_signal <= 1'b0;
            end
        end
    end
    
    // -----------------------------------------------------------------------
    // Baud Rate Update Logic
    // -----------------------------------------------------------------------
    // When LCR bit 7 is 1, the DLL and DLM registers are used to set the baud rate.
    // We will update the baud_divisor_val when DLL or DLM is written.
    // This is a simplified implementation. In a real 16550, the baud rate is set by writing DLM first, then DLL.
    // We will update the baud_divisor_val whenever DLL or DLM is written.
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            baud_divisor_val <= 16'd0;
        end else begin
            if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0] == 1'b1 && wb_adr_i == 32'h08) begin
                // DLL written
                baud_divisor_val[7:0] <= wb_dat_i;
            end else if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i[0] == 1'b1 && wb_adr_i == 32'h09) begin
                // DLM written
                baud_divisor_val[15:8] <= wb_dat_i;
            end
        end
    end
    
    // -----------------------------------------------------------------------
    // Modem Pin Logic
    // -----------------------------------------------------------------------
    // STX: Output, driven by TX FIFO empty (or software control)
    // RTS: Output, driven by MCR bit 6 (RTS)
    // DTR: Output, driven by MCR bit 5 (DTR)
    // CTS, DSR, RI, DCD: Inputs, used to generate interrupts
    
    // We will also implement a simple handshake for STX.
    // STX is active when the TX FIFO is empty.
    
    // -----------------------------------------------------------------------
    // End of Module
    // -----------------------------------------------------------------------
    
endmodule
```<|im_end|>
