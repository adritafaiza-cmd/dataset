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
reg [3:0] sclk_div;
reg [N-1:0] capture_reg;
reg [3:0] bit_cnt;
reg [1:0] state;

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_ssel_o <= 1'b1;
        spi_sck_o <= 1'b0;
        sclk_div <= 4'b0;
        bit_cnt <= 4'b0;
        state <= 2'b0;
    end else begin
        case (state)
            2'b00: begin // idle
                spi_ssel_o <= 1'b1;
                spi_sck_o <= 1'b0;
                if (di_req_o) begin
                    state <= 2'b01;
                end
            end
            2'b01: begin // capture
                if (sclk_div == SPI_2X_CLK_DIV) begin
                    sclk_div <= 4'b0;
                    capture_reg[N-1] <= spi_miso_i;
                    if (bit_cnt == N-1) begin
                        state <= 2'b10;
                    end else begin
                        bit_cnt <= bit_cnt + 1'b1;
                    end
                end else begin
                    sclk_div <= sclk_div + 1'b1;
                end
            end
            2'b10: begin // shift
                spi_ssel_o <= 1'b0;
                if (sclk_div == SPI_2X_CLK_DIV) begin
                    sclk_div <= 4'b0;
                    spi_mosi_o <= shift_reg[N-1];
                    shift_reg <= {shift_reg[N-2:0], 1'b0};
                    if (bit_cnt == N-1) begin
                        state <= 2'b00;
                    end else begin
                        bit_cnt <= bit_cnt + 1'b1;
                    end
                end else begin
                    sclk_div <= sclk_div + 1'b1;
                    spi_sck_o <= ~spi_sck_o;
                end
            end
        endcase
    end
end

always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        di_req_o <= 1'b0;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
        do_o <= {N{1'b0}};
    end else begin
        case (state)
            2'b00: begin // idle
                if (wren_i) begin
                    shift_reg <= di_i;
                    bit_cnt <= 4'b0;
                    di_req_o <= 1'b0;
                    wr_ack_o <= 1'b1;
                end else begin
                    wr_ack_o <= 1'b0;
                end
                if (~di_req_o) begin
                    di_req_o <= 1'b1;
                end
            end
            2'b01: begin // capture
                di_req_o <= 1'b0;
            end
            2'b10: begin // shift
                if (bit_cnt == N-1) begin
                    do_o <= capture_reg;
                    do_valid_o <= 1'b1;
                end else begin
                    do_valid_o <= 1'b0;
                end
            end
        endcase
    end
end

endmodule
