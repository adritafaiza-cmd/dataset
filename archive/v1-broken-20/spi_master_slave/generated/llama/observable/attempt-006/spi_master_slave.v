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
reg [2:0] state;
reg [N-1:0] data_out;
reg [N-1:0] data_in;
reg spi_ssel;
reg spi_sck;
reg spi_mosi;
reg [1:0] cnt;

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        state <= 0;
        shift_reg <= 0;
        spi_ssel <= 1;
        spi_sck <= 0;
        spi_mosi <= 0;
        cnt <= 0;
    end
    else
    begin
        case (state)
            0: // idle
            begin
                if (cnt == 0)
                begin
                    spi_ssel <= 0;
                    state <= 1;
                end
                else
                begin
                    cnt <= cnt - 1;
                end
            end
            1: // transmit
            begin
                spi_mosi <= shift_reg[N-1];
                shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                if (cnt == 0)
                begin
                    state <= 2;
                end
                else
                begin
                    cnt <= cnt - 1;
                end
            end
            2: // receive
            begin
                data_in <= shift_reg;
                state <= 0;
                cnt <= SPI_2X_CLK_DIV;
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
        data_out <= 0;
    end
    else
    begin
        if (wren_i)
        begin
            data_out <= di_i;
            wr_ack_o <= 1;
        end
        else
        begin
            wr_ack_o <= 0;
        end
        if (di_req_o)
        begin
            di_req_o <= 0;
        end
        if (state == 2)
        begin
            do_valid_o <= 1;
            do_o <= data_in;
        end
        else
        begin
            do_valid_o <= 0;
        end
    end
end

assign spi_ssel_o = spi_ssel;
assign spi_sck_o = spi_sck;
assign spi_mosi_o = spi_mosi;

always @(posedge sclk_i)
begin
    if (rst_i)
    begin
        spi_sck <= 0;
    end
    else
    begin
        case (state)
            0: spi_sck <= 0;
            1: spi_sck <= ~spi_sck;
            2: spi_sck <= 0;
        endcase
    end
end

always @(posedge sclk_i)
begin
    if (rst_i)
    begin
        cnt <= 0;
    end
    else
    begin
        case (state)
            0: cnt <= SPI_2X_CLK_DIV;
            1: cnt <= SPI_2X_CLK_DIV;
            2: cnt <= SPI_2X_CLK_DIV;
        endcase
    end
end

always @(posedge sclk_i)
begin
    if (rst_i)
    begin
        shift_reg <= 0;
    end
    else
    begin
        case (state)
            0: shift_reg <= data_out;
            1: shift_reg <= {shift_reg[N-2:0], spi_miso_i};
            2: shift_reg <= 0;
        endcase
    end
end

always @(posedge sclk_i)
begin
    if (rst_i)
    begin
        state <= 0;
    end
    else
    begin
        case (state)
            0: state <= 1;
            1: state <= 2;
            2: state <= 0;
        endcase
    end
end

always @(posedge pclk_i)
begin
    if (rst_i)
    begin
        di_req_o <= 0;
    end
    else
    begin
        if (state == 0)
        begin
            di_req_o <= 1;
        end
        else
        begin
            di_req_o <= 0;
        end
    end
end
