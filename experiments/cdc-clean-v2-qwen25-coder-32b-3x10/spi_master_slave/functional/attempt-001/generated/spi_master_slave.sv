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
    reg         sclk_div_cnt;
    reg         sclk_edge;
    reg         pclk_edge;
    reg         shift_en;
    reg         load_en;
    reg         done;

    // SCLK edge detection
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div_cnt <= 0;
            sclk_edge <= 0;
        end else begin
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 0;
                sclk_edge <= ~sclk_edge;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end
        end
    end

    // PCLK edge detection
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_edge <= 0;
        end else begin
            pclk_edge <= ~pclk_edge;
        end
    end

    // State machine
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 0;
            spi_sck_o <= 0;
            di_req_o <= 1;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            shift_en <= 0;
            load_en <= 0;
            done <= 0;
            bit_cnt <= 0;
        end else begin
            wr_ack_o <= 0;
            do_valid_o <= 0;

            if (done) begin
                spi_ssel_o <= 0;
                di_req_o <= 1;
                done <= 0;
            end else if (di_req_o && wren_i) begin
                spi_ssel_o <= 1;
                di_req_o <= 0;
                wr_ack_o <= 1;
                load_en <= 1;
                shift_en <= 1;
                bit_cnt <= N - 1;
            end else if (shift_en) begin
                if (sclk_edge) begin
                    if (bit_cnt == 0) begin
                        shift_en <= 0;
                        done <= 1;
                        do_valid_o <= 1;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
            end
        end
    end

    // Shift register and data handling
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_reg <= 0;
            do_o <= 0;
        end else begin
            if (load_en) begin
                shift_reg <= di_i;
                load_en <= 0;
            end else if (shift_en && sclk_edge) begin
                shift_reg <= {shift_reg[N-2:0], 1'b0};
                do_o <= {do_o[N-2:0], spi_miso_i};
            end
        end
    end

    // SPI signals
    assign spi_mosi_o = shift_reg[N-1];
    assign spi_sck_o = sclk_edge;

endmodule
