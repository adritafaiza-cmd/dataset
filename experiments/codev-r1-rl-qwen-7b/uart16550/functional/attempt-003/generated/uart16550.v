module uart_top (
    // Wishbone interface
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire [31:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    input wire wb_we_i,
    input wire wb_stb_i,
    input wire wb_cyc_i,
    output reg wb_ack_o,
    input wire [3:0] wb_sel_i,

    // UART signals
    input wire srx_pad_i,
    output wire stx_pad_o,
    input wire cts_pad_i,
    output wire rts_pad_o,
    output wire dtr_pad_o,
    input wire dsr_pad_i,
    input wire ri_pad_i,
    input wire dcd_pad_i
);

    // Internal registers
    reg [7:0] data_reg; // Data register (TX/RX)
    reg [7:0] ier;      // Interrupt Enable Register
    reg [7:0] fcr;      // FIFO Control Register
    reg [7:0] lcr;      // Line Control Register
    reg [7:0] mcr;      // Modem Control Register
    reg [7:0] lsr;      // Line Status Register
    reg [7:0] msr;      // Modem Status Register
    reg [15:0] divisor; // Baud divisor

    // FIFOs
    reg [7:0] tx_fifo [0:15];
    reg [7:0] rx_fifo [0:15];
    reg [3:0] tx_wr_ptr, tx_rd_ptr;
    reg [3:0] rx_wr_ptr, rx_rd_ptr;
    reg tx_fifo_full, tx_fifo_empty;
    reg rx_fifo_full, rx_fifo_empty;

    // Baud generator
    reg [15:0] baud_counter;
    wire baud_tick = (baud_counter == divisor);

    // TX and RX state
    reg tx_busy;
    reg [3:0] tx_bit_cnt;
    reg [7:0] tx_data;
    reg stx_pad;

    reg rx_busy;
    reg [3:0] rx_bit_cnt;
    reg [7:0] rx_data;
    reg srx_sync;

    // Modem control
    assign rts_pad_o = mcr[1];
    assign dtr_pad_o = mcr[0];

    // Line status
    assign lsr[0] = ~rx_fifo_empty; // Data ready
    assign lsr[5] = tx_fifo_empty;  // THRE
    assign lsr[6] = tx_fifo_empty;  // TEMT

    // Interrupt
    wire int_o = ier[0] & lsr[0];

    // Loopback: connect TX to RX
    assign stx_pad_o = stx_pad;

    // Synchronize srx_pad_i
    always @(posedge wb_clk_i) begin
        srx_sync <= srx_pad_i;
    end

    // Wishbone handling
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            wb_ack_o <= 0;
            // Reset registers
            data_reg <= 0;
            ier <= 0;
            fcr <= 0;
            lcr <= 0;
            mcr <= 0;
            lsr <= 0;
            msr <= 0;
            divisor <= 0;
            tx_wr_ptr <= 0;
            tx_rd_ptr <= 0;
            rx_wr_ptr <= 0;
            rx_rd_ptr <= 0;
            tx_fifo_full <= 0;
            tx_fifo_empty <= 1;
            rx_fifo_full <= 0;
            rx_fifo_empty <= 1;
            baud_counter <= 0;
            tx_busy <= 0;
            rx_busy <= 0;
            stx_pad <= 1;
        end else begin
            wb_ack_o <= 0;

            // Handle Wishbone transactions
            if (wb_cyc_i && wb_stb_i && !wb_ack_o) begin
                wb_ack_o <= 1;

                if (wb_we_i) begin
                    case (wb_adr_i)
                        // Data register (0x00)
                        32'h00000000: data_reg <= wb_dat_i[7:0];
                        // IER (0x04)
                        32'h00000004: ier <= wb_dat_i[7:0];
                        // FCR (0x08)
                        32'h00000008: fcr <= wb_dat_i[7:0];
                        // LCR (0x0C)
                        32'h0000000C: lcr <= wb_dat_i[7:0];
                        // MCR (0x10)
                        32'h00000010: mcr <= wb_dat_i[7:0];
                        // Divisor (0x1C LSB, 0x20 MSB)
                        32'h0000001C: divisor[7:0] <= wb_dat_i[7:0];
                        32'h00000020: divisor[15:8] <= wb_dat_i[7:0];
                        default: ;
                    endcase
                end else begin
                    case (wb_adr_i)
                        32'h00000000: wb_dat_o <= {24'b0, data_reg};
                        32'h00000004: wb_dat_o <= {24'b0, ier};
                        32'h00000008: wb_dat_o <= {24'b0, fcr};
                        32'h0000000C: wb_dat_o <= {24'b0, lcr};
                        32'h00000010: wb_dat_o <= {24'b0, mcr};
                        32'h00000014: wb_dat_o <= {24'b0, lsr};
                        32'h00000018: wb_dat_o <= {24'b0, msr};
                        default: wb_dat_o <= 0;
                    endcase
                end
            end

            // TX FIFO write
            if (wb_we_i && wb_adr_i == 32'h00000000 && !tx_fifo_full) begin
                tx_fifo[tx_wr_ptr] <= data_reg;
                tx_wr_ptr <= tx_wr_ptr + 1;
                tx_fifo_full <= (tx_wr_ptr == tx_rd_ptr);
                tx_fifo_empty <= 0;
            end

            // TX state machine
            if (tx_busy) begin
                if (baud_tick) begin
                    if (tx_bit_cnt == 8) begin
                        tx_busy <= 0;
                        stx_pad <= 1;
                    end else begin
                        tx_bit_cnt <= tx_bit_cnt + 1;
                        stx_pad <= tx_data[tx_bit_cnt];
                    end
                end
            end else if (!tx_fifo_empty) begin
                tx_data <= tx_fifo[tx_rd_ptr];
                tx_rd_ptr <= tx_rd_ptr + 1;
                tx_fifo_empty <= (tx_rd_ptr == tx_wr_ptr);
                tx_busy <= 1;
                tx_bit_cnt <= 0;
                stx_pad <= 0; // Start bit
            end

            // RX state machine
            if (!rx_busy) begin
                if (srx_sync == 0) begin // Start bit detected
                    rx_busy <= 1;
                    rx_bit_cnt <= 0;
                end
            end else begin
                if (baud_tick) begin
                    if (rx_bit_cnt == 8) begin
                        rx_fifo[rx_wr_ptr] <= rx_data;
                        rx_wr_ptr <= rx_wr_ptr + 1;
                        rx_fifo_full <= (rx_wr_ptr == rx_rd_ptr);
                        rx_fifo_empty <= 0;
                        rx_busy <= 0;
                    end else begin
                        rx_data <= {srx_sync, rx_data[7:1]};
                        rx_bit_cnt <= rx_bit_cnt + 1;
                    end
                end
            end

            // Baud counter
            if (baud_tick)
                baud_counter <= 0;
            else
                baud_counter <= baud_counter + 1;
        end
    end

endmodule
