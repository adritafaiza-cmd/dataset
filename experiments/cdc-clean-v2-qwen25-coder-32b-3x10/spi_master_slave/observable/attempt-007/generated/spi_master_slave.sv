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
    reg [3:0]          bit_cnt;
    reg                spi_start;
    reg                spi_busy;
    reg                spi_done;
    reg [N-1:0]        di_i_sync;
    reg                wren_i_sync;

    // Synchronize inputs from parallel clock domain to SPI clock domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_i_sync <= 0;
            wren_i_sync <= 0;
        end else begin
            di_i_sync <= di_i;
            wren_i_sync <= wren_i;
        end
    end

    // SPI state machine
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_start <= 0;
            spi_busy <= 0;
            spi_done <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
        end else begin
            spi_done <= 0;
            if (!spi_busy && spi_start) begin
                spi_busy <= 1;
                spi_ssel_o <= 0;
                bit_cnt <= N-1;
                shift_reg <= di_i_sync;
            end else if (spi_busy) begin
                if (bit_cnt == 0) begin
                    spi_busy <= 0;
                    spi_done <= 1;
                    spi_ssel_o <= 1;
                end else begin
                    bit_cnt <= bit_cnt - 1;
                end
            end
        end
    end

    // SPI clock generation
    reg [1:0] sclk_div;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div <= 0;
            spi_sck_o <= 0;
        end else begin
            sclk_div <= sclk_div + 1;
            if (sclk_div == SPI_2X_CLK_DIV - 1) begin
                sclk_div <= 0;
                spi_sck_o <= ~spi_sck_o;
            end
        end
    end

    // SPI data handling
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_mosi_o <= 0;
            do_o <= 0;
        end else begin
            if (spi_busy) begin
                spi_mosi_o <= shift_reg[bit_cnt];
                if (spi_sck_o) begin
                    do_o[bit_cnt] <= spi_miso_i;
                end
            end
        end
    end

    // Parallel clock domain logic
    reg wr_ack_o_reg;
    reg do_valid_o_reg;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 1;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            wr_ack_o_reg <= 0;
            do_valid_o_reg <= 0;
        end else begin
            wr_ack_o <= 0;
            do_valid_o <= 0;
            if (!spi_busy && !spi_start && wren_i_sync) begin
                spi_start <= 1;
                wr_ack_o <= 1;
                wr_ack_o_reg <= 1;
            end else if (spi_done) begin
                spi_start <= 0;
                do_valid_o <= 1;
                do_valid_o_reg <= 1;
            end else if (wr_ack_o_reg) begin
                wr_ack_o_reg <= 0;
            end else if (do_valid_o_reg) begin
                do_valid_o_reg <= 0;
                di_req_o <= 1;
            end else begin
                di_req_o <= 0;
            end
        end
    end

endmodule
