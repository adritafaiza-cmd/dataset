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

    reg [N-1:0] data_reg;
    reg [3:0] bit_cnt;
    reg sclk_reg, sclk_prev;
    reg [N-1:0] shift_reg;
    reg spi_ssel_reg;
    reg wr_ack_reg;
    reg do_valid_reg;
    reg [N-1:0] do_reg;

    // Clock-domain crossing for reset
    reg rst_o;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) rst_o <= 1;
        else rst_o <= 0;
    end

    // SPI core logic
    always @(posedge pclk_i or posedge rst_o) begin
        if (rst_o) begin
            spi_ssel_reg <= 1;
            sclk_reg <= 0;
            shift_reg <= 0;
            wr_ack_reg <= 0;
            do_valid_reg <= 0;
            do_reg <= 0;
        end else begin
            spi_ssel_reg <= 1;
            sclk_reg <= 0;
            wr_ack_reg <= 0;
            do_valid_reg <= 0;
            do_reg <= 0;

            if (di_req_o) begin
                data_reg <= di_i;
                wr_ack_reg <= 1;
            end

            if (wren_i) begin
                spi_ssel_reg <= 0;
                shift_reg <= data_reg;
                bit_cnt <= 0;
                wr_ack_reg <= 0;
            end

            if (!spi_ssel_reg) begin
                spi_sck_reg <= ~sclk_reg;
                if (!sclk_reg) begin
                    shift_reg <= {shift_reg[0], spi_miso_i};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == N-1) begin
                        do_reg <= shift_reg;
                        do_valid_reg <= 1;
                        spi_ssel_reg <= 1;
                    end
                end
            end
        end
    end

    // Output assignments
    assign spi_ssel_o = spi_ssel_reg;
    assign spi_sck_o = spi_sck_reg;
    assign spi_mosi_o = shift_reg[7];
    assign wr_ack_o = wr_ack_reg;
    assign do_valid_o = do_valid_reg;
    assign do_o = do_reg;

endmodule
