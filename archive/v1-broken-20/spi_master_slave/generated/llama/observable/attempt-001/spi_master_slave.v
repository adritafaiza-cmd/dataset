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
reg [SPI_2X_CLK_DIV-1:0] clk_div;
reg sclk_en;

always @(posedge sclk_i or posedge rst_i)
if (rst_i) begin
    state <= 0;
    shift_reg <= 0;
    data_out <= 0;
    data_in <= 0;
    clk_div <= 0;
    sclk_en <= 0;
    spi_ssel_o <= 1;
    spi_sck_o <= 0;
    spi_mosi_o <= 0;
end else begin
    case (state)
        0: begin
            if (di_req_o && wren_i) begin
                state <= 1;
                data_out <= di_i;
                shift_reg <= {1'b0, data_out[N-1:1]};
                clk_div <= 0;
                sclk_en <= 1;
                spi_ssel_o <= 0;
            end else begin
                di_req_o <= 1;
            end
        end
        1: begin
            if (clk_div == SPI_2X_CLK_DIV-1) begin
                clk_div <= 0;
                sclk_en <= ~sclk_en;
                if (~sclk_en) begin
                    shift_reg <= {spi_miso_i, shift_reg[N-1:1]};
                    if (shift_reg[N-1] == 1'b1) begin
                        state <= 2;
                        data_in <= shift_reg[N-2:0];
                    end
                end
            end else begin
                clk_div <= clk_div + 1;
            end
        end
        2: begin
            state <= 0;
            spi_ssel_o <= 1;
            wr_ack_o <= 1;
            do_valid_o <= 1;
            do_o <= data_in;
        end
    endcase
end

always @(posedge pclk_i or posedge rst_i)
if (rst_i) begin
    wr_ack_o <= 0;
    do_valid_o <= 0;
    do_o <= 0;
    di_req_o <= 0;
end else begin
    if (state == 2) begin
        wr_ack_o <= 0;
        do_valid_o <= 0;
        do_o <= 0;
    end
end

always @(posedge sclk_i)
if (sclk_en) begin
    spi_sck_o <= ~spi_sck_o;
end

always @(posedge sclk_i)
spi_mosi_o <= shift_reg[N-1];

endmodule
