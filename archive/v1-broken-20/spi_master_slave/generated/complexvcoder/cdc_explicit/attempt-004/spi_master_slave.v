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
    reg sclk_d, sclk_dd;
    reg pclk_d, pclk_dd;
    reg spi_ssel_d, spi_ssel_dd;
    reg spi_sck_d, spi_sck_dd;
    reg spi_mosi_d, spi_mosi_dd;
    reg wr_ack_d, wr_ack_dd;

    // CDC synchronization for sclk
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_dd <= 0;
        end else begin
            sclk_dd <= sclk_d;
            sclk_d <= sclk_i;
        end
    end

    // CDC synchronization for pclk
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_dd <= 0;
        end else begin
            pclk_dd <= pclk_d;
            pclk_d <= pclk_i;
        end
    end

    // CDC synchronization for spi_ssel
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_dd <= 0;
        end else begin
            spi_ssel_dd <= spi_ssel_d;
            spi_ssel_d <= spi_ssel_o;
        end
    end

    // CDC synchronization for spi_sck
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_dd <= 0;
        end else begin
            spi_sck_dd <= spi_sck_d;
            spi_sck_d <= spi_sck_o;
        end
    end

    // CDC synchronization for spi_mosi
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_mosi_dd <= 0;
        end else begin
            spi_mosi_dd <= spi_mosi_d;
            spi_mosi_d <= spi_mosi_o;
        end
    end

    // CDC synchronization for wr_ack
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_dd <= 0;
        end else begin
            wr_ack_dd <= wr_ack_d;
            wr_ack_d <= wr_ack_o;
        end
    end

    // SPI master logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            do_o <= 0;
            shift_reg <= 0;
            bit_cnt <= 3;
        end else begin
            if (wren_i && bit_cnt == 3) begin
                shift_reg <= di_i;
                wr_ack_o <= 1;
                di_req_o <= 1;
                bit_cnt <= 0;
            end else if (wren_i && bit_cnt < 3) begin
                spi_ssel_o <= 0;
                spi_sck_o <= 1;
                spi_mosi_o <= shift_reg[0];
                shift_reg <= {shift_reg[1:N-1], 1'b0};
                bit_cnt <= bit_cnt + 1;
            end else if (bit_cnt == 3) begin
                spi_ssel_o <= 1;
                spi_sck_o <= 0;
                spi_mosi_o <= 0;
                wr_ack_o <= 0;
                di_req_o <= 0;
                bit_cnt <= 3;
            end

            if (spi_miso_i) begin
                do_o <= {do_o[N-2:0], spi_miso_i};
                do_valid_o <= 1;
            end else begin
                do_valid_o <= 0;
            end
        end
    end

endmodule
