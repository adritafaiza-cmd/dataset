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
reg spi_ssel_en;
reg [1:0] state;
reg [N-1:0] bit_cnt;

always @(posedge pclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        di_req_o <= 1'b1;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
        state <= 2'b00;
        bit_cnt <= N;
    end
    else
    begin
        case (state)
            2'b00:
            begin
                if (wren_i)
                begin
                    shift_reg <= di_i;
                    wr_ack_o <= 1'b1;
                    state <= 2'b01;
                    bit_cnt <= N;
                end
                else
                begin
                    wr_ack_o <= 1'b0;
                end
            end
            2'b01:
            begin
                if (bit_cnt == 0)
                begin
                    state <= 2'b10;
                    bit_cnt <= N;
                end
            end
            2'b10:
            begin
                if (bit_cnt == 0)
                begin
                    state <= 2'b00;
                    do_valid_o <= 1'b1;
                    di_req_o <= 1'b1;
                end
            end
        endcase
    end
end

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        spi_sck_o <= 1'b0;
        spi_ssel_o <= 1'b1;
        sclk_div <= 4'b0000;
        sclk_cnt <= 4'b0000;
        spi_sck_en <= 1'b0;
        spi_ssel_en <= 1'b0;
    end
    else
    begin
        if (sclk_div == SPI_2X_CLK_DIV)
        begin
            sclk_div <= 4'b0000;
            spi_sck_en <= ~spi_sck_en;
        end
        else
        begin
            sclk_div <= sclk_div + 1'b1;
        end

        case (state)
            2'b00:
            begin
                spi_ssel_o <= 1'b1;
                spi_sck_o <= 1'b0;
            end
            2'b01:
            begin
                spi_ssel_o <= 1'b0;
                spi_sck_o <= spi_sck_en;
                if (spi_sck_en)
                begin
                    spi_mosi_o <= shift_reg[N-1];
                    shift_reg <= {shift_reg[N-2:0], 1'b0};
                    bit_cnt <= bit_cnt - 1'b1;
                end
            end
            2'b10:
            begin
                spi_ssel_o <= 1'b0;
                spi_sck_o <= spi_sck_en;
                if (spi_sck_en)
                begin
                    capture_reg <= {capture_reg[N-2:0], spi_miso_i};
                    bit_cnt <= bit_cnt - 1'b1;
                end
                if (bit_cnt == 0)
                begin
                    do_o <= capture_reg;
                    do_valid_o <= 1'b1;
                    di_req_o <= 1'b1;
                end
            end
        endcase
    end
end

endmodule
