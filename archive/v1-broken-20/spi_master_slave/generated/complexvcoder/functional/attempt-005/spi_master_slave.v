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
    reg [2:0] bit_count;
    reg [2:0] sclk_div_counter;
    reg sclk_div;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            shift_reg <= 0;
            bit_count <= 0;
            sclk_div_counter <= 0;
            sclk_div <= 0;
        end else begin
            if (wren_i && bit_count == 0) begin
                shift_reg <= di_i;
                bit_count <= N - 1;
                di_req_o <= 1;
                wr_ack_o <= 0;
            end else if (bit_count > 0) begin
                spi_ssel_o <= 0;
                spi_sck_o <= sclk_div;
                spi_mosi_o <= shift_reg[N - 1];
                shift_reg <= {shift_reg[N - 2:0], 1'b0};
                bit_count <= bit_count - 1;
                if (sclk_div) begin
                    do_valid_o <= 1;
                    do_o <= {shift_reg[N - 1:0], 1'b0};
                    wr_ack_o <= 1;
                end else begin
                    do_valid_o <= 0;
                end
            end else begin
                spi_ssel_o <= 1;
                di_req_o <= 0;
                wr_ack_o <= 0;
                do_valid_o <= 0;
            end

            sclk_div_counter <= sclk_div_counter + 1;
            if (sclk_div_counter == SPI_2X_CLK_DIV - 1) begin
                sclk_div_counter <= 0;
                sclk_div <= ~sclk_div;
            end
        end
    end

endmodule
