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
    reg [3:0]   bit_cnt;
    reg         sclk_div_cnt;
    reg         sclk_edge;
    reg         pclk_edge;
    reg         shift_start;
    reg         shift_done;

    // SCLK Divider
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div_cnt <= 0;
        end else begin
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 0;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end
        end
    end

    // SCLK Edge Detection
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_edge <= 0;
        end else begin
            if (sclk_div_cnt == 0) begin
                sclk_edge <= ~sclk_edge;
            end
        end
    end

    // PCLK Edge Detection
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_edge <= 0;
        end else begin
            pclk_edge <= ~pclk_edge;
        end
    end

    // Shift Register Control
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_reg <= 0;
            bit_cnt <= 0;
            spi_ssel_o <= 0;
            spi_sck_o <= 0;
            di_req_o <= 1;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            do_o <= 0;
            shift_start <= 0;
            shift_done <= 0;
        end else begin
            if (shift_start) begin
                spi_ssel_o <= 1;
                bit_cnt <= N - 1;
                shift_reg <= di_i;
                shift_start <= 0;
            end else if (bit_cnt < N) begin
                if (sclk_edge) begin
                    spi_sck_o <= ~spi_sck_o;
                    if (spi_sck_o) begin
                        spi_mosi_o <= shift_reg[N-1];
                        shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                        bit_cnt <= bit_cnt - 1;
                    end
                end
            end else begin
                spi_sck_o <= 0;
                spi_ssel_o <= 0;
                shift_done <= 1;
            end

            if (shift_done) begin
                do_o <= shift_reg;
                do_valid_o <= 1;
                shift_done <= 0;
            end else begin
                do_valid_o <= 0;
            end

            if (wren_i && di_req_o) begin
                shift_start <= 1;
                wr_ack_o <= 1;
                di_req_o <= 0;
            end else begin
                wr_ack_o <= 0;
            end

            if (do_valid_o) begin
                di_req_o <= 1;
            end
        end
    end

endmodule
