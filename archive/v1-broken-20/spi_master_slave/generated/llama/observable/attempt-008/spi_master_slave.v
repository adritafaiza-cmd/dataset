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
reg [N-1:0] tx_data;
reg [N-1:0] rx_data;
reg [SPI_2X_CLK_DIV-1:0] clk_div;
reg [N-1:0] shift_reg;

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        state <= 0;
        spi_ssel_o <= 1;
        spi_sck_o <= 0;
        spi_mosi_o <= 0;
        tx_data <= 0;
        rx_data <= 0;
        clk_div <= 0;
        shift_reg <= 0;
    end
    else
    begin
        case (state)
            0: // IDLE
            begin
                spi_ssel_o <= 1;
                spi_sck_o <= 0;
                if (di_req_o)
                begin
                    state <= 1;
                    tx_data <= di_i;
                    rx_data <= 0;
                    clk_div <= 0;
                    shift_reg <= tx_data;
                end
            end
            1: // START
            begin
                spi_ssel_o <= 0;
                spi_sck_o <= 0;
                if (clk_div == SPI_2X_CLK_DIV - 1)
                begin
                    state <= 2;
                    clk_div <= 0;
                end
                else
                begin
                    clk_div <= clk_div + 1;
                end
            end
            2: // SHIFT
            begin
                spi_sck_o <= 1;
                if (clk_div == SPI_2X_CLK_DIV - 1)
                begin
                    state <= 3;
                    clk_div <= 0;
                    shift_reg <= {shift_reg[6:0], spi_miso_i};
                    rx_data <= shift_reg;
                end
                else
                begin
                    clk_div <= clk_div + 1;
                end
            end
            3: // STOP
            begin
                spi_sck_o <= 0;
                spi_mosi_o <= 0;
                if (clk_div == SPI_2X_CLK_DIV - 1)
                begin
                    state <= 0;
                    clk_div <= 0;
                    spi_ssel_o <= 1;
                    wr_ack_o <= 1;
                    do_valid_o <= 1;
                    do_o <= rx_data;
                end
                else
                begin
                    clk_div <= clk_div + 1;
                end
            end
        endcase
    end
end

always @(posedge pclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        di_req_o <= 0;
        wr_ack_o <= 0;
        do_valid_o <= 0;
    end
    else
    begin
        di_req_o <= wren_i;
        wr_ack_o <= 0;
        do_valid_o <= 0;
    end
end

always @(posedge sclk_i)
begin
    spi_mosi_o <= shift_reg[N-1];
end

always @(posedge pclk_i)
begin
    if (wren_i)
    begin
        wr_ack_o <= 1;
    end
    else
    begin
        wr_ack_o <= 0;
    end
end
