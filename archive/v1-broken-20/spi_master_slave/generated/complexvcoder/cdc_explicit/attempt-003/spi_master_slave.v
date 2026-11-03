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

    reg [N-1:0] data_reg;
    reg [2:0] bit_cnt;
    reg [1:0] state;
    reg [1:0] ssel_reg;
    reg [1:0] sck_reg;
    reg [1:0] mosi_reg;
    reg [1:0] miso_reg;

    parameter IDLE = 2'b00;
    parameter SEND_DATA = 2'b01;
    parameter RECEIVE_DATA = 2'b10;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            data_reg <= 0;
            bit_cnt <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (wren_i) begin
                        data_reg <= di_i;
                        wr_ack_o <= 1'b1;
                        di_req_o <= 1'b1;
                        state <= SEND_DATA;
                    end
                end
                SEND_DATA: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o <= 1'b0;
                    spi_mosi_o <= data_reg[0];
                    bit_cnt <= 0;
                    state <= RECEIVE_DATA;
                end
                RECEIVE_DATA: begin
                    spi_sck_o <= ~spi_sck_o;
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == N-1) begin
                        spi_ssel_o <= 1'b1;
                        wr_ack_o <= 1'b0;
                        do_valid_o <= 1'b1;
                        do_o <= {miso_reg[1], miso_reg[0]};
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
