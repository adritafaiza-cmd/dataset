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

    // State machine states
    localparam S_IDLE    = 2'd0;
    localparam S_WAIT_WR = 2'd1;
    localparam S_SHIFT   = 2'd2;
    localparam S_DONE    = 2'd3;

    reg [1:0] state;
    reg [N-1:0] tx_shift_reg;
    reg [N-1:0] rx_shift_reg;
    reg [N-1:0] bit_count;
    reg [N-1:0] tx_word;
    reg         word_ready;

    // SCLK divider counter
    reg [31:0] clk_div_cnt;
    reg         clk_div_done;

    // Asynchronous reset for sclk domain
    reg         sclk_rst;
    reg         sclk_rst_d1;
    reg         sclk_rst_d2;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_rst_d1 <= 1'b1;
            sclk_rst_d2 <= 1'b1;
        end else begin
            sclk_rst_d1 <= 1'b1;
            sclk_rst_d2 <= sclk_rst_d1;
        end
    end

    assign sclk_rst = sclk_rst_d2;

    // SCLK generation logic
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            clk_div_cnt  <= 0;
            clk_div_done <= 1'b0;
            spi_sck_o    <= 1'b0;
        end else begin
            if (state == S_SHIFT) begin
                if (clk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                    clk_div_cnt  <= 0;
                    clk_div_done <= 1'b1;
                    spi_sck_o    <= ~spi_sck_o;
                end else begin
                    clk_div_cnt  <= clk_div_cnt + 1;
                    clk_div_done <= 1'b0;
                end
            end else begin
                clk_div_cnt  <= 0;
                clk_div_done <= 1'b0;
                spi_sck_o    <= 1'b0;
            end
        end
    end

    // Main state machine in sclk domain
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            state        <= S_IDLE;
            spi_ssel_o   <= 1'b0;
            di_req_o     <= 1'b0;
            tx_shift_reg <= {N{1'b0}};
            rx_shift_reg <= {N{1'b0}};
            bit_count    <= {N{1'b0}};
            word_ready   <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    spi_ssel_o <= 1'b0;
                    di_req_o   <= 1'b0;
                    if (word_ready) begin
                        state      <= S_SHIFT;
                        spi_ssel_o <= 1'b1;
                        tx_shift_reg <= tx_word;
                        rx_shift_reg <= {N{1'b0}};
                        bit_count    <= N - 1;
                        word_ready   <= 1'b0;
                    end
                end

                S_SHIFT: begin
                    if (clk_div_done) begin
                        // On rising edge of SCK, shift out MSB and capture MISO
                        // We toggle SCK, so we need to determine if this is a rising or falling edge
                        // Since we start with SCK low and toggle, first toggle is rising
                        // We'll use a simple approach: shift on every toggle, but only capture on rising
                        // For simplicity, let's shift on every other toggle
                        // Actually, let's use a different approach:
                        // We'll shift out on the rising edge and capture on the rising edge
                        // Since we toggle SCK, we need to track the edge direction
                        
                        // Let's simplify: shift out the MSB and capture MISO on every SCK toggle
                        // This is a common approach for SPI master
                        rx_shift_reg <= {spi_miso_i, rx_shift_reg[N-1:1]};
                        tx_shift_reg <= {tx_shift_reg[N-2:0], 1'b0};
                        
                        if (bit_count == 0) begin
                            state <= S_DONE;
                        end else begin
                            bit_count <= bit_count - 1;
                        end
                    end
                end

                S_DONE: begin
                    spi_ssel_o <= 1'b0;
                    state      <= S_IDLE;
                    di_req_o   <= 1'b1;
                end

                default: begin
                    state <= S_IDLE;
                end
            end
        end
    end

    // PCLK domain: handle write requests and output valid
    reg         pclk_rst;
    reg         pclk_rst_d1;
    reg         pclk_rst_d2;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_rst_d1 <= 1'b1;
            pclk_rst_d2 <= 1'b1;
        end else begin
            pclk_rst_d1 <= 1'b1;
            pclk_rst_d2 <= pclk_rst_d1;
        end
    end

    assign pclk_rst = pclk_rst_d2;

    // Synchronize sclk domain signals to pclk domain
    reg [N-1:0] tx_word_sync;
    reg         word_ready_sync;
    reg         di_req_sync;
    reg [N-1:0] rx_shift_reg_sync;
    reg         done_sync;

    // Synchronize word_ready
    reg [2:0] word_ready_sync_reg;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            word_ready_sync_reg <= 3'b0;
        end else begin
            word_ready_sync_reg <= {word_ready_sync_reg[1:0], word_ready};
        end
    end
    assign word_ready_sync = word_ready_sync_reg[2];

    // Synchronize di_req
    reg [2:0] di_req_sync_reg;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            di_req_sync_reg <= 3'b0;
        end else begin
            di_req_sync_reg <= {di_req_sync_reg[1:0], di_req_o};
        end
    end
    assign di_req_sync = di_req_sync_reg[2];

    // Synchronize rx_shift_reg
    reg [2:0] rx_sync_valid;
    reg [N-1:0] rx_sync_data;
    reg [N-1:0] rx_sync_data_d1;
    reg [N-1:0] rx_sync_data_d2;
    reg         rx_sync_valid_d1;
    reg         rx_sync_valid_d2;

    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            rx_sync_data_d1 <= {N{1'b0}};
            rx_sync_data_d2 <= {N{1'b0}};
            rx_sync_valid_d1 <= 1'b0;
            rx_sync_valid_d2 <= 1'b0;
        end else begin
            rx_sync_data_d1 <= rx_shift_reg;
            rx_sync_data_d2 <= rx_sync_data_d1;
            rx_sync_valid_d1 <= (state == S_DONE);
            rx_sync_valid_d2 <= rx_sync_valid_d1;
        end
    end
    assign rx_sync_valid = rx_sync_valid_d2;
    assign rx_sync_data  = rx_sync_data_d2;

    // Synchronize tx_word
    reg [N-1:0] tx_word_d1;
    reg [N-1:0] tx_word_d2;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            tx_word_d1 <= {N{1'b0}};
            tx_word_d2 <= {N{1'b0}};
        end else begin
            tx_word_d1 <= tx_word;
            tx_word_d2 <= tx_word_d1;
        end
    end
    assign tx_word_sync = tx_word_d2;

    // PCLK domain state machine
    reg         p_state_wait_wr;
    reg         p_state_wr_ack;
    reg [N-1:0] p_tx_word;
    reg         p_word_loaded;

    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            p_state_wait_wr <= 1'b0;
            p_state_wr_ack  <= 1'b0;
            p_tx_word       <= {N{1'b0}};
            p_word_loaded   <= 1'b0;
            wr_ack_o        <= 1'b0;
            do_valid_o      <= 1'b0;
            do_o            <= {N{1'b0}};
        end else begin
            // Default: clear one-cycle pulses
            wr_ack_o   <= 1'b0;
            do_valid_o <= 1'b0;

            if (wren_i && !p_word_loaded) begin
                // Accept write
                p_tx_word     <= di_i;
                p_word_loaded <= 1'b1;
                wr_ack_o      <= 1'b1;
            end

            // When word is loaded and sclk domain is ready, transfer it
            if (p_word_loaded && word_ready_sync) begin
                p_word_loaded <= 1'b0;
            end

            // Output received data
            if (rx_sync_valid) begin
                do_o       <= rx_sync_data;
                do_valid_o <= 1'b1;
            end
        end
    end

    // Drive tx_word to sclk domain
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            tx_word    <= {N{1'b0}};
            word_ready <= 1'b0;
        end else begin
            // When pclk domain loads a word, set word_ready
            if (p_word_loaded && !word_ready) begin
                tx_word    <= p_tx_word;
                word_ready <= 1'b1;
            end
        end
    end

    // MOSI output
    assign spi_mosi_o = tx_shift_reg[N-1];

endmodule
