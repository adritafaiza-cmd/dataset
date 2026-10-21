```verilog
module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // --------------------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------------------
    parameter WB_ADDR_WIDTH = 16;
    parameter WB_DATA_WIDTH  = 32;
    parameter BAUD_RATE      = 9600;
    parameter SYS_CLK_FREQ   = 50_000_000; // 50 MHz assumed for calculation
    parameter BAUD_COUNTER_MAX = (SYS_CLK_FREQ / BAUD_RATE) - 1;
    parameter FIFO_DEPTH      = 16;

    // --------------------------------------------------------------------------
    // Internal Clocks and Resets
    // --------------------------------------------------------------------------
    // We generate a baud clock from the system clock.
    // To ensure CDC safety, we use a synchronous counter driven by wb_clk_i.
    // The baud clock is only used internally for the shift register logic.
    // We do not expose the baud clock to the outside world to avoid CDC issues.
    // Instead, we use a synchronous baud counter state machine.
    
    reg [31:0] baud_counter;
    reg        baud_tick;
    reg        baud_enable;
    
    // Modem status registers (input side)
    reg [3:0] modem_status_reg; // CTS, DSR, RI, DCD
    reg        modem_status_valid;
    
    // --------------------------------------------------------------------------
    // Wishbone Slave Interface
    // --------------------------------------------------------------------------
    // Register Map (16-bit address space):
    // 0x00: Control Register (Write)
    // 0x04: Status Register (Read)
    // 0x08: Line Control Register (Write)
    // 0x0C: Modem Control Register (Write)
    // 0x10: Interrupt Enable Register (Write)
    // 0x14: Interrupt Identification Register (Read)
    // 0x18: FIFO Control Register (Write)
    // 0x1C: FIFO Status Register (Read)
    // 0x20: IER (Interrupt Enable) - Alias for 0x10
    // 0x24: ISR (Interrupt Status) - Alias for 0x14
    // 0x28: LCR (Line Control) - Alias for 0x08
    // 0x2C: MCR (Modem Control) - Alias for 0x0C
    // 0x30: DLL (Divisor Latch Low) - Write only when DL=1
    // 0x34: DLM (Divisor Latch High) - Write only when DL=1
    // 0x38: IER (Interrupt Enable) - Alias for 0x10
    // 0x3C: ISR (Interrupt Status) - Alias for 0x14
    
    // We will implement a simplified but compliant register map:
    // 0x00: Control (Write) - Enable FIFO, Reset FIFO, Enable Interrupts
    // 0x04: Status (Read) - RX FIFO Full, TX FIFO Empty, Modem Status
    // 0x08: Line Control (Write) - Word length, Parity, Stop bits
    // 0x0C: Modem Control (Write) - RTS, DTR, Out1, Out2
    // 0x10: Interrupt Enable (Write) - Enable RX, TX, Modem
    // 0x14: Interrupt Status (Read) - RX, TX, Modem
    // 0x18: FIFO Control (Write) - Reset RX, Reset TX
    // 0x1C: FIFO Status (Read) - RX Full, TX Empty
    
    // --------------------------------------------------------------------------
    // Wishbone Decoder and Logic
    // --------------------------------------------------------------------------
    reg [WB_ADDR_WIDTH-1:0] addr_reg;
    reg [WB_DATA_WIDTH-1:0] data_in;
    reg [WB_DATA_WIDTH-1:0] data_out;
    reg                   we;
    reg                   stb;
    reg                   cyc;
    reg                   ack;
    reg                   sel;
    
    // Internal registers for Wishbone
    reg [31:0] reg_control;
    reg [31:0] reg_status;
    reg [31:0] reg_line_ctrl;
    reg [31:0] reg_modem_ctrl;
    reg [31:0] reg_int_enable;
    reg [31:0] reg_int_status;
    reg [31:0] reg_fifo_ctrl;
    reg [31:0] reg_fifo_status;
    
    // Baud Rate Divider State
    reg [31:0] baud_divider;
    reg        baud_tick_out;
    
    // Shift Register State
    reg [7:0]  shift_reg;
    reg        shift_reg_valid;
    reg        shift_reg_empty;
    reg        shift_reg_full;
    
    // FIFO State
    reg [FIFO_DEPTH-1:0] rx_fifo;
    reg [FIFO_DEPTH-1:0] tx_fifo;
    reg [FIFO_DEPTH-1:0] rx_fifo_ptr;
    reg [FIFO_DEPTH-1:0] tx_fifo_ptr;
    reg                rx_fifo_full;
    reg                tx_fifo_empty;
    reg                rx_fifo_empty;
    reg                tx_fifo_full;
    
    // Interrupt State
    reg                int_rx;
    reg                int_tx;
    reg                int_modem;
    reg                int_pending;
    reg                int_mask_rx;
    reg                int_mask_tx;
    reg                int_mask_modem;
    
    // Modem Pins
    reg                rts_out;
    reg                dtr_out;
    reg                stx_out;
    
    // --------------------------------------------------------------------------
    // Wishbone Logic
    // --------------------------------------------------------------------------
    assign wb_ack_o = ack;
    assign wb_dat_o = data_out;
    assign wb_sel_i = sel;
    assign wb_we_i = we;
    assign wb_stb_i = stb;
    assign wb_cyc_i = cyc;
    assign wb_adr_i = addr_reg;
    assign wb_dat_i = data_in;
    
    // Address Decoding
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            addr_reg <= 0;
        end else begin
            addr_reg <= wb_adr_i;
        end
    end
    
    // Wishbone Read/Write Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ack <= 0;
            data_out <= 0;
            we <= 0;
            stb <= 0;
            cyc <= 0;
            sel <= 0;
        end else begin
            // Wishbone protocol: stb and cyc are asserted together for a cycle
            // We assume the master drives stb and cyc correctly.
            // For simplicity in this model, we assume stb is the main enable.
            // In a real implementation, we would check cyc and stb.
            
            if (wb_stb_i && wb_cyc_i) begin
                we <= wb_we_i;
                stb <= 1;
                cyc <= 1;
                sel <= 1;
            end else begin
                ack <= 0;
                stb <= 0;
                cyc <= 0;
                sel <= 0;
            end
        end
    end
    
    // Read Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            data_out <= 0;
            ack <= 0;
        end else if (wb_stb_i && wb_cyc_i && !we) begin
            case (addr_reg[15:0])
                16'h00: data_out <= {16'd0, reg_control[15:0]}; // Control (Write only, but read returns 0 or last value)
                16'h04: data_out <= {16'd0, reg_status[15:0]};
                16'h08: data_out <= {16'd0, reg_line_ctrl[15:0]};
                16'h0C: data_out <= {16'd0, reg_modem_ctrl[15:0]};
                16'h10: data_out <= {16'd0, reg_int_enable[15:0]};
                16'h14: data_out <= {16'd0, reg_int_status[15:0]};
                16'h18: data_out <= {16'd0, reg_fifo_ctrl[15:0]};
                16'h1C: data_out <= {16'd0, reg_fifo_status[15:0]};
                16'h20: data_out <= {16'd0, reg_int_enable[15:0]}; // Alias
                16'h24: data_out <= {16'd0, reg_int_status[15:0]}; // Alias
                16'h28: data_out <= {16'd0, reg_int_enable[15:0]}; // Alias
                16'h2C: data_out <= {16'd0, reg_int_status[15:0]}; // Alias
                16'h30: data_out <= {16'd0, 16'd0}; // DLL (Write only)
                16'h34: data_out <= {16'd0, 16'd0}; // DLM (Write only)
                16'h38: data_out <= {16'd0, reg_int_enable[15:0]}; // Alias
                16'h3C: data_out <= {16'd0, reg_int_status[15:0]}; // Alias
                default: data_out <= 0;
            endcase
            ack <= 1;
        end
    end
    
    // Write Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            // Default values
            reg_control <= 0;
            reg_line_ctrl <= 0;
            reg_modem_ctrl <= 0;
            reg_int_enable <= 0;
            reg_fifo_ctrl <= 0;
            rx_fifo <= 0;
            tx_fifo <= 0;
            rx_fifo_ptr <= 0;
            tx_fifo_ptr <= 0;
            shift_reg <= 0;
            shift_reg_valid <= 0;
            shift_reg_empty <= 1;
            shift_reg_full <= 0;
            int_rx <= 0;
            int_tx <= 0;
            int_modem <= 0;
            int_pending <= 0;
            int_mask_rx <= 0;
            int_mask_tx <= 0;
            int_mask_modem <= 0;
            rts_out <= 1;
            dtr_out <= 1;
            stx_out <= 0;
            baud_divider <= 0;
            baud_tick_out <= 0;
            modem_status_reg <= 0;
            modem_status_valid <= 0;
        end else if (wb_stb_i && wb_cyc_i && we) begin
            case (addr_reg[15:0])
                16'h00: reg_control <= data_in[15:0];
                16'h08: reg_line_ctrl <= data_in[15:0];
                16'h0C: reg_modem_ctrl <= data_in[15:0];
                16'h10: reg_int_enable <= data_in[15:0];
                16'h18: reg_fifo_ctrl <= data_in[15:0];
                16'h30: if (reg_line_ctrl[0]) begin // DL=1
                    baud_divider[7:0] <= data_in[7:0];
                end
                16'h34: if (reg_line_ctrl[0]) begin // DL=1
                    baud_divider[15:8] <= data_in[15:8];
                end
                default: ;
            endcase
        end
    end
    
    // --------------------------------------------------------------------------
    // Baud Rate Generator (Synchronous)
    // --------------------------------------------------------------------------
    // Calculate divisor: SYS_CLK / BAUD_RATE
    // For 50MHz / 9600 = 5208.33 -> 5208
    // We use a simple counter.
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            baud_divider <= 0;
            baud_tick_out <= 0;
        end else begin
            if (baud_divider == BAUD_COUNTER_MAX) begin
                baud_divider <= 0;
                baud_tick_out <= 1;
            end else begin
                baud_divider <= baud_divider + 1;
                baud_tick_out <= 0;
            end
        end
    end
    
    // --------------------------------------------------------------------------
    // FIFO Logic
    // --------------------------------------------------------------------------
    // RX FIFO
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_fifo <= {FIFO_DEPTH{1'b0}};
            rx_fifo_ptr <= 0;
            rx_fifo_full <= 0;
            rx_fifo_empty <= 1;
        end else begin
            if (rx_fifo_ptr == FIFO_DEPTH-1) begin
                rx_fifo_full <= 1;
            end else begin
                rx_fifo_full <= 0;
            end
            if (rx_fifo_ptr == 0) begin
                rx_fifo_empty <= 1;
            end else begin
                rx_fifo_empty <= 0;
            end
        end
    end
    
    // TX FIFO
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo <= {FIFO_DEPTH{1'b0}};
            tx_fifo_ptr <= 0;
            tx_fifo_empty <= 1;
            tx_fifo_full <= 0;
        end else begin
            if (tx_fifo_ptr == 0) begin
                tx_fifo_empty <= 1;
            end else begin
                tx_fifo_empty <= 0;
            end
            if (tx_fifo_ptr == FIFO_DEPTH-1) begin
                tx_fifo_full <= 1;
            end else begin
                tx_fifo_full <= 0;
            end
        end
    end
    
    // RX FIFO Write Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_fifo_ptr <= 0;
        end else if (rx_fifo_ptr == FIFO_DEPTH-1) begin
            // FIFO Full, ignore write
        end else begin
            rx_fifo[rx_fifo_ptr] <= shift_reg;
            rx_fifo_ptr <= rx_fifo_ptr + 1;
        end
    end
    
    // TX FIFO Write Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_ptr <= 0;
        end else if (tx_fifo_ptr == FIFO_DEPTH-1) begin
            // FIFO Full, ignore write
        end else begin
            tx_fifo[tx_fifo_ptr] <= shift_reg;
            tx_fifo_ptr <= tx_fifo_ptr + 1;
        end
    end
    
    // RX FIFO Read Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_fifo_ptr <= 0;
        end else if (rx_fifo_ptr == 0 && !rx_fifo_empty) begin
            rx_fifo_ptr <= FIFO_DEPTH-1;
        end else if (rx_fifo_ptr == 0) begin
            // FIFO Empty, do nothing
        end else begin
            rx_fifo_ptr <= rx_fifo_ptr - 1;
        end
    end
    
    // TX FIFO Read Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            tx_fifo_ptr <= 0;
        end else if (tx_fifo_ptr == 0 && !tx_fifo_empty) begin
            tx_fifo_ptr <= FIFO_DEPTH-1;
        end else if (tx_fifo_ptr == 0) begin
            // FIFO Empty, do nothing
        end else begin
            tx_fifo_ptr <= tx_fifo_ptr - 1;
        end
    end
    
    // --------------------------------------------------------------------------
    // Shift Register Logic
    // --------------------------------------------------------------------------
    // 8-bit shift register with start bit, data bits, stop bit.
    // We assume 8-N-1 (8 data bits, no parity, 1 stop bit) as default.
    // Parity and stop bits can be configured via Line Control Register.
    
    reg [7:0] parity_calc;
    reg       parity_enable;
    reg       stop_bits;
    reg       word_length;
    
    // Line Control Register bits
    // Bit 0: DL (Divisor Latch) - handled separately
    // Bit 1: Break
    // Bit 2: Parity Enable
    // Bit 3: Parity Type (0=Even, 1=Odd)
    // Bit 4: Stop Bits (0=1, 1=2)
    // Bits 7-5: Word Length (000=5, 001=6, 010=7, 011=8, 1xx=9)
    
    assign parity_enable = reg_line_ctrl[2];
    assign parity_type = reg_line_ctrl[3];
    assign stop_bits = reg_line_ctrl[4];
    assign word_length = reg_line_ctrl[5:3];
    
    // Parity Calculation
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            parity_calc <= 0;
        end else begin
            if (parity_enable) begin
                parity_calc <= parity_calc ^ shift_reg;
            end else begin
                parity_calc <= 0;
            end
        end
    end
    
    // Shift Register State Machine
    // States: IDLE, START, DATA, PARITY, STOP
    // We use a synchronous counter for the shift register clock.
    
    reg [2:0] shift_state; // 0:IDLE, 1:START, 2:DATA, 3:PARITY, 4:STOP
    reg       shift_clk;
    reg       shift_enable;
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            shift_state <= 0;
            shift_clk <= 0;
            shift_enable <= 0;
        end else begin
            // Shift clock generation
            if (shift_state == 1) begin // START
                shift_clk <= 1;
            end else if (shift_state == 2) begin // DATA
                shift_clk <= 1;
            end else if (shift_state == 3) begin // PARITY
                shift_clk <= 1;
            end else if (shift_state == 4) begin // STOP
                shift_clk <= 1;
            end else begin
                shift_clk <= 0;
            end
        end
    end
    
    // Shift Register Data
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            shift_reg <= 0;
            shift_reg_valid <= 0;
            shift_reg_empty <= 1;
            shift_reg_full <= 0;
        end else begin
            if (shift_state == 1) begin // START
                shift_reg <= 0; // Start bit is 0
            end else if (shift_state == 2) begin // DATA
                shift_reg <= {shift_reg[6:0], shift_reg[7]}; // Shift left
            end else if (shift_state == 3) begin // PARITY
                shift_reg <= {shift_reg[6:0], parity_calc};
            end else if (shift_state == 4) begin // STOP
                shift_reg <= {shift_reg[6:0], 1'b1}; // Stop bit is 1
            end else begin
                // IDLE
                shift_reg <= 0;
            end
        end
    end
    
    // Shift State Machine
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            shift_state <= 0;
        end else begin
            if (shift_state == 0) begin // IDLE
                if (shift_enable) begin
                    shift_state <= 1; // START
                end
            end else if (shift_state == 1) begin // START
                shift_state <= 2; // DATA
            end else if (shift_state == 2) begin // DATA
                if (word_length == 4) begin // 5 bits
                    shift_state <= 3; // PARITY
                end else if (word_length == 5) begin // 6 bits
                    shift_state <= 3; // PARITY
                end else if (word_length == 6) begin // 7 bits
                    shift_state <= 3; // PARITY
                end else if (word_length == 7) begin // 8 bits
                    shift_state <= 3; // PARITY
                end else if (word_length == 8) begin // 9 bits
                    shift_state <= 4; // STOP
                end else begin
                    shift_state <= 4; // STOP
                end
            end else if (shift_state == 3) begin // PARITY
                if (stop_bits == 0) begin // 1 stop bit
                    shift_state <= 4; // STOP
                end else begin // 2 stop bits
                    shift_state <= 4; // STOP
                end
            end else if (shift_state == 4) begin // STOP
                shift_state <= 0; // IDLE
            end
        end
    end
    
    // Shift Enable Logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            shift_enable <= 0;
        end else begin
            // Shift enable if TX FIFO is not empty and shift register is empty
            if (!tx_fifo_empty && shift_reg_empty) begin
                shift_enable <= 1;
            end else begin
                shift_enable <= 0;
            end
        end
    end
    
    // Shift Register Valid
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            shift_reg_valid <= 0;
        end else begin
            if (shift_state == 4) begin // STOP
                shift_reg_valid <= 1;
            end else begin
                shift_reg_valid <= 0;
            end
        end
    end
    
    // --------------------------------------------------------------------------
    // Modem Pins Logic
    // --------------------------------------------------------------------------
    // RTS (Request to Send)
    // DTR (Data Terminal Ready)
    // STX (Start to Xmit)
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rts_out <= 1;
            dtr_out <= 1;
            stx_out <= 0;
        end else begin
            // RTS: Asserted when TX FIFO is not empty or shift register is not empty
            if (tx_fifo_empty && shift_reg_empty) begin
                rts_out <= 0;
            end else begin
                rts_out <= 1;
            end
            
            // DTR: Asserted when device is ready (always 1 in this simple model)
            dtr_out <= 1;
            
            // STX: Asserted when shift register is ready to send (start bit)
            if (shift_state == 1) begin
                stx_out <= 1;
            end else begin
                stx_out <= 0;
            end
        end
    end
    
    // --------------------------------------------------------------------------
    // Interrupt Logic
    // --------------------------------------------------------------------------
    // Interrupt Enable Register (IER)
    // Bit 0: Enable RX Interrupt
    // Bit 1: Enable TX Interrupt
    // Bit 2: Enable Modem Interrupt
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            int_mask_rx <= 0;
            int_mask_tx <= 0;
            int_mask_modem <= 0;
        end else begin
            int_mask_rx <= reg_int_enable[0];
            int_mask_tx <= reg_int_enable[1];
            int_mask_modem <= reg_int_enable[2];
        end
    end
    
    // Interrupt Status Register (ISR)
    // Bit 0: RX Interrupt
    // Bit 1: TX Interrupt
    // Bit 2: Modem Interrupt
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            int_rx <= 0;
            int_tx <= 0;
            int_modem <= 0;
            int_pending <= 0;
        end else begin
            // RX Interrupt
            if (rx_fifo_full && int_mask_rx) begin
                int_rx <= 1;
            end else begin
                int_rx <= 0;
            end
            
            // TX Interrupt
            if (tx_fifo_empty && shift_reg_empty && int_mask_tx) begin
                int_tx <= 1;
            end else begin
                int_tx <= 0;
            end
            
            // Modem Interrupt
            if (modem_status_valid && int_mask_modem) begin
                int_modem <= 1;
            end else begin
                int_modem <= 0;
            end
            
            // Pending Interrupt
            if (int_rx || int_tx || int_modem) begin
                int_pending <= 1;
            end else begin
                int_pending <= 0;
            end
        end
    end
    
    // --------------------------------------------------------------------------
    // Modem Status Logic
    // --------------------------------------------------------------------------
    // CTS (Clear to Send)
    // DSR (Data Set Ready)
    // RI (Ring Indicator)
    // DCD (Data Carrier Detect)
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            modem_status_reg <= 0;
            modem_status_valid <= 0;
        end else begin
            // CTS: Asserted when RTS is asserted (simple loopback)
            if (rts_out) begin
                modem_status_reg[0] <= 1; // CTS
            end else begin
                modem_status_reg[0] <= 0;
            end
            
            // DSR: Always 1
            modem_status_reg[1] <= 1; // DSR
            
            // RI: Always 0
            modem_status_reg[2] <= 0; // RI
            
            // DCD: Always 0
            modem_status_reg[3] <= 0; // DCD
            
            modem_status_valid <= 1;
        end
    end
    
    // --------------------------------------------------------------------------
    // Output Ports
    // --------------------------------------------------------------------------
    assign int_o = int_pending;
    assign stx_pad_o = stx_out;
    assign rts_pad_o = rts_out;
    assign dtr_pad_o = dtr_out;
    assign srx_pad_i = shift_reg_valid; // Output the received byte when valid
    
    // --------------------------------------------------------------------------
    // End of Module
    // --------------------------------------------------------------------------
endmodule
```<|im_end|>
