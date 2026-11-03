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
    reg [N-1:0] miso_reg;
    reg [N-1:0] bit_cnt;
    reg         sclk_cnt;
    reg         di_req;
    reg         wr_ack;
    reg         do_valid;

    // SCLK domain logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 0;
            spi_sck_o  <= 0;
            spi_mosi_o <= 0;
            shift_reg  <= 0;
            miso_reg   <= 0;
            bit_cnt    <= 0;
            sclk_cnt   <= 0;
        end else begin
            // SCK generation
            sclk_cnt <= ~sclk_cnt;
            spi_sck_o <= sclk_cnt;

            if (sclk_cnt == 0) begin
                if (bit_cnt < N) begin
                    // Shift out MOSI and shift in MISO
                    spi_mosi_o <= shift_reg[N-1];
                    miso_reg <= {miso_reg[N-2:0], spi_miso_i};
                    shift_reg <= {shift_reg[N-2:0], 1'b0};
                    bit_cnt <= bit_cnt + 1;
                end else begin
                    // End of transaction
                    spi_ssel_o <= 0;
                    bit_cnt <= 0;
                end
            end else begin
                if (bit_cnt == 0) begin
                    // Start of transaction
                    spi_ssel_o <= 1;
                    shift_reg <= di_i;
                end
            end
        end
    end

    // PCLK domain logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o   <= 0;
            wr_ack_o   <= 0;
            do_valid_o <= 0;
            do_o       <= 0;
        end else begin
            // Request next word
            di_req_o <= ~spi_ssel_o;

            // Write acknowledge
            wr_ack_o <= (wren_i && !wr_ack_o) ? 1 : 0;

            // Data valid and output
            do_valid_o <= (bit_cnt == N && sclk_cnt == 0) ? 1 : 0;
            do_o <= (bit_cnt == N && sclk_cnt == 0) ? miso_reg : do_o;
        end
    end

endmodule
