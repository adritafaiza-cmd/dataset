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
    reg [2:0] bit_counter;
    reg [N-1:0] tx_word;
    reg [N-1:0] rx_word;
    reg sck_toggle, sck_toggle_d, sck_toggle_dd, sck_toggle_edge;
    reg tx_complete, rx_complete, tx_start, rx_start;
    reg di_req_ff, wr_ack_ff, do_valid_ff;

    // CDC synchronization for MISO
    reg miso_sync_in, miso_sync_out;
    reg wren_sync_in, wren_sync_out;
    reg [N-1:0] di_sync_in, di_sync_out;

    // CDC module instantiation for MISO
    cdc_sync #(
        .N(1)
    ) cdc_miso_sync (
        .sclk_i(sclk_i),
        .pclk_i(pclk_i),
        .rst_i(rst_i),
        .miso_sync_in(spi_miso_i),
        .miso_sync_out(miso_sync_out)
    );

    // CDC module instantiation for WREN
    cdc_sync #(
        .N(1)
    ) cdc_wren_sync (
        .sclk_i(sclk_i),
        .pclk_i(pclk_i),
        .rst_i(rst_i),
        .miso_sync_in(wren_i),
        .miso_sync_out(wren_sync_out)
    );

    // CDC module instantiation for DI
    cdc_sync #(
        .N(N)
    ) cdc_di_sync (
        .sclk_i(sclk_i),
        .pclk_i(pclk_i),
        .rst_i(rst_i),
        .miso_sync_in(di_i),
        .miso_sync_out(di_sync_out)
    );

    // CDC Sync module for single-bit signals
    module cdc_sync #(
        parameter N = 1
    ) (
        input sclk_i,
        input pclk_i,
        input rst_i,
        input [N-1:0] miso_sync_in,
        output reg [N-1:0] miso_sync_out
    );
        reg [N-1:0] sync_stage1;
        reg [N-1:0] sync_stage2;

        always @(posedge sclk_i or posedge rst_i) begin
            if (rst_i) begin
                sync_stage1 <= {N{1'b0}};
                sync_stage2 <= {N{1'b0}};
            end else begin
                sync_stage1 <= miso_sync_in;
                sync_stage2 <= sync_stage1;
            end
        end

        always @(posedge pclk_i or posedge rst_i) begin
            if (rst_i)
                miso_sync_out <= {N{1'b0}};
            else
                miso_sync_out <= sync_stage2;
        end
    endmodule

    // SCK toggle generation
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sck_toggle <= 1'b0;
            sck_toggle_d <= 1'b0;
            sck_toggle_dd <= 1'b0;
        end else begin
            sck_toggle <= ~sck_toggle;
            sck_toggle_d <= sck_toggle;
            sck_toggle_dd <= sck_toggle_d;
        end
    end

    assign sck_toggle_edge = sck_toggle_d & ~sck_toggle_dd;

    // SPI control and data handling
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b0;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            shift_reg <= {N{1'b0}};
            bit_counter <= 3'b0;
            tx_word <= {N{1'b0}};
            rx_word <= {N{1'b0}};
            tx_complete <= 1'b0;
            rx_complete <= 1'b0;
            tx_start <= 1'b0;
            rx_start <= 1'b0;
        end else begin
            if (tx_start) begin
                spi_ssel_o <= 1'b1;
                shift_reg <= tx_word;
                bit_counter <= 3'b0;
                tx_start <= 1'b0;
            end

            if (sck_toggle_edge) begin
                spi_sck_o <= sck_toggle;
                spi_mosi_o <= shift_reg[N-1];
                shift_reg <= {shift_reg[N-2:0], 1'b0};
                bit_counter <= bit_counter + 1;
            end

            if (bit_counter == N-1 && sck_toggle_edge) begin
                tx_complete <= 1'b1;
                rx_start <= 1'b1;
            end

            if (rx_start && sck_toggle_edge) begin
                rx_word <= {rx_word[N-2:0], miso_sync_out};
                bit_counter <= bit_counter - 1;
            end

            if (bit_counter == 0 && sck_toggle_edge) begin
                rx_complete <= 1'b1;
                spi_ssel_o <= 1'b0;
                rx_start <= 1'b0;
            end
        end
    end

    // Control signals handling in pclk domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= {N{1'b0}};
            di_req_ff <= 1'b0;
            wr_ack_ff <= 1'b0;
            do_valid_ff <= 1'b0;
        end else begin
            if (wren_sync_out && ~wr_ack_ff) begin
                tx_word <= di_sync_out;
                tx_start <= 1'b1;
                wr_ack_o <= 1'b1;
                wr_ack_ff <= 1'b1;
            end else if (wr_ack_o) begin
                wr_ack_o <= 1'b0;
                wr_ack_ff <= 1'b0;
            end

            if (tx_complete) begin
                tx_complete <= 1'b0;
                di_req_o <= 1'b1;
                di_req_ff <= 1'b1;
            end else if (di_req_o && ~wren_sync_out) begin
                di_req_o <= 1'b0;
                di_req_ff <= 1'b0;
            end

            if (rx_complete) begin
                do_o <= rx_word;
                do_valid_o <= 1'b1;
                do_valid_ff <= 1'b1;
                rx_complete <= 1'b0;
            end else if (do_valid_o) begin
                do_valid_o <= 1'b0;
                do_valid_ff <= 1'b0;
            end
        end
    end

endmodule
