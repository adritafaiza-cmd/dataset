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
input  [31:0] wb_adr_i;
input  [31:0] wb_dat_i;
output [31:0] wb_dat_o;
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

reg [31:0]    wb_dat_o;
reg           wb_ack_o;
reg           int_o;
reg           stx_pad_o;
reg           rts_pad_o;
reg           dtr_pad_o;

reg [7:0]     rbr; // Receive Buffer Register
reg [7:0]     thr; // Transmit Hold Register
reg [7:0]     ier; // Interrupt Enable Register
reg [7:0]     iir; // Interrupt Identification Register
reg [7:0]     lcr; // Line Control Register
reg [7:0]     mcr; // Modem Control Register
reg [7:0]     lsr; // Line Status Register
reg [7:0]     msr; // Modem Status Register
reg [7:0]     scr; // Scratch Register
reg [15:0]    dll; // Divisor Latch LSB
reg [15:0]    dlm; // Divisor Latch MSB
reg [7:0]     fcr; // FIFO Control Register
reg [7:0]     fifos; // FIFO status

reg [7:0]     tx_fifo[16]; // Transmit FIFO
reg [7:0]     rx_fifo[16]; // Receive FIFO
reg [3:0]     tx_fifo_ptr; // Transmit FIFO pointer
reg [3:0]     rx_fifo_ptr; // Receive FIFO pointer
reg [3:0]     tx_fifo_cnt; // Transmit FIFO count
reg [3:0]     rx_fifo_cnt; // Receive FIFO count

wire          tx_empty;
wire          rx_full;
wire          tx_full;
wire          rx_empty;

assign tx_empty = (tx_fifo_cnt == 0);
assign rx_full  = (rx_fifo_cnt == 16);
assign tx_full  = (tx_fifo_cnt == 16);
assign rx_empty = (rx_fifo_cnt == 0);

always @(posedge wb_clk_i or posedge wb_rst_i)
begin
    if (wb_rst_i)
    begin
        wb_dat_o <= 32'd0;
        wb_ack_o <= 1'b0;
        int_o    <= 1'b0;
        stx_pad_o <= 1'b1;
        rts_pad_o <= 1'b1;
        dtr_pad_o <= 1'b1;
        rbr       <= 8'd0;
        thr       <= 8'd0;
        ier       <= 8'd0;
        iir       <= 8'd1;
        lcr       <= 8'd0;
        mcr       <= 8'd0;
        lsr       <= 8'd20;
        msr       <= 8'd0;
        scr       <= 8'd0;
        dll       <= 16'd0;
        dlm       <= 16'd0;
        fcr       <= 8'd0;
        fifos     <= 8'd0;
        tx_fifo   <= '{default: 8'd0};
        rx_fifo   <= '{default: 8'd0};
        tx_fifo_ptr <= 4'd0;
        rx_fifo_ptr <= 4'd0;
        tx_fifo_cnt <= 4'd0;
        rx_fifo_cnt <= 4'd0;
    end
    else
    begin
        if (wb_stb_i && wb_cyc_i)
        begin
            case (wb_adr_i[7:2])
                4'h0: // RBR
                begin
                    if (wb_we_i)
                    begin
                        // Not writable
                    end
                    else
                    begin
                        wb_dat_o <= {24'd0, rbr};
                    end
                end
                4'h4: // THR
                begin
                    if (wb_we_i)
                    begin
                        thr <= wb_dat_i[7:0];
                        if (!tx_full)
                        begin
                            tx_fifo[tx_fifo_ptr] <= thr;
                            tx_fifo_ptr <= tx_fifo_ptr + 1;
                            tx_fifo_cnt <= tx_fifo_cnt + 1;
                        end
                    end
                    else
                    begin
                        wb_dat_o <= {24'd0, thr};
                    end
                end
                4'h8: // IER
                begin
                    if (wb_we_i)
                    begin
                        ier <= wb_dat_i[7:0];
                    end
                    else
                    begin
                        wb_dat_o <= {24'd0, ier};
                    end
                end
                4'hC: // IIR
                begin
                    if (wb_we_i)
                    begin
                        // Not writable
                    end
                    else
                    begin
                        wb_dat_o <= {24'd0, iir};
                    end
                end
                4'10: // LCR
                begin
                    if (wb_we_i)
                    begin
                        lcr <= wb_dat_i[7:0];
                    end
                    else
                    begin
                        wb_dat_o <= {24'd0, lcr};
                    end
                end
                4'14: // MCR
                begin
                    if (wb_we_i)
                    begin
                        mcr <= wb_dat_i[7:0];
                    end
                    else
                    begin
                        wb_dat_o <= {24'd0, mcr};
                    end
                end
                4'18: // LSR
                begin
                    if (wb_we_i)
                    begin
                        // Not writable
                    end
                    else
                    begin
                        wb_dat_o <= {24'd0, lsr};
                    end
                end
                4'1C: // MSR
                begin
                    if (wb_we_i)
                    begin
                        // Not writable
                    end
                    else
                    begin
                        wb_dat_o <= {24'd0, msr};
                    end
                end
                4'20: // SCR
                begin
                    if (wb_we_i)
                    begin
                        scr <= wb_dat_i[7:0];
                    end
                    else
                    begin
                        wb_dat_o <= {24'd0, scr};
                    end
                end
                4'24: // DLL
                begin
                    if (wb_we_i)
                    begin
                        dll <= wb_dat_i[7:0];
                    end
                    else
                    begin
                        wb_dat_o <= {24'd0, dll};
                    end
                end
                4'28: // DLM
                begin
                    if (wb_we_i)
                    begin
                        dlm <= wb_dat_i[7:0];
                    end
                    else
                    begin
                        wb_dat_o <= {24'd0, dlm};
                    end
                end
                4'2C: // FCR
                begin
                    if (wb_we_i)
                    begin
                        fcr <= wb_dat_i[7:0];
                    end
                    else
                    begin
                        wb_dat_o <= {24'd0, fcr};
                    end
                end
                default:
                begin
                    wb_dat_o <= 32'd0;
                end
            endcase
            wb_ack_o <= 1'b1;
        end
        else
        begin
            wb_ack_o <= 1'b0;
        end

        // UART transmitter
        if (!tx_empty && !tx_full)
        begin
            stx_pad_o <= tx_fifo[tx_fifo_ptr];
            tx_fifo_ptr <= tx_fifo_ptr + 1;
            tx_fifo_cnt <= tx_fifo_cnt - 1;
        end

        // UART receiver
        if (srx_pad_i && !rx_full)
        begin
            rx_fifo[rx_fifo_ptr] <= srx_pad_i;
            rx_fifo_ptr <= rx_fifo_ptr + 1;
            rx_fifo_cnt <= rx_fifo_cnt + 1;
        end

        // Interrupt handling
        if (ier[0] && !rx_empty)
        begin
            int_o <= 1'b1;
        end
        else
        begin
            int_o <= 1'b0;
        end
    end
end

endmodule
