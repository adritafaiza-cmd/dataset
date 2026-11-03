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
    wire spi_clk_toggle;

    assign spi_clk_en = (spi_clk_cnt == SPI_CLK_DIV - 1);
    assign spi_clk_toggle = spi_clk_en;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            spi_clk_cnt <= 0;
        else if (spi_clk_en)
            spi_clk_cnt <= 0;
        else
            spi_clk_cnt <= spi_clk_cnt + 1;
    end

    // SPI state machine
    localparam S_IDLE = 2'd0;
    localparam S_TX   = 2'd1;
    localparam S_RX   = 2'd2;

    reg [1:0] spi_state;
    reg [N-1:0] tx_shift;
    reg [N-1:0] rx_shift;
    reg [3:0] bit_cnt;
    reg spi_sck_reg;
    reg spi_ssel_reg;
    reg spi_mosi_reg;

    // Handshake signals from SPI domain to parallel domain
    reg spi_wr_ack_pulse;
    reg spi_do_valid_pulse;
    reg [N-1:0] spi_do_data;

    // Parallel domain registers
    reg p_di_req;
    reg p_wr_ack;
    reg p_do_valid;
    reg [N-1:0] p_do_data;
    reg [N-1:0] p_tx_word;
    reg p_tx_valid;

    // Synchronizers for SPI domain signals to parallel domain
    reg [1:0] sync_wr_ack;
    reg [1:0] sync_do_valid;
    reg [N-1:0] sync_do_data;
    reg [N-1:0] sync_do_data_d1;

    // Synchronizers for parallel domain signals to SPI domain
    reg [1:0] sync_p_tx_valid;
    reg [N-1:0] sync_p_tx_word;
    reg [N-1:0] sync_p_tx_word_d1;

    // SPI domain: detect rising edge of p_tx_valid
    reg p_tx_valid_sync_d1;
    wire p_tx_valid_rise;

    // Parallel domain: detect rising edge of spi_wr_ack and spi_do_valid
    reg sync_wr_ack_d1;
    reg sync_do_valid_d1;
    wire wr_ack_rise;
    wire do_valid_rise;

    // SPI domain logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_state <= S_IDLE;
            tx_shift <= {N{1'b0}};
            rx_shift <= {N{1'b0}};
            bit_cnt <= 0;
            spi_sck_reg <= 1'b0;
            spi_ssel_reg <= 1'b1;
            spi_mosi_reg <= 1'b0;
            spi_wr_ack_pulse <= 1'b0;
            spi_do_valid_pulse <= 1'b0;
            spi_do_data <= {N{1'b0}};
            p_tx_valid_sync_d1 <= 1'b0;
        end else begin
            spi_wr_ack_pulse <= 1'b0;
            spi_do_valid_pulse <= 1'b0;

            // Synchronize p_tx_valid
            p_tx_valid_sync_d1 <= sync_p_tx_valid[1];
            p_tx_valid_rise = sync_p_tx_valid[1] & ~p_tx_valid_sync_d1;

            case (spi_state)
                S_IDLE: begin
                    spi_sck_reg <= 1'b0;
                    spi_ssel_reg <= 1'b1;
                    spi_mosi_reg <= 1'b0;
                    if (p_tx_valid_rise) begin
                        spi_state <= S_TX;
                        tx_shift <= sync_p_tx_word[1];
                        bit_cnt <= 0;
                        spi_ssel_reg <= 1'b0;
                        spi_mosi_reg <= sync_p_tx_word[1][N-1];
                        spi_wr_ack_pulse <= 1'b1;
                    end
                end
                S_TX: begin
                    if (spi_clk_toggle) begin
                        if (bit_cnt == N-1) begin
                            spi_state <= S_RX;
                            rx_shift <= {spi_miso_i, rx_shift[N-1:1]};
                            bit_cnt <= 0;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                            spi_mosi_reg <= tx_shift[N-2-bit_cnt];
                            spi_sck_reg <= ~spi_sck_reg;
                        end
                    end
                end
                S_RX: begin
                    if (spi_clk_toggle) begin
                        if (bit_cnt == N-1) begin
                            spi_state <= S_IDLE;
                            spi_ssel_reg <= 1'b1;
                            spi_sck_reg <= 1'b0;
                            spi_mosi_reg <= 1'b0;
                            spi_do_data <= rx_shift;
                            spi_do_valid_pulse <= 1'b1;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                            rx_shift <= {spi_miso_i, rx_shift[N-1:1]};
                            spi_sck_reg <= ~spi_sck_reg;
                        end
                    end
                end
                default: begin
                    spi_state <= S_IDLE;
                end
            endcase
        end
    end

    assign spi_ssel_o = spi_ssel_reg;
    assign spi_sck_o = spi_sck_reg;
    assign spi_mosi_o = spi_mosi_reg;

    // Synchronize SPI domain signals to parallel domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            sync_wr_ack <= 2'b00;
            sync_do_valid <= 2'b00;
            sync_do_data <= {N{1'b0}};
            sync_do_data_d1 <= {N{1'b0}};
            sync_p_tx_valid <= 2'b00;
            sync_p_tx_word <= {N{1'b0}};
            sync_p_tx_word_d1 <= {N{1'b0}};
        end else begin
            sync_wr_ack <= {sync_wr_ack[0], spi_wr_ack_pulse};
            sync_do_valid <= {sync_do_valid[0], spi_do_valid_pulse};
            sync_do_data <= spi_do_data;
            sync_do_data_d1 <= sync_do_data;
            sync_p_tx_valid <= {sync_p_tx_valid[0], p_tx_valid};
            sync_p_tx_word <= p_tx_word;
            sync_p_tx_word_d1 <= sync_p_tx_word;
        end
    end

    // Parallel domain logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            p_di_req <= 1'b0;
            p_wr_ack <= 1'b0;
            p_do_valid <= 1'b0;
            p_do_data <= {N{1'b0}};
            p_tx_word <= {N{1'b0}};
            p_tx_valid <= 1'b0;
            sync_wr_ack_d1 <= 1'b0;
            sync_do_valid_d1 <= 1'b0;
        end else begin
            p_wr_ack <= 1'b0;
            p_do_valid <= 1'b0;

            sync_wr_ack_d1 <= sync_wr_ack[1];
            sync_do_valid_d1 <= sync_do_valid[1];
            wr_ack_rise = sync_wr_ack[1] & ~sync_wr_ack_d1;
            do_valid_rise = sync_do_valid[1] & ~sync_do_valid_d1;

            if (do_valid_rise) begin
                p_do_valid <= 1'b1;
                p_do_data <= sync_do_data_d1;
                p_di_req <= 1'b1;
                p_tx_valid <= 1'b0;
            end else if (wr_ack_rise) begin
                p_wr_ack <= 1'b1;
                p_di_req <= 1'b0;
            end else if (p_di_req && wren_i) begin
                p_tx_word <= di_i;
                p_tx_valid <= 1'b1;
                p_di_req <= 1'b0;
            end
        end
    end

    assign di_req_o = p_di_req;
    assign wr_ack_o = p_wr_ack;
    assign do_valid_o = p_do_valid;
    assign do_o = p_do_data;

endmodule
