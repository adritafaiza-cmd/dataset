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
    reg [2:0] bit_counter;
    reg spi_clk_div;
    reg spi_clk_toggle;
    reg di_req_o_sclk;
    reg wren_i_sclk;
    reg wr_ack_o_sclk;
    reg do_valid_o_sclk;
    reg [N-1:0] do_o_sclk;

    // Clock domain crossing instances
    cd_cross cd_cross_di_req (
        .clk_src(pclk_i),
        .clk_dst(sclk_i),
        .rst(rst_i),
        .data_src(di_req_o),
        .data_dst(di_req_o_sclk)
    );

    cd_cross cd_cross_wren (
        .clk_src(pclk_i),
        .clk_dst(sclk_i),
        .rst(rst_i),
        .data_src(wren_i),
        .data_dst(wren_i_sclk)
    );

    cd_cross cd_cross_wr_ack (
        .clk_src(sclk_i),
        .clk_dst(pclk_i),
        .rst(rst_i),
        .data_src(wr_ack_o_sclk),
        .data_dst(wr_ack_o)
    );

    cd_cross cd_cross_do_valid (
        .clk_src(sclk_i),
        .clk_dst(pclk_i),
        .rst(rst_i),
        .data_src(do_valid_o_sclk),
        .data_dst(do_valid_o)
    );

    cd_cross cd_cross_do_o (
        .clk_src(sclk_i),
        .clk_dst(pclk_i),
        .rst(rst_i),
        .data_src(do_o_sclk),
        .data_dst(do_o)
    );

    // SPI master control logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b0;
            spi_sck_o <= 1'b0;
            spi_clk_div <= 1'b0;
            spi_clk_toggle <= 1'b0;
            bit_counter <= 3'b0;
            shift_reg <= {N{1'b0}};
            wr_ack_o_sclk <= 1'b0;
            do_valid_o_sclk <= 1'b0;
            do_o_sclk <= {N{1'b0}};
        end else begin
            // SPI clock divider
            spi_clk_div <= ~spi_clk_div;

            // SPI clock toggle
            if (spi_clk_div) begin
                spi_clk_toggle <= ~spi_clk_toggle;
            end

            // SPI clock output
            spi_sck_o <= spi_clk_toggle;

            if (wren_i_sclk && !bit_counter) begin
                // Start new transaction
                spi_ssel_o <= 1'b1;
                shift_reg <= di_i;
                bit_counter <= N-1;
                wr_ack_o_sclk <= 1'b1;
            end else if (spi_clk_toggle && bit_counter) begin
                // Shift data during active SPI clock
                shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                bit_counter <= bit_counter - 1;
                wr_ack_o_sclk <= 1'b0;
            end else if (spi_clk_toggle && !bit_counter) begin
                // End transaction
                spi_ssel_o <= 1'b0;
                do_o_sclk <= shift_reg;
                do_valid_o_sclk <= 1'b1;
                bit_counter <= 3'b0;
            end else begin
                wr_ack_o_sclk <= 1'b0;
                do_valid_o_sclk <= 1'b0;
            end
        end
    end

    // Parallel interface control logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 1'b1;
        end else begin
            if (do_valid_o) begin
                di_req_o <= 1'b1;
            end else if (wren_i) begin
                di_req_o <= 1'b0;
            end
        end
    end

endmodule

module cd_cross (
    input clk_src,
    input clk_dst,
    input rst,
    input data_src,
    output reg data_dst
);

    reg data_reg;

    always @(posedge clk_src or posedge rst) begin
        if (rst) begin
            data_reg <= 1'b0;
        end else begin
            data_reg <= data_src;
        end
    end

    always @(posedge clk_dst or posedge rst) begin
        if (rst) begin
            data_dst <= 1'b0;
        end else begin
            data_dst <= data_reg;
        end
    end

endmodule
