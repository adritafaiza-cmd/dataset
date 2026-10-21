```verilog
module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_sel_i,
    wb_ack_o,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // --------------------------------------------------------------------------
    // Internal Signals
    // --------------------------------------------------------------------------
    reg [15:0] wb_dat_o_reg;
    reg wb_ack_o_reg;
    reg int_o_reg;
    reg stx_pad_o_reg;
    reg rts_pad_o_reg;
    reg dtr_pad_o_reg;
    
    // FIFO Signals
    reg [7:0] fifo_data [0:15];
    reg [3:0] fifo_count;
    reg fifo_full;
    reg fifo_empty;
    reg fifo_write_en;
    reg fifo_read_en;
    reg [3:0] fifo_ptr_wr;
    reg [3:0] fifo_ptr_rd;
    
    // Baud Rate Generator
    reg [15:0] baud_divider;
    reg [15:0] baud_counter;
    reg baud_overflow;
    reg [7:0] lsb_divider;
    reg [7:0] lsb_counter;
    reg baud_enable;
    
    // State Machine for FIFO Read
    reg [2:0] fsm_state; // 0: Idle, 1: Read, 2: Wait
    reg [7:0] fsm_data;
    
    // Modem Status Register (MSR) bits
    reg [3:0] modem_status; // RI, DSR, CTS, DCD
    
    // --------------------------------------------------------------------------
    // Parameters
    // --------------------------------------------------------------------------
    localparam WB_ADDR_FIFO_DATA = 16'h0000;
    localparam WB_ADDR_FIFO_STATUS = 16'h0004;
    localparam WB_ADDR_FIFO_CONTROL = 16'h0008;
    localparam WB_ADDR_BAUD_DIV = 16'h000C;
    localparam WB_ADDR_LSR = 16'h0010;
    localparam WB_ADDR_MSR = 16'h0014;
    localparam WB_ADDR_IER = 16'h0018;
    localparam WB_ADDR_FCR = 16'h001C;
    localparam WB_ADDR_LINE_CTL = 16'h0020;
    localparam WB_ADDR_MCR = 16'h0024;
    localparam WB_ADDR_SCRATCH = 16'h0028;
    
    // --------------------------------------------------------------------------
    // Baud Rate Generator Logic
    // --------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            baud_counter <= 16'd0;
            baud_overflow <= 1'b0;
            baud_enable <= 1'b0;
            lsb_counter <= 8'd0;
        end else begin
            if (baud_enable) begin
                baud_counter <= baud_counter + 1'b1;
                if (baud_counter >= baud_divider) begin
                    baud_counter <= 16'd0;
                    baud_overflow <= 1'b1;
                end
            end else begin
                baud_counter <= 16'd0;
                baud_overflow <= 1'b0;
            end
            
            // LSB Divider for finer granularity if needed (simplified here)
            lsb_counter <= lsb_counter + 1'b1;
            if (lsb_counter >= lsb_divider) begin
                lsb_counter <= 8'd0;
                // In a full implementation, this would trigger the shift register
            end
        end
    end

    // --------------------------------------------------------------------------
    // FIFO Logic
    // --------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            fifo_count <= 4'd0;
            fifo_ptr_wr <= 4'd0;
            fifo_ptr_rd <= 4'd0;
            fifo_full <= 1'b0;
            fifo_empty <= 1'b1;
        end else begin
            fifo_full <= (fifo_count == 8);
            fifo_empty <= (fifo_count == 0);
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            fifo_write_en <= 1'b0;
            fifo_read_en <= 1'b0;
        end else begin
            fifo_write_en <= (wb_adr_i == WB_ADDR_FIFO_DATA) && wb_we_i && wb_stb_i && wb_cyc_i;
            fifo_read_en <= (wb_adr_i == WB_ADDR_FIFO_DATA) && !wb_we_i && wb_stb_i && wb_cyc_i;
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            // Initialize FIFO with dummy data or clear
            for (integer i = 0; i < 16; i = i + 1)
                fifo_data[i] <= 8'd0;
        end else begin
            if (fifo_write_en && !fifo_full) begin
                fifo_data[fifo_ptr_wr] <= wb_dat_i;
                fifo_ptr_wr <= fifo_ptr_wr + 1'b1;
                fifo_count <= fifo_count + 1'b1;
            end else if (fifo_read_en && !fifo_empty) begin
                fifo_ptr_rd <= fifo_ptr_rd + 1'b1;
                fifo_count <= fifo_count - 1'b1;
            end
        end
    end

    // --------------------------------------------------------------------------
    // UART State Machine & Shift Register
    // --------------------------------------------------------------------------
    reg [7:0] shift_register;
    reg [1:0] uart_state; // 0: Idle, 1: Start, 2: Data, 3: Parity, 4: Stop
    reg uart_tx_enable;
    reg uart_rx_enable;
    reg [3:0] rx_data;
    reg [1:0] rx_state; // 0: Idle, 1: Start, 2: Data, 3: Parity, 4: Stop
    reg rx_data_valid;
    reg [7:0] rx_fifo_data;
    reg [3:0] rx_fifo_count;
    reg [3:0] rx_fifo_ptr;
    
    // Modem Control Logic
    reg [3:0] mcr_register;
    reg [3:0] lsr_register;
    reg [3:0] ier_register;
    reg [3:0] fcr_register;
    reg [3:0] line_ctl_register;
    reg [3:0] scr_register;
    reg [3:0] mcr_out;
    reg [3:0] lsr_out;
    reg [3:0] ier_out;
    reg [3:0] fcr_out;
    reg [3:0] line_ctl_out;
    reg [3:0] scr_out;
    
    // --------------------------------------------------------------------------
    // Register File Logic
    // --------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_dat_o_reg <= 16'd0;
            wb_ack_o_reg <= 1'b0;
            int_o_reg <= 1'b0;
            stx_pad_o_reg <= 1'b0;
            rts_pad_o_reg <= 1'b1;
            dtr_pad_o_reg <= 1'b1;
            
            // Default Register Values
            mcr_register <= 4'h0;
            lsr_register <= 4'h0;
            ier_register <= 4'h0;
            fcr_register <= 4'h0;
            line_ctl_register <= 4'h0;
            scr_register <= 4'h0;
            
            // Reset FIFOs
            for (integer i = 0; i < 16; i = i + 1)
                fifo_data[i] <= 8'd0;
            fifo_count <= 4'd0;
            fifo_ptr_wr <= 4'd0;
            fifo_ptr_rd <= 4'd0;
            
            // Reset UART State
            shift_register <= 8'd0;
            uart_state <= 2'd0;
            uart_tx_enable <= 1'b0;
            uart_rx_enable <= 1'b0;
            rx_data_valid <= 1'b0;
            rx_fifo_count <= 4'd0;
            rx_fifo_ptr <= 4'd0;
            
            // Reset Modem Status
            modem_status <= 4'd0;
        end else begin
            // Write Logic
            if (wb_we_i && wb_stb_i && wb_cyc_i) begin
                case (wb_adr_i)
                    WB_ADDR_FIFO_DATA: begin
                        if (!fifo_full) begin
                            fifo_data[fifo_ptr_wr] <= wb_dat_i;
                            fifo_ptr_wr <= fifo_ptr_wr + 1'b1;
                            fifo_count <= fifo_count + 1'b1;
                            if (fifo_count == 8) fifo_full <= 1'b1;
                        end
                    end
                    WB_ADDR_FIFO_STATUS: begin
                        wb_dat_o_reg <= {fifo_count[3:0], 12'd0};
                        wb_ack_o_reg <= 1'b1;
                    end
                    WB_ADDR_FIFO_CONTROL: begin
                        fcr_register <= wb_dat_i;
                        wb_ack_o_reg <= 1'b1;
                    end
                    WB_ADDR_BAUD_DIV: begin
                        baud_divider <= wb_dat_i;
                        wb_ack_o_reg <= 1'b1;
                    end
                    WB_ADDR_LSR: begin
                        lsr_register <= lsr_out;
                        wb_dat_o_reg <= lsr_register;
                        wb_ack_o_reg <= 1'b1;
                    end
                    WB_ADDR_MSR: begin
                        modem_status <= {cts_pad_i, dsr_pad_i, ri_pad_i, dcd_pad_i};
                        wb_dat_o_reg <= modem_status;
                        wb_ack_o_reg <= 1'b1;
                    end
                    WB_ADDR_IER: begin
                        ier_register <= wb_dat_i;
                        wb_ack_o_reg <= 1'b1;
                    end
                    WB_ADDR_FCR: begin
                        fcr_register <= wb_dat_i;
                        wb_ack_o_reg <= 1'b1;
                    end
                    WB_ADDR_LINE_CTL: begin
                        line_ctl_register <= wb_dat_i;
                        wb_ack_o_reg <= 1'b1;
                    end
                    WB_ADDR_MCR: begin
                        mcr_register <= wb_dat_i;
                        wb_ack_o_reg <= 1'b1;
                    end
                    WB_ADDR_SCRATCH: begin
                        scr_register <= wb_dat_i;
                        wb_ack_o_reg <= 1'b1;
                    end
                    default: begin
                        wb_dat_o_reg <= 16'd0;
                        wb_ack_o_reg <= 1'b0;
                    end
                endcase
            end else begin
                wb_ack_o_reg <= 1'b0;
            end
            
            // Read Logic
            case (wb_adr_i)
                WB_ADDR_FIFO_DATA: begin
                    if (fifo_empty) begin
                        wb_dat_o_reg <= 8'd0;
                    end else begin
                        wb_dat_o_reg <= fifo_data[fifo_ptr_rd];
                        fifo_ptr_rd <= fifo_ptr_rd + 1'b1;
                        fifo_count <= fifo_count - 1'b1;
                    end
                end
                WB_ADDR_FIFO_STATUS: begin
                    wb_dat_o_reg <= {fifo_count[3:0], 12'd0};
                end
                WB_ADDR_FIFO_CONTROL: begin
                    wb_dat_o_reg <= fcr_register;
                end
                WB_ADDR_BAUD_DIV: begin
                    wb_dat_o_reg <= baud_divider;
                end
                WB_ADDR_LSR: begin
                    wb_dat_o_reg <= lsr_out;
                end
                WB_ADDR_MSR: begin
                    wb_dat_o_reg <= modem_status;
                end
                WB_ADDR_IER: begin
                    wb_dat_o_reg <= ier_register;
                end
                WB_ADDR_FCR: begin
                    wb_dat_o_reg <= fcr_register;
                end
                WB_ADDR_LINE_CTL: begin
                    wb_dat_o_reg <= line_ctl_register;
                end
                WB_ADDR_MCR: begin
                    wb_dat_o_reg <= mcr_register;
                end
                WB_ADDR_SCRATCH: begin
                    wb_dat_o_reg <= scr_register;
                end
                default: begin
                    wb_dat_o_reg <= 16'd0;
                end
            endcase
            
            // Acknowledge Logic
            if (wb_we_i && wb_stb_i && wb_cyc_i) begin
                wb_ack_o_reg <= 1'b1;
            end else begin
                wb_ack_o_reg <= 1'b0;
            end
            
            // Interrupt Logic
            int_o_reg <= 1'b0;
            if (ier_register[0] && (lsr_out[0] || lsr_out[1])) begin
                int_o_reg <= 1'b1;
            end
            if (ier_register[1] && (modem_status[0] || modem_status[1] || modem_status[2] || modem_status[3])) begin
                int_o_reg <= 1'b1;
            end
            
            // Output Register Updates
            stx_pad_o_reg <= uart_tx_enable;
            rts_pad_o_reg <= mcr_out[1]; // RTS
            dtr_pad_o_reg <= mcr_out[0]; // DTR
        end
    end

    // --------------------------------------------------------------------------
    // UART TX Logic
    // --------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            uart_state <= 2'd0;
            shift_register <= 8'd0;
            uart_tx_enable <= 1'b0;
        end else begin
            case (uart_state)
                2'd0: begin // Idle
                    if (fifo_count > 0) begin
                        shift_register <= fifo_data[fifo_ptr_rd];
                        fifo_ptr_rd <= fifo_ptr_rd + 1'b1;
                        fifo_count <= fifo_count - 1'b1;
                        uart_state <= 2'd1;
                    end else begin
                        uart_tx_enable <= 1'b0;
                    end
                end
                2'd1: begin // Start Bit
                    shift_register <= 8'd0; // Clear MSB for start bit
                    uart_tx_enable <= 1'b1;
                    uart_state <= 2'd2;
                end
                2'd2: begin // Data Bits
                    if (line_ctl_register[0]) begin // 8 data bits
                        shift_register <= {shift_register[6:0], 1'b0};
                        uart_tx_enable <= 1'b1;
                        uart_state <= 2'd2;
                    end else begin // 7 data bits
                        shift_register <= {shift_register[5:0], 1'b0};
                        uart_tx_enable <= 1'b1;
                        uart_state <= 2'd2;
                    end
                end
                2'd3: begin // Parity Bit
                    if (line_ctl_register[1]) begin // Even parity
                        // Calculate parity
                        reg [7:0] temp = shift_register;
                        reg parity = 1'b0;
                        for (integer i = 0; i < 8; i = i + 1) begin
                            if (temp[i]) parity = ~parity;
                        end
                        shift_register <= {parity, shift_register[6:0]};
                        uart_tx_enable <= 1'b1;
                        uart_state <= 2'd4;
                    end else begin // Odd parity
                        // Calculate parity
                        reg [7:0] temp = shift_register;
                        reg parity = 1'b0;
                        for (integer i = 0; i < 8; i = i + 1) begin
                            if (temp[i]) parity = ~parity;
                        end
                        shift_register <= {~parity, shift_register[6:0]};
                        uart_tx_enable <= 1'b1;
                        uart_state <= 2'd4;
                    end
                end
                2'd4: begin // Stop Bit(s)
                    shift_register <= 8'd0; // Clear MSB for stop bit
                    uart_tx_enable <= 1'b1;
                    uart_state <= 2'd0;
                end
                default: begin
                    uart_state <= 2'd0;
                    uart_tx_enable <= 1'b0;
                end
            endcase
        end
    end

    // --------------------------------------------------------------------------
    // UART RX Logic
    // --------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            rx_state <= 2'd0;
            rx_data_valid <= 1'b0;
        end else begin
            case (rx_state)
                2'd0: begin // Idle
                    if (baud_overflow) begin
                        baud_overflow <= 1'b0;
                        rx_state <= 2'd1;
                    end else begin
                        rx_data_valid <= 1'b0;
                    end
                end
                2'd1: begin // Start Bit
                    rx_state <= 2'd2;
                end
                2'd2: begin // Data Bits
                    if (line_ctl_register[0]) begin // 8 data bits
                        rx_data_valid <= 1'b1;
                        rx_data <= shift_register[7:0];
                        rx_state <= 2'd3;
                    end else begin // 7 data bits
                        rx_data_valid <= 1'b1;
                        rx_data <= shift_register[6:0];
                        rx_state <= 2'd3;
                    end
                end
                2'd3: begin // Parity Bit
                    if (line_ctl_register[1]) begin // Even parity
                        // Check parity
                        reg [7:0] temp = shift_register;
                        reg parity = 1'b0;
                        for (integer i = 0; i < 8; i = i + 1) begin
                            if (temp[i]) parity = ~parity;
                        end
                        // If parity mismatch, set error bit in LSR
                        if (parity != shift_register[7]) begin
                            lsr_out[2] <= 1'b1;
                        end else begin
                            lsr_out[2] <= 1'b0;
                        end
                        rx_state <= 2'd4;
                    end else begin // Odd parity
                        // Check parity
                        reg [7:0] temp = shift_register;
                        reg parity = 1'b0;
                        for (integer i = 0; i < 8; i = i + 1) begin
                            if (temp[i]) parity = ~parity;
                        end
                        // If parity mismatch, set error bit in LSR
                        if (parity != ~shift_register[7]) begin
                            lsr_out[2] <= 1'b1;
                        end else begin
                            lsr_out[2] <= 1'b0;
                        end
                        rx_state <= 2'd4;
                    end
                end
                2'd4: begin // Stop Bit
                    rx_data_valid <= 1'b0;
                    rx_state <= 2'd0;
                end
                default: begin
                    rx_state <= 2'd0;
                    rx_data_valid <= 1'b0;
                end
            endcase
        end
    end

    // --------------------------------------------------------------------------
    // Modem Control Logic
    // --------------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            mcr_out <= 4'h0;
            lsr_out <= 4'h0;
            ier_out <= 4'h0;
            fcr_out <= 4'h0;
            line_ctl_out <= 4'h0;
            scr_out <= 4'h0;
        end else begin
            mcr_out <= mcr_register;
            lsr_out <= lsr_register;
            ier_out <= ier_register;
            fcr_out <= fcr_register;
            line_ctl_out <= line_ctl_register;
            scr_out <= scr_register;
        end
    end

    // --------------------------------------------------------------------------
    // Output Assignments
    // --------------------------------------------------------------------------
    assign wb_dat_o = wb_dat_o_reg;
    assign wb_ack_o = wb_ack_o_reg;
    assign int_o = int_o_reg;
    assign stx_pad_o = stx_pad_o_reg;
    assign rts_pad_o = rts_pad_o_reg;
    assign dtr_pad_o = dtr_pad_o_reg;

endmodule
```<|im_end|>
