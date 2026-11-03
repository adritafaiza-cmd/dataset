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
reg [3:0] state;
reg [3:0] bit_cnt;
reg [1:0] sclk_div;
reg sclk_en;
reg pclk_en;
reg rst_sync_sclk;
reg rst_sync_pclk;

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        rst_sync_sclk <= 1'b1;
        spi_sck_o <= 1'b0;
        sclk_div <= 2'b00;
        sclk_en <= 1'b0;
    end
    else
    begin
        rst_sync_sclk <= 1'b0;
        if (sclk_div == 2'b11)
        begin
            sclk_en <= ~sclk_en;
            spi_sck_o <= sclk_en;
            sclk_div <= 2'b00;
        end
        else
        begin
            sclk_div <= sclk_div + 1'b1;
        end
    end
end

always @(posedge pclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        rst_sync_pclk <= 1'b1;
        di_req_o <= 1'b0;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
    end
    else
    begin
        rst_sync_pclk <= 1'b0;
        if (wren_i)
        begin
            shift_reg <= di_i;
            wr_ack_o <= 1'b1;
            di_req_o <= 1'b0;
        end
        else
        begin
            wr_ack_o <= 1'b0;
        end
        if (state == 4'b0000)
        begin
            di_req_o <= 1'b1;
        end
    end
end

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        state <= 4'b0000;
        bit_cnt <= 4'b0000;
        spi_ssel_o <= 1'b1;
        spi_mosi_o <= 1'b0;
    end
    else
    begin
        if (sclk_en)
        begin
            case (state)
                4'b0000:
                begin
                    if (di_req_o)
                    begin
                        state <= 4'b0001;
                        spi_ssel_o <= 1'b0;
                    end
                end
                4'b0001:
                begin
                    spi_mosi_o <= shift_reg[N-1];
                    shift_reg <= {shift_reg[N-2:0], 1'b0};
                    bit_cnt <= bit_cnt + 1'b1;
                    if (bit_cnt == N)
                    begin
                        state <= 4'b0010;
                        bit_cnt <= 4'b0000;
                    end
                end
                4'b0010:
                begin
                    capture_reg <= {capture_reg[N-2:0], spi_miso_i};
                    bit_cnt <= bit_cnt + 1'b1;
                    if (bit_cnt == N)
                    begin
                        state <= 4'b0011;
                        bit_cnt <= 4'b0000;
                    end
                end
                4'b0011:
                begin
                    spi_ssel_o <= 1'b1;
                    state <= 4'b0000;
                end
                default:
                begin
                    state <= 4'b0000;
                end
            endcase
        end
    end
end

always @(posedge pclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        do_o <= {N{1'b0}};
    end
    else
    begin
        if (state == 4'b0011)
        begin
            do_o <= capture_reg;
            do_valid_o <= 1'b1;
        end
        else
        begin
            do_valid_o <= 1'b0;
        end
    end
end

endmodule
