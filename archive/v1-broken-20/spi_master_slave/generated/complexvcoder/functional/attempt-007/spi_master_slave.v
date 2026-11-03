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

    reg [N-1:0] shift_reg;
    reg [3:0] bit_count;
    reg [3:0] sclk_cnt;
    reg sclk_en;
    reg [1:0] state;

    parameter IDLE = 2'b00;
    parameter SEND = 2'b01;
    parameter RECEIVE = 2'b10;
    parameter DONE = 2'b11;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o <= 1'b0;
                    spi_mosi_o <= 1'b0;
                    di_req_o <= 1'b0;
                    wr_ack_o <= 1'b0;
                    do_valid_o <= 1'b0;
                    if (wren_i) begin
                        state <= SEND;
                        shift_reg <= di_i;
                        bit_count <= 4'b0000;
                        sclk_cnt <= 4'b0000;
                        sclk_en <= 1'b0;
                    end
                end
                SEND: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o <= sclk_en;
                    spi_mosi_o <= shift_reg[0];
                    di_req_o <= 1'b1;
                    wr_ack_o <= 1'b0;
                    do_valid_o <= 1'b0;
                    shift_reg <= {shift_reg[7:1], spi_miso_i};
                    sclk_cnt <= sclk_cnt + 1;
                    if (sclk_cnt == SPI_2X_CLK_DIV - 1) begin
                        sclk_en <= ~sclk_en;
                        sclk_cnt <= 4'b0000;
                        if (bit_count == N - 1) begin
                            state <= RECEIVE;
                        end
                    end
                end
                RECEIVE: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o <= 1'b0;
                    spi_mosi_o <= 1'b0;
                    di_req_o <= 1'b1;
                    wr_ack_o <= 1'b0;
                    do_valid_o <= 1'b1;
                    do_o <= shift_reg;
                    state <= DONE;
                end
                DONE: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o <= 1'b0;
                    spi_mosi_o <= 1'b0;
                    di_req_o <= 1'b0;
                    wr_ack_o <= 1'b1;
                    do_valid_o <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
