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
    reg                sclk_en;
    reg                sclk_cnt;
    reg                pclk_cnt;
    reg                pclk_en;
    reg                wr_ack_sync;
    reg                wr_ack_sync2;
    reg                di_req_sync;
    reg                di_req_sync2;

    // SCLK domain logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_cnt <= 0;
            sclk_en <= 0;
        end else begin
            if (sclk_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_cnt <= 0;
                sclk_en <= ~sclk_en;
            end else begin
                sclk_cnt <= sclk_cnt + 1;
            end
        end
    end

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_o <= 0;
        end else begin
            spi_sck_o <= sclk_en;
        end
    end

    // Shift register and bit counter
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_reg <= 0;
            bit_cnt <= 0;
            shift_en <= 0;
            shift_done <= 0;
            miso_sample <= 0;
        end else begin
            if (shift_en) begin
                if (bit_cnt < N) begin
                    shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                    bit_cnt <= bit_cnt + 1;
                    miso_sample <= 1;
                end else begin
                    shift_done <= 1;
                    shift_en <= 0;
                end
            end else if (shift_done) begin
                shift_done <= 0;
                miso_sample <= 0;
            end else if (wr_ack_sync2) begin
                shift_reg <= di_i;
                bit_cnt <= 0;
                shift_en <= 1;
            end
        end
    end

    // MOSI output
    assign spi_mosi_o = shift_reg[N-1];

    // PCLK domain logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_cnt <= 0;
            pclk_en <= 0;
        end else begin
            if (pclk_cnt == SPI_2X_CLK_DIV - 1) begin
                pclk_cnt <= 0;
                pclk_en <= ~pclk_en;
            end else begin
                pclk_cnt <= pclk_cnt + 1;
            end
        end
    end

    // SSEL control
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1;
        end else begin
            if (wr_ack_sync2) begin
                spi_ssel_o <= 0;
            end else if (shift_done) begin
                spi_ssel_o <= 1;
            end
        end
    end

    // Write acknowledge and request signals
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_o <= 0;
            wr_ack_sync <= 0;
            wr_ack_sync2 <= 0;
            di_req_o <= 0;
            di_req_sync <= 0;
            di_req_sync2 <= 0;
        end else begin
            wr_ack_sync <= wr_ack_sync2;
            wr_ack_sync2 <= wren_i & ~wr_ack_sync2;
            wr_ack_o <= wr_ack_sync2 & ~wr_ack_sync;

            di_req_sync <= di_req_sync2;
            di_req_sync2 <= shift_done & ~di_req_sync2;
            di_req_o <= di_req_sync2 & ~di_req_sync;
        end
    end

    // Data output and valid signal
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_o <= 0;
            do_valid_o <= 0;
        end else begin
            if (miso_sample) begin
                miso_reg <= shift_reg;
            end
            if (shift_done) begin
                do_o <= miso_reg;
                do_valid_o <= 1;
            end else begin
                do_valid_o <= 0;
            end
        end
    end

endmodule
