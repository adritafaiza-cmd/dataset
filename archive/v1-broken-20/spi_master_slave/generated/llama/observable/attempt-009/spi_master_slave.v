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

reg [1:0] state;
reg [N-1:0] shift_reg;
reg [N-1:0] receive_reg;
reg [3:0] bit_cnt;
reg [1:0] clk_div;

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        state <= 2'b00;
        shift_reg <= {N{1'b0}};
        receive_reg <= {N{1'b0}};
        bit_cnt <= 4'b0000;
        clk_div <= 2'b00;
        spi_ssel_o <= 1'b1;
        spi_sck_o <= 1'b0;
    end
    else
    begin
        case (state)
            2'b00:
            begin
                if (di_req_o && wren_i)
                begin
                    state <= 2'b01;
                    shift_reg <= di_i;
                    bit_cnt <= 4'b1000;
                    clk_div <= 2'b00;
                    spi_ssel_o <= 1'b0;
                end
                else
                begin
                    state <= 2'b00;
                end
            end
            2'b01:
            begin
                if (clk_div == SPI_2X_CLK_DIV - 1)
                begin
                    clk_div <= 2'b00;
                    spi_sck_o <= ~spi_sck_o;
                    if (spi_sck_o == 1'b1)
                    begin
                        shift_reg <= {shift_reg[N-2:0], 1'b0};
                        bit_cnt <= bit_cnt - 1'b1;
                        if (bit_cnt == 4'b0000)
                        begin
                            state <= 2'b10;
                            spi_ssel_o <= 1'b1;
                        end
                    end
                end
                else
                begin
                    clk_div <= clk_div + 1'b1;
                end
            end
            2'b10:
            begin
                if (di_req_o && wren_i)
                begin
                    state <= 2'b01;
                    shift_reg <= di_i;
                    bit_cnt <= 4'b1000;
                    clk_div <= 2'b00;
                    spi_ssel_o <= 1'b0;
                end
                else
                begin
                    state <= 2'b10;
                end
            end
            default:
            begin
                state <= 2'b00;
            end
        endcase
    end
end

always @(posedge pclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        di_req_o <= 1'b0;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
        do_o <= {N{1'b0}};
    end
    else
    begin
        case (state)
            2'b00:
            begin
                di_req_o <= 1'b1;
                wr_ack_o <= 1'b0;
                do_valid_o <= 1'b0;
            end
            2'b01:
            begin
                di_req_o <= 1'b0;
                wr_ack_o <= 1'b0;
                do_valid_o <= 1'b0;
            end
            2'b10:
            begin
                di_req_o <= 1'b0;
                wr_ack_o <= 1'b1;
                do_valid_o <= 1'b1;
                do_o <= receive_reg;
            end
            default:
            begin
                di_req_o <= 1'b0;
                wr_ack_o <= 1'b0;
                do_valid_o <= 1'b0;
            end
        endcase
    end
end

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        spi_mosi_o <= 1'b0;
        receive_reg <= {N{1'b0}};
    end
    else
    begin
        case (state)
            2'b00:
            begin
                spi_mosi_o <= 1'b0;
                receive_reg <= {N{1'b0}};
            end
            2'b01:
            begin
                spi_mosi_o <= shift_reg[N-1];
                if (spi_sck_o == 1'b0)
                begin
                    receive_reg[N-1] <= spi_miso_i;
                end
                if (bit_cnt == 4'b0000)
                begin
                    receive_reg <= {N{1'b0}};
                end
            end
            2'b10:
            begin
                spi_mosi_o <= 1'b0;
                receive_reg <= {N{1'b0}};
            end
            default:
            begin
                spi_mosi_o <= 1'b0;
                receive_reg <= {N{1'b0}};
            end
        endcase
    end
end

endmodule
