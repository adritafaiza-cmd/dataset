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
    reg [3:0] bit_cnt;
    reg sclk_prev;
    reg pclk_prev;
    reg [N-1:0] di_reg;
    reg wren_reg;
    reg [N-1:0] do_reg;
    reg do_valid_reg;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            shift_reg <= 0;
            bit_cnt <= 0;
            di_reg <= 0;
            wren_reg <= 0;
            do_reg <= 0;
            do_valid_reg <= 0;
        end else begin
            di_reg <= di_i;
            wren_reg <= wren_i;
            if (wren_reg) begin
                wr_ack_o <= 1;
                shift_reg <= di_reg;
                bit_cnt <= N;
                spi_ssel_o <= 0;
            end else begin
                wr_ack_o <= 0;
            end
            if (bit_cnt > 0) begin
                spi_mosi_o <= shift_reg[N-1];
                shift_reg <= {shift_reg[N-2:0], 1'b0};
                bit_cnt <= bit_cnt - 1;
                spi_sck_o <= ~spi_sck_o;
            end else begin
                spi_ssel_o <= 1;
            end
            if (spi_sck_o && !sclk_prev) begin
                do_o <= spi_miso_i;
                do_valid_reg <= 1;
            end else begin
                do_valid_reg <= 0;
            end
            if (!spi_sck_o && sclk_prev) begin
                di_req_o <= 1;
            end else begin
                di_req_o <= 0;
            end
            if (do_valid_reg) begin
                do_o <= do_reg;
                do_valid_o <= 1;
            end else begin
                do_valid_o <= 0;
            end
        end
    end

    always @(posedge sclk_i) begin
        sclk_prev <= sclk_i;
    end

    always @(posedge pclk_i) begin
        pclk_prev <= pclk_i;
    end

endmodule
