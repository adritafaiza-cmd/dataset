module spi_master #(
    parameter N = 8,
    parameter SPI_2X_CLK_DIV = 2
)(
    input              sclk_i,
    input              pclk_i,
    input              rst_i,
    output reg         spi_ssel_o,
    output reg         spi_sck_o,
    output             spi_mosi_o,
    input              spi_miso_i,
    output reg         di_req_o,
    input  [N-1:0]     di_i,
    input              wren_i,
    output reg         wr_ack_o,
    output reg         do_valid_o,
    output reg [N-1:0] do_o
);

    // SPI clock divider counter
    reg [31:0] clk_div_cnt;
    wire clk_div_tick = (clk_div_cnt == SPI_2X_CLK_DIV - 1);

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            clk_div_cnt <= 0;
        else if (clk_div_tick)
            clk_div_cnt <= 0;
        else
            clk_div_cnt <= clk_div_cnt + 1;
    end

    // SPI state machine
    localparam S_IDLE = 2'd0;
    localparam S_TX   = 2'd1;
    localparam S_RX   = 2'd2;

    reg [1:0] spi_state;
    reg [N-1:0] tx_shift;
    reg [N-1:0] rx_shift;
    reg [3:0] bit_cnt;
    reg sck_phase; // 0 = low, 1 = high

    // Parallel side registers
    reg [N-1:0] tx_word;
    reg [N-1:0] rx_word;
    reg tx_valid;
    reg rx_valid;

    // Clock domain crossing: sclk -> pclk
    reg [1:0] tx_valid_sync;
    reg [1:0] rx_valid_sync;
    reg [N-1:0] tx_word_sync;
    reg [N-1:0] rx_word_sync;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_valid_sync <= 2'b00;
            rx_valid_sync <= 2'b00;
            tx_word_sync <= {N{1'b0}};
            rx_word_sync <= {N{1'b0}};
        end else begin
            tx_valid_sync <= {tx_valid_sync[0], tx_valid};
            rx_valid_sync <= {rx_valid_sync[0], rx_valid};
            tx_word_sync <= tx_word;
            rx_word_sync <= rx_word;
        end
    end

    // Clock domain crossing: pclk -> sclk
    reg [1:0] wren_sync;
    reg [N-1:0] di_sync;
    reg wren_pulse;
    reg di_pulse;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            wren_sync <= 2'b00;
            di_sync <= {N{1'b0}};
            wren_pulse <= 1'b0;
            di_pulse <= 1'b0;
        end else begin
            wren_sync <= {wren_sync[0], wren_i};
            di_sync <= di_i;
            wren_pulse <= wren_sync[1] & ~wren_sync[0];
            di_pulse <= wren_sync[1] & ~wren_sync[0];
        end
    end

    // SPI outputs
    assign spi_mosi_o = tx_shift[N-1];

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_state <= S_IDLE;
            tx_shift <= {N{1'b0}};
            rx_shift <= {N{1'b0}};
            bit_cnt <= 4'd0;
            sck_phase <= 1'b0;
            tx_word <= {N{1'b0}};
            rx_word <= {N{1'b0}};
            tx_valid <= 1'b0;
            rx_valid <= 1'b0;
        end else begin
            case (spi_state)
                S_IDLE: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o <= 1'b0;
                    sck_phase <= 1'b0;
                    if (wren_pulse) begin
                        tx_word <= di_sync;
                        tx_shift <= di_sync;
                        bit_cnt <= 4'd0;
                        spi_ssel_o <= 1'b0;
                        spi_state <= S_TX;
                    end
                end
                S_TX: begin
                    if (clk_div_tick) begin
                        if (sck_phase == 1'b0) begin
                            // Rising edge: shift out MSB, sample MISO
                            spi_sck_o <= 1'b1;
                            sck_phase <= 1'b1;
                            rx_shift <= {rx_shift[N-2:0], spi_miso_i};
                            tx_shift <= {tx_shift[N-2:0], 1'b0};
                            bit_cnt <= bit_cnt + 1;
                            if (bit_cnt == N - 1) begin
                                spi_state <= S_RX;
                            end
                        end else begin
                            // Falling edge
                            spi_sck_o <= 1'b0;
                            sck_phase <= 1'b0;
                        end
                    end
                end
                S_RX: begin
                    if (clk_div_tick) begin
                        if (sck_phase == 1'b0) begin
                            spi_sck_o <= 1'b1;
                            sck_phase <= 1'b1;
                            rx_shift <= {rx_shift[N-2:0], spi_miso_i};
                            tx_shift <= {tx_shift[N-2:0], 1'b0};
                            bit_cnt <= bit_cnt + 1;
                            if (bit_cnt == N - 1) begin
                                spi_state <= S_IDLE;
                                rx_word <= rx_shift;
                                rx_valid <= 1'b1;
                            end
                        end else begin
                            spi_sck_o <= 1'b0;
                            sck_phase <= 1'b0;
                        end
                    end
                end
                default: begin
                    spi_state <= S_IDLE;
                end
            endcase

            // Clear rx_valid after one cycle
            if (rx_valid && spi_state != S_RX)
                rx_valid <= 1'b0;
        end
    end

    // Parallel side handshake
    reg di_req_int;
    reg wr_ack_int;
    reg do_valid_int;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 1'b1;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= {N{1'b0}};
            di_req_int <= 1'b1;
            wr_ack_int <= 1'b0;
            do_valid_int <= 1'b0;
        end else begin
            // di_req_o: high when idle and no pending transaction
            di_req_o <= di_req_int;

            // wr_ack_o: pulse when accepting a new word
            wr_ack_o <= wr_ack_int;

            // do_valid_o: pulse when a received word is ready
            do_valid_o <= do_valid_int;

            // Update internal flags
            if (rx_valid_sync[1] & ~rx_valid_sync[0]) begin
                do_valid_int <= 1'b1;
                do_o <= rx_word_sync;
            end else begin
                do_valid_int <= 1'b0;
            end

            if (wren_i & di_req_int) begin
                wr_ack_int <= 1'b1;
                di_req_int <= 1'b0;
            end else begin
                wr_ack_int <= 1'b0;
            end

            // di_req_int goes high when SPI is back to idle
            if (spi_state == S_IDLE && !wren_i) begin
                di_req_int <= 1'b1;
            end
        end
    end

endmodule
