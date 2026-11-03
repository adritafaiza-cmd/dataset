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
    reg [N-1:0]        rx_shift_reg;
    reg [3:0]          bit_cnt;
    reg                tx_start;
    reg                rx_done;
    reg                tx_done;
    reg                sclk_en;
    reg                pclk_en;
    reg                sclk_rst;
    reg                pclk_rst;
    reg [N-1:0]        di_sync;
    reg                wren_sync;
    reg                wr_ack_sync;
    reg                do_valid_sync;
    reg [N-1:0]        do_o_sync;

    // Clock enable generation
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_en <= 0;
            sclk_rst <= 1;
        end else begin
            sclk_en <= ~sclk_en;
            sclk_rst <= 0;
        end
    end

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_en <= 0;
            pclk_rst <= 1;
        end else begin
            pclk_en <= ~pclk_en;
            pclk_rst <= 0;
        end
    end

    // Synchronization of inputs from pclk domain to sclk domain
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            di_sync <= 0;
            wren_sync <= 0;
        end else begin
            di_sync <= di_i;
            wren_sync <= wren_i;
        end
    end

    // Synchronization of outputs from sclk domain to pclk domain
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            wr_ack_sync <= 0;
            do_valid_sync <= 0;
            do_o_sync <= 0;
        end else begin
            wr_ack_sync <= wr_ack_o;
            do_valid_sync <= do_valid_o;
            do_o_sync <= do_o;
        end
    end

    // Assign synchronized outputs
    assign wr_ack_o = wr_ack_sync;
    assign do_valid_o = do_valid_sync;
    assign do_o = do_o_sync;

    // SPI control logic
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            spi_ssel_o <= 0;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            tx_start <= 0;
            rx_done <= 0;
            tx_done <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
            rx_shift_reg <= 0;
        end else if (sclk_en) begin
            if (tx_start) begin
                spi_ssel_o <= 1;
                spi_sck_o <= 0;
                shift_reg <= di_sync;
                bit_cnt <= N-1;
                tx_start <= 0;
            end else if (bit_cnt < N) begin
                spi_sck_o <= ~spi_sck_o;
                if (spi_sck_o) begin
                    spi_mosi_o <= shift_reg[bit_cnt];
                    shift_reg <= {shift_reg[N-2:0], 1'b0};
                    rx_shift_reg <= {spi_miso_i, rx_shift_reg[N-1:1]};
                    bit_cnt <= bit_cnt - 1;
                end
            end else begin
                spi_sck_o <= 0;
                spi_ssel_o <= 0;
                rx_done <= 1;
                tx_done <= 1;
            end
        end
    end

    // Request and acknowledge logic
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
        end else begin
            if (tx_done) begin
                wr_ack_o <= 1;
                tx_done <= 0;
            end else if (wr_ack_o) begin
                wr_ack_o <= 0;
            end

            if (rx_done) begin
                do_valid_o <= 1;
                do_o <= rx_shift_reg;
                rx_done <= 0;
            end else if (do_valid_o) begin
                do_valid_o <= 0;
            end

            if (tx_done && !wren_sync) begin
                di_req_o <= 1;
            end else if (di_req_o && !wren_sync) begin
                di_req_o <= 0;
            end

            if (wren_sync && !tx_start && !tx_done) begin
                tx_start <= 1;
            end
        end
    end

endmodule
