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

    reg [N-1:0]        shift_reg;
    reg [3:0]          bit_cnt;
    reg [N-1:0]        data_out;
    reg                spi_sck_reg;
    reg                spi_ssel_reg;
    reg                di_req_reg;
    reg                wr_ack_reg;
    reg                do_valid_reg;
    reg [SPI_2X_CLK_DIV-1:0] sclk_div_cnt;

    // PCLK domain logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            do_o <= 0;
        end else begin
            // Request new data
            if (!spi_ssel_reg && !di_req_reg) begin
                di_req_o <= 1;
            end else if (wren_i) begin
                di_req_o <= 0;
                wr_ack_o <= 1;
                data_out <= di_i;
            end else begin
                wr_ack_o <= 0;
            end

            // Validate data output
            if (bit_cnt == N) begin
                do_valid_o <= 1;
                do_o <= shift_reg;
            end else begin
                do_valid_o <= 0;
            end
        end
    end

    // SCLK domain logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 0;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            shift_reg <= 0;
            bit_cnt <= 0;
            sclk_div_cnt <= 0;
        end else begin
            // SPI clock generation
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 0;
                spi_sck_o <= ~spi_sck_reg;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end

            // SPI transfer logic
            if (sclk_div_cnt == 0) begin
                spi_sck_reg <= spi_sck_o;

                if (!spi_ssel_reg && wren_i) begin
                    spi_ssel_o <= 1;
                    bit_cnt <= 0;
                    shift_reg <= data_out;
                end else if (bit_cnt < N) begin
                    spi_mosi_o <= shift_reg[N-1];
                    shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                    bit_cnt <= bit_cnt + 1;
                end else begin
                    spi_ssel_o <= 0;
                end
            end
        end
    end

endmodule
