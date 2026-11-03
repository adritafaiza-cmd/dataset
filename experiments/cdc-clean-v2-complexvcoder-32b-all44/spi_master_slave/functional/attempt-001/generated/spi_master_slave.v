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
    reg [$clog2(N)-1:0] bit_cnt;
    reg [N-1:0] miso_reg;
    reg wren_d;
    reg wr_ack_d;
    reg do_valid_d;
    reg di_req_d;
    reg [$clog2(SPI_2X_CLK_DIV)-1:0] sclk_div_cnt;
    reg sclk_div_toggle;
    reg spi_sck_d;
    reg spi_ssel_d;
    reg spi_mosi_d;

    // SPI clock generation
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div_cnt <= 0;
            sclk_div_toggle <= 0;
        end else begin
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 0;
                sclk_div_toggle <= ~sclk_div_toggle;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end
        end
    end

    // SPI clock and select signals
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_o <= 0;
            spi_ssel_o <= 1;
        end else begin
            spi_sck_o <= sclk_div_toggle;
            spi_ssel_o <= (bit_cnt == 0) ? 1 : 0;
        end
    end

    // Data write request handling
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_o <= 0;
            di_req_o <= 1;
            shift_reg <= 0;
            bit_cnt <= 0;
            wren_d <= 0;
        end else begin
            wr_ack_o <= 0;
            di_req_o <= 1;
            if (wren_i && !wren_d) begin
                wr_ack_o <= 1;
                di_req_o <= 0;
                shift_reg <= di_i;
                bit_cnt <= N - 1;
            end
            wren_d <= wren_i;
        end
    end

    // Data shifting and MISO capturing
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_mosi_o <= 0;
            miso_reg <= 0;
        end else begin
            if (sclk_div_toggle) begin
                if (bit_cnt < N) begin
                    spi_mosi_o <= shift_reg[bit_cnt];
                    if (bit_cnt > 0) begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
                miso_reg <= {miso_reg[N-2:0], spi_miso_i};
            end
        end
    end

    // Data output and valid signal
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_valid_o <= 0;
            do_o <= 0;
        end else begin
            do_valid_o <= 0;
            if (bit_cnt == 0 && !sclk_div_toggle) begin
                do_valid_o <= 1;
                do_o <= miso_reg;
            end
        end
    end

endmodule
