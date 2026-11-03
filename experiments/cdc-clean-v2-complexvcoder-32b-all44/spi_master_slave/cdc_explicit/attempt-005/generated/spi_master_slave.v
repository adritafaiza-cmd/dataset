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
    reg [N-1:0]        do_reg;
    reg [$clog2(N):0]  bit_cnt;
    reg                tx_start;
    reg                tx_done;
    reg                rx_done;
    reg [$clog2(SPI_2X_CLK_DIV):0] sclk_cnt;
    reg                miso_synced;
    reg                wren_synced;
    reg                miso_reg;
    reg                wren_reg;

    // CDC synchronization instances
    cdc_sync miso_sync (
        .clk(sclk_i),
        .async_clk(pclk_i),
        .async_rst(rst_i),
        .async_data(spi_miso_i),
        .sync_data(miso_synced)
    );

    cdc_sync wren_sync (
        .clk(pclk_i),
        .async_clk(sclk_i),
        .async_rst(rst_i),
        .async_data(wren_i),
        .sync_data(wren_synced)
    );

    // SPI master control logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 0;
            spi_sck_o  <= 0;
            shift_reg  <= 0;
            miso_reg   <= 0;
            bit_cnt    <= 0;
            tx_start   <= 0;
            tx_done    <= 0;
            rx_done    <= 0;
            sclk_cnt   <= 0;
        end else begin
            // SPI clock generation
            if (sclk_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_cnt <= 0;
                spi_sck_o  <= ~spi_sck_o;
            end else begin
                sclk_cnt <= sclk_cnt + 1;
            end

            // SPI transmission and reception
            if (tx_start) begin
                spi_ssel_o <= 1;
                if (spi_sck_o) begin
                    if (bit_cnt < N) begin
                        shift_reg <= {shift_reg[N-2:0], 1'b0};
                        miso_reg  <= miso_synced;
                        bit_cnt   <= bit_cnt + 1;
                    end else begin
                        tx_done <= 1;
                        spi_ssel_o <= 0;
                    end
                end
            end else begin
                spi_ssel_o <= 0;
            end

            // Completion detection
            if (tx_done && (bit_cnt == N)) begin
                tx_done <= 0;
                rx_done <= 1;
                do_reg  <= {>>{miso_reg, miso_reg, miso_reg, miso_reg, miso_reg, miso_reg, miso_reg, miso_reg}}; // Collect all bits
            end
        end
    end

    // Parallel side control logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o   <= 1;
            wr_ack_o   <= 0;
            do_valid_o <= 0;
            do_o       <= 0;
            tx_start   <= 0;
            rx_done    <= 0;
        end else begin
            // Word acceptance
            if (wren_synced && !wr_ack_o) begin
                shift_reg <= di_i;
                wr_ack_o  <= 1;
                di_req_o  <= 0;
                tx_start  <= 1;
                bit_cnt   <= 0;
            end

            // Handshake
            if (tx_done && rx_done) begin
                do_valid_o <= 1;
                do_o       <= do_reg;
                di_req_o   <= 1;
                rx_done    <= 0;
            end else begin
                do_valid_o <= 0;
            end

            // Re-arm
            if (do_valid_o && !wren_synced) begin
                wr_ack_o <= 0;
            end
        end
    end

    // Output assignments
    assign spi_mosi_o = shift_reg[N-1];

endmodule

module cdc_sync (
    input  clk,
    input  async_clk,
    input  async_rst,
    input  async_data,
    output sync_data
);

    reg sync_reg1;
    reg sync_reg2;

    // Reset behavior
    always @(posedge async_clk or posedge async_rst) begin
        if (async_rst) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
        end else begin
            sync_reg1 <= async_data;
            sync_reg2 <= sync_reg1;
        end
    end

    // Output assignment
    assign sync_data = sync_reg2;

endmodule
