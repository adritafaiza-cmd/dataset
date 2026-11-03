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
    reg [N-1:0]        bit_cnt;
    reg [N-1:0]        shift_reg;
    reg [N-1:0]        rx_shift_reg;
    reg [$clog2(SPI_2X_CLK_DIV)-1:0] sclk_div_cnt;
    reg              sclk_edge;
    reg              wren_reg;
    reg              wren_d1;
    reg              do_valid_reg;
    reg              do_valid_d1;

    // SPI clock divider
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div_cnt <= 0;
            spi_sck_o <= 0;
        end else begin
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 0;
                spi_sck_o <= ~spi_sck_o;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end
        end
    end

    // SPI clock edge detection
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_edge <= 0;
        end else begin
            sclk_edge <= ~spi_sck_o;
        end
    end

    // Parallel interface handling
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 1;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            do_o <= 0;
            wren_reg <= 0;
            wren_d1 <= 0;
            do_valid_reg <= 0;
            do_valid_d1 <= 0;
        end else begin
            // Request next word
            if (di_req_o && !wren_i) begin
                di_req_o <= 0;
            end

            // Accept word
            if (wren_i && !wren_reg) begin
                shift_reg <= di_i;
                bit_cnt <= N - 1;
                spi_ssel_o <= 1;
                di_req_o <= 1;
                wr_ack_o <= 1;
                wren_reg <= 1;
            end else begin
                wr_ack_o <= 0;
            end

            // Shift word
            if (sclk_edge && spi_ssel_o) begin
                spi_mosi_o <= shift_reg[N-1];
                shift_reg <= {shift_reg[N-2:0], 1'b0};
                rx_shift_reg <= {spi_miso_i, rx_shift_reg[N-1:1]};
                if (bit_cnt == 0) begin
                    spi_ssel_o <= 0;
                    do_o <= rx_shift_reg;
                    do_valid_reg <= 1;
                end else begin
                    bit_cnt <= bit_cnt - 1;
                end
            end

            // Update do_valid_o
            do_valid_d1 <= do_valid_reg;
            do_valid_o <= do_valid_reg & ~do_valid_d1;
            do_valid_reg <= 0;

            // Update wren_d1
            wren_d1 <= wren_reg;
            wren_reg <= wren_i;
        end
    end

    // Assign output
    assign spi_mosi_o = spi_ssel_o ? shift_reg[N-1] : 1'bz;

endmodule
