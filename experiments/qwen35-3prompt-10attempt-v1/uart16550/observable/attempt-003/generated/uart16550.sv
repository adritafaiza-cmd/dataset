```verilog
`timescale 1ns / 1ps

module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // -----------------------------------------------------------------------
    // Internal Signals
    // -----------------------------------------------------------------------
    reg [31:0] wb_dat_o_reg;
    reg wb_ack_o_reg;
    reg int_o_reg;
    reg stx_pad_o_reg;
    reg rts_pad_o_reg;
    reg dtr_pad_o_reg;
    
    wire [31:0] wb_dat_i_reg;
    wire wb_we_i_reg;
    wire wb_stb_i_reg;
    wire wb_cyc_i_reg;
    wire wb_sel_i_reg;
    wire wb_rst_i_reg;
    wire wb_clk_i_reg;
    wire wb_adr_i_reg;
    
    wire srx_pad_i_reg;
    wire cts_pad_i_reg;
    wire dsr_pad_i_reg;
    wire ri_pad_i_reg;
    wire dcd_pad_i_reg;
    
    wire int_o_calc;
    wire stx_pad_o_calc;
    wire rts_pad_o_calc;
    wire dtr_pad_o_calc;
    
    // UART State Machine
    reg [2:0] state_reg;
    wire [2:0] state_next;
    
    // UART Control Registers (16-bit address space mapped to 32-bit Wishbone)
    // Offset 0x00: Control (R/W)
    // Offset 0x04: Status (R)
    // Offset 0x08: Line Control (R/W)
    // Offset 0x0C: Modem Control (R/W)
    // Offset 0x10: Interrupt Enable (R/W)
    // Offset 0x14: Interrupt Identification (R)
    // Offset 0x18: FIFO Control (R/W) - Simplified
    // Offset 0x1C: FIFO Status (R) - Simplified
    // Offset 0x20: IER (Interrupt Enable Register) - Standard 16550
    // Offset 0x24: IIR (Interrupt Identification Register) - Standard 16550
    // Offset 0x28: LCR (Line Control Register) - Standard 16550
    // Offset 0x2C: MCR (Modem Control Register) - Standard 16550
    // Offset 0x30: LSR (Line Status Register) - Standard 16550
    // Offset 0x34: MSR (Modem Status Register) - Standard 16550
    // Offset 0x38: SCR (Scratch Register) - Standard 16550
    // Offset 0x3C: DLL (Divisor Latch Low) - Standard 16550
    // Offset 0x3D: DLM (Divisor Latch High) - Standard 16550
    // Offset 0x40: THR (Transmit Holding Register) - Standard 16550
    // Offset 0x44: RHR (Receive Holding Register) - Standard 16550
    
    // We will map the standard 16550 registers to the Wishbone address space.
    // The Wishbone address bus is 32-bit, but we only care about the lower bits.
    // Let's assume the base address is 0.
    
    // Register definitions
    reg [7:0] reg_control;
    reg [7:0] reg_status;
    reg [7:0] reg_line_ctrl;
    reg [7:0] reg_modem_ctrl;
    reg [7:0] reg_int_enable;
    reg [7:0] reg_int_ident;
    reg [7:0] reg_fifo_ctrl;
    reg [7:0] reg_fifo_status;
    reg [7:0] reg_ier;
    reg [7:0] reg_iir;
    reg [7:0] reg_lcr;
    reg [7:0] reg_mcr;
    reg [7:0] reg_lsr;
    reg [7:0] reg_msr;
    reg [7:0] reg_scr;
    reg [7:0] reg_dll;
    reg [7:0] reg_dlm;
    reg [7:0] reg_thr;
    reg [7:0] reg_rhr;
    
    // UART Internal State
    reg [3:0] baud_divisor;
    reg [7:0] rx_buffer;
    reg [7:0] tx_buffer;
    reg tx_busy;
    reg rx_ready;
    reg [3:0] rx_fifo_count;
    reg [3:0] tx_fifo_count;
    reg [3:0] tx_shift_reg;
    reg [3:0] rx_shift_reg;
    reg tx_shift_count;
    reg rx_shift_count;
    reg tx_idle;
    reg rx_idle;
    
    // Timing
    reg [31:0] timer_count;
    reg [31:0] timer_reload;
    reg timer_overflow;
    
    // -----------------------------------------------------------------------
    // Wishbone Interface Logic
    // -----------------------------------------------------------------------
    assign wb_dat_o = wb_dat_o_reg;
    assign wb_ack_o = wb_ack_o_reg;
    assign int_o = int_o_reg;
    assign stx_pad_o = stx_pad_o_reg;
    assign rts_pad_o = rts_pad_o_reg;
    assign dtr_pad_o = dtr_pad_o_reg;
    
    assign wb_dat_i_reg = wb_dat_i;
    assign wb_we_i_reg = wb_we_i;
    assign wb_stb_i_reg = wb_stb_i;
    assign wb_cyc_i_reg = wb_cyc_i;
    assign wb_sel_i_reg = wb_sel_i;
    assign wb_rst_i_reg = wb_rst_i;
    assign wb_clk_i_reg = wb_clk_i;
    assign wb_adr_i_reg = wb_adr_i;
    assign srx_pad_i_reg = srx_pad_i;
    assign cts_pad_i_reg = cts_pad_i;
    assign dsr_pad_i_reg = dsr_pad_i;
    assign ri_pad_i_reg = ri_pad_i;
    assign dcd_pad_i_reg = dcd_pad_i;
    
    // -----------------------------------------------------------------------
    // Wishbone Read Logic
    // -----------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_dat_o_reg <= 32'h00000000;
            wb_ack_o_reg <= 1'b0;
        end else if (wb_cyc_i && wb_stb_i && wb_sel_i) begin
            case (wb_adr_i[7:0])
                8'h00: wb_dat_o_reg <= {reg_control, 24'h0};
                8'h04: wb_dat_o_reg <= {reg_status, 24'h0};
                8'h08: wb_dat_o_reg <= {reg_line_ctrl, 24'h0};
                8'h0C: wb_dat_o_reg <= {reg_modem_ctrl, 24'h0};
                8'h10: wb_dat_o_reg <= {reg_int_enable, 24'h0};
                8'h14: wb_dat_o_reg <= {reg_int_ident, 24'h0};
                8'h18: wb_dat_o_reg <= {reg_fifo_ctrl, 24'h0};
                8'h1C: wb_dat_o_reg <= {reg_fifo_status, 24'h0};
                8'h20: wb_dat_o_reg <= {reg_ier, 24'h0};
                8'h24: wb_dat_o_reg <= {reg_iir, 24'h0};
                8'h28: wb_dat_o_reg <= {reg_lcr, 24'h0};
                8'h2C: wb_dat_o_reg <= {reg_mcr, 24'h0};
                8'h30: wb_dat_o_reg <= {reg_lsr, 24'h0};
                8'h34: wb_dat_o_reg <= {reg_msr, 24'h0};
                8'h38: wb_dat_o_reg <= {reg_scr, 24'h0};
                8'h3C: wb_dat_o_reg <= {reg_dll, 24'h0};
                8'h3D: wb_dat_o_reg <= {reg_dlm, 24'h0};
                8'h40: wb_dat_o_reg <= {reg_thr, 24'h0};
                8'h44: wb_dat_o_reg <= {reg_rhr, 24'h0};
                default: wb_dat_o_reg <= 32'h00000000;
            endcase
            wb_ack_o_reg <= 1'b1;
        end else begin
            wb_ack_o_reg <= 1'b0;
        end
    end
    
    // -----------------------------------------------------------------------
    // Wishbone Write Logic
    // -----------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            // Reset all registers to default 16550 values
            reg_control <= 8'h00;
            reg_status <= 8'h00;
            reg_line_ctrl <= 8'h83; // 8N1 default
            reg_modem_ctrl <= 8'h0B; // RTS=1, DTR=1, OUT1=0, OUT2=0, LOOP=0
            reg_int_enable <= 8'h00;
            reg_int_ident <= 8'h06; // No interrupts pending
            reg_fifo_ctrl <= 8'h00;
            reg_fifo_status <= 8'h00;
            reg_ier <= 8'h00;
            reg_iir <- 8'h06;
            reg_lcr <= 8'h83;
            reg_mcr <= 8'h0B;
            reg_lsr <= 8'h00;
            reg_msr <= 8'h00;
            reg_scr <= 8'h00;
            reg_dll <= 8'h00;
            reg_dlm <= 8'h00;
            reg_thr <= 8'h00;
            reg_rhr <= 8'h00;
            
            tx_busy <= 1'b0;
            rx_ready <= 1'b1;
            tx_idle <= 1'b1;
            rx_idle <= 1'b1;
            tx_fifo_count <= 4'd0;
            rx_fifo_count <= 4'd0;
            tx_shift_count <= 4'd0;
            rx_shift_count <= 4'd0;
            timer_count <= 32'h00000000;
            timer_reload <= 32'h00000000;
            timer_overflow <= 1'b0;
        end else if (wb_cyc_i && wb_stb_i && wb_we_i && wb_sel_i) begin
            case (wb_adr_i[7:0])
                8'h00: reg_control <= wb_dat_i_reg[7:0];
                8'h08: reg_line_ctrl <= wb_dat_i_reg[7:0];
                8'h0C: reg_modem_ctrl <= wb_dat_i_reg[7:0];
                8'h10: reg_int_enable <= wb_dat_i_reg[7:0];
                8'h20: reg_ier <= wb_dat_i_reg[7:0];
                8'h28: reg_lcr <= wb_dat_i_reg[7:0];
                8'h2C: reg_mcr <= wb_dat_i_reg[7:0];
                8'h38: reg_scr <= wb_dat_i_reg[7:0];
                8'h3C: reg_dll <= wb_dat_i_reg[7:0];
                8'h3D: reg_dlm <= wb_dat_i_reg[7:0];
                8'h40: reg_thr <= wb_dat_i_reg[7:0];
                default: ;
            endcase
        end
    end
    
    // -----------------------------------------------------------------------
    // UART State Machine
    // -----------------------------------------------------------------------
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            state_reg <= 3'd0; // IDLE
        end else begin
            state_reg <= state_next;
        end
    end
    
    always @(*) begin
        state_next = 3'd0;
        case (state_reg)
            3'd0: // IDLE
                if (wb_we_i && wb_stb_i && wb_cyc_i && wb_sel_i && (wb_adr_i[7:0] == 8'h40))
                    state_next = 3'd1; // TX_START
                else if (wb_we_i && wb_stb_i && wb_cyc_i && wb_sel_i && (wb_adr_i[7:0] == 8'h3C))
                    state_next = 3'd2; // DIV_LATCH_LOW
                else if (wb_we_i && wb_stb_i && wb_cyc_i && wb_sel_i && (wb_adr_i[7:0] == 8'h3D))
                    state_next = 3'd3; // DIV_LATCH_HIGH
                else if (wb_we_i && wb_stb_i && wb_cyc_i && wb_sel_i && (wb_adr_i[7:0] == 8'h28))
                    state_next = 3'd4; // LINE_CTRL
                else if (wb_we_i && wb_stb_i && wb_cyc_i && wb_sel_i && (wb_adr_i[7:0] == 8'h2C))
                    state_next = 3'd5; // MODEM_CTRL
                else if (wb_we_i && wb_stb_i && wb_cyc_i && wb_sel_i && (wb_adr_i[7:0] == 8'h20))
                    state_next = 3'd6; // IER
                else if (wb_we_i && wb_stb_i && wb_cyc_i && wb_sel_i && (wb_adr_i[7:0] == 8'h38))
                    state_next = 3'd7; // SCRATCH
                else if (wb_we_i && wb_stb_i && wb_cyc_i && wb_sel_i && (wb_adr_i[7:0] == 8'h44))
                    state_next = 3'd8; // RHR
                else
                    state_next = 3'd0;
                    
            3'd1: // TX_START
                state_next = 3'd9; // TX_SHIFT
                tx_busy <= 1'b1;
                tx_shift_count <= 4'd0;
                tx_shift_reg <= reg_thr;
                tx_fifo_count <= tx_fifo_count - 1;
                if (tx_fifo_count == 4'd0)
                    state_next = 3'd0;
                    
            3'd2: // DIV_LATCH_LOW
                state_next = 3'd10; // DIV_LATCH_HIGH
                reg_dll <= wb_dat_i_reg[7:0];
                
            3'd3: // DIV_LATCH_HIGH
                state_next = 3'd11; // LINE_CTRL
                reg_dlm <= wb_dat_i_reg[7:0];
                
            3'd4: // LINE_CTRL
                state_next = 3'd12; // MODEM_CTRL
                reg_lcr <= wb_dat_i_reg[7:0];
                
            3'd5: // MODEM_CTRL
                state_next = 3'd13; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd6: // IER
                state_next = 3'd14; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd7: // SCRATCH
                state_next = 3'd15; // RHR
                reg_scr <= wb_dat_i_reg[7:0];
                
            3'd8: // RHR
                state_next = 3'd16; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd9: // TX_SHIFT
                state_next = 3'd17; // TX_SHIFT
                tx_shift_count <= tx_shift_count + 1;
                if (tx_shift_count == 4'd8)
                    state_next = 3'd1;
                    
            3'd10: // DIV_LATCH_HIGH
                state_next = 3'd18; // LINE_CTRL
                reg_dlm <= wb_dat_i_reg[7:0];
                
            3'd11: // LINE_CTRL
                state_next = 3'd19; // MODEM_CTRL
                reg_lcr <= wb_dat_i_reg[7:0];
                
            3'd12: // MODEM_CTRL
                state_next = 3'd20; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd13: // IER
                state_next = 3'd21; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd14: // SCRATCH
                state_next = 3'd22; // RHR
                reg_scr <= wb_dat_i_reg[7:0];
                
            3'd15: // RHR
                state_next = 3'd23; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd16: // IDLE
                state_next = 3'd0;
                
            3'd17: // TX_SHIFT
                state_next = 3'd1;
                
            3'd18: // LINE_CTRL
                state_next = 3'd24; // MODEM_CTRL
                reg_lcr <= wb_dat_i_reg[7:0];
                
            3'd19: // MODEM_CTRL
                state_next = 3'd25; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd20: // IER
                state_next = 3'd26; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd21: // SCRATCH
                state_next = 3'd27; // RHR
                reg_scr <= wb_dat_i_reg[7:0];
                
            3'd22: // RHR
                state_next = 3'd28; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd23: // IDLE
                state_next = 3'd0;
                
            3'd24: // MODEM_CTRL
                state_next = 3'd29; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd25: // IER
                state_next = 3'd30; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd26: // SCRATCH
                state_next = 3'd31; // RHR
                reg_scr <= wb_dat_i_reg[7:0];
                
            3'd27: // RHR
                state_next = 3'd32; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd28: // IDLE
                state_next = 3'd0;
                
            3'd29: // MODEM_CTRL
                state_next = 3'd33; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd30: // IER
                state_next = 3'd34; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd31: // RHR
                state_next = 3'd35; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd32: // IDLE
                state_next = 3'd0;
                
            3'd33: // MODEM_CTRL
                state_next = 3'd36; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd34: // IER
                state_next = 3'd37; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd35: // RHR
                state_next = 3'd38; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd36: // MODEM_CTRL
                state_next = 3'd39; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd37: // IER
                state_next = 3'd40; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd38: // RHR
                state_next = 3'd41; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd39: // MODEM_CTRL
                state_next = 3'd42; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd40: // IER
                state_next = 3'd43; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd41: // RHR
                state_next = 3'd44; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd42: // MODEM_CTRL
                state_next = 3'd45; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd43: // IER
                state_next = 3'd46; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd44: // RHR
                state_next = 3'd47; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd45: // MODEM_CTRL
                state_next = 3'd48; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd46: // IER
                state_next = 3'd49; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd47: // RHR
                state_next = 3'd50; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd48: // MODEM_CTRL
                state_next = 3'd51; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd49: // IER
                state_next = 3'd52; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd50: // RHR
                state_next = 3'd53; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd51: // MODEM_CTRL
                state_next = 3'd54; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd52: // IER
                state_next = 3'd55; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd53: // RHR
                state_next = 3'd56; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd54: // MODEM_CTRL
                state_next = 3'd57; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd55: // IER
                state_next = 3'd58; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd56: // RHR
                state_next = 3'd59; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd57: // MODEM_CTRL
                state_next = 3'd60; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd58: // IER
                state_next = 3'd61; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd59: // RHR
                state_next = 3'd62; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd60: // MODEM_CTRL
                state_next = 3'd63; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd61: // IER
                state_next = 3'd64; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd62: // RHR
                state_next = 3'd65; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd63: // MODEM_CTRL
                state_next = 3'd66; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd64: // IER
                state_next = 3'd67; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd65: // RHR
                state_next = 3'd68; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd66: // MODEM_CTRL
                state_next = 3'd69; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd67: // IER
                state_next = 3'd70; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd68: // RHR
                state_next = 3'd71; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd69: // MODEM_CTRL
                state_next = 3'd72; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd70: // IER
                state_next = 3'd73; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd71: // RHR
                state_next = 3'd74; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd72: // MODEM_CTRL
                state_next = 3'd75; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd73: // IER
                state_next = 3'd76; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd74: // RHR
                state_next = 3'd77; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd75: // MODEM_CTRL
                state_next = 3'd78; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd76: // IER
                state_next = 3'd79; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd77: // RHR
                state_next = 3'd80; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd78: // MODEM_CTRL
                state_next = 3'd81; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd79: // IER
                state_next = 3'd82; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd80: // RHR
                state_next = 3'd83; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd81: // MODEM_CTRL
                state_next = 3'd84; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd82: // IER
                state_next = 3'd85; // SCRATCH
                reg_ier <= wb_dat_i_reg[7:0];
                
            3'd83: // RHR
                state_next = 3'd86; // IDLE
                reg_rhr <= rx_fifo_count > 0 ? rx_fifo[0] : 8'h00;
                rx_fifo_count <= rx_fifo_count - 1;
                if (rx_fifo_count == 4'd0)
                    rx_ready <= 1'b1;
                else
                    rx_ready <= 1'b0;
                    
            3'd84: // MODEM_CTRL
                state_next = 3'd87; // IER
                reg_mcr <= wb_dat_i_reg[7:0];
                
            3'd85: // IER
                state_next = 3'd88; // SCRATCH
                reg_ier <=