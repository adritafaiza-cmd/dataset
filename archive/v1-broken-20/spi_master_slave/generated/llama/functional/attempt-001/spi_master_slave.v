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
reg [1:0] state;
reg [1:0] next_state;

always @(posedge pclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        state <= 2'b00;
        spi_ssel_o <= 1'b1;
        di_req_o <= 1'b0;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
    end
    else
    begin
        state <= next_state;
        case (state)
            2'b00:
            begin
                spi_ssel_o <= 1'b1;
                di_req_o <= 1'b1;
                wr_ack_o <= 1'b0;
                do_valid_o <= 1'b0;
            end
            2'b01:
            begin
                spi_ssel_o <= 1'b0;
                di_req_o <= 1'b0;
                wr_ack_o <= 1'b1;
            end
            2'b10:
            begin
                spi_ssel_o <= 1'b0;
                di_req_o <= 1'b0;
                wr_ack_o <= 1'b0;
            end
            2'b11:
            begin
                spi_ssel_o <= 1'b1;
                di_req_o <= 1'b1;
                wr_ack_o <= 1'b0;
                do_valid_o <= 1'b1;
            end
        endcase
    end
end

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        sclk_div <= 4'b0000;
        sclk_cnt <= 4'b0000;
        spi_sck_en <= 1'b0;
        spi_sck_rst <= 1'b1;
        spi_ssel_en <= 1'b0;
        spi_ssel_rst <= 1'b1;
        shift_reg <= {N{1'b0}};
        capture_reg <= {N{1'b0}};
    end
    else
    begin
        if (spi_sck_rst)
        begin
            sclk_div <= 4'b0000;
            sclk_cnt <= 4'b0000;
            spi_sck_en <= 1'b0;
            spi_sck_rst <= 1'b0;
        end
        else if (spi_sck_en)
        begin
            sclk_div <= sclk_div + 1'b1;
            if (sclk_div == SPI_2X_CLK_DIV)
            begin
                sclk_div <= 4'b0000;
                sclk_cnt <= sclk_cnt + 1'b1;
                if (sclk_cnt == N)
                begin
                    sclk_cnt <= 4'b0000;
                    spi_sck_en <= 1'b0;
                    spi_sck_rst <= 1'b1;
                end
            end
        end
        if (spi_ssel_rst)
        begin
            spi_ssel_en <= 1'b0;
            spi_ssel_rst <= 1'b0;
        end
        else if (spi_ssel_en)
        begin
            if (sclk_cnt == N)
            begin
                spi_ssel_en <= 1'b0;
                spi_ssel_rst <= 1'b1;
            end
        end
        if (spi_sck_en)
        begin
            shift_reg <= {shift_reg[N-2:0], 1'b0};
            capture_reg <= {capture_reg[N-2:0], spi_miso_i};
        end
    end
end

always @(*)
begin
    spi_mosi_o = shift_reg[N-1];
    do_o = capture_reg;
    case (state)
        2'b00:
        begin
            next_state = wren_i? 2'b01 : 2'b00;
            spi_sck_en = 1'b0;
            spi_sck_rst = 1'b1;
            spi_ssel_en = 1'b0;
            spi_ssel_rst = 1'b1;
            shift_reg = {N{1'b0}};
            capture_reg = {N{1'b0}};
        end
        2'b01:
        begin
            next_state = 2'b10;
            spi_sck_en = 1'b1;
            spi_sck_rst = 1'b0;
            spi_ssel_en = 1'b1;
            spi_ssel_rst = 1'b0;
            shift_reg = di_i;
        end
        2'b10:
        begin
            next_state = 2'b11;
            spi_sck_en = 1'b1;
            spi_sck_rst = 1'b0;
            spi_ssel_en = 1'b1;
            spi_ssel_rst = 1'b0;
        end
        2'b11:
        begin
            next_state = 2'b00;
            spi_sck_en = 1'b0;
            spi_sck_rst = 1'b1;
            spi_ssel_en = 1'b0;
            spi_ssel_rst = 1'b1;
        end
    endcase
end

endmodule
