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
    reg [N-1:0] data_reg;
    reg [2:0] bit_cnt;
    reg [2:0] state;
    reg sclk_divided, pclk_divided;

    // State definitions
    parameter IDLE = 3'b000;
    parameter SEND = 3'b001;
    parameter RECEIVE = 3'b010;

    // Clock dividers
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            sclk_divided <= 0;
        else
            sclk_divided <= ~sclk_divided;
    end

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            pclk_divided <= 0;
        else
            pclk_divided <= ~pclk_divided;
    end

    // SPI controller logic
    always @(posedge pclk_divided or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            bit_cnt <= 0;
            data_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (wren_i) begin
                        di_req_o <= 1;
                        data_reg <= di_i;
                        state <= SEND;
                    end
                end
                SEND: begin
                    spi_ssel_o <= 0;
                    spi_sck_o <= sclk_divided;
                    spi_mosi_o <= data_reg[7];
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == N-1) begin
                        state <= RECEIVE;
                        bit_cnt <= 0;
                    end
                end
                RECEIVE: begin
                    spi_ssel_o <= 0;
                    spi_sck_o <= sclk_divided;
                    data_reg <= {data_reg[6:0], spi_miso_i};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == N-1) begin
                        state <= IDLE;
                        wr_ack_o <= 1;
                        do_valid_o <= 1;
                        do_o <= data_reg;
                    end
                end
            endcase
        end
    end

endmodule
