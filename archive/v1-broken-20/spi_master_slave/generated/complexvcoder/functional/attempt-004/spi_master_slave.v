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
    reg [3:0]   bit_cnt;
    reg         sclk_reg;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o  <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o   <= 1'b0;
            wr_ack_o   <= 1'b0;
            do_valid_o <= 1'b0;
            do_o       <= 1'b0;
            shift_reg  <= 1'b0;
            bit_cnt    <= 4'b0000;
        end else begin
            if (wren_i) begin
                wr_ack_o <= 1'b1;
                di_req_o <= 1'b0;
                shift_reg <= di_i;
                bit_cnt <= 4'b1000;
            end else begin
                wr_ack_o <= 1'b0;
                di_req_o <= 1'b1;
            end

            if (bit_cnt != 4'b0000) begin
                spi_ssel_o <= 1'b0;
                spi_sck_o  <= sclk_reg;
                spi_mosi_o <= shift_reg[N-1];
                shift_reg  <= {shift_reg[N-2:0], spi_miso_i};
                bit_cnt    <= bit_cnt - 1;
                sclk_reg   <= ~sclk_reg;
            end else begin
                spi_ssel_o <= 1'b1;
            end

            if (bit_cnt == 4'b0000) begin
                do_valid_o <= 1'b1;
                do_o       <= shift_reg;
            end else begin
                do_valid_o <= 1'b0;
            end
        end
    end

endmodule
