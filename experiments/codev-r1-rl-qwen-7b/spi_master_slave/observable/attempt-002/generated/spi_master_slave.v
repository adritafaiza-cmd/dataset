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

    // CDC signals for transfer start
    reg transfer_pending_pclk;
    reg transfer_pending_pclk_sync1, transfer_pending_pclk_sync2;
    reg transfer_start_pulse;

    // CDC signals for done
    reg done_spi;
    reg done_spi_sync1, done_spi_sync2;

    // SPI domain registers
    reg [N-1:0] tx_shift;
    reg [N-1:0] rx_shift;
    reg [$clog2(N):0] bit_count;
    reg state; // 0: idle, 1: active
    reg sck_internal;
    reg [15:0] sclk_div_counter;

    // PCLK domain registers
    reg [N-1:0] tx_buffer;
    reg di_req_reg;
    reg transfer_pending_pclk_reg;

    // SPI clock generation
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div_counter <= 0;
            sck_internal <= 0;
        end else begin
            if (sclk_div_counter == SPI_2X_CLK_DIV - 1) begin
                sclk_div_counter <= 0;
                sck_internal <= ~sck_internal;
            end else begin
                sclk_div_counter <= sclk_div_counter + 1;
            end
        end
    end

    assign spi_sck_o = (state == 1) ? sck_internal : 1'b0;

    // State machine for SPI
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= 0;
            spi_ssel_o <= 1'b1;
            tx_shift <= 0;
            rx_shift <= 0;
            bit_count <= N;
            done_spi <= 0;
        end else begin
            done_spi <= 0;
            if (state == 0) begin // IDLE
                if (transfer_pending_pclk_sync2) begin
                    spi_ssel_o <= 1'b0;
                    tx_shift <= tx_buffer;
                    state <= 1;
                    bit_count <= N;
                end
            end else begin // ACTIVE
                if (sck_internal) begin // rising edge
                    rx_shift <= {rx_shift[N-2:0], spi_miso_i};
                    bit_count <= bit_count - 1;
                    if (bit_count == 1) begin
                        state <= 0;
                        spi_ssel_o <= 1'b1;
                        done_spi <= 1;
                    end
                end
                if (!sck_internal) begin // falling edge
                    tx_shift <= tx_shift << 1;
                end
            end
        end
    end

    // CDC for transfer start (PCLK to SPI)
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            transfer_pending_pclk <= 0;
            di_req_reg <= 1;
            transfer_pending_pclk_reg <= 0;
            tx_buffer <= 0;
            wr_ack_o <= 0;
        end else begin
            wr_ack_o <= 0;
            if (wren_i && di_req_reg) begin
                tx_buffer <= di_i;
                transfer_pending_pclk <= 1;
                di_req_reg <= 0;
                wr_ack_o <= 1;
            end else if (done_spi_sync2) begin
                di_req_reg <= 1;
                transfer_pending_pclk <= 0;
            end
        end
    end

    // CDC for transfer start (PCLK to SPI)
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            transfer_pending_pclk_sync1 <= 0;
            transfer_pending_pclk_sync2 <= 0;
        end else begin
            transfer_pending_pclk_sync1 <= transfer_pending_pclk;
            transfer_pending_pclk_sync2 <= transfer_pending_pclk_sync1;
        end
    end

    // CDC for done (SPI to PCLK)
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            done_spi_sync1 <= 0;
            done_spi_sync2 <= 0;
            do_valid_o <= 0;
            do_o <= 0;
        end else begin
            done_spi_sync1 <= done_spi;
            done_spi_sync2 <= done_spi_sync1;
            if (done_spi_sync2) begin
                do_valid_o <= 1;
                do_o <= rx_shift;
            end else begin
                do_valid_o <= 0;
            end
        end
    end

    assign spi_mosi_o = tx_shift[N-1];

    assign di_req_o = di_req_reg;

endmodule
