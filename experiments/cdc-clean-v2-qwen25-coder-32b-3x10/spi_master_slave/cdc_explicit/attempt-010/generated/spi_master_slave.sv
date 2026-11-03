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
    reg [N-1:0]        rx_data;
    reg [3:0]          bit_cnt;
    reg                tx_start;
    reg                rx_done;
    reg                tx_done;
    reg                spi_sck;
    reg                spi_ssel;
    reg                di_req;
    reg                wr_ack;
    reg                do_valid;

    // Cross-domain synchronization
    reg                wren_sync;
    reg                wren_sync2;
    reg                tx_done_sync;
    reg                tx_done_sync2;

    // Synchronize wren_i from pclk_i domain to sclk_i domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            wren_sync <= 0;
            wren_sync2 <= 0;
        end else begin
            wren_sync <= wren_i;
            wren_sync2 <= wren_sync;
        end
    end

    // Synchronize tx_done from sclk_i domain to pclk_i domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_done_sync <= 0;
            tx_done_sync2 <= 0;
        end else begin
            tx_done_sync <= tx_done;
            tx_done_sync2 <= tx_done_sync;
        end
    end

    // SPI control logic in sclk_i domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck <= 0;
            spi_ssel <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
            tx_start <= 0;
            tx_done <= 0;
            rx_data <= 0;
            rx_done <= 0;
        end else begin
            // SPI clock generation
            spi_sck <= ~spi_sck;

            // SPI transaction control
            if (tx_start) begin
                spi_ssel <= 1;
                bit_cnt <= N-1;
                shift_reg <= di_i;
                tx_start <= 0;
            end else if (bit_cnt < N) begin
                spi_mosi_o <= shift_reg[N-1];
                shift_reg <= {shift_reg[N-2:0], 1'b0};
                rx_data <= {rx_data[N-2:0], spi_miso_i};
                bit_cnt <= bit_cnt - 1;
            end else begin
                spi_ssel <= 0;
                tx_done <= 1;
                rx_done <= 1;
            end

            // End of transaction
            if (tx_done && spi_sck) begin
                tx_done <= 0;
            end

            if (rx_done && ~spi_sck) begin
                rx_done <= 0;
            end
        end
    end

    // Data request and write acknowledge in pclk_i domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req <= 0;
            wr_ack <= 0;
            do_valid <= 0;
            do_o <= 0;
        end else begin
            // Request new data
            if (tx_done_sync2 && ~tx_done_sync) begin
                di_req <= 1;
            end else if (wren_sync2 && ~wren_sync) begin
                di_req <= 0;
                wr_ack <= 1;
                tx_start <= 1;
            end else begin
                wr_ack <= 0;
            end

            // Data valid and output
            if (rx_done_sync2 && ~rx_done_sync) begin
                do_valid <= 1;
                do_o <= rx_data;
            end else begin
                do_valid <= 0;
            end
        end
    end

    // Assign outputs
    assign spi_sck_o = spi_sck;
    assign spi_ssel_o = spi_ssel;
    assign di_req_o = di_req;
    assign wr_ack_o = wr_ack;
    assign do_valid_o = do_valid;
    assign do_o = do_o;

endmodule
