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
    reg [N-1:0] data_in;
    reg [N-1:0] data_out;
    reg [3:0]   bit_cnt;
    reg         sclk_div_cnt;
    reg         sclk_edge;
    reg         transfer_active;
    reg         data_loaded;

    // SCLK Divider
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div_cnt <= 0;
        end else begin
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 0;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end
        end
    end

    // SCLK Edge Detection
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_edge <= 0;
        end else begin
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_edge <= ~sclk_edge;
            end
        end
    end

    // SPI Control Logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o  <= 1'b0;
            di_req_o   <= 1'b1;
            wr_ack_o   <= 1'b0;
            do_valid_o <= 1'b0;
            data_loaded <= 1'b0;
            transfer_active <= 1'b0;
            bit_cnt <= 0;
            shift_reg <= 0;
            data_in <= 0;
            data_out <= 0;
        end else begin
            // Request new data
            if (!transfer_active && !data_loaded) begin
                di_req_o <= 1'b1;
            end else begin
                di_req_o <= 1'b0;
            end

            // Accept new data
            if (wren_i && di_req_o) begin
                data_in <= di_i;
                data_loaded <= 1'b1;
                wr_ack_o <= 1'b1;
            end else begin
                wr_ack_o <= 1'b0;
            end

            // Start transfer
            if (data_loaded && !transfer_active) begin
                transfer_active <= 1'b1;
                spi_ssel_o <= 1'b0;
                shift_reg <= data_in;
                bit_cnt <= N - 1;
                data_loaded <= 1'b0;
            end

            // Shift data
            if (transfer_active && sclk_edge) begin
                spi_sck_o <= ~spi_sck_o;
                if (spi_sck_o) begin
                    spi_mosi_o = shift_reg[bit_cnt];
                    if (bit_cnt == 0) begin
                        transfer_active <= 1'b0;
                        spi_ssel_o <= 1'b1;
                        data_out <= shift_reg;
                        do_valid_o <= 1'b1;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end else begin
                    data_out[bit_cnt] = spi_miso_i;
                end
            end

            // End of transfer
            if (do_valid_o) begin
                do_valid_o <= 1'b0;
                do_o <= data_out;
            end
        end
    end

    assign spi_mosi_o = shift_reg[bit_cnt];

endmodule
