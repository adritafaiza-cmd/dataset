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
    reg [7:0] data_reg; // Data buffer
    reg [7:0] ier;      // Interrupt Enable Register
    reg [7:0] fcr;      // FIFO Control Register
    reg [7:0] lcr;      // Line Control Register
    reg [7:0] mcr;      // Modem Control Register
    reg [7:0] lsr;      // Line Status Register
    reg [7:0] msr;      // Modem Status Register
    reg [7:0] scratch;  // Scratchpad

    // Divisor Latch
    reg [15:0] divisor;
    reg dlab_dll;

    // FIFOs
    reg [7:0] tx_fifo [0:15];
    reg [7:0] rx_fifo [0:15];
    reg [3:0] tx_wr_ptr, tx_rd_ptr;
    reg [3:0] rx_wr_ptr, rx_rd_ptr;

    // Baud rate generator
    reg [15:0] baud_counter;
    wire baud_tick = (baud_counter == 0);

    // Transmitter
    reg tx_busy;
    reg [3:0] tx_bit_count;
    reg [7:0] tx_data;
    reg stx_pad;

    // Receiver
    reg rx_busy;
    reg [3:0] rx_bit_count;
    reg [7:0] rx_data;

    // Wishbone ack
    reg wb_ack;

    // Address decoding
    wire [2:0] reg_addr = wb_adr_i[2:0];

    // Wishbone read data
    reg [31:0] wb_dat_o_reg;

    // Wishbone ack generation
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            wb_ack <= 0;
        end else begin
            wb_ack <= wb_cyc_i & wb_stb_i & !wb_ack;
        end
    end

    assign wb_ack_o = wb_ack;

    // Wishbone read
    always @* begin
        case (reg_addr)
            3'h0: wb_dat_o_reg = {24'b0, data_reg};
            3'h1: wb_dat_o_reg = {24'b0, ier};
            3'h2: wb_dat_o_reg = {24'b0, fcr};
            3'h3: wb_dat_o_reg = {24'b0, lcr};
            3'h4: wb_dat_o_reg = {24'b0, mcr};
            3'h5: wb_dat_o_reg = {24'b0, lsr};
            3'h6: wb_dat_o_reg = {24'b0, msr};
            3'h7: wb_dat_o_reg = {24'b0, scratch};
            default: wb_dat_o_reg = 32'b0;
        endcase
    end

    assign wb_dat_o = wb_dat_o_reg;

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
            scratch <= 0;
            divisor <= 0;
            dlab_dll <= 0;
            tx_wr_ptr <= 0;
            tx_rd_ptr <= 0;
            rx_wr_ptr <= 0;
            rx_rd_ptr <= 0;
            baud_counter <= 0;
            tx_busy <= 0;
            rx_busy <= 0;
        end else if (wb_cyc_i && wb_stb_i && wb_we_i && !wb_ack) begin
            case (reg_addr)
                3'h0: begin
                    if (lcr[7]) begin // DLAB active
                        if (dlab_dll) begin
                            divisor[15:8] <= wb_dat_i;
                            dlab_dll <= 0;
                        end else begin
                            divisor[7:0] <= wb_dat_i;
                            dlab_dll <= 1;
                        end
                    end else begin
                        data_reg <= wb_dat_i;
                    end
                end
                3'h1: ier <= wb_dat_i;
                3'h2: fcr <= wb_dat_i;
                3'h3: lcr <= wb_dat_i;
                3'h4: mcr <= wb_dat_i;
                3'h5: lsr <= wb_dat_i; // Not writable
                3'h6: msr <= wb_dat_i; // Not writable
                3'h7: scratch <= wb_dat_i;
            endcase
        end
    end

    // Baud rate generation
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            baud_counter <= 0;
        end else if (baud_tick) begin
            baud_counter <= divisor;
        end else begin
            baud_counter <= baud_counter - 1;
        end
    end

    // Transmitter state machine
    // Simplified for brevity; actual implementation requires more states
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            tx_busy <= 0;
            stx_pad <= 1;
        end else if (baud_tick && !tx_busy) begin
            // Start transmission logic
            tx_busy <= 1;
            stx_pad <= 0; // Start bit
        end else if (tx_busy) begin
            // Transmit data bits
            if (tx_bit_count == 8) begin
                stx_pad <= 1; // Stop bit
                tx_busy <= 0;
            end
        end
    end

    // Receiver state machine
    // Simplified for brevity
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            rx_busy <= 0;
        end else if (srx_pad_i == 0 && !rx_busy) begin
            // Start bit detected
            rx_busy <= 1;
            rx_bit_count <= 0;
        end else if (rx_busy) begin
            // Sample data bits
            if (rx_bit_count == 8) begin
                rx_busy <= 0;
                data_reg <= rx_data;
            end
        end
    end

    // Modem signals
    assign rts_pad_o = mcr[1];
    assign dtr_pad_o = mcr[0];

    // Line status
    always @* begin
        lsr[5] = (tx_fifo[tx_wr_ptr] == tx_rd_ptr); // THRE
        lsr[0] = (rx_wr_ptr != rx_rd_ptr); // DR
    end

    // Interrupt logic
    assign int_o = (lsr[5] & ier[0]) | (lsr[0] & ier[1]);

    // Serial output
    assign stx_pad_o = stx_pad;

endmodule
