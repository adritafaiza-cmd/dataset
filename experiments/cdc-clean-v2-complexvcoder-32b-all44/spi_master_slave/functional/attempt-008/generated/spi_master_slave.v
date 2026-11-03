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
    reg [N-1:0]        shift_reg;
    reg [N-1:0]        bit_counter;
    reg [$clog2(SPI_2X_CLK_DIV)-1:0] sclk_div_counter;
    reg [N-1:0]        do_reg;
    reg                wr_ack;
    reg                di_req;
    reg                data_loaded;
    reg                data_received;

    // Reset all internal signals on reset
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 0;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            do_o <= 0;
            shift_reg <= 0;
            bit_counter <= 0;
            sclk_div_counter <= 0;
            do_reg <= 0;
            wr_ack <= 0;
            di_req <= 0;
            data_loaded <= 0;
            data_received <= 0;
        end else begin
            // Write acknowledge
            wr_ack_o <= wr_ack;
            wr_ack <= 0;

            // Data request
            di_req_o <= di_req;
            if (di_req) di_req <= 0;

            // Data valid
            do_valid_o <= do_valid;
            if (do_valid) do_valid <= 0;

            // Load data into shift register
            if (wren_i && !data_loaded) begin
                shift_reg <= di_i;
                wr_ack <= 1;
                data_loaded <= 1;
            end

            // Data received
            if (data_received) begin
                do_reg <= {spi_miso_i, shift_reg[N-1:1]};
                do_valid <= 1;
                data_received <= 0;
            end
        end
    end

    // SPI clock and data handling
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            spi_ssel_o <= 0;
            bit_counter <= 0;
            sclk_div_counter <= 0;
        end else begin
            // SPI clock generation
            if (sclk_div_counter == SPI_2X_CLK_DIV - 1) begin
                spi_sck_o <= ~spi_sck_o;
                sclk_div_counter <= 0;
            end else begin
                sclk_div_counter <= sclk_div_counter + 1;
            end

            // SPI data handling
            if (data_loaded) begin
                // Output MSB on MOSI
                spi_mosi_o <= shift_reg[N-1];
                spi_ssel_o <= 1;

                // Shift register and bit counter on rising edge of SCK
                if (spi_sck_o) begin
                    shift_reg <= {shift_reg[N-2:0], 1'b0};
                    bit_counter <= bit_counter + 1;

                    // Check if all bits are sent
                    if (bit_counter == N - 1) begin
                        spi_ssel_o <= 0;
                        data_received <= 1;
                        data_loaded <= 0;
                    end
                end
            end
        end
    end

    // Output the received data
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_o <= 0;
        end else begin
            do_o <= do_reg;
        end
    end

endmodule
