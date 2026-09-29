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

    // Internal registers and wires
    reg         ack;
    assign wb_ack_o = ack;

    // Wishbone read data
    reg [31:0] wb_dat_o_reg;
    assign wb_dat_o = wb_dat_o_reg;

    // Line Control Register (LCR)
    reg [7:0] lcr_reg;
    wire dlab = lcr_reg[7];

    // Baud rate divisor
    reg [15:0] divisor_reg;

    // Transmitter
    reg [7:0] tx_shift;
    reg [3:0] tx_count;
    reg tx_busy;
    reg tx_start;
    reg tx_parity;
    reg [15:0] baud_counter_tx;
    wire baud_tick_tx = (baud_counter_tx == 0);

    // Receiver
    reg [7:0] rx_shift;
    reg [3:0] rx_count;
    reg rx_busy;
    reg rx_parity;
    reg rx_parity_error;
    reg [15:0] baud_counter_rx;
    wire baud_tick_rx = (baud_counter_rx == 0);

    // Line Status Register (LSR)
    reg [7:0] lsr_reg;

    // Modem Control Register (MCR)
    reg [7:0] mcr_reg;
    assign dtr_pad_o = mcr_reg[0];
    assign rts_pad_o = mcr_reg[1];

    // Modem Status Register (MSR)
    reg [7:0] msr_reg;

    // Interrupt Enable Register (IER)
    reg [7:0] ier_reg;

    // Data Register (DR)
    reg [7:0] data_reg;

    // FIFOs
    reg [7:0] tx_fifo [0:15];
    reg [7:0] rx_fifo [0:15];
    reg [3:0] tx_wr_ptr, tx_rd_ptr;
    reg [3:0] rx_wr_ptr, rx_rd_ptr;

    // Baud rate generator
    reg [15:0] baud_counter;

    // Transmitter FSM
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            tx_busy <= 0;
            tx_count <= 0;
            tx_shift <= 0;
            tx_parity <= 0;
            baud_counter_tx <= 0;
            stx_pad_o <= 1;
        end else begin
            if (tx_start && !tx_busy) begin
                tx_busy <= 1;
                tx_shift <= data_reg;
                tx_parity <= ^data_reg;
                tx_count <= 0;
                baud_counter_tx <= divisor_reg;
                stx_pad_o <= 0; // Start bit
            end else if (tx_busy) begin
                if (baud_tick_tx) begin
                    if (tx_count == 10) begin // 1 start, 8 data, 1 parity, 1 stop
                        tx_busy <= 0;
                        stx_pad_o <= 1;
                    end else begin
                        tx_count <= tx_count + 1;
                        baud_counter_tx <= divisor_reg;
                        if (tx_count == 0) begin
                            stx_pad_o <= 0; // Start bit
                        end else if (tx_count <= 8) begin
                            stx_pad_o <= tx_shift[tx_count-1];
                        end else if (tx_count == 9) begin
                            stx_pad_o <= tx_parity;
                        end else begin
                            stx_pad_o <= 1; // Stop bit
                        end
                    end
                end else begin
                    baud_counter_tx <= baud_counter_tx - 1;
                end
            end
        end
    end

    // Receiver FSM
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            rx_busy <= 0;
            rx_count <= 0;
            rx_shift <= 0;
            rx_parity <= 0;
            baud_counter_rx <= 0;
            srx_pad_i <= 1;
        end else begin
            if (!rx_busy && srx_pad_i == 0) begin // Start bit detected
                rx_busy <= 1;
                rx_count <= 0;
                baud_counter_rx <= divisor_reg;
            end else if (rx_busy) begin
                if (baud_tick_rx) begin
                    if (rx_count == 10) begin // 1 start, 8 data, 1 parity, 1 stop
                        rx_busy <= 0;
                        rx_parity_error <= ^rx_shift != rx_parity;
                        rx_fifo[rx_wr_ptr] <= rx_shift;
                        rx_wr_ptr <= rx_wr_ptr + 1;
                        lsr_reg[0] <= 1; // Data ready
                    end else begin
                        rx_count <= rx_count + 1;
                        baud_counter_rx <= divisor_reg;
                        if (rx_count == 0) begin
                            // Start bit
                        end else if (rx_count <= 8) begin
                            rx_shift <= {srx_pad_i, rx_shift[7:1]};
                        end else if (rx_count == 9) begin
                            rx_parity <= srx_pad_i;
                        end
                    end
                end else begin
                    baud_counter_rx <= baud_counter_rx - 1;
                end
            end
        end
    end

    // Wishbone write handling
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            ack <= 0;
            lcr_reg <= 0;
            divisor_reg <= 0;
            mcr_reg <= 0;
            ier_reg <= 0;
            data_reg <= 0;
            tx_wr_ptr <= 0;
            tx_rd_ptr <= 0;
            rx_wr_ptr <= 0;
            rx_rd_ptr <= 0;
            lsr_reg <= 8'h60; // Default line status
        end else begin
            ack <= 0;
            if (wb_stb_i && wb_cyc_i) begin
                ack <= 1;
                if (wb_we_i) begin
                    if (dlab) begin
                        if (wb_adr_i == 32'h00) divisor_reg[7:0] <= wb_dat_i[7:0];
                        else if (wb_adr_i == 32'h04) divisor_reg[15:8] <= wb_dat_i[7:0];
                        else if (wb_adr_i == 32'h08) ier_reg <= wb_dat_i[7:0];
                        else if (wb_adr_i == 32'h10) lcr_reg <= wb_dat_i[7:0];
                        else if (wb_adr_i == 32'h14) mcr_reg <= wb_dat_i[7:0];
                    end else begin
                        case (wb_adr_i)
                            32'h00: begin
                                data_reg <= wb_dat_i[7:0];
                                tx_start <= 1;
                            end
                            32'h04: ier_reg <= wb_dat_i[7:0];
                            32'h08: lcr_reg <= wb_dat_i[7:0];
                            32'h10: mcr_reg <= wb_dat_i[7:0];
                            // Other registers...
                        endcase
                    end
                end else begin
                    case (wb_adr_i)
                        32'h00: wb_dat_o_reg <= {24'h0, data_reg};
                        32'h04: wb_dat_o_reg <= {24'h0, ier_reg};
                        32'h08: wb_dat_o_reg <= {24'h0, lcr_reg};
                        32'h10: wb_dat_o_reg <= {24'h0, mcr_reg};
                        // Other registers...
                    endcase
                end
            end
        end
    end

    // Interrupt logic
    assign int_o = (lsr_reg[0] && ier_reg[0]);

endmodule
