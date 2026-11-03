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
    reg [N-1:0] tx_shift_reg;
    reg [N-1:0] rx_shift_reg;
    reg [N-1:0] bit_count;
    reg         spi_active;
    reg         spi_done;

    // Clock domain crossing: pclk to sclk
    reg [1:0] pclk_sync;
    reg       pclk_sync_next;
    wire      pclk_rising;

    // Clock domain crossing: sclk to pclk
    reg [1:0] sclk_sync;
    reg       sclk_sync_next;
    wire      sclk_rising;

    // Parallel side state
    reg       wr_ack_reg;
    reg       do_valid_reg;
    reg [N-1:0] do_reg;
    reg       di_req_reg;
    reg       word_pending;
    reg [N-1:0] pending_word;

    // SPI state machine
    localparam SPI_IDLE = 2'd0;
    localparam SPI_SHIFT = 2'd1;
    localparam SPI_DONE = 2'd2;

    reg [1:0] spi_state;
    reg [N-1:0] spi_bit_count;

    // 2x clock divider for SPI
    reg [SPI_2X_CLK_DIV-1:0] clk_div;
    wire clk_div_done;

    assign clk_div_done = (clk_div == SPI_2X_CLK_DIV - 1);

    // Synchronize pclk to sclk domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            pclk_sync <= 2'b00;
        else
            pclk_sync <= {pclk_sync[0], pclk_i};
    end

    assign pclk_rising = (pclk_sync == 2'b10);

    // Synchronize sclk to pclk domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            sclk_sync <= 2'b00;
        else
            sclk_sync <= {sclk_sync[0], sclk_i};
    end

    assign sclk_rising = (sclk_sync == 2'b10);

    // SPI master logic in sclk domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            tx_shift_reg <= {N{1'b0}};
            rx_shift_reg <= {N{1'b0}};
            bit_count <= {N{1'b0}};
            spi_active <= 1'b0;
            spi_done <= 1'b0;
            spi_state <= SPI_IDLE;
            spi_bit_count <= {N{1'b0}};
            clk_div <= {SPI_2X_CLK_DIV{1'b0}};
        end else begin
            // Default: clear one-shot signals
            spi_done <= 1'b0;

            case (spi_state)
                SPI_IDLE: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o <= 1'b0;
                    clk_div <= {SPI_2X_CLK_DIV{1'b0}};
                    if (pclk_rising && word_pending) begin
                        // Start SPI transaction
                        tx_shift_reg <= pending_word;
                        rx_shift_reg <= {N{1'b0}};
                        spi_bit_count <= {N{1'b0}};
                        spi_ssel_o <= 1'b0;
                        spi_state <= SPI_SHIFT;
                        clk_div <= {SPI_2X_CLK_DIV{1'b0}};
                    end
                end

                SPI_SHIFT: begin
                    if (clk_div_done) begin
                        clk_div <= {SPI_2X_CLK_DIV{1'b0}};
                        // Toggle SCK
                        spi_sck_o <= ~spi_sck_o;
                        if (spi_sck_o) begin
                            // Rising edge of SCK: shift in MISO, shift out MOSI
                            rx_shift_reg <= {rx_shift_reg[N-2:0], spi_miso_i};
                            tx_shift_reg <= {tx_shift_reg[N-2:0], 1'b0};
                            spi_bit_count <= spi_bit_count + 1'b1;
                            if (spi_bit_count == N - 1) begin
                                spi_state <= SPI_DONE;
                            end
                        end
                    end else begin
                        clk_div <= clk_div + 1'b1;
                    end
                end

                SPI_DONE: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o <= 1'b0;
                    spi_done <= 1'b1;
                    spi_state <= SPI_IDLE;
                end

                default: begin
                    spi_state <= SPI_IDLE;
                end
            end
        end
    end

    // MOSI output
    assign spi_mosi_o = tx_shift_reg[N-1];

    // Parallel side logic in pclk domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 1'b1;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= {N{1'b0}};
            word_pending <= 1'b0;
            pending_word <= {N{1'b0}};
        end else begin
            // Default: clear one-shot signals
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;

            if (spi_done) begin
                // SPI transaction completed
                do_o <= rx_shift_reg;
                do_valid_o <= 1'b1;
                di_req_o <= 1'b1;
            end else if (di_req_o && wren_i) begin
                // Accept new word
                pending_word <= di_i;
                word_pending <= 1'b1;
                wr_ack_o <= 1'b1;
                di_req_o <= 1'b0;
            end
        end
    end

endmodule
