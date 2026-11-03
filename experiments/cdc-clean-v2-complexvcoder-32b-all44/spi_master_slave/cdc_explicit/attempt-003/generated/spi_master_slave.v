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

    // Internal signals
    reg [N-1:0] tx_data_sync;
    reg [N-1:0] rx_data_sync;
    reg [N-1:0] shift_reg;
    reg [N-1:0] rx_shift_reg;
    reg [$clog2(N):0] bit_cnt;
    reg tx_start;
    reg tx_done;
    reg rx_done;
    reg sclk_rst;
    reg pclk_rst;
    reg spi_clk_div;

    // Reset synchronizers
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            sclk_rst <= 1'b1;
        else
            sclk_rst <= 1'b0;
    end

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            pclk_rst <= 1'b1;
        else
            pclk_rst <= 1'b0;
    end

    // SPI clock divider
    reg [$clog2(SPI_2X_CLK_DIV)-1:0] clk_div_cnt;
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            clk_div_cnt <= {$clog2(SPI_2X_CLK_DIV){1'b0}};
        else
            clk_div_cnt <= clk_div_cnt + 1'b1;
    end

    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            spi_clk_div <= 1'b0;
        else if (clk_div_cnt == SPI_2X_CLK_DIV - 1)
            spi_clk_div <= ~spi_clk_div;
    end

    // Data synchronization
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            tx_data_sync <= {N{1'b0}};
        end else if (tx_start) begin
            tx_data_sync <= di_i;
        end
    end

    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            rx_data_sync <= {N{1'b0}};
            do_o <= {N{1'b0}};
        end else if (rx_done) begin
            rx_data_sync <= rx_shift_reg;
            do_o <= rx_data_sync;
        end
    end

    // State machine
    typedef enum reg [2:0] {
        IDLE,
        TX_START,
        TX_RECEIVE,
        TX_DONE,
        RX_DONE
    } state_t;

    state_t state, next_state;

    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        spi_ssel_o = 1'b0;
        spi_sck_o = 1'b0;
        spi_mosi_o = 1'b0;
        di_req_o = 1'b0;
        wr_ack_o = 1'b0;
        do_valid_o = 1'b0;
        tx_start = 1'b0;
        tx_done = 1'b0;
        rx_done = 1'b0;

        case (state)
            IDLE: begin
                di_req_o = 1'b1;
                if (wren_i) begin
                    next_state = TX_START;
                    tx_start = 1'b1;
                end
            end
            TX_START: begin
                spi_ssel_o = 1'b1;
                next_state = TX_RECEIVE;
            end
            TX_RECEIVE: begin
                spi_ssel_o = 1'b1;
                spi_sck_o = spi_clk_div;
                spi_mosi_o = shift_reg[N-1];
                if (spi_clk_div) begin
                    if (bit_cnt < N) begin
                        shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                        bit_cnt <= bit_cnt + 1'b1;
                    end else begin
                        next_state = TX_DONE;
                        tx_done = 1'b1;
                    end
                end
            end
            TX_DONE: begin
                spi_ssel_o = 1'b0;
                next_state = RX_DONE;
                rx_done = 1'b1;
            end
            RX_DONE: begin
                spi_ssel_o = 1'b0;
                do_valid_o = 1'b1;
                wr_ack_o = 1'b1;
                next_state = IDLE;
            end
        endcase
    end

    // Shift register initialization and update
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            shift_reg <= {N{1'b0}};
            rx_shift_reg <= {N{1'b0}};
            bit_cnt <= {$clog2(N){1'b0}};
        end else if (tx_start) begin
            shift_reg <= tx_data_sync;
            rx_shift_reg <= {N{1'b0}};
            bit_cnt <= {$clog2(N){1'b0}};
        end
    end

endmodule
