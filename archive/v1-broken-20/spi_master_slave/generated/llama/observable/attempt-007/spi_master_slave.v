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
reg spi_miso;
reg di_req;
reg [N-1:0] di;
reg wren;
reg wr_ack;
reg do_valid;
reg [N-1:0] do;

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i)
    begin
        spi_ssel_o <= 1'b1;
        spi_sck_o <= 1'b0;
        spi_mosi_o <= 1'b0;
        state <= 3'b000;
        shift_reg <= {N{1'b0}};
    end
    else
    begin
        case (state)
            3'b000: // idle
            begin
                spi_ssel_o <= 1'b1;
                spi_sck_o <= 1'b0;
                spi_mosi_o <= 1'b0;
                if (di_req_o)
                begin
                    state <= 3'b001;
                    shift_reg <= di_i;
                end
            end
            3'b001: // transmit
            begin
                spi_ssel_o <= 1'b0;
                spi_sck_o <= ~spi_sck_o;
                spi_mosi_o <= shift_reg[N-1];
                shift_reg <= {shift_reg[N-2:N-1], spi_miso_i};
                if (shift_reg[N-1] == 1'b0)
                begin
                    state <= 3'b010;
                end
            end
            3'b010: // receive
            begin
                spi_ssel_o <= 1'b0;
                spi_sck_o <= ~spi_sck_o;
                spi_mosi_o <= 1'b0;
                shift_reg <= {shift_reg[N-2:N-1], spi_miso_i};
                if (shift_reg[N-1] == 1'b1)
                begin
                    state <= 3'b011;
                end
            end
            3'b011: // done
            begin
                spi_ssel_o <= 1'b1;
                spi_sck_o <= 1'b0;
                spi_mosi_o <= 1'b0;
                state <= 3'b000;
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
        di_req_o <= 1'b0;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
        if (wren_i)
        begin
            di_req_o <= 1'b1;
            wr_ack_o <= 1'b1;
        end
        if (state == 3'b011)
        begin
            do_valid_o <= 1'b1;
            do_o <= shift_reg;
        end
    end
end

endmodule
