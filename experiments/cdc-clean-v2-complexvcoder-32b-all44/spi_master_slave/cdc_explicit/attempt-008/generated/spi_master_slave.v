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
    reg [1:0]          sclk_div_cnt;
    reg [N-1:0]        shift_reg;
    reg [$clog2(N):0]  bit_cnt;
    reg                spi_ssel;
    reg                spi_sck;
    reg                spi_mosi;
    reg                di_req;
    reg                wr_ack;
    reg                do_valid;
    reg [N-1:0]        do_reg;
    reg                wren_sync;
    reg                wren_sync2;
    reg                wren_edge;
    reg [N-1:0]        miso_reg;
    reg [N-1:0]        miso_sync;
    reg [N-1:0]        miso_sync2;
    reg                miso_edge;
    reg                sclk_rst;
    reg                pclk_rst;
    reg                rst_sync_sclk;
    reg                rst_sync_pclk;

    // Reset synchronization for sclk domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            rst_sync_sclk <= 1'b1;
        end else begin
            rst_sync_sclk <= 1'b0;
        end
    end

    // Reset synchronization for pclk domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            rst_sync_pclk <= 1'b1;
        end else begin
            rst_sync_pclk <= 1'b0;
        end
    end

    // SCLK domain logic
    always @(posedge sclk_i or posedge rst_sync_sclk) begin
        if (rst_sync_sclk) begin
            sclk_div_cnt <= 2'b00;
            spi_ssel <= 1'b0;
            spi_sck <= 1'b0;
            spi_mosi <= 1'b0;
            bit_cnt <= 0;
            shift_reg <= 0;
            miso_reg <= 0;
        end else begin
            // SCLK divider
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 2'b00;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end

            // SPI clock generation
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 2) begin
                spi_sck <= ~spi_sck;
            end

            // SPI slave select
            if (bit_cnt == 0 && wren_sync2) begin
                spi_ssel <= 1'b1;
            end else if (bit_cnt == N) begin
                spi_ssel <= 1'b0;
            end

            // Shift register and bit count
            if (spi_sck && bit_cnt < N) begin
                spi_mosi <= shift_reg[N-1];
                shift_reg <= {shift_reg[N-2:0], 1'b0};
                bit_cnt <= bit_cnt + 1;
            end

            // MISO synchronization
            miso_sync <= spi_miso_i;
            miso_sync2 <= miso_sync;
            miso_edge <= miso_sync & ~miso_sync2;
            if (spi_sck && bit_cnt < N) begin
                miso_reg <= {miso_reg[N-2:0], miso_sync};
            end
        end
    end

    // PCLK domain logic
    always @(posedge pclk_i or posedge rst_sync_pclk) begin
        if (rst_sync_pclk) begin
            di_req <= 1'b0;
            wr_ack <= 1'b0;
            do_valid <= 1'b0;
            do_o <= 0;
            wren_sync <= 1'b0;
            wren_sync2 <= 1'b0;
            wren_edge <= 1'b0;
        end else begin
            // WREN synchronization
            wren_sync <= wren_i;
            wren_sync2 <= wren_sync;
            wren_edge <= wren_sync & ~wren_sync2;

            // Data request and write acknowledge
            di_req <= ~spi_ssel;
            wr_ack <= wren_edge;

            // Data output valid and data register
            if (bit_cnt == N && spi_sck) begin
                do_valid <= 1'b1;
                do_reg <= miso_reg;
            end else begin
                do_valid <= 1'b0;
            end

            // Data output
            do_o <= do_reg;
        end
    end

    // Assignments to output ports
    assign spi_ssel_o = spi_ssel;
    assign spi_sck_o = spi_sck;
    assign spi_mosi_o = spi_mosi;
    assign di_req_o = di_req;
    assign wr_ack_o = wr_ack;
    assign do_valid_o = do_valid;
    assign do_o = do_o;

endmodule
