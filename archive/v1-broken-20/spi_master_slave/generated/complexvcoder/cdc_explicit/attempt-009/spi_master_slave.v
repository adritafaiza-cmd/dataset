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

    reg [N-1:0] di_reg;
    reg [N-1:0] do_reg;
    reg [N-1:0] shift_reg;
    reg [2:0] bit_cnt;
    reg [1:0] state;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            di_reg <= 0;
            do_reg <= 0;
            shift_reg <= 0;
            bit_cnt <= 0;
            state <= 2'b00;
        end else begin
            case (state)
                2'b00: begin
                    if (wren_i) begin
                        di_reg <= di_i;
                        state <= 2'b01;
                    end
                end
                2'b01: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o <= 1'b0;
                    spi_mosi_o <= di_reg[0];
                    bit_cnt <= 0;
                    state <= 2'b10;
                end
                2'b10: begin
                    spi_sck_o <= ~spi_sck_o;
                    if (spi_sck_o) begin
                        shift_reg <= {shift_reg[0], spi_miso_i};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == N - 1) begin
                            do_reg <= shift_reg;
                            state <= 2'b11;
                        end
                    end
                end
                2'b11: begin
                    spi_ssel_o <= 1'b1;
                    wr_ack_o <= 1'b1;
                    do_valid_o <= 1'b1;
                    di_req_o <= 1'b1;
                    state <= 2'b00;
                end
            endcase
        end
    end

endmodule
