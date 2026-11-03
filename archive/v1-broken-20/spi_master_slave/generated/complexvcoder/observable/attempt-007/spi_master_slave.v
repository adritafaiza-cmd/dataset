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

    reg [3:0] state;
    reg [3:0] bit_cnt;
    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg [2:0] sclk_cnt;
    reg spi_ssel;
    reg spi_sck;
    reg spi_mosi;
    reg [N-1:0] data_reg;

    // State definitions
    parameter IDLE = 4'b0000;
    parameter SEND = 4'b0001;
    parameter RECEIVE = 4'b0010;
    parameter DONE = 4'b0011;

    // Clock dividers
    reg [3:0] sclk_div_cnt;
    reg [3:0] pclk_div_cnt;

    // SPI signals
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div_cnt <= 4'b0;
            spi_ssel <= 1'b1;
            spi_sck <= 1'b0;
            spi_mosi <= 1'b0;
        end else begin
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 4'b0;
                spi_sck <= ~spi_sck;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end
        end
    end

    // SPI master logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            bit_cnt <= 4'b0;
            tx_data <= 8'b0;
            rx_data <= 8'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (wren_i) begin
                        di_req_o <= 1'b1;
                        tx_data <= di_i;
                        state <= SEND;
                    end
                end
                SEND: begin
                    spi_ssel <= 1'b0;
                    spi_mosi <= tx_data[7];
                    tx_data <= {tx_data[6:0], 1'b0};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        bit_cnt <= 4'b0;
                        state <= RECEIVE;
                    end
                end
                RECEIVE: begin
                    rx_data <= {rx_data[6:0], spi_miso_i};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        bit_cnt <= 4'b0;
                        spi_ssel <= 1'b1;
                        state <= DONE;
                    end
                end
                DONE: begin
                    wr_ack_o <= 1'b1;
                    do_valid_o <= 1'b1;
                    do_o <= rx_data;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
