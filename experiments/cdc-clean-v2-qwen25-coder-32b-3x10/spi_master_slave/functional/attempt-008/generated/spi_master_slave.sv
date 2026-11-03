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
    reg         pclk_edge;
    reg         start_transfer;
    reg         transfer_in_progress;

    // Synchronous reset for pclk domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 1'b1;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            spi_ssel_o <= 1'b0;
            spi_sck_o <= 1'b0;
            start_transfer <= 1'b0;
            transfer_in_progress <= 1'b0;
            bit_cnt <= 4'b0;
            sclk_div_cnt <= 1'b0;
        end else begin
            // Request new data if not busy
            if (!transfer_in_progress) begin
                di_req_o <= 1'b1;
            end

            // Accept new data
            if (wren_i && di_req_o) begin
                data_in <= di_i;
                di_req_o <= 1'b0;
                wr_ack_o <= 1'b1;
                start_transfer <= 1'b1;
            end else begin
                wr_ack_o <= 1'b0;
            end

            // Start transfer
            if (start_transfer) begin
                start_transfer <= 1'b0;
                transfer_in_progress <= 1'b1;
                spi_ssel_o <= 1'b1;
                shift_reg <= data_in;
                bit_cnt <= N-1;
            end

            // Transfer in progress
            if (transfer_in_progress) begin
                if (sclk_edge) begin
                    if (bit_cnt == 0) begin
                        transfer_in_progress <= 1'b0;
                        spi_ssel_o <= 1'b0;
                        do_o <= data_out;
                        do_valid_o <= 1'b1;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
            end else begin
                do_valid_o <= 1'b0;
            end
        end
    end

    // Synchronous reset for sclk domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_o <= 1'b0;
            sclk_div_cnt <= 1'b0;
            sclk_edge <= 1'b0;
            data_out <= {N{1'b0}};
        end else begin
            // SCK generation
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 1'b0;
                spi_sck_o <= ~spi_sck_o;
                sclk_edge <= 1'b1;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
                sclk_edge <= 1'b0;
            end

            // Shift register and data out capture
            if (sclk_edge && spi_sck_o) begin
                spi_mosi_o <= shift_reg[N-1];
                shift_reg <= {shift_reg[N-2:0], 1'b0};
                data_out <= {data_out[N-2:0], spi_miso_i};
            end
        end
    end

endmodule
