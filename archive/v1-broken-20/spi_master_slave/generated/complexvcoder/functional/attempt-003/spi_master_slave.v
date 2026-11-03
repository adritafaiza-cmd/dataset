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
    reg [2:0] bit_cnt;
    reg ssel_reg;
    reg sck_reg;
    reg [N-1:0] do_reg;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= 0;
        end else begin
            di_req_o <= 1'b1;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;

            if (wren_i && bit_cnt == 0) begin
                shift_reg <= di_i;
                bit_cnt <= N;
                ssel_reg <= 1'b0;
                wr_ack_o <= 1'b1;
            end

            if (bit_cnt > 0) begin
                spi_ssel_o <= ssel_reg;
                spi_sck_o <= ~sck_reg;
                spi_mosi_o <= shift_reg[N-1];
                bit_cnt <= bit_cnt - 1;
                shift_reg <= {shift_reg[N-2:0], 1'b0};
                sck_reg <= ~sck_reg;

                if (sck_reg) begin
                    do_reg <= {do_reg[N-2:0], spi_miso_i};
                end

                if (bit_cnt == 0) begin
                    spi_ssel_o <= 1'b1;
                    do_o <= do_reg;
                    do_valid_o <= 1'b1;
                end
            end
        end
    end

endmodule
