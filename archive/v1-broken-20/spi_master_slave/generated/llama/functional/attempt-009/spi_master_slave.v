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
reg [N-1:0] capture_reg;
reg [3:0] sclk_div;
reg [3:0] sclk_cnt;
reg [N-1:0] bit_cnt;
reg spi_ssel_int;
reg spi_sck_int;
reg spi_mosi_int;
reg di_req_int;
reg wr_ack_int;
reg do_valid_int;
reg [N-1:0] do_int;

always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_ssel_o <= 1'b1;
        spi_sck_o <= 1'b0;
        spi_mosi_o <= 1'b0;
        di_req_o <= 1'b0;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
        do_o <= {N{1'b0}};
        shift_reg <= {N{1'b0}};
        capture_reg <= {N{1'b0}};
        sclk_div <= {4{1'b0}};
        sclk_cnt <= {4{1'b0}};
        bit_cnt <= {N{1'b0}};
        spi_ssel_int <= 1'b1;
        spi_sck_int <= 1'b0;
        spi_mosi_int <= 1'b0;
        di_req_int <= 1'b0;
        wr_ack_int <= 1'b0;
        do_valid_int <= 1'b0;
        do_int <= {N{1'b0}};
    end else begin
        spi_ssel_o <= spi_ssel_int;
        spi_sck_o <= spi_sck_int;
        spi_mosi_o <= spi_mosi_int;
        di_req_o <= di_req_int;
        wr_ack_o <= wr_ack_int;
        do_valid_o <= do_valid_int;
        do_o <= do_int;

        if (wren_i) begin
            shift_reg <= di_i;
            bit_cnt <= N - 1;
            spi_ssel_int <= 1'b0;
            wr_ack_int <= 1'b1;
        end else begin
            wr_ack_int <= 1'b0;
        end

        if (bit_cnt == 0) begin
            spi_ssel_int <= 1'b1;
            di_req_int <= 1'b1;
        end else begin
            di_req_int <= 1'b0;
        end

        if (spi_ssel_int == 1'b0) begin
            spi_mosi_int <= shift_reg[N - 1];
            if (sclk_cnt == SPI_2X_CLK_DIV - 1) begin
                shift_reg <= {shift_reg[N - 2:0], 1'b0};
                bit_cnt <= bit_cnt - 1;
                sclk_cnt <= {4{1'b0}};
            end else begin
                sclk_cnt <= sclk_cnt + 1;
            end
        end
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_sck_int <= 1'b0;
        sclk_div <= {4{1'b0}};
    end else begin
        if (sclk_div == SPI_2X_CLK_DIV - 1) begin
            spi_sck_int <= ~spi_sck_int;
            sclk_div <= {4{1'b0}};
        end else begin
            sclk_div <= sclk_div + 1;
        end
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        capture_reg <= {N{1'b0}};
        do_valid_int <= 1'b0;
    end else begin
        if (spi_ssel_int == 1'b0) begin
            capture_reg[N - 1] <= spi_miso_i;
            if (sclk_cnt == SPI_2X_CLK_DIV - 1) begin
                capture_reg <= {capture_reg[N - 2:0], 1'b0};
                if (bit_cnt == 1) begin
                    do_int <= capture_reg;
                    do_valid_int <= 1'b1;
                end
            end
        end else begin
            do_valid_int <= 1'b0;
        end
    end
end

endmodule
