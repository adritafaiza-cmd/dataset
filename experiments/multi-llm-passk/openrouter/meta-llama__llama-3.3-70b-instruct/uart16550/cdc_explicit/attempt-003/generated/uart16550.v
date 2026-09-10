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

// UART registers
reg [7:0] rbr; // Receive Buffer Register
reg [7:0] thr; // Transmit Hold Register
reg [7:0] ier; // Interrupt Enable Register
reg [7:0] iir; // Interrupt Identification Register
reg [7:0] lcr; // Line Control Register
reg [7:0] mcr; // Modem Control Register
reg [7:0] lsr; // Line Status Register
reg [7:0] msr; // Modem Status Register
reg [7:0] scr; // Scratch Register

// UART FIFOs
reg [7:0] rxfifo[16];
reg [7:0] txfifo[16];
reg [3:0] rxcount;
reg [3:0] txcount;
reg [3:0] rxptr;
reg [3:0] txptr;

// UART control signals
reg txready;
reg rxready;
reg txempty;
reg rxempty;
reg txint;
reg rxint;

// UART baud rate generator
reg [15:0] baudcnt;
reg [15:0] bauddiv;

// UART modem control signals
reg rts;
reg cts;
reg dtr;
reg dsr;
reg ri;
reg dcd;

// Wishbone slave signals
reg ack;
reg [31:0] dat_o;

// UART interrupt signals
reg int;

always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if (wb_rst_i) begin
        // Reset UART registers
        rbr <= 8'h00;
        thr <= 8'h00;
        ier <= 8'h00;
        iir <= 8'h00;
        lcr <= 8'h00;
        mcr <= 8'h00;
        lsr <= 8'h00;
        msr <= 8'h00;
        scr <= 8'h00;

        // Reset UART FIFOs
        rxcount <= 4'h0;
        txcount <= 4'h0;
        rxptr <= 4'h0;
        txptr <= 4'h0;

        // Reset UART control signals
        txready <= 1'b0;
        rxready <= 1'b0;
        txempty <= 1'b1;
        rxempty <= 1'b1;
        txint <= 1'b0;
        rxint <= 1'b0;

        // Reset UART baud rate generator
        baudcnt <= 16'h0000;
        bauddiv <= 16'h0000;

        // Reset UART modem control signals
        rts <= 1'b0;
        cts <= 1'b0;
        dtr <= 1'b0;
        dsr <= 1'b0;
        ri <= 1'b0;
        dcd <= 1'b0;

        // Reset Wishbone slave signals
        ack <= 1'b0;
        dat_o <= 32'h00000000;

        // Reset UART interrupt signals
        int <= 1'b0;
    end else begin
        // UART receive logic
        if (rxready &&!rxempty) begin
            rbr <= rxfifo[rxptr];
            rxptr <= rxptr + 1;
            rxcount <= rxcount - 1;
            if (rxcount == 4'h0) begin
                rxempty <= 1'b1;
            end
        end

        // UART transmit logic
        if (txready &&!txempty) begin
            stx_pad_o <= txfifo[txptr];
            txptr <= txptr + 1;
            txcount <= txcount - 1;
            if (txcount == 4'h0) begin
                txempty <= 1'b1;
            end
        end

        // UART baud rate generator
        baudcnt <= baudcnt + 1;
        if (baudcnt == bauddiv) begin
            baudcnt <= 16'h0000;
            txready <= 1'b1;
            rxready <= 1'b1;
        end

        // UART modem control logic
        rts <= mcr[1];
        cts <= cts_pad_i;
        dtr <= mcr[0];
        dsr <= dsr_pad_i;
        ri <= ri_pad_i;
        dcd <= dcd_pad_i;

        // Wishbone slave logic
        if (wb_stb_i && wb_cyc_i) begin
            case (wb_adr_i[7:2])
                8'h00: begin // RBR
                    dat_o <= {24'h000000, rbr};
                end
                8'h04: begin // THR
                    if (wb_we_i) begin
                        thr <= wb_dat_i[7:0];
                        txfifo[txptr] <= wb_dat_i[7:0];
                        txptr <= txptr + 1;
                        txcount <= txcount + 1;
                        if (txcount == 4'h10) begin
                            txempty <= 1'b0;
                        end
                    end else begin
                        dat_o <= {24'h000000, thr};
                    end
                end
                8'h08: begin // IER
                    if (wb_we_i) begin
                        ier <= wb_dat_i[7:0];
                    end else begin
                        dat_o <= {24'h000000, ier};
                    end
                end
                8'h0c: begin // IIR
                    dat_o <= {24'h000000, iir};
                end
                8'h10: begin // LCR
                    if (wb_we_i) begin
                        lcr <= wb_dat_i[7:0];
                    end else begin
                        dat_o <= {24'h000000, lcr};
                    end
                end
                8'h14: begin // MCR
                    if (wb_we_i) begin
                        mcr <= wb_dat_i[7:0];
                    end else begin
                        dat_o <= {24'h000000, mcr};
                    end
                end
                8'h18: begin // LSR
                    dat_o <= {24'h000000, lsr};
                end
                8'h1c: begin // MSR
                    dat_o <= {24'h000000, msr};
                end
                8'h20: begin // SCR
                    if (wb_we_i) begin
                        scr <= wb_dat_i[7:0];
                    end else begin
                        dat_o <= {24'h000000, scr};
                    end
                end
                default: begin
                    dat_o <= 32'h00000000;
                end
            endcase
            ack <= 1'b1;
        end else begin
            ack <= 1'b0;
        end

        // UART interrupt logic
        if (ier[0] && txempty) begin
            txint <= 1'b1;
        end
        if (ier[1] && rxempty) begin
            rxint <= 1'b1;
        end
        if (txint || rxint) begin
            int <= 1'b1;
        end
    end
end

assign wb_dat_o = dat_o;
assign wb_ack_o = ack;
assign int_o = int;
assign stx_pad_o = txready? txfifo[txptr] : 1'b0;
assign rts_pad_o = rts;
assign dtr_pad_o = dtr;

endmodule
