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
    reg [31:0] spi_clk_cnt;
    wire spi_clk_edge;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            spi_clk_cnt <= 0;
        else
            spi_clk_cnt <= spi_clk_cnt + 1;
    end

    assign spi_clk_edge = (spi_clk_cnt == SPI_CLK_DIV - 1);

    // SPI state machine
    localparam S_IDLE = 0;
    localparam S_TX   = 1;
    localparam S_RX   = 2;

    reg [1:0] spi_state;
    reg [N-1:0] tx_shift;
    reg [N-1:0] rx_shift;
    reg [31:0] bit_cnt;
    reg spi_sck_reg;
    reg spi_ssel_reg;
    reg spi_mosi_reg;

    // Parallel side handshake
    reg di_req_reg;
    reg wr_ack_reg;
    reg do_valid_reg;
    reg [N-1:0] do_reg;
    reg [N-1:0] pending_word;
    reg pending_valid;

    // Clock domain crossing: pclk to sclk
    reg [N-1:0] pclk_word_sync1;
    reg [N-1:0] pclk_word_sync2;
    reg pclk_wren_sync1;
    reg pclk_wren_sync2;
    reg pclk_wren_sync3;
    reg pclk_wr_ack_sync1;
    reg pclk_wr_ack_sync2;
    reg pclk_do_valid_sync1;
    reg pclk_do_valid_sync2;
    reg [N-1:0] pclk_do_sync1;
    reg [N-1:0] pclk_do_sync2;

    // pclk domain: synchronize sclk signals
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_word_sync1 <= 0;
            pclk_word_sync2 <= 0;
            pclk_wren_sync1 <= 0;
            pclk_wren_sync2 <= 0;
            pclk_wren_sync3 <= 0;
            pclk_wr_ack_sync1 <= 0;
            pclk_wr_ack_sync2 <= 0;
            pclk_do_valid_sync1 <= 0;
            pclk_do_valid_sync2 <= 0;
            pclk_do_sync1 <= 0;
            pclk_do_sync2 <= 0;
        end else begin
            pclk_word_sync1 <= pending_word;
            pclk_word_sync2 <= pclk_word_sync1;
            pclk_wren_sync1 <= pending_valid;
            pclk_wren_sync2 <= pclk_wren_sync1;
            pclk_wren_sync3 <= pclk_wren_sync2;
            pclk_wr_ack_sync1 <= wr_ack_reg;
            pclk_wr_ack_sync2 <= pclk_wr_ack_sync1;
            pclk_do_valid_sync1 <= do_valid_reg;
            pclk_do_valid_sync2 <= pclk_do_valid_sync1;
            pclk_do_sync1 <= do_reg;
            pclk_do_sync2 <= pclk_do_sync1;
        end
    end

    // sclk domain: synchronize pclk signals
    reg [N-1:0] sclk_di_sync1;
    reg [N-1:0] sclk_di_sync2;
    reg sclk_wren_sync1;
    reg sclk_wren_sync2;
    reg sclk_wren_sync3;
    reg sclk_di_req_sync1;
    reg sclk_di_req_sync2;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_di_sync1 <= 0;
            sclk_di_sync2 <= 0;
            sclk_wren_sync1 <= 0;
            sclk_wren_sync2 <= 0;
            sclk_wren_sync3 <= 0;
            sclk_di_req_sync1 <= 0;
            sclk_di_req_sync2 <= 0;
        end else begin
            sclk_di_sync1 <= di_i;
            sclk_di_sync2 <= sclk_di_sync1;
            sclk_wren_sync1 <= wren_i;
            sclk_wren_sync2 <= sclk_wren_sync1;
            sclk_wren_sync3 <= sclk_wren_sync2;
            sclk_di_req_sync1 <= di_req_reg;
            sclk_di_req_sync2 <= sclk_di_req_sync1;
        end
    end

    // pclk domain: generate outputs
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 1;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            do_o <= 0;
        end else begin
            di_req_o <= sclk_di_req_sync2;
            wr_ack_o <= pclk_wr_ack_sync1 & ~pclk_wr_ack_sync2;
            do_valid_o <= pclk_do_valid_sync1 & ~pclk_do_valid_sync2;
            do_o <= pclk_do_sync2;
        end
    end

    // sclk domain: SPI state machine
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_state <= S_IDLE;
            tx_shift <= 0;
            rx_shift <= 0;
            bit_cnt <= 0;
            spi_sck_reg <= 0;
            spi_ssel_reg <= 1;
            spi_mosi_reg <= 0;
            di_req_reg <= 1;
            wr_ack_reg <= 0;
            do_valid_reg <= 0;
            do_reg <= 0;
            pending_word <= 0;
            pending_valid <= 0;
        end else begin
            // Default: clear single-cycle pulses
            wr_ack_reg <= 0;
            do_valid_reg <= 0;

            case (spi_state)
                S_IDLE: begin
                    spi_sck_reg <= 0;
                    spi_ssel_reg <= 1;
                    spi_mosi_reg <= 0;
                    bit_cnt <= 0;
                    if (sclk_wren_sync3 & sclk_di_req_sync2) begin
                        // Accept new word
                        pending_word <= sclk_di_sync2;
                        pending_valid <= 1;
                        tx_shift <= sclk_di_sync2;
                        rx_shift <= 0;
                        bit_cnt <= 0;
                        spi_ssel_reg <= 0;
                        spi_state <= S_TX;
                        di_req_reg <= 0;
                        wr_ack_reg <= 1;
                    end else begin
                        di_req_reg <= 1;
                    end
                end

                S_TX: begin
                    if (spi_clk_edge) begin
                        if (bit_cnt == N - 1) begin
                            spi_sck_reg <= 0;
                            spi_state <= S_RX;
                            bit_cnt <= 0;
                        end else begin
                            spi_sck_reg <= ~spi_sck_reg;
                            if (spi_sck_reg == 0) begin
                                // Rising edge: shift out next bit
                                spi_mosi_reg <= tx_shift[0];
                                tx_shift <= {1'b0, tx_shift[N-1:1]};
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end
                end

                S_RX: begin
                    if (spi_clk_edge) begin
                        if (bit_cnt == N - 1) begin
                            spi_sck_reg <= 0;
                            spi_ssel_reg <= 1;
                            spi_state <= S_IDLE;
                            bit_cnt <= 0;
                            do_reg <= rx_shift;
                            do_valid_reg <= 1;
                            pending_valid <= 0;
                        end else begin
                            spi_sck_reg <= ~spi_sck_reg;
                            if (spi_sck_reg == 1) begin
                                // Falling edge: sample MISO
                                rx_shift <= {spi_miso_i, rx_shift[N-1:1]};
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end
                end

                default: begin
                    spi_state <= S_IDLE;
                    spi_ssel_reg <= 1;
                    spi_sck_reg <= 0;
                end
            endcase
        end
    end

    assign spi_ssel_o = spi_ssel_reg;
    assign spi_sck_o = spi_sck_reg;
    assign spi_mosi_o = spi_mosi_reg;

endmodule
