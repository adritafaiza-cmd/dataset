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

    // Internal signals
    reg [N-1:0] shift_reg;
    reg [2:0] bit_cnt;
    reg [N-1:0] data_out;
    reg [N-1:0] data_in;
    reg spi_ssel;
    reg spi_sck;
    reg spi_mosi;
    reg sclk_div;
    reg pclk_div;

    // SPI master core logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            shift_reg <= 0;
            bit_cnt <= 0;
            data_out <= 0;
            data_in <= 0;
            spi_ssel <= 1'b1;
            spi_sck <= 1'b0;
            spi_mosi <= 1'b0;
        end else begin
            if (di_req_o && wren_i) begin
                wr_ack_o <= 1'b0;
                shift_reg <= di_i;
                bit_cnt <= 0;
                spi_ssel_o <= 1'b0;
                spi_sck_o <= 1'b0;
                spi_mosi_o <= shift_reg[0];
                di_req_o <= 1'b0;
            end else if (!spi_ssel_o) begin
                if (bit_cnt < N) begin
                    spi_sck_o <= ~spi_sck_o;
                    if (spi_sck_o) begin
                        spi_mosi_o <= shift_reg[0];
                        shift_reg <= {shift_reg[1:N-1], spi_miso_i};
                        bit_cnt <= bit_cnt + 1;
                    end
                end else begin
                    wr_ack_o <= 1'b1;
                    spi_ssel_o <= 1'b1;
                end
            end
        end
    end

    // Clock dividers
    always @(posedge sclk_i) begin
        sclk_div <= ~sclk_div;
    end
    always @(posedge pclk_i) begin
        pclk_div <= ~pclk_div;
    end

    // SPI signals cross-clock domain
    always @(posedge pclk_i) begin
        spi_ssel <= spi_ssel_o;
        spi_sck <= spi_sck_o;
        spi_mosi <= spi_mosi_o;
    end
    always @(posedge sclk_i) begin
        spi_miso_i <= spi_miso;
    end

    // Output data when valid
    always @(posedge pclk_i) begin
        if (wr_ack_o) begin
            do_valid_o <= 1'b1;
            do_o <= data_out;
        end else begin
            do_valid_o <= 1'b0;
        end
    end

endmodule
