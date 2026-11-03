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
    reg                spi_sck_o_sync;

    // Clock domain crossing for di_i and wren_i
    always @(posedge pclk_i or posedge rst_i) begin
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
            spi_busy <= 0;
            spi_done <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
            spi_start <= 0;
        end else begin
            spi_done <= 0;
            if (!spi_busy && spi_start) begin
                spi_busy <= 1;
                spi_ssel_o <= 0;
                bit_cnt <= N-1;
                shift_reg <= di_i_sync;
                spi_sck_o <= 0;
            end else if (spi_busy) begin
                if (bit_cnt == 0) begin
                    spi_busy <= 0;
                    spi_ssel_o <= 1;
                    spi_done <= 1;
                end else begin
                    spi_sck_o <= ~spi_sck_o;
                    if (spi_sck_o) begin
                        shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                        bit_cnt <= bit_cnt - 1;
                    end
                end
            end
        end
    end

    // SPI MOSI output
    assign spi_mosi_o = shift_reg[N-1];

    // Clock domain crossing for spi_sck_o
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck_o_sync <= 0;
        end else begin
            spi_sck_o_sync <= spi_sck_o;
        end
    end

    // Parallel interface control
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 1;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            do_o <= 0;
        end else begin
            wr_ack_o <= 0;
            do_valid_o <= 0;
            if (!spi_busy && !spi_start) begin
                if (wren_i_sync) begin
                    spi_start <= 1;
                    wr_ack_o <= 1;
                    di_req_o <= 0;
                end
            end else if (spi_done) begin
                do_o <= shift_reg;
                do_valid_o <= 1;
                di_req_o <= 1;
            end
        end
    end

endmodule
