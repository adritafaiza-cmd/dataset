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
reg spi_sck_en;
reg spi_sck_rst;
reg spi_ssel_en;
reg spi_ssel_rst;
reg [N-1:0] bit_cnt;
reg wr_ack_reg;
reg di_req_reg;
reg do_valid_reg;

always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_ssel_o <= 1'b1;
        spi_sck_o <= 1'b0;
        di_req_o <= 1'b0;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
        do_o <= {N{1'b0}};
        shift_reg <= {N{1'b0}};
        capture_reg <= {N{1'b0}};
        sclk_div <= {4{1'b0}};
        sclk_cnt <= {4{1'b0}};
        spi_sck_en <= 1'b0;
        spi_sck_rst <= 1'b1;
        spi_ssel_en <= 1'b0;
        spi_ssel_rst <= 1'b1;
        bit_cnt <= {N{1'b0}};
        wr_ack_reg <= 1'b0;
        di_req_reg <= 1'b0;
        do_valid_reg <= 1'b0;
    end else begin
        spi_sck_rst <= 1'b0;
        spi_ssel_rst <= 1'b0;
        if (wren_i) begin
            shift_reg <= di_i;
            bit_cnt <= N;
            wr_ack_reg <= 1'b1;
            di_req_reg <= 1'b0;
        end else begin
            wr_ack_reg <= 1'b0;
        end
        if (bit_cnt == 0) begin
            di_req_reg <= 1'b1;
        end
        if (spi_ssel_en) begin
            if (sclk_cnt == SPI_2X_CLK_DIV) begin
                sclk_cnt <= {4{1'b0}};
                spi_sck_en <= ~spi_sck_en;
                if (bit_cnt > 0) begin
                    capture_reg[N-1] <= spi_miso_i;
                    capture_reg[N-2:0] <= capture_reg[N-1:1];
                    shift_reg[N-1:1] <= shift_reg[N-2:0];
                    shift_reg[0] <= 1'b0;
                    bit_cnt <= bit_cnt - 1;
                end
            end else begin
                sclk_cnt <= sclk_cnt + 1;
            end
        end
        if (bit_cnt == 0 && spi_ssel_en) begin
            spi_ssel_en <= 1'b0;
            do_valid_reg <= 1'b1;
            do_o <= capture_reg;
        end
        if (di_req_reg) begin
            spi_ssel_en <= 1'b1;
            do_valid_reg <= 1'b0;
        end
        spi_ssel_o <= spi_ssel_rst? 1'b1 : spi_ssel_en? 1'b0 : 1'b1;
        spi_sck_o <= spi_sck_rst? 1'b0 : spi_sck_en? 1'b1 : 1'b0;
        spi_mosi_o <= shift_reg[N-1];
        di_req_o <= di_req_reg;
        wr_ack_o <= wr_ack_reg;
        do_valid_o <= do_valid_reg;
    end
end

endmodule
