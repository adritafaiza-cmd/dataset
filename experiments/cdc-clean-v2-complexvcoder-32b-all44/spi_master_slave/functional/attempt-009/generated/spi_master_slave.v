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
reg [N-1:0] rx_shift_reg;
reg [$clog2(N)-1:0] bit_counter;
reg [$clog2(SPI_2X_CLK_DIV)-1:0] sclk_div_counter;
reg sclk_edge;
reg [N-1:0] data_in_reg;
reg [N-1:0] data_out_reg;
reg write_req;
reg write_ack;
reg read_valid;
reg spi_ssel_reg;
reg spi_sck_reg;
reg spi_mosi_reg;
reg di_req_reg;
reg wr_ack_reg;
reg do_valid_reg;
reg [N-1:0] do_reg;

// SCLK domain logic
always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        sclk_div_counter <= 0;
        sclk_edge <= 0;
        spi_sck_o <= 0;
    end else begin
        if (sclk_div_counter == SPI_2X_CLK_DIV - 1) begin
            sclk_div_counter <= 0;
            sclk_edge <= ~sclk_edge;
            spi_sck_o <= sclk_edge;
        end else begin
            sclk_div_counter <= sclk_div_counter + 1;
        end

        if (sclk_edge) begin
            shift_reg <= {shift_reg[N-2:0], 1'b0};
            spi_mosi_o <= shift_reg[N-1];
            rx_shift_reg <= {spi_miso_i, rx_shift_reg[N-1:1]};
        end
    end
end

// PCLK domain logic
always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_ssel_o <= 0;
        di_req_o <= 1;
        wr_ack_o <= 0;
        do_valid_o <= 0;
        do_o <= 0;
        bit_counter <= 0;
        write_req <= 0;
        read_valid <= 0;
        data_in_reg <= 0;
        data_out_reg <= 0;
        do_reg <= 0;
    end else begin
        // Write request handling
        if (wren_i && !write_req) begin
            data_in_reg <= di_i;
            write_req <= 1;
        end

        // Write acknowledge
        if (write_req && !spi_ssel_o) begin
            shift_reg <= data_in_reg;
            spi_ssel_o <= 1;
            write_req <= 0;
            wr_ack_o <= 1;
        end else begin
            wr_ack_o <= 0;
        end

        // Bit counter and transaction completion
        if (spi_ssel_o && sclk_edge) begin
            bit_counter <= bit_counter + 1;
            if (bit_counter == N - 1) begin
                spi_ssel_o <= 0;
                data_out_reg <= rx_shift_reg;
                read_valid <= 1;
                bit_counter <= 0;
            end
        end

        // Read valid and data output
        if (read_valid) begin
            do_reg <= data_out_reg;
            do_valid_o <= 1;
            read_valid <= 0;
        end else begin
            do_valid_o <= 0;
        end

        // Data output valid and request next data
        if (do_valid_o) begin
            di_req_o <= 1;
        end else if (write_req == 0) begin
            di_req_o <= 0;
        end

        // Data output
        do_o <= do_reg;
    end
end

endmodule
