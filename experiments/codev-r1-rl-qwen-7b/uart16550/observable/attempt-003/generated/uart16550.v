module uart_top (
    // Wishbone interface
    input         wb_clk_i,
    input         wb_rst_i,
    input  [31:0] wb_adr_i,
    input  [31:0] wb_dat_i,
    output [31:0] wb_dat_o,
    input         wb_we_i,
    input         wb_stb_i,
    input         wb_cyc_i,
    output        wb_ack_o,
    input  [3:0]  wb_sel_i,

    // Interrupt
    output        int_o,

    // Serial
    output        stx_pad_o,
    input         srx_pad_i,

    // Modem
    output        rts_pad_o,
    input         cts_pad_i,
    output        dtr_pad_o,
    input         dsr_pad_i,
    input         ri_pad_i,
    input         dcd_pad_i
);

    // Registers
    reg [7:0] data_reg; // Data register
    reg [7:0] ier;      // Interrupt Enable Register
    reg [7:0] fcr;      // FIFO Control Register
    reg [7:0] lcr;      // Line Control Register
    reg [7:0] mcr;      // Modem Control Register
    reg [7:0] lsr;      // Line Status Register
    reg [7:0] msr;      // Modem Status Register
    reg [15:0] dll;     // Divisor Latch (LSB)
    reg [15:0] dlm;     // Divisor Latch (MSB)

    // FIFOs
    reg [7:0] tx_fifo [0:15];
    reg [3:0] tx_head, tx_tail;
    reg [7:0] rx_fifo [0:15];
    reg [3:0] rx_head, rx_tail;

    // Baud rate generation
    reg [15:0] baud_counter;
    wire baud_tick = (baud_counter == 0);

    // Transmitter
    reg tx_busy;
    reg [3:0] tx_bit;
    reg [7:0] tx_shift;
    reg stx_pad;

    // Receiver
    reg rx_busy;
    reg [3:0] rx_bit;
    reg [7:0] rx_shift;
    reg srx_sync;

    // Modem signals
    assign rts_pad_o = mcr[1];
    assign dtr_pad_o = mcr[0];

    // Modem status
    assign msr[4] = cts_pad_i;
    assign msr[5] = dsr_pad_i;
    assign msr[6] = ri_pad_i;
    assign msr[7] = dcd_pad_i;

    // Line status
    assign lsr[0] = ~rx_fifo_empty;
    assign lsr[5] = tx_fifo_empty;
    assign lsr[6] = tx_fifo_empty;

    // Interrupt
    wire int_cond = (lsr[0] & ier[0]) | (lsr[5] & ier[1]) | (lsr[6] & ier[2]) | (lsr[3] & ier[3]);
    assign int_o = int_cond;

    // FIFO status
    wire tx_fifo_empty = (tx_head == tx_tail);
    wire tx_fifo_full = ((tx_head + 1) % 16 == tx_tail);
    wire rx_fifo_empty = (rx_head == rx_tail);

    // Wishbone ack
    reg wb_ack;
    assign wb_ack_o = wb_ack;

    // Synchronize srx_pad_i
    reg srx_sync1, srx_sync2;
    always @(posedge wb_clk_i) begin
        srx_sync1 <= srx_pad_i;
        srx_sync2 <= srx_sync1;
    end

    // Transmitter logic
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            tx_busy <= 0;
            tx_bit <= 0;
            tx_shift <= 0;
            stx_pad <= 1;
        end else begin
            if (tx_busy) begin
                if (baud_tick) begin
                    if (tx_bit == 9) begin
                        stx_pad <= 1;
                        tx_busy <= 0;
                    end else begin
                        stx_pad <= tx_shift[tx_bit];
                        tx_bit <= tx_bit + 1;
                    end
                end
            end else if (!tx_fifo_empty) begin
                tx_shift <= tx_fifo[tx_tail];
                tx_tail <= tx_tail + 1;
                tx_bit <= 0;
                tx_busy <= 1;
                stx_pad <= 0;
            end
        end
    end

    // Receiver logic
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            rx_busy <= 0;
            rx_bit <= 0;
            rx_shift <= 0;
        end else begin
            if (rx_busy) begin
                if (baud_tick) begin
                    if (rx_bit == 9) begin
                        rx_fifo[rx_head] <= rx_shift;
                        rx_head <= rx_head + 1;
                        rx_busy <= 0;
                    end else begin
                        rx_shift[rx_bit] <= srx_sync2;
                        rx_bit <= rx_bit + 1;
                    end
                end
            end else begin
                if (!srx_sync2) begin
                    rx_shift <= 0;
                    rx_bit <= 0;
                    rx_busy <= 1;
                end
            end
        end
    end

    // Baud rate generation
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            baud_counter <= 0;
        end else begin
            if (baud_tick)
                baud_counter <= dll | (dlm << 8);
            else
                baud_counter <= baud_counter - 1;
        end
    end

    // Wishbone write
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            data_reg <= 0;
            ier <= 0;
            fcr <= 0;
            lcr <= 0;
            mcr <= 0;
            lsr <= 0;
            msr <= 0;
            dll <= 0;
            dlm <= 0;
            tx_head <= 0;
            tx_tail <= 0;
            rx_head <= 0;
            rx_tail <= 0;
        end else if (wb_stb_i && wb_cyc_i && wb_we_i) begin
            case (wb_adr_i)
                32'h00: begin // Data
                    if (lcr[7]) begin // DLAB
                        if (wb_adr_i[2])
                            dlm <= wb_dat_i[15:8];
                        else
                            dll <= wb_dat_i[7:0];
                    end else if (!tx_fifo_full) begin
                        tx_fifo[tx_head] <= wb_dat_i[7:0];
                        tx_head <= tx_head + 1;
                    end
                end
                32'h04: ier <= wb_dat_i[7:0];
                32'h08: fcr <= wb_dat_i[7:0];
                32'h0C: lcr <= wb_dat_i[7:0];
                32'h10: mcr <= wb_dat_i[7:0];
                // Additional registers can be added here
            endcase
        end
    end

    // Wishbone read
    reg [31:0] wb_dat_o_reg;
    assign wb_dat_o = wb_dat_o_reg;

    always @* begin
        case (wb_adr_i)
            32'h00: wb_dat_o_reg = {24'b0, data_reg};
            32'h04: wb_dat_o_reg = {24'b0, ier};
            32'h08: wb_dat_o_reg = {24'b0, fcr};
            32'h0C: wb_dat_o_reg = {24'b0, lcr};
            32'h10: wb_dat_o_reg = {24'b0, mcr};
            32'h14: wb_dat_o_reg = {24'b0, lsr};
            32'h18: wb_dat_o_reg = {24'b0, msr};
            32'h20: wb_dat_o_reg = {16'b0, dll};
            32'h24: wb_dat_o_reg = {16'b0, dlm};
            default: wb_dat_o_reg = 32'h0;
        endcase
    end

    // Wishbone ack generation
    always @(posedge wb_clk_i) begin
        wb_ack <= wb_stb_i && wb_cyc_i;
    end

    // Assign serial output
    assign stx_pad_o = stx_pad;

endmodule
