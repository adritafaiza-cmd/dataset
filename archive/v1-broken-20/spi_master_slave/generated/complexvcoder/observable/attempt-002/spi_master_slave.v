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
    reg [N-1:0] p2s_out;
    reg [N-1:0] s2p_out;
    reg [2:0] sclk_cnt;
    reg [3:0] bit_cnt;
    reg [N-1:0] data_reg;
    reg sclk_sreg;
    reg spi_sck_sreg;
    reg spi_mosi_sreg;
    reg [N-1:0] spi_miso_sreg;
    reg sclk_rst;
    reg spi_sck_rst;
    reg spi_mosi_rst;
    reg spi_miso_rst;

    // SPI Controller instance
    spi_controller #(.N(N), .SPI_2X_CLK_DIV(SPI_2X_CLK_DIV)) spi_ctrl (
        .pclk_i(pclk_i),
        .rst_i(rst_i),
        .spi_clk_i(sclk_sreg),
        .spi_ssel_o(spi_ssel_o),
        .spi_sck_o(spi_sck_o),
        .spi_mosi_o(spi_mosi_o),
        .spi_miso_i(spi_miso_sreg),
        .wr_en(di_req_o),
        .wr_data(p2s_out),
        .rd_en(do_valid_o),
        .rd_data(s2p_out)
    );

    // Parallel to Serial converter instance
    parallel_to_serial #(.N(N)) p2s (
        .pclk_i(pclk_i),
        .rst_i(rst_i),
        .di_i(di_i),
        .wren_i(wren_i),
        .do_o(p2s_out)
    );

    // Serial to Parallel converter instance
    serial_to_parallel #(.N(N)) s2p (
        .pclk_i(pclk_i),
        .rst_i(rst_i),
        .di_i(spi_miso_sreg),
        .do_o(do_o)
    );

    // Clock domain crossing for SPI signals
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_sreg <= 0;
            spi_mosi_sreg <= 0;
        end else begin
            spi_sck_sreg <= spi_sck_o;
            spi_mosi_sreg <= spi_mosi_o;
        end
    end

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_miso_sreg <= 0;
        end else begin
            spi_miso_sreg <= spi_miso_i;
        end
    end

    // Reset logic for all modules
    always @(posedge pclk_i) begin
        if (rst_i) begin
            sclk_rst <= 1;
            spi_sck_rst <= 1;
            spi_mosi_rst <= 1;
            spi_miso_rst <= 1;
        end else begin
            sclk_rst <= 0;
            spi_sck_rst <= 0;
            spi_mosi_rst <= 0;
            spi_miso_rst <= 0;
        end
    end

    // Handshake logic for data input and output
    always @(posedge pclk_i) begin
        if (rst_i) begin
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
        end else begin
            if (wren_i && !di_req_o) begin
                di_req_o <= 1;
            end
            if (spi_ctrl.wr_ack_o) begin
                wr_ack_o <= 1;
            end else begin
                wr_ack_o <= 0;
            end
            if (spi_ctrl.rd_en) begin
                do_valid_o <= 1;
            end else begin
                do_valid_o <= 0;
            end
        end
    end

    // SPI communication logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_cnt <= 0;
            bit_cnt <= 0;
        end else begin
            if (spi_ctrl.wr_en || spi_ctrl.rd_en) begin
                if (sclk_cnt == SPI_2X_CLK_DIV - 1) begin
                    sclk_cnt <= 0;
                    if (bit_cnt < N) begin
                        bit_cnt <= bit_cnt + 1;
                    end
                end else begin
                    sclk_cnt <= sclk_cnt + 1;
                end
            end
        end
    end

endmodule
