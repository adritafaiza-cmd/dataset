module uart_top (
    wb_clk_i,
    wb_rst_i, 
    wb_adr_i, 
    wb_dat_i, 
    wb_dat_o, 
    wb_we_i, 
    wb_stb_i, 
    wb_cyc_i, 
    wb_ack_o, 
    wb_sel_i,
    int_o,
    stx_pad_o, 
    srx_pad_i,
    rts_pad_o, 
    cts_pad_i, 
    dtr_pad_o, 
    dsr_pad_i, 
    ri_pad_i, 
    dcd_pad_i
);

input         wb_clk_i;
input         wb_rst_i;
input  [7:0]  wb_adr_i;
input  [7:0]  wb_dat_i;
output [7:0]  wb_dat_o;
input         wb_we_i;
input         wb_stb_i;
input         wb_cyc_i;
output        wb_ack_o;
input  [3:0]  wb_sel_i;
output        int_o;
output        stx_pad_o;
input         srx_pad_i;
output        rts_pad_o;
input         cts_pad_i;
output        dtr_pad_o;
input         dsr_pad_i;
input         ri_pad_i;
input         dcd_pad_i;

reg   [7:0]   wb_dat_o;
reg           wb_ack_o;
reg           int_o;
reg           stx_pad_o;
reg           rts_pad_o;
reg           dtr_pad_o;

reg   [7:0]   rbr;  // Receive Buffer Register
reg   [7:0]   thr;  // Transmit Hold Register
reg   [7:0]   ier;  // Interrupt Enable Register
reg   [7:0]   iir;  // Interrupt Identification Register
reg   [7:0]   lcr;  // Line Control Register
reg   [7:0]   mcr;  // Modem Control Register
reg   [7:0]   lsr;  // Line Status Register
reg   [7:0]   msr;  // Modem Status Register
reg   [7:0]   scr;  // Scratch Register

reg   [7:0]   baud_div_l;  // Baud Rate Divisor (Low)
reg   [7:0]   baud_div_h;  // Baud Rate Divisor (High)

reg   [3:0]   fifo_rptr;  // Receive FIFO Pointer
reg   [3:0]   fifo_wptr;  // Transmit FIFO Pointer
reg   [7:0]   fifo_rx[16];  // Receive FIFO
reg   [7:0]   fifo_tx[16];  // Transmit FIFO

reg           tx_empty;
reg           rx_full;
reg           tx_full;
reg           rx_empty;

always @(posedge wb_clk_i or posedge wb_rst_i)
begin
    if (wb_rst_i)
    begin
        wb_dat_o <= 8'h00;
        wb_ack_o <= 1'b0;
        int_o <= 1'b0;
        stx_pad_o <= 1'b1;
        rts_pad_o <= 1'b1;
        dtr_pad_o <= 1'b1;
        rbr <= 8'h00;
        thr <= 8'h00;
        ier <= 8'h00;
        iir <= 8'h01;
        lcr <= 8'h00;
        mcr <= 8'h00;
        lsr <= 8'h20;
        msr <= 8'h00;
        scr <= 8'h00;
        baud_div_l <= 8'h00;
        baud_div_h <= 8'h00;
        fifo_rptr <= 4'h0;
        fifo_wptr <= 4'h0;
        fifo_rx <= '{default: 8'h00};
        fifo_tx <= '{default: 8'h00};
        tx_empty <= 1'b1;
        rx_full <= 1'b0;
        tx_full <= 1'b0;
        rx_empty <= 1'b1;
    end
    else
    begin
        if (wb_stb_i && wb_cyc_i)
        begin
            case (wb_adr_i)
                8'h00:  // RBR
                begin
                    if (wb_we_i)
                    begin
                        rbr <= wb_dat_i;
                    end
                    else
                    begin
                        wb_dat_o <= rbr;
                    end
                end
                8'h04:  // IER
                begin
                    if (wb_we_i)
                    begin
                        ier <= wb_dat_i;
                    end
                    else
                    begin
                        wb_dat_o <= ier;
                    end
                end
                8'h08:  // IIR
                begin
                    if (wb_we_i)
                    begin
                        iir <= wb_dat_i;
                    end
                    else
                    begin
                        wb_dat_o <= iir;
                    end
                end
                8'h0c:  // LCR
                begin
                    if (wb_we_i)
                    begin
                        lcr <= wb_dat_i;
                    end
                    else
                    begin
                        wb_dat_o <= lcr;
                    end
                end
                8'h10:  // MCR
                begin
                    if (wb_we_i)
                    begin
                        mcr <= wb_dat_i;
                    end
                    else
                    begin
                        wb_dat_o <= mcr;
                    end
                end
                8'h14:  // LSR
                begin
                    if (wb_we_i)
                    begin
                        lsr <= wb_dat_i;
                    end
                    else
                    begin
                        wb_dat_o <= lsr;
                    end
                end
                8'h18:  // MSR
                begin
                    if (wb_we_i)
                    begin
                        msr <= wb_dat_i;
                    end
                    else
                    begin
                        wb_dat_o <= msr;
                    end
                end
                8'h1c:  // SCR
                begin
                    if (wb_we_i)
                    begin
                        scr <= wb_dat_i;
                    end
                    else
                    begin
                        wb_dat_o <= scr;
                    end
                end
                8'h40:  // Baud Divisor (Low)
                begin
                    if (wb_we_i)
                    begin
                        baud_div_l <= wb_dat_i;
                    end
                    else
                    begin
                        wb_dat_o <= baud_div_l;
                    end
                end
                8'h44:  // Baud Divisor (High)
                begin
                    if (wb_we_i)
                    begin
                        baud_div_h <= wb_dat_i;
                    end
                    else
                    begin
                        wb_dat_o <= baud_div_h;
                    end
                end
                default:
                begin
                    wb_dat_o <= 8'h00;
                end
            endcase
            wb_ack_o <= 1'b1;
        end
        else
        begin
            wb_ack_o <= 1'b0;
        end

        // Receive FIFO
        if (srx_pad_i && !rx_full)
        begin
            fifo_rx[fifo_wptr] <= srx_pad_i;
            fifo_wptr <= fifo_wptr + 1;
            rx_full <= (fifo_wptr == 4'hF);
            rx_empty <= 1'b0;
        end

        // Transmit FIFO
        if (tx_empty && !tx_full)
        begin
            fifo_tx[fifo_rptr] <= thr;
            fifo_rptr <= fifo_rptr + 1;
            tx_full <= (fifo_rptr == 4'hF);
            tx_empty <= 1'b0;
        end

        // Interrupt Generation
        if (ier[0] && !rx_empty)
        begin
            int_o <= 1'b1;
        end
        else if (ier[1] && tx_empty)
        begin
            int_o <= 1'b1;
        end
        else
        begin
            int_o <= 1'b0;
        end

        // Modem Control
        if (mcr[0])
        begin
            dtr_pad_o <= 1'b0;
        end
        else
        begin
            dtr_pad_o <= 1'b1;
        end

        if (mcr[1])
        begin
            rts_pad_o <= 1'b0;
        end
        else
        begin
            rts_pad_o <= 1'b1;
        end

        // Line Status
        if (lsr[0])
        begin
            lsr[5] <= 1'b1;
        end
        else
        begin
            lsr[5] <= 1'b0;
        end

        if (lsr[1])
        begin
            lsr[6] <= 1'b1;
        end
        else
        begin
            lsr[6] <= 1'b0;
        end

        if (lsr[2])
        begin
            lsr[7] <= 1'b1;
        end
        else
        begin
            lsr[7] <= 1'b0;
        end

        // Modem Status
        if (msr[0])
        begin
            msr[3] <= 1'b1;
        end
        else
        begin
            msr[3] <= 1'b0;
        end

        if (msr[1])
        begin
            msr[4] <= 1'b1;
        end
        else
        begin
            msr[4] <= 1'b0;
        end

        if (msr[2])
        begin
            msr[5] <= 1'b1;
        end
        else
        begin
            msr[5] <= 1'b0;
        end

        if (msr[3])
        begin
            msr[6] <= 1'b1;
        end
        else
        begin
            msr[6] <= 1'b0;
        end

        // Baud Rate Generation
        if (baud_div_l == 8'h00)
        begin
            baud_div_l <= 8'h01;
        end
        else
        begin
            baud_div_l <= baud_div_l - 1;
        end

        if (baud_div_h == 8'h00)
        begin
            baud_div_h <= 8'h01;
        end
        else
        begin
            baud_div_h <= baud_div_h - 1;
        end

        // Transmit
        if (tx_empty && !tx_full)
        begin
            stx_pad_o <= fifo_tx[fifo_rptr];
            fifo_rptr <= fifo_rptr + 1;
            tx_empty <= 1'b0;
        end
    end
end

endmodule
