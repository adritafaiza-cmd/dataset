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

    reg [N-1:0] state;
    reg [N-1:0] spi_word;
    reg [N-1:0] sclk_reg;
    reg [N-1:0] pclk_reg;
    reg [N-1:0] spi_mosi_reg;
    reg [N-1:0] do_reg;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b1;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= 1'b0;
        end else begin
            case (state)
                2'b00: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o <= 1'b0;
                    spi_mosi_o <= di_i[0];
                    di_req_o <= 1'b0;
                    wr_ack_o <= 1'b0;
                    do_valid_o <= 1'b0;
                    if (wren_i) begin
                        state <= 2'b01;
                        spi_word <= di_i;
                        wr_ack_o <= 1'b1;
                    end
                end
                2'b01: begin
                    spi_sck_o <= ~spi_sck_o;
                    spi_mosi_o <= spi_word[N-1];
                    if (spi_sck_o) begin
                        spi_word <= {spi_word[N-2:0], spi_miso_i};
                    end
                    if (spi_sck_o && !spi_sck_o) begin
                        state <= 2'b10;
                    end
                end
                2'b10: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o <= 1'b0;
                    spi_mosi_o <= 1'b0;
                    di_req_o <= 1'b1;
                    wr_ack_o <= 1'b0;
                    do_valid_o <= 1'b1;
                    do_o <= spi_word;
                    state <= 2'b00;
                end
                default: begin
                    state <= 2'b00;
                end
            endcase
        end
    end

endmodule
