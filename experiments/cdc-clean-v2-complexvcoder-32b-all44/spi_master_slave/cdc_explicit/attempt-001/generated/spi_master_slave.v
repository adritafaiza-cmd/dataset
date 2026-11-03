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
    reg [N-1:0]        di_reg;
    reg [N-1:0]        shift_reg;
    reg [2:0]          bit_counter;
    reg [1:0]          sclk_div_counter;
    reg                rst_sync_out;
    reg                wren_sync_out;
    reg                miso_sync_out;
    reg                wr_ack_reg;
    reg                do_valid_reg;
    reg                spi_ssel_reg;
    reg                spi_sck_reg;
    reg                spi_mosi_reg;
    reg                di_req_reg;

    // CDC instances
    cdc_sync rst_sync (
        .rst_sync_in    (rst_i),
        .rst_sync_out   (rst_sync_out),
        .wren_sync_in   (1'b0),
        .wren_sync_out  (),
        .miso_sync_in   (1'b0),
        .miso_sync_out  (),
        .sclk_i         (sclk_i),
        .pclk_i         (pclk_i)
    );

    cdc_sync wren_sync (
        .rst_sync_in    (rst_i),
        .rst_sync_out   (),
        .wren_sync_in   (wren_i),
        .wren_sync_out  (wren_sync_out),
        .miso_sync_in   (1'b0),
        .miso_sync_out  (),
        .sclk_i         (sclk_i),
        .pclk_i         (pclk_i)
    );

    cdc_sync miso_sync (
        .rst_sync_in    (rst_i),
        .rst_sync_out   (),
        .wren_sync_in   (1'b0),
        .wren_sync_out  (),
        .miso_sync_in   (spi_miso_i),
        .miso_sync_out  (miso_sync_out),
        .sclk_i         (sclk_i),
        .pclk_i         (pclk_i)
    );

    // SPI Master logic
    always @(posedge sclk_i or posedge rst_sync_out) begin
        if (rst_sync_out) begin
            spi_ssel_o <= 0;
            spi_sck_o  <= 0;
            spi_mosi_o <= 0;
            shift_reg  <= 0;
            bit_counter <= 0;
            sclk_div_counter <= 0;
            spi_sck_reg <= 0;
        end else begin
            if (wren_sync_out && !bit_counter) begin
                shift_reg <= di_reg;
                bit_counter <= N-1;
                spi_ssel_o <= 1;
            end

            if (bit_counter != 0) begin
                if (sclk_div_counter == SPI_2X_CLK_DIV - 1) begin
                    spi_sck_reg <= ~spi_sck_reg;
                    if (spi_sck_reg) begin
                        spi_mosi_o <= shift_reg[N-1];
                        shift_reg <= {shift_reg[N-2:0], 1'b0};
                        bit_counter <= bit_counter - 1;
                    end
                    sclk_div_counter <= 0;
                end else begin
                    sclk_div_counter <= sclk_div_counter + 1;
                end
            end else begin
                spi_sck_reg <= 0;
                spi_ssel_o <= 0;
            end
        end
    end

    // Parallel side logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_reg <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            do_o <= 0;
            di_req_o <= 0;
            do_valid_reg <= 0;
            wr_ack_reg <= 0;
            di_req_reg <= 0;
        end else begin
            if (wren_sync_out && !bit_counter) begin
                di_reg <= di_i;
                wr_ack_o <= 1;
                wr_ack_reg <= 1;
            end else if (wr_ack_reg) begin
                wr_ack_o <= 0;
                wr_ack_reg <= 0;
            end

            if (!bit_counter && spi_ssel_o) begin
                do_o <= {miso_sync_out, do_o[N-1:1]};
                do_valid_o <= 1;
                do_valid_reg <= 1;
                di_req_o <= 1;
                di_req_reg <= 1;
            end else if (do_valid_reg) begin
                do_valid_o <= 0;
                do_valid_reg <= 0;
                di_req_o <= 0;
                di_req_reg <= 0;
            end
        end
    end

endmodule

module cdc_sync (
    input              rst_sync_in,
    output reg         rst_sync_out,
    input              wren_sync_in,
    output reg         wren_sync_out,
    input              miso_sync_in,
    output reg         miso_sync_out,
    input              sclk_i,
    input              pclk_i
);

    // Internal signals
    reg                rst_sync_stage1;
    reg                rst_sync_stage2;
    reg                wren_sync_stage1;
    reg                wren_sync_stage2;
    reg                miso_sync_stage1;
    reg                miso_sync_stage2;

    // Reset synchronization
    always @(posedge sclk_i or posedge rst_sync_in) begin
        if (rst_sync_in) begin
            rst_sync_stage1 <= 1;
            rst_sync_stage2 <= 1;
        end else begin
            rst_sync_stage1 <= 0;
            rst_sync_stage2 <= rst_sync_stage1;
        end
    end

    assign rst_sync_out = rst_sync_stage2;

    // Write enable synchronization
    always @(posedge sclk_i or posedge rst_sync_in) begin
        if (rst_sync_in) begin
            wren_sync_stage1 <= 0;
            wren_sync_stage2 <= 0;
        end else begin
            wren_sync_stage1 <= wren_sync_in;
            wren_sync_stage2 <= wren_sync_stage1;
        end
    end

    assign wren_sync_out = wren_sync_stage2;

    // MISO synchronization
    always @(posedge pclk_i or posedge rst_sync_in) begin
        if (rst_sync_in) begin
            miso_sync_stage1 <= 0;
            miso_sync_stage2 <= 0;
        end else begin
            miso_sync_stage1 <= miso_sync_in;
            miso_sync_stage2 <= miso_sync_stage1;
        end
    end

    assign miso_sync_out = miso_sync_stage2;

endmodule
