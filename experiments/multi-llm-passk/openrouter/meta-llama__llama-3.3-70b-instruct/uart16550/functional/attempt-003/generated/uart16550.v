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

input wb_clk_i;
input wb_rst_i;
input [31:0] wb_adr_i;
input [31:0] wb_dat_i;
output [31:0] wb_dat_o;
input wb_we_i;
input wb_stb_i;
input wb_cyc_i;
output wb_ack_o;
input [3:0] wb_sel_i;
output int_o;
output stx_pad_o;
input srx_pad_i;
output rts_pad_o;
input cts_pad_i;
output dtr_pad_o;
input dsr_pad_i;
input ri_pad_i;
input dcd_pad_i;

reg [31:0] rbr; // Receive Buffer Register
reg [31:0] thr; // Transmit Hold Register
reg [31:0] ier; // Interrupt Enable Register
reg [31:0] iir; // Interrupt Identification Register
reg [31:0] lcr; // Line Control Register
reg [31:0] mcr; // Modem Control Register
reg [31:0] lsr; // Line Status Register
reg [31:0] msr; // Modem Status Register
reg [31:0] scr; // Scratch Register
reg [31:0] dll; // Divisor Latch LSB
reg [31:0] dlm; // Divisor Latch MSB
reg [31:0] fcr; // FIFO Control Register
reg [31:0] fdr; // FIFO Data Register

reg [7:0] rx_fifo[16]; // Receive FIFO
reg [7:0] tx_fifo[16]; // Transmit FIFO
reg [3:0] rx_fifo_ptr; // Receive FIFO Pointer
reg [3:0] tx_fifo_ptr; // Transmit FIFO Pointer
reg [3:0] rx_fifo_cnt; // Receive FIFO Count
reg [3:0] tx_fifo_cnt; // Transmit FIFO Count

reg int_pending;
reg tx_empty;
reg rx_full;

assign wb_dat_o = (wb_adr_i[1:0] == 2'b00)? rbr :
                  (wb_adr_i[1:0] == 2'b01)? ier :
                  (wb_adr_i[1:0] == 2'b10)? iir :
                  (wb_adr_i[1:0] == 2'b11)? lcr :
                  (wb_adr_i[1:0] == 2'b00 && wb_adr_i[8] == 1'b1)? mcr :
                  (wb_adr_i[1:0] == 2'b01 && wb_adr_i[8] == 1'b1)? lsr :
                  (wb_adr_i[1:0] == 2'b10 && wb_adr_i[8] == 1'b1)? msr :
                  (wb_adr_i[1:0] == 2'b11 && wb_adr_i[8] == 1'b1)? scr :
                  (wb_adr_i[1:0] == 2'b00 && wb_adr_i[8] == 1'b0)? dll :
                  (wb_adr_i[1:0] == 2'b01 && wb_adr_i[8] == 1'b0)? dlm :
                  (wb_adr_i[1:0] == 2'b10 && wb_adr_i[8] == 1'b0)? fcr :
                  32'd0;

assign int_o = int_pending;
assign stx_pad_o = (tx_fifo_cnt > 0)? tx_fifo[tx_fifo_ptr] : 8'd0;
assign rts_pad_o = (tx_fifo_cnt > 0)? 1'b1 : 1'b0;
assign dtr_pad_o = (tx_fifo_cnt > 0)? 1'b1 : 1'b0;

always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if (wb_rst_i) begin
        rbr <= 32'd0;
        thr <= 32'd0;
        ier <= 32'd0;
        iir <= 32'd0;
        lcr <= 32'd0;
        mcr <= 32'd0;
        lsr <= 32'd0;
        msr <= 32'd0;
        scr <= 32'd0;
        dll <= 32'd0;
        dlm <= 32'd0;
        fcr <= 32'd0;
        rx_fifo_ptr <= 4'd0;
        tx_fifo_ptr <= 4'd0;
        rx_fifo_cnt <= 4'd0;
        tx_fifo_cnt <= 4'd0;
        int_pending <= 1'b0;
        tx_empty <= 1'b1;
        rx_full <= 1'b0;
    end else if (wb_stb_i && wb_cyc_i) begin
        if (wb_we_i) begin
            case (wb_adr_i[1:0])
                2'b00: rbr <= wb_dat_i;
                2'b01: ier <= wb_dat_i;
                2'b10: iir <= wb_dat_i;
                2'b11: lcr <= wb_dat_i;
            endcase
            if (wb_adr_i[8] == 1'b1) begin
                case (wb_adr_i[1:0])
                    2'b00: mcr <= wb_dat_i;
                    2'b01: lsr <= wb_dat_i;
                    2'b10: msr <= wb_dat_i;
                    2'b11: scr <= wb_dat_i;
                endcase
            end else begin
                case (wb_adr_i[1:0])
                    2'b00: dll <= wb_dat_i;
                    2'b01: dlm <= wb_dat_i;
                    2'b10: fcr <= wb_dat_i;
                endcase
            end
        end else begin
            case (wb_adr_i[1:0])
                2'b00: wb_dat_o <= rbr;
                2'b01: wb_dat_o <= ier;
                2'b10: wb_dat_o <= iir;
                2'b11: wb_dat_o <= lcr;
            endcase
            if (wb_adr_i[8] == 1'b1) begin
                case (wb_adr_i[1:0])
                    2'b00: wb_dat_o <= mcr;
                    2'b01: wb_dat_o <= lsr;
                    2'b10: wb_dat_o <= msr;
                    2'b11: wb_dat_o <= scr;
                endcase
            end else begin
                case (wb_adr_i[1:0])
                    2'b00: wb_dat_o <= dll;
                    2'b01: wb_dat_o <= dlm;
                    2'b10: wb_dat_o <= fcr;
                endcase
            end
        end
    end else begin
        // UART logic
        if (srx_pad_i == 1'b1) begin
            // Receive data
            if (rx_fifo_cnt < 16) begin
                rx_fifo[rx_fifo_ptr] <= srx_pad_i;
                rx_fifo_ptr <= rx_fifo_ptr + 1;
                rx_fifo_cnt <= rx_fifo_cnt + 1;
            end
        end
        if (tx_fifo_cnt > 0) begin
            // Transmit data
            stx_pad_o <= tx_fifo[tx_fifo_ptr];
            tx_fifo_ptr <= tx_fifo_ptr + 1;
            tx_fifo_cnt <= tx_fifo_cnt - 1;
        end
        if (cts_pad_i == 1'b1 && dsr_pad_i == 1'b1 && ri_pad_i == 1'b1 && dcd_pad_i == 1'b1) begin
            // Modem status
            msr <= {1'b0, cts_pad_i, dsr_pad_i, ri_pad_i, dcd_pad_i, 28'd0};
        end
        if (int_pending) begin
            // Interrupt handling
            int_o <= 1'b1;
        end
    end
end

always @(posedge wb_clk_i) begin
    if (wb_stb_i && wb_cyc_i && wb_we_i) begin
        wb_ack_o <= 1'b1;
    end else begin
        wb_ack_o <= 1'b0;
    end
end

endmodule
