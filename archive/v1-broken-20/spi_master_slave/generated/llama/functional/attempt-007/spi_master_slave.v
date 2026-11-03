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
reg wr_ack_rst;
reg wr_ack_en;
reg di_req_rst;
reg di_req_en;
reg do_valid_rst;
reg do_valid_en;

always @(posedge pclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
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
        wr_ack_rst <= 1'b1;
        wr_ack_en <= 1'b0;
        di_req_rst <= 1'b1;
        di_req_en <= 1'b0;
        do_valid_rst <= 1'b1;
        do_valid_en <= 1'b0;
    end
    else
    begin
        spi_ssel_rst <= 1'b0;
        spi_sck_rst <= 1'b0;
        wr_ack_rst <= 1'b0;
        di_req_rst <= 1'b0;
        do_valid_rst <= 1'b0;

        if (wren_i)
        begin
            shift_reg <= di_i;
            bit_cnt <= N - 1;
            spi_ssel_en <= 1'b1;
            di_req_o <= 1'b0;
            wr_ack_en <= 1'b1;
        end
        else
        begin
            wr_ack_en <= 1'b0;
        end

        if (spi_ssel_en)
        begin
            if (bit_cnt == 0)
            begin
                spi_ssel_en <= 1'b0;
                spi_ssel_rst <= 1'b1;
                do_valid_en <= 1'b1;
                capture_reg <= {N{1'b0}};
                bit_cnt <= N - 1;
            end
            else
            begin
                bit_cnt <= bit_cnt - 1;
            end
        end

        if (do_valid_en)
        begin
            do_valid_o <= 1'b1;
            do_o <= capture_reg;
            do_valid_en <= 1'b0;
            di_req_en <= 1'b1;
        end
        else
        begin
            do_valid_en <= 1'b0;
        end

        if (di_req_en)
        begin
            di_req_o <= 1'b1;
            di_req_en <= 1'b0;
        end
        else
        begin
            di_req_en <= 1'b0;
        end

        if (wr_ack_en)
        begin
            wr_ack_o <= 1'b1;
            wr_ack_en <= 1'b0;
        end
        else
        begin
            wr_ack_o <= 1'b0;
        end

        if (spi_ssel_rst)
        begin
            spi_ssel_o <= 1'b1;
            spi_ssel_rst <= 1'b0;
        end

        if (spi_sck_en)
        begin
            if (sclk_cnt == SPI_2X_CLK_DIV - 1)
            begin
                spi_sck_o <= ~spi_sck_o;
                sclk_cnt <= {4{1'b0}};
                if (spi_sck_o == 1'b1)
                begin
                    capture_reg[N-1] <= spi_miso_i;
                    shift_reg <= {shift_reg[N-2:0], 1'b0};
                    spi_mosi_o <= shift_reg[N-1];
                end
            end
            else
            begin
                sclk_cnt <= sclk_cnt + 1;
            end
        end
        else
        begin
            sclk_cnt <= {4{1'b0}};
        end

        if (spi_sck_rst)
        begin
            spi_sck_o <= 1'b0;
            spi_sck_rst <= 1'b0;
            sclk_cnt <= {4{1'b0}};
        end

        if (spi_ssel_en)
        begin
            spi_sck_en <= 1'b1;
        end
        else
        begin
            spi_sck_en <= 1'b0;
        end

        if (spi_ssel_en)
        begin
            spi_ssel_o <= 1'b0;
        end

        if (do_valid_rst)
        begin
            do_valid_o <= 1'b0;
            do_valid_rst <= 1'b0;
        end

        if (wr_ack_rst)
        begin
            wr_ack_o <= 1'b0;
            wr_ack_rst <= 1'b0;
        end

        if (di_req_rst)
        begin
            di_req_o <= 1'b0;
            di_req_rst <= 1'b0;
        end
    end
end

endmodule
