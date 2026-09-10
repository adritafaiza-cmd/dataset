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

// UART registers
reg [7:0]     rbr;  // Receive Buffer Register
reg [7:0]     thr;  // Transmit Hold Register
reg [7:0]     ier;  // Interrupt Enable Register
reg [7:0]     iir;  // Interrupt Identification Register
reg [7:0]     lcr;  // Line Control Register
reg [7:0]     mcr;  // Modem Control Register
reg [7:0]     lsr;  // Line Status Register
reg [7:0]     msr;  // Modem Status Register
reg [7:0]     scr;  // Scratch Register
reg [15:0]    dll;  // Divisor Latch LSB
reg [15:0]    dlh;  // Divisor Latch MSB
reg [7:0]     fcr;  // FIFO Control Register

// UART FIFOs
reg [7:0]     rxfifo[16];
reg [7:0]     txfifo[16];
reg [3:0]     rxcount;
reg [3:0]     txcount;
reg           rxempty;
reg           rxfull;
reg           txempty;
reg           txfull;

// UART state machines
reg           rxstate;
reg           txstate;

// UART counters
reg [15:0]    baudcounter;
reg [3:0]     rxbitcounter;
reg [3:0]     txbitcounter;

// Modem control signals
reg           cts;
reg           dsr;
reg           ri;
reg           dcd;

// UART interrupts
reg           int_rx;
reg           int_tx;
reg           int_modem;

// Reset logic
always @(posedge wb_clk_i or posedge wb_rst_i)
begin
    if (wb_rst_i)
    begin
        wb_dat_o <= 32'd0;
        wb_ack_o <= 1'b0;
        int_o <= 1'b0;
        stx_pad_o <= 1'b0;
        rts_pad_o <= 1'b0;
        dtr_pad_o <= 1'b0;
        rbr <= 8'd0;
        thr <= 8'd0;
        ier <= 8'd0;
        iir <= 8'd0;
        lcr <= 8'd0;
        mcr <= 8'd0;
        lsr <= 8'd0;
        msr <= 8'd0;
        scr <= 8'd0;
        dll <= 16'd0;
        dlh <= 16'd0;
        fcr <= 8'd0;
        rxcount <= 4'd0;
        txcount <= 4'd0;
        rxempty <= 1'b1;
        rxfull <= 1'b0;
        txempty <= 1'b1;
        txfull <= 1'b0;
        rxstate <= 1'b0;
        txstate <= 1'b0;
        baudcounter <= 16'd0;
        rxbitcounter <= 4'd0;
        txbitcounter <= 4'd0;
        cts <= 1'b0;
        dsr <= 1'b0;
        ri <= 1'b0;
        dcd <= 1'b0;
        int_rx <= 1'b0;
        int_tx <= 1'b0;
        int_modem <= 1'b0;
    end
    else
    begin
        // UART Wishbone slave logic
        if (wb_stb_i && wb_cyc_i)
        begin
            case (wb_adr_i[3:0])
                4'h0: // RBR
                    wb_dat_o <= {24'd0, rbr};
                4'h4: // THR
                    if (wb_we_i)
                        thr <= wb_dat_i[7:0];
                4'h8: // IER
                    if (wb_we_i)
                        ier <= wb_dat_i[7:0];
                4'hc: // IIR
                    wb_dat_o <= {24'd0, iir};
                4'h10: // LCR
                    if (wb_we_i)
                        lcr <= wb_dat_i[7:0];
                4'h14: // MCR
                    if (wb_we_i)
                        mcr <= wb_dat_i[7:0];
                4'h18: // LSR
                    wb_dat_o <= {24'd0, lsr};
                4'h1c: // MSR
                    wb_dat_o <= {24'd0, msr};
                4'h20: // SCR
                    if (wb_we_i)
                        scr <= wb_dat_i[7:0];
                4'h24: // DLL
                    if (wb_we_i)
                        dll <= wb_dat_i[15:0];
                4'h28: // DLH
                    if (wb_we_i)
                        dlh <= wb_dat_i[15:0];
                4'h2c: // FCR
                    if (wb_we_i)
                        fcr <= wb_dat_i[7:0];
                default:
                    wb_dat_o <= 32'd0;
            endcase
            wb_ack_o <= 1'b1;
        end
        else
            wb_ack_o <= 1'b0;

        // UART receive logic
        if (rxstate == 1'b0)
        begin
            if (srx_pad_i == 1'b0)
                rxstate <= 1'b1;
        end
        else if (rxstate == 1'b1)
        begin
            if (baudcounter == 16'd0)
            begin
                rxbitcounter <= rxbitcounter + 1'b1;
                if (rxbitcounter == 4'd9)
                begin
                    rbr <= {srx_pad_i, rbr[7:1]};
                    rxstate <= 1'b0;
                    rxbitcounter <= 4'd0;
                    if (rxcount < 4'd16)
                        rxcount <= rxcount + 1'b1;
                    rxempty <= 1'b0;
                end
                baudcounter <= dll + dlh;
            end
            else
                baudcounter <= baudcounter - 1'b1;
        end

        // UART transmit logic
        if (txstate == 1'b0)
        begin
            if (txcount > 4'd0)
            begin
                txstate <= 1'b1;
                txbitcounter <= 4'd0;
                baudcounter <= dll + dlh;
            end
        end
        else if (txstate == 1'b1)
        begin
            if (baudcounter == 16'd0)
            begin
                stx_pad_o <= thr[txbitcounter];
                txbitcounter <= txbitcounter + 1'b1;
                if (txbitcounter == 4'd9)
                begin
                    txstate <= 1'b0;
                    txbitcounter <= 4'd0;
                    txcount <= txcount - 1'b1;
                    txempty <= 1'b1;
                end
                baudcounter <= dll + dlh;
            end
            else
                baudcounter <= baudcounter - 1'b1;
        end

        // UART interrupt logic
        if (int_rx || int_tx || int_modem)
            int_o <= 1'b1;
        else
            int_o <= 1'b0;

        // Modem control logic
        cts <= cts_pad_i;
        dsr <= dsr_pad_i;
        ri <= ri_pad_i;
        dcd <= dcd_pad_i;
        rts_pad_o <= mcr[1];
        dtr_pad_o <= mcr[0];
    end
end

endmodule
