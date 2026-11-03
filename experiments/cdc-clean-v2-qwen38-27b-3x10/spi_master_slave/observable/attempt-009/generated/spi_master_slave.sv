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

    // SPI clock divider
    localparam SPI_CLK_DIV = SPI_2X_CLK_DIV;
    reg [3:0] spi_clk_cnt;
    wire spi_clk_en;
    wire spi_clk_pulse;

    // Generate SPI clock enable and pulse
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_clk_cnt <= 0;
        end else begin
            spi_clk_cnt <= spi_clk_cnt + 1;
        end
    end

    assign spi_clk_en = (spi_clk_cnt == SPI_CLK_DIV - 1);
    assign spi_clk_pulse = (spi_clk_cnt == SPI_CLK_DIV - 1);

    // SPI state machine
    localparam SPI_IDLE = 2'd0;
    localparam SPI_TX   = 2'd1;
    localparam SPI_RX   = 2'd2;

    reg [1:0] spi_state;
    reg [N-1:0] tx_shift;
    reg [N-1:0] rx_shift;
    reg [3:0] bit_cnt;
    reg spi_sck_reg;
    reg spi_ssel_reg;
    reg spi_mosi_reg;

    // Parallel side registers
    reg [N-1:0] tx_word;
    reg [N-1:0] rx_word;
    reg di_req_reg;
    reg wr_ack_reg;
    reg do_valid_reg;
    reg [N-1:0] do_reg;

    // Clock domain crossing: pclk to sclk
    reg [N-1:0] tx_word_sync1;
    reg [N-1:0] tx_word_sync2;
    reg tx_word_valid_sync1;
    reg tx_word_valid_sync2;
    reg tx_word_valid_sync3;

    // Clock domain crossing: sclk to pclk
    reg spi_done_sync1;
    reg spi_done_sync2;
    reg spi_done_sync3;
    reg [N-1:0] rx_word_sync1;
    reg [N-1:0] rx_word_sync2;
    reg [N-1:0] rx_word_sync3;

    // SPI clock domain logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_state <= SPI_IDLE;
            tx_shift <= 0;
            rx_shift <= 0;
            bit_cnt <= 0;
            spi_sck_reg <= 0;
            spi_ssel_reg <= 1;
            spi_mosi_reg <= 0;
            tx_word_sync1 <= 0;
            tx_word_sync2 <= 0;
            tx_word_valid_sync1 <= 0;
            tx_word_valid_sync2 <= 0;
            tx_word_valid_sync3 <= 0;
        end else begin
            // Synchronize tx_word and valid from pclk domain
            tx_word_sync1 <= tx_word;
            tx_word_sync2 <= tx_word_sync1;
            tx_word_valid_sync1 <= tx_word_valid_sync2;
            tx_word_valid_sync2 <= tx_word_valid_sync3;
            tx_word_valid_sync3 <= di_req_reg;

            case (spi_state)
                SPI_IDLE: begin
                    spi_sck_reg <= 0;
                    spi_ssel_reg <= 1;
                    spi_mosi_reg <= 0;
                    if (tx_word_valid_sync3) begin
                        spi_state <= SPI_TX;
                        tx_shift <= tx_word_sync2;
                        rx_shift <= 0;
                        bit_cnt <= 0;
                        spi_ssel_reg <= 0;
                        spi_mosi_reg <= tx_word_sync2[N-1];
                    end
                end
                SPI_TX: begin
                    if (spi_clk_en) begin
                        if (bit_cnt == N-1) begin
                            spi_state <= SPI_RX;
                            spi_sck_reg <= 0;
                        end else begin
                            spi_sck_reg <= ~spi_sck_reg;
                            if (spi_sck_reg) begin
                                // On rising edge of SCK, shift out next bit
                                tx_shift <= {tx_shift[N-2:0], 1'b0};
                                spi_mosi_reg <= tx_shift[N-2];
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end
                end
                SPI_RX: begin
                    if (spi_clk_en) begin
                        if (bit_cnt == N-1) begin
                            spi_state <= SPI_IDLE;
                            spi_ssel_reg <= 1;
                            spi_sck_reg <= 0;
                            spi_mosi_reg <= 0;
                        end else begin
                            spi_sck_reg <= ~spi_sck_reg;
                            if (spi_sck_reg) begin
                                // On rising edge of SCK, shift in MISO
                                rx_shift <= {spi_miso_i, rx_shift[N-1:1]};
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end
                end
                default: begin
                    spi_state <= SPI_IDLE;
                end
            endcase
        end
    end

    assign spi_ssel_o = spi_ssel_reg;
    assign spi_sck_o = spi_sck_reg;
    assign spi_mosi_o = spi_mosi_reg;

    // Detect SPI completion in sclk domain
    wire spi_done_pulse = (spi_state == SPI_IDLE) && (tx_word_valid_sync3 == 1'b0) && (tx_word_valid_sync2 == 1'b1);

    // Synchronize done and rx_word to pclk domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_done_sync1 <= 0;
            spi_done_sync2 <= 0;
            spi_done_sync3 <= 0;
            rx_word_sync1 <= 0;
            rx_word_sync2 <= 0;
            rx_word_sync3 <= 0;
        end else begin
            spi_done_sync1 <= spi_done_pulse;
            spi_done_sync2 <= spi_done_sync1;
            spi_done_sync3 <= spi_done_sync2;
            rx_word_sync1 <= rx_shift;
            rx_word_sync2 <= rx_word_sync1;
            rx_word_sync3 <= rx_word_sync2;
        end
    end

    // Parallel side logic in pclk domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_reg <= 1;
            wr_ack_reg <= 0;
            do_valid_reg <= 0;
            do_reg <= 0;
            tx_word <= 0;
        end else begin
            // Default: no ack, no valid
            wr_ack_reg <= 0;
            do_valid_reg <= 0;

            // Check for SPI completion
            if (spi_done_sync3) begin
                do_valid_reg <= 1;
                do_reg <= rx_word_sync3;
                di_req_reg <= 1;
            end

            // Accept new word if di_req is high and wren is asserted
            if (di_req_reg && wren_i) begin
                tx_word <= di_i;
                wr_ack_reg <= 1;
                di_req_reg <= 0;
            end
        end
    end

    assign di_req_o = di_req_reg;
    assign wr_ack_o = wr_ack_reg;
    assign do_valid_o = do_valid_reg;
    assign do_o = do_reg;

endmodule
