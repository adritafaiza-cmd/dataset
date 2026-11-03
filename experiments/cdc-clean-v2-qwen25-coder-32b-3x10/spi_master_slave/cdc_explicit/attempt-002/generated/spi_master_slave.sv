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
    reg [N-1:0]        miso_reg;
    reg [3:0]          bit_cnt;
    reg                shift_en;
    reg                shift_done;
    reg                miso_sample;
    reg                miso_sample_d;
    reg                miso_sample_d2;
    reg                wren_sync;
    reg                wren_sync_d;
    reg                wren_sync_d2;
    reg                di_req_sync;
    reg                di_req_sync_d;
    reg                di_req_sync_d2;

    // Clock domain crossing for wren_i
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wren_sync <= 1'b0;
            wren_sync_d <= 1'b0;
            wren_sync_d2 <= 1'b0;
        end else begin
            wren_sync <= wren_i;
            wren_sync_d <= wren_sync;
            wren_sync_d2 <= wren_sync_d;
        end
    end

    // Clock domain crossing for di_req_o
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_sync <= 1'b0;
            di_req_sync_d <= 1'b0;
            di_req_sync_d2 <= 1'b0;
        end else begin
            di_req_sync <= di_req_o;
            di_req_sync_d <= di_req_sync;
            di_req_sync_d2 <= di_req_sync_d;
        end
    end

    // SPI clock generation
    reg [1:0] sclk_div;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div <= 2'b00;
            spi_sck_o <= 1'b0;
        end else begin
            sclk_div <= sclk_div + 1'b1;
            if (sclk_div == SPI_2X_CLK_DIV - 1) begin
                spi_sck_o <= ~spi_sck_o;
                sclk_div <= 2'b00;
            end
        end
    end

    // SPI control logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            shift_reg <= {N{1'b0}};
            miso_reg <= {N{1'b0}};
            bit_cnt <= 4'b0000;
            shift_en <= 1'b0;
            shift_done <= 1'b0;
            miso_sample <= 1'b0;
            miso_sample_d <= 1'b0;
            miso_sample_d2 <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            di_req_o <= 1'b0;
        end else begin
            if (shift_done) begin
                spi_ssel_o <= 1'b1;
                do_o <= miso_reg;
                do_valid_o <= 1'b1;
                di_req_o <= 1'b1;
            end else begin
                do_valid_o <= 1'b0;
                di_req_o <= 1'b0;
            end

            if (wren_sync_d2 && !wren_sync_d) begin
                spi_ssel_o <= 1'b0;
                shift_reg <= di_i;
                bit_cnt <= N - 1;
                shift_en <= 1'b1;
                wr_ack_o <= 1'b1;
            end else if (shift_en) begin
                if (spi_sck_o) begin
                    miso_sample <= spi_miso_i;
                end else begin
                    miso_sample <= miso_sample;
                end

                if (bit_cnt == 4'b0000) begin
                    shift_en <= 1'b0;
                    shift_done <= 1'b1;
                end else begin
                    shift_en <= 1'b1;
                    shift_done <= 1'b0;
                    bit_cnt <= bit_cnt - 1;
                end
            end else begin
                wr_ack_o <= 1'b0;
            end

            // MISO sampling
            miso_sample_d <= miso_sample;
            miso_sample_d2 <= miso_sample_d;

            if (!spi_sck_o) begin
                miso_reg <= {miso_reg[N-2:0], miso_sample_d2};
            end
        end
    end

endmodule
