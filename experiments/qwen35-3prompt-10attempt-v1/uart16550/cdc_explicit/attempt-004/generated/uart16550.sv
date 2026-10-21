```verilog
module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // --------------------------------------------------------------------------
    // Internal Parameters and Constants
    // --------------------------------------------------------------------------
    localparam WB_ADDR_WIDTH = 16;
    localparam WB_DATA_WIDTH = 32;
    localparam FIFO_DEPTH     = 16;
    localparam BAUD_DIVISOR   = 16; // 16x oversampling for baud generation

    // Register Map (Standard 16550 layout)
    localparam REG_IER      = 0x00; // Interrupt Enable Register
    localparam REG_IIR      = 0x01; // Interrupt Identification Register
    localparam REG_FCR      = 0x02; // FIFO Control Register
    localparam REG_LCR      = 0x03; // Line Control Register
    localparam REG_MCR      = 0x04; // Modem Control Register
    localparam REG_LSR      = 0x05; // Line Status Register
    localparam REG_MSR      = 0x06; // Modem Status Register
    localparam REG_SPDR     = 0x07; // Scratch Pad / Data Register
    localparam REG_IER_ADDR = 0x00;
    localparam REG_IIR_ADDR = 0x01;
    localparam REG_FCR_ADDR = 0x02;
    localparam REG_LCR_ADDR = 0x03;
    localparam REG_MCR_ADDR = 0x04;
    localparam REG_LSR_ADDR = 0x05;
    localparam REG_MSR_ADDR = 0x06;
    localparam REG_SPDR_ADDR = 0x07;

    // --------------------------------------------------------------------------
    // Internal Signals
    // --------------------------------------------------------------------------
    wire [WB_ADDR_WIDTH-1:0] wb_adr_i;
    wire [WB_DATA_WIDTH-1:0] wb_dat_i;
    reg [WB_DATA_WIDTH-1:0]  wb_dat_o;
    reg                     wb_ack_o;
    reg                     wb_we_i;
    reg                     wb_stb_i;
    reg                     wb_cyc_i;
    reg                     wb_sel_i;
    reg                     int_o;

    // Pad Signals
    wire srx_pad_i;
    wire cts_pad_i;
    wire dsr_pad_i;
    wire ri_pad_i;
    wire dcd_pad_i;
    reg  stx_pad_o;
    reg  rts_pad_o;
    reg  dtr_pad_o;

    // Internal Clocks and Resets
    wire wb_clk_i;
    wire wb_rst_i;
    wire clk_rx;
    wire clk_tx;
    wire rst_rx;
    wire rst_tx;
    wire rst_fifo;

    // State Registers (Dual Clock Domain Safe)
    reg [3:0] ier_reg;
    reg [3:0] iir_reg;
    reg [3:0] fcr_reg;
    reg [3:0] lcr_reg;
    reg [3:0] mcr_reg;
    reg [3:0] lsr_reg;
    reg [3:0] msr_reg;
    reg [7:0] spdr_reg;
    reg [7:0] spdr_out; // Output data for read

    // FIFO Signals
    reg [FIFO_DEPTH-1:0] fifo_rx_data;
    reg [FIFO_DEPTH-1:0] fifo_rx_ptr;
    reg [FIFO_DEPTH-1:0] fifo_rx_tail;
    reg [FIFO_DEPTH-1:0] fifo_tx_data;
    reg [FIFO_DEPTH-1:0] fifo_tx_ptr;
    reg [FIFO_DEPTH-1:0] fifo_tx_tail;
    reg                 fifo_rx_empty;
    reg                 fifo_tx_empty;
    reg                 fifo_rx_full;
    reg                 fifo_tx_full;

    // Baud Rate Generator
    reg [15:0] baud_div_cnt_rx;
    reg [15:0] baud_div_cnt_tx;
    reg         baud_rx_tick;
    reg         baud_tx_tick;

    // Status Flags
    reg         rx_data_ready;
    reg         tx_fifo_empty;
    reg         tx_fifo_full;
    reg         tx_fifo_not_empty;
    reg         tx_fifo_not_full;
    reg         rx_fifo_not_empty;
    reg         rx_fifo_not_full;

    // --------------------------------------------------------------------------
    // Clock and Reset Generation (CDC Safe)
    // --------------------------------------------------------------------------
    // Use a simple asynchronous clock divider with proper reset handling.
    // Reset is synchronized to the target clock domain before use.
    
    // RX Clock Domain
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            rst_rx <= 1'b1;
        else
            rst_rx <= 1'b0;
    end

    // TX Clock Domain
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            rst_tx <= 1'b1;
        else
            rst_tx <= 1'b0;
    end

    // FIFO Reset Domain (Same as WB for simplicity, but could be separate)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            rst_fifo <= 1'b1;
        else
            rst_fifo <= 1'b0;
    end

    // --------------------------------------------------------------------------
    // Baud Rate Generator (Asynchronous to WB)
    // --------------------------------------------------------------------------
    // RX Baud Gen
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            baud_div_cnt_rx <= 16'd0;
            baud_rx_tick    <= 1'b0;
        end else begin
            baud_div_cnt_rx <= baud_div_cnt_rx + 1'b1;
            if (baud_div_cnt_rx == BAUD_DIVISOR - 1) begin
                baud_div_cnt_rx <= 16'd0;
                baud_rx_tick    <= 1'b1;
            end
        end
    end

    // TX Baud Gen
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            baud_div_cnt_tx <= 16'd0;
            baud_tx_tick    <= 1'b0;
        end else begin
            baud_div_cnt_tx <= baud_div_cnt_tx + 1'b1;
            if (baud_div_cnt_tx == BAUD_DIVISOR - 1) begin
                baud_div_cnt_tx <= 16'd0;
                baud_tx_tick    <= 1'b1;
            end
        end
    end

    // --------------------------------------------------------------------------
    // FIFO Logic (Synchronous to WB)
    // --------------------------------------------------------------------------
    // RX FIFO Write
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            fifo_rx_ptr <= 16'd0;
            fifo_rx_tail <= 16'd0;
            fifo_rx_data <= {FIFO_DEPTH{1'b0}};
            fifo_rx_empty <= 1'b1;
            fifo_rx_full <= 1'b0;
        end else begin
            if (wb_stb_i && wb_cyc_i && wb_we_i && (wb_sel_i == 16'h02)) begin // FCR write
                // FCR write can affect FIFO enable, but for simplicity we assume
                // FIFO is always enabled unless explicitly disabled via FCR bit 0.
                // Here we just store the value.
                fifo_rx_data <= wb_dat_i[7:0]; // Assuming 8-bit data width for FIFO
                fifo_rx_ptr <= fifo_rx_ptr + 1'b1;
                
                if (fifo_rx_ptr == FIFO_DEPTH) begin
                    fifo_rx_ptr <= 16'd0;
                    fifo_rx_full <= 1'b1;
                end
            end
            // Note: In a real 16550, FCR bit 0 enables/disables FIFO. 
            // For this implementation, we assume FIFO is active if FCR[0] is set.
            // To keep it simple and robust, we will treat the FIFO as always active 
            // for the sake of the exercise, or we can add logic to check FCR[0].
            // Let's add the check for correctness.
            if (fcr_reg[0]) begin
                if (fifo_rx_ptr == FIFO_DEPTH) begin
                    fifo_rx_ptr <= 16'd0;
                    fifo_rx_full <= 1'b1;
                end
            end
        end
    end

    // RX FIFO Read (Triggered by TX FIFO not empty or direct read)
    // We need to handle the case where the FIFO is read by the TX logic.
    // The TX logic will pull from the RX FIFO if the TX FIFO is empty.
    
    // TX FIFO Write
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            fifo_tx_ptr <= 16'd0;
            fifo_tx_tail <= 16'd0;
            fifo_tx_data <= {FIFO_DEPTH{1'b0}};
            fifo_tx_empty <= 1'b1;
            fifo_tx_full <= 1'b0;
        end else begin
            if (wb_stb_i && wb_cyc_i && wb_we_i && (wb_sel_i == 16'h07)) begin // SPDR write
                fifo_tx_data <= wb_dat_i[7:0];
                fifo_tx_ptr <= fifo_tx_ptr + 1'b1;
                
                if (fifo_tx_ptr == FIFO_DEPTH) begin
                    fifo_tx_ptr <= 16'd0;
                    fifo_tx_full <= 1'b1;
                end
            end
            if (fcr_reg[0]) begin // FIFO enabled
                if (fifo_tx_ptr == FIFO_DEPTH) begin
                    fifo_tx_ptr <= 16'd0;
                    fifo_tx_full <= 1'b1;
                end
            end
        end
    end

    // TX FIFO Read (Triggered by TX shift register empty)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            fifo_tx_tail <= 16'd0;
            fifo_tx_empty <= 1'b1;
        end else begin
            if (fcr_reg[0]) begin // FIFO enabled
                if (fifo_tx_ptr == fifo_tx_tail) begin
                    fifo_tx_empty <= 1'b1;
                end else begin
                    fifo_tx_tail <= fifo_tx_tail + 1'b1;
                    fifo_tx_empty <= 1'b0;
                end
            end else begin
                // FIFO disabled, treat as empty if ptr != tail? 
                // Actually, if FIFO is disabled, it acts like a 1-deep buffer or direct path.
                // Standard 16550: If FIFO disabled, it's a 1-deep buffer.
                // We'll simplify: if FIFO disabled, we don't use the FIFO logic here,
                // and the TX logic will read directly from SPDR or a 1-deep buffer.
                // For this implementation, we will assume FIFO is always enabled for simplicity
                // unless FCR[0] is 0. If FCR[0] is 0, we skip FIFO logic.
                fifo_tx_empty <= 1'b1;
            end
        end
    end

    // RX FIFO Read (Triggered by RX shift register full)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            fifo_rx_tail <= 16'd0;
            fifo_rx_empty <= 1'b1;
        end else begin
            if (fcr_reg[0]) begin // FIFO enabled
                if (fifo_rx_ptr == fifo_rx_tail) begin
                    fifo_rx_empty <= 1'b1;
                end else begin
                    fifo_rx_tail <= fifo_rx_tail + 1'b1;
                    fifo_rx_empty <= 1'b0;
                end
            end else begin
                fifo_rx_empty <= 1'b1;
            end
        end
    end

    // --------------------------------------------------------------------------
    // Register File Logic (Synchronous to WB)
    // --------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ier_reg <= 4'b0000;
            iir_reg <= 4'b0001; // No interrupts
            fcr_reg <= 4'b0000;
            lcr_reg <= 4'b0000;
            mcr_reg <= 4'b0000;
            lsr_reg <= 4'b0000;
            msr_reg <= 4'b0000;
            spdr_reg <= 8'b00000000;
            spdr_out <= 8'b00000000;
            int_o <= 1'b0;
        end else if (wb_stb_i && wb_cyc_i && wb_we_i) begin
            case (wb_sel_i)
                REG_IER_ADDR: ier_reg <= wb_dat_i[7:4];
                REG_IIR_ADDR: iir_reg <= wb_dat_i[7:4];
                REG_FCR_ADDR: fcr_reg <= wb_dat_i[7:4];
                REG_LCR_ADDR: lcr_reg <= wb_dat_i[7:4];
                REG_MCR_ADDR: mcr_reg <= wb_dat_i[7:4];
                REG_SPDR_ADDR: spdr_reg <= wb_dat_i[7:0];
                default:      ;
            endcase
        end else if (wb_stb_i && wb_cyc_i && !wb_we_i) begin
            case (wb_sel_i)
                REG_IER_ADDR: wb_dat_o <= ier_reg;
                REG_IIR_ADDR: wb_dat_o <= iir_reg;
                REG_FCR_ADDR: wb_dat_o <= fcr_reg;
                REG_LCR_ADDR: wb_dat_o <= lcr_reg;
                REG_MCR_ADDR: wb_dat_o <= mcr_reg;
                REG_LSR_ADDR: wb_dat_o <= lsr_reg;
                REG_MSR_ADDR: wb_dat_o <= msr_reg;
                REG_SPDR_ADDR: wb_dat_o <= spdr_out;
                default:      wb_dat_o <= 32'b0;
            endcase
        end
    end

    // --------------------------------------------------------------------------
    // UART State Machine and Data Path
    // --------------------------------------------------------------------------
    // We need a state machine to handle start bit, data bits, parity, stop bit.
    // Since we are using a single clock domain for the UART logic (wb_clk_i),
    // we can implement the state machine directly here.
    
    reg [3:0] uart_state;
    reg [7:0] uart_data_in;
    reg [7:0] uart_data_out;
    reg [3:0] uart_bits_received;
    reg       uart_start_bit;
    reg       uart_stop_bit;
    reg       uart_parity_error;
    reg       uart_frame_error;
    reg       uart_rx_done;
    reg       uart_tx_done;
    reg       uart_tx_shift;
    reg       uart_rx_shift;
    reg       uart_tx_enable;
    reg       uart_rx_enable;
    reg       uart_rx_fifo_full;
    reg       uart_tx_fifo_empty;

    // Initial State
    initial begin
        uart_state = 4'b0000;
        uart_data_in = 8'b0;
        uart_data_out = 8'b0;
        uart_bits_received = 4'b0000;
        uart_start_bit = 1'b0;
        uart_stop_bit = 1'b0;
        uart_parity_error = 1'b0;
        uart_frame_error = 1'b0;
        uart_rx_done = 1'b0;
        uart_tx_done = 1'b0;
        uart_tx_shift = 1'b0;
        uart_rx_shift = 1'b0;
        uart_tx_enable = 1'b0;
        uart_rx_enable = 1'b0;
        uart_rx_fifo_full = 1'b0;
        uart_tx_fifo_empty = 1'b1;
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            uart_state <= 4'b0000;
            uart_data_in <= 8'b0;
            uart_data_out <= 8'b0;
            uart_bits_received <= 4'b0000;
            uart_start_bit <= 1'b0;
            uart_stop_bit <= 1'b0;
            uart_parity_error <= 1'b0;
            uart_frame_error <= 1'b0;
            uart_rx_done <= 1'b0;
            uart_tx_done <= 1'b0;
            uart_tx_shift <= 1'b0;
            uart_rx_shift <= 1'b0;
            uart_tx_enable <= 1'b0;
            uart_rx_enable <= 1'b0;
            uart_rx_fifo_full <= 1'b0;
            uart_tx_fifo_empty <= 1'b1;
        end else begin
            // Enable RX/TX based on configuration
            uart_rx_enable <= (lcr_reg[0] || lcr_reg[1]) && baud_rx_tick; // Simplified enable
            uart_tx_enable <= (lcr_reg[0] || lcr_reg[1]) && baud_tx_tick; // Simplified enable
            
            // Actually, let's use a more robust state machine
            // State 0: Idle
            // State 1: Start Bit
            // State 2-5: Data Bits
            // State 6: Parity Bit (if enabled)
            // State 7: Stop Bit
            // State 8: Idle (after stop bit)
            
            case (uart_state)
                4'b0000: // Idle
                    if (baud_rx_tick) begin
                        uart_state <= 4'b0001; // Start Bit
                        uart_data_in <= 8'b0;
                        uart_bits_received <= 4'b0000;
                        uart_parity_error <= 1'b0;
                        uart_frame_error <= 1'b0;
                    end
                    if (baud_tx_tick) begin
                        // Check if TX FIFO is empty
                        if (fifo_tx_empty) begin
                            uart_tx_done <= 1'b1;
                            uart_state <= 4'b0000;
                        end else begin
                            // Shift out data
                            uart_tx_shift <= 1'b1;
                            uart_state <= 4'b0001; // Start Bit
                            uart_data_out <= fifo_tx_data[7:0];
                            fifo_tx_data <= fifo_tx_data[15:8]; // Shift left
                            fifo_tx_ptr <= fifo_tx_ptr + 1'b1;
                            if (fifo_tx_ptr == FIFO_DEPTH) begin
                                fifo_tx_ptr <= 16'd0;
                                fifo_tx_full <= 1'b1;
                            end
                        end
                    end
                4'b0001: // Start Bit
                    if (baud_rx_tick) begin
                        uart_state <= 4'b0010; // Data Bit 0
                        uart_bits_received <= 4'b0001;
                    end
                    if (baud_tx_tick) begin
                        uart_tx_shift <= 1'b1;
                        uart_state <= 4'b0010; // Data Bit 0
                        uart_data_out <= uart_data_out[6:0] | {1'b0, uart_data_out[7]}; // Shift left
                    end
                4'b0010: // Data Bit 0
                    if (baud_rx_tick) begin
                        uart_data_in[0] <= srx_pad_i;
                        uart_state <= 4'b0011; // Data Bit 1
                        uart_bits_received <= 4'b0010;
                    end
                    if (baud_tx_tick) begin
                        uart_tx_shift <= 1'b1;
                        uart_state <= 4'b0011; // Data Bit 1
                        uart_data_out <= uart_data_out[6:0] | {1'b0, uart_data_out[7]};
                    end
                4'b0011: // Data Bit 1
                    if (baud_rx_tick) begin
                        uart_data_in[1] <= srx_pad_i;
                        uart_state <= 4'b0100; // Data Bit 2
                        uart_bits_received <= 4'b0011;
                    end
                    if (baud_tx_tick) begin
                        uart_tx_shift <= 1'b1;
                        uart_state <= 4'b0100; // Data Bit 2
                        uart_data_out <= uart_data_out[6:0] | {1'b0, uart_data_out[7]};
                    end
                4'b0100: // Data Bit 2
                    if (baud_rx_tick) begin
                        uart_data_in[2] <= srx_pad_i;
                        uart_state <= 4'b0101; // Data Bit 3
                        uart_bits_received <= 4'b0100;
                    end
                    if (baud_tx_tick) begin
                        uart_tx_shift <= 1'b1;
                        uart_state <= 4'b0101; // Data Bit 3
                        uart_data_out <= uart_data_out[6:0] | {1'b0, uart_data_out[7]};
                    end
                4'b0101: // Data Bit 3
                    if (baud_rx_tick) begin
                        uart_data_in[3] <= srx_pad_i;
                        uart_state <= 4'b0110; // Data Bit 4
                        uart_bits_received <= 4'b0101;
                    end
                    if (baud_tx_tick) begin
                        uart_tx_shift <= 1'b1;
                        uart_state <= 4'b0110; // Data Bit 4
                        uart_data_out <= uart_data_out[6:0] | {1'b0, uart_data_out[7]};
                    end
                4'b0110: // Data Bit 4
                    if (baud_rx_tick) begin
                        uart_data_in[4] <= srx_pad_i;
                        uart_state <= 4'b0111; // Data Bit 5
                        uart_bits_received <= 4'b0110;
                    end
                    if (baud_tx_tick) begin
                        uart_tx_shift <= 1'b1;
                        uart_state <= 4'b0111; // Data Bit 5
                        uart_data_out <= uart_data_out[6:0] | {1'b0, uart_data_out[7]};
                    end
                4'b0111: // Data Bit 5
                    if (baud_rx_tick) begin
                        uart_data_in[5] <= srx_pad_i;
                        uart_state <= 4'b1000; // Data Bit 6
                        uart_bits_received <= 4'b0111;
                    end
                    if (baud_tx_tick) begin
                        uart_tx_shift <= 1'b1;
                        uart_state <= 4'b1000; // Data Bit 6
                        uart_data_out <= uart_data_out[6:0] | {1'b0, uart_data_out[7]};
                    end
                4'b1000: // Data Bit 6
                    if (baud_rx_tick) begin
                        uart_data_in[6] <= srx_pad_i;
                        uart_state <= 4'b1001; // Data Bit 7
                        uart_bits_received <= 4'b1000;
                    end
                    if (baud_tx_tick) begin
                        uart_tx_shift <= 1'b1;
                        uart_state <= 4'b1001; // Data Bit 7
                        uart_data_out <= uart_data_out[6:0] | {1'b0, uart_data_out[7]};
                    end
                4'b1001: // Data Bit 7
                    if (baud_rx_tick) begin
                        uart_data_in[7] <= srx_pad_i;
                        uart_state <= 4'b1010; // Parity Bit (if enabled)
                        uart_bits_received <= 4'b1001;
                    end
                    if (baud_tx_tick) begin
                        uart_tx_shift <= 1'b1;
                        uart_state <= 4'b1010; // Parity Bit
                        uart_data_out <= uart_data_out[6:0] | {1'b0, uart_data_out[7]};
                    end
                4'b1010: // Parity Bit
                    if (baud_rx_tick) begin
                        // Calculate parity
                        if (lcr_reg[3]) begin // Parity Enable
                            if (~^uart_data_in[7:0] == srx_pad_i) begin
                                uart_parity_error <= 1'b1;
                            end
                        end
                        uart_state <= 4'b1011; // Stop Bit
                        uart_bits_received <= 4'b1010;
                    end
                    if (baud_tx_tick) begin
                        if (lcr_reg[3]) begin // Parity Enable
                            if (~^uart_data_out[7:0] == 1'b0) begin
                                uart_data_out[7] <= 1'b1;
                            end else begin
                                uart_data_out[7] <= 1'b0;
                            end
                        end
                        uart_tx_shift <= 1'b1;
                        uart_state <= 4'b1011; // Stop Bit
                    end
                4'b1011: // Stop Bit
                    if (baud_rx_tick) begin
                        if (srx_pad_i) begin
                            uart_state <= 4'b0000; // Idle
                            uart_rx_done <= 1'b1;
                            if (uart_parity_error) begin
                                uart_frame_error <= 1'b1;
                            end
                            // Move data to FIFO
                            if (!fifo_rx_full) begin
                                fifo_rx_data[fifo_rx_ptr] <= uart_data_in;
                                fifo_rx_ptr <= fifo_rx_ptr + 1'b1;
                                if (fifo_rx_ptr == FIFO_DEPTH) begin
                                    fifo_rx_ptr <= 16'd0;
                                    fifo_rx_full <= 1'b1;
                                end
                            end
                        end else begin
                            // Frame error
                            uart_frame_error <= 1'b1;
                            uart_state <= 4'b0000; // Idle
                        end
                    end
                    if (baud_tx_tick) begin
                        uart_tx_shift <= 1'b1;
                        uart_state <= 4'b0000; // Idle
                    end
                default:
                    uart_state <= 4'b0000;
            endcase
        end
    end

    // --------------------------------------------------------------------------
    // Interrupt Logic
    // --------------------------------------------------------------------------
    // Interrupts are generated based on the IER register and the status of the UART.
    // We need to debounce the interrupts slightly or use a flag to avoid multiple triggers.
    // For simplicity, we will generate an interrupt if the corresponding bit in IER is set
    // and the condition is met.
    
    reg int_rx;
    reg int_tx;
    reg int_modem;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            int_rx <= 1'b0;
            int_tx <= 1'b0;
            int_modem <= 1'b0;
            int_o <= 1'b0;
        end else begin
            // RX Interrupt
            if (ier_reg[0]) begin // RX Data Ready
                if (fifo_rx_not_empty) begin
                    int_rx <= 1'b1;
                end else begin
                    int_rx <= 1'b0;
                end
            end else begin
                int_rx <= 1'b0;
            end

            // TX Interrupt
            if (ier_reg[1]) begin // TX Holding Register Empty
                if (fifo_tx_empty) begin
                    int_tx <= 1'b1;
                end else begin
                    int_tx <= 1'b0;
                end
            end else begin
                int_tx <= 1'b0;
            end

            // Modem Interrupt
            if (ier_reg[2]) begin // Modem Status Change
                if (msr_reg != 4'b0000) begin // Simplified check
                    int_modem <= 1'b1;
                end else begin
                    int_modem <= 1'b0;
                end
            end else begin
                int_modem <= 1'b0;
            end

            // Combine interrupts
            int_o <= int_rx | int_tx | int_modem;
        end
    end

    // --------------------------------------------------------------------------
    // Modem Control Logic
    // --------------------------------------------------------------------------
    // RTS, DTR, CTS, DSR, RI, DCD
    // These are controlled by the MCR register and the MSR register.
    // For simplicity, we will assume the modem pins are controlled by the MCR register
    // and the MSR register reflects the status of the modem pins.
    
    // RTS Control
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rts_pad_o <= 1'b1;
        end else begin
            if (mcr_reg[0]) begin
                rts_pad_o <= 1'b0;
            end else begin
                rts_pad_o <= 1'b1;
            end
        end
    end

    // DTR Control
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            dtr_pad_o <= 1'b1;
        end else begin
            if (mcr_reg[1]) begin
                dtr_pad_o <= 1'b0;
            end else begin
                dtr_pad_o <= 1'b1;
            end
        end
    end

    // CTS, DSR, RI, DCD
    // These are inputs to the UART, but we need to reflect them in the MSR register.
    // For simplicity, we will assume the modem pins are controlled by the MCR register
    // and the MSR register reflects the status of the modem pins.
    // In a real implementation, these would be controlled by the modem circuit.
    // For this implementation, we will assume the modem pins are controlled by the MCR register
    // and the MSR register reflects the status of the modem pins.
    
    // MSR Register Update
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            msr_reg <= 4'b0000;
        end else begin
            // CTS
            if (cts_pad_i) begin
                msr_reg[0] <= 1'b1;
            end else begin
                msr_reg[0] <= 1'b0;
            end
            // DSR
            if (dsr_pad_i) begin
                msr_reg[1] <= 1'b1;
            end else begin
                msr_reg[1] <= 1'b0;
            end
            // RI
            if (ri_pad_i) begin
                msr_reg[2] <= 1'b1;
            end else begin
                msr_reg[2] <= 1'b0;
            end
            // DCD
            if (dcd_pad_i) begin
                msr_reg[3] <= 1'b1;
            end else begin
                msr_reg[3] <= 1'b0;
            end
        end
    end

    // --------------------------------------------------------------------------
    // Line Status Register Update
    // --------------------------------------------------------------------------
    // LSR Register Update
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            lsr_reg <= 4'b0000;
        end else begin
            // BI (Break Indicator)
            // PE (Parity Error)
            if (uart_parity_error) begin
                lsr_reg[1] <= 1'b1;
            end else begin
                lsr_reg[1] <= 1'b0;
            end
            // FE (Framing Error)
            if (uart_frame_error) begin
                lsr_reg[2] <= 1'b1;
            end else begin
                lsr_reg[2] <= 1'b0;
            end
            // TI (Transmitter Holding Register Empty)
            if (fifo_tx_empty) begin
                lsr_reg[3] <= 1'b1;
            end else begin
                lsr_reg[3] <= 1'b0;
            end
            // RE (Receiver Holding Register Full)
            if (fifo_rx_not_empty) begin
                lsr_reg[4] <= 1'b1;
            end else begin
                lsr_reg[4] <= 1'b0;
            end
            // THRE (Transmitter Holding Register Empty)
            if (fifo_tx_empty) begin
                lsr_reg[5] <= 1'b1;
            end else begin
                lsr_reg[5] <= 1'b0;
            end
            // MCE (Modem Control Error)
            lsr_reg[6] <= 1'b0;
            // OVR (Overrun Error)
            lsr_reg[7] <= 1'b0;
        end
    end

    // --------------------------------------------------------------------------
    // Output Assignments
    // --------------------------------------------------------------------------
    // stx_pad_o
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            stx_pad_o <= 1'b0;
        end else begin
            if (uart_tx_shift) begin
                stx_pad_o <= uart_data_out[0];
            end else begin
                stx_pad_o <= 1'b0;
            end
        end
    end

    // srx_pad_i is an input, so no assignment needed.

    // int_o is already assigned in the interrupt logic.

    // --------------------------------------------------------------------------
    // Wishbone Acknowledge
    // --------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_ack_o <= 1'b0;
        end else if (wb_stb_i && wb_cyc_i) begin
            wb_ack_o <= 1'b1;
        end
    end

    // --------------------------------------------------------------------------
    // FIFO Status Flags
    // --------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            fifo_rx_not_empty <= 1'b0;
            fifo_rx_not_full <= 1'b1;
            fifo_tx_not_empty <= 1'b0;
            fifo_tx_not_full <= 1'b1;
        end else begin
            if (fcr_reg[0]) begin // FIFO enabled
                if (fifo_rx_ptr != fifo_rx_tail) begin
                    fifo_rx_not_empty <= 1'b1;
                end else begin
                    fifo_rx_not_empty <= 1'b0;
                end
                if (fifo_rx_ptr != fifo_rx_tail + 1) begin
                    fifo_rx_not_full <= 1'b1;
                end else begin
                    fifo_rx_not_full <= 1'b0;
                end
                if (fifo_tx