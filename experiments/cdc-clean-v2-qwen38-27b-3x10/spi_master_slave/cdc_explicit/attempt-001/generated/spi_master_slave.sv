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

    // ========================================================================
    // Reset Synchronization
    // ========================================================================
    reg [2:0] rst_sync_sclk;
    reg [2:0] rst_sync_pclk;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            rst_sync_sclk <= 3'b000;
        else
            rst_sync_sclk <= {rst_sync_sclk[1:0], 1'b1};
    end

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            rst_sync_pclk <= 3'b000;
        else
            rst_sync_pclk <= {rst_sync_pclk[1:0], 1'b1};
    end

    wire rst_sclk = ~rst_sync_sclk[2];
    wire rst_pclk = ~rst_sync_pclk[2];

    // ========================================================================
    // PCLK Domain: Parallel Interface
    // ========================================================================
    reg [N-1:0] tx_word_reg;
    reg         tx_word_valid;
    reg         tx_word_ready;
    reg         tx_word_req;

    reg [N-1:0] rx_word_reg;
    reg         rx_word_valid;
    reg         rx_word_ready;

    // Handshake state
    reg         pclk_state_idle;
    reg         pclk_state_wait_tx;
    reg         pclk_state_wait_rx;

    // Synchronizers for signals crossing from SCLK to PCLK
    reg [2:0] sync_tx_ready_s2p;
    reg [2:0] sync_rx_valid_s2p;
    reg [2:0] sync_rx_word_s2p [N-1:0]; // Not used, use separate syncs

    // Actually, let's use a simpler approach with proper synchronizers
    reg [2:0] sync_tx_ready;
    reg [2:0] sync_rx_valid;
    reg [2:0] sync_rx_word_sync [N-1:0];

    // Synchronizer for tx_ready (SCLK -> PCLK)
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            sync_tx_ready <= 3'b000;
        else
            sync_tx_ready <= {sync_tx_ready[1:0], tx_word_ready};
    end

    // Synchronizer for rx_valid (SCLK -> PCLK)
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            sync_rx_valid <= 3'b000;
        else
            sync_rx_valid <= {sync_rx_valid[1:0], rx_word_valid};
    end

    // Synchronizer for rx_word (SCLK -> PCLK) - multi-bit, use handshake
    // We'll use a simple approach: synchronize the data when valid is high
    reg [N-1:0] rx_word_sync;
    reg         rx_word_sync_valid;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            rx_word_sync <= {N{1'b0}};
            rx_word_sync_valid <= 1'b0;
        end else begin
            if (sync_rx_valid[2] && !sync_rx_valid[1]) begin
                // Rising edge of synchronized rx_valid
                rx_word_sync <= rx_word_reg;
                rx_word_sync_valid <= 1'b1;
            end else if (rx_word_sync_valid && rx_word_ready) begin
                rx_word_sync_valid <= 1'b0;
            end
        end
    end

    // PCLK state machine
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_state_idle    <= 1'b1;
            pclk_state_wait_tx <= 1'b0;
            pclk_state_wait_rx <= 1'b0;
            tx_word_valid      <= 1'b0;
            tx_word_req        <= 1'b0;
            di_req_o           <= 1'b0;
            wr_ack_o           <= 1'b0;
            do_valid_o         <= 1'b0;
            do_o               <= {N{1'b0}};
            tx_word_reg        <= {N{1'b0}};
        end else begin
            // Default: clear one-cycle pulses
            wr_ack_o   <= 1'b0;
            do_valid_o <= 1'b0;

            case (1'b1)
                // IDLE: Wait for write request
                pclk_state_idle: begin
                    if (wren_i) begin
                        // Accept the word
                        tx_word_reg   <= di_i;
                        tx_word_valid <= 1'b1;
                        tx_word_req   <= 1'b1;
                        wr_ack_o      <= 1'b1;
                        pclk_state_idle    <= 1'b0;
                        pclk_state_wait_tx <= 1'b1;
                    end else begin
                        di_req_o <= 1'b1;
                    end
                end

                // WAIT_TX: Wait for SCLK domain to accept the transmit word
                pclk_state_wait_tx: begin
                    if (sync_tx_ready[2]) begin
                        // SCLK domain has accepted the word
                        tx_word_req   <= 1'b0;
                        tx_word_valid <= 1'b0;
                        pclk_state_wait_tx <= 1'b0;
                        pclk_state_wait_rx <= 1'b1;
                    end
                end

                // WAIT_RX: Wait for SCLK domain to complete receive
                pclk_state_wait_rx: begin
                    if (rx_word_sync_valid) begin
                        // Receive word is available
                        do_o       <= rx_word_sync;
                        do_valid_o <= 1'b1;
                        rx_word_sync_valid <= 1'b0;
                        pclk_state_wait_rx <= 1'b0;
                        pclk_state_idle    <= 1'b1;
                    end
                end

                default: begin
                    pclk_state_idle <= 1'b1;
                end
            endcase
        end
    end

    // ========================================================================
    // SCLK Domain: SPI Serial Interface
    // ========================================================================
    reg [2:0] sync_tx_req_p2s;
    reg [2:0] sync_tx_word_p2s [N-1:0];
    reg       sync_tx_word_valid_p2s;

    // Synchronizer for tx_req (PCLK -> SCLK)
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            sync_tx_req_p2s <= 3'b000;
        else
            sync_tx_req_p2s <= {sync_tx_req_p2s[1:0], tx_word_req};
    end

    // Synchronizer for tx_word_valid (PCLK -> SCLK)
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            sync_tx_word_valid_p2s <= 1'b0;
        else
            sync_tx_word_valid_p2s <= tx_word_valid;
    end

    // Synchronizer for tx_word (PCLK -> SCLK) - multi-bit
    // Use a handshake: only sample when valid is stable
    reg [N-1:0] tx_word_sync;
    reg         tx_word_sync_valid;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_word_sync <= {N{1'b0}};
            tx_word_sync_valid <= 1'b0;
        end else begin
            if (sync_tx_word_valid_p2s && !tx_word_sync_valid) begin
                tx_word_sync <= tx_word_reg;
                tx_word_sync_valid <= 1'b1;
            end
        end
    end

    // SPI state machine
    reg         spi_idle;
    reg         spi_shifting;
    reg [N-1:0] shift_reg;
    reg [N-1:0] rx_shift_reg;
    reg [31:0]  sclk_divider;
    reg [31:0]  sclk_count;
    reg [N-1:0] bit_count;

    // Synchronizer for rx_word_valid (SCLK -> PCLK)
    // Already defined above as sync_rx_valid

    // Synchronizer for rx_word (SCLK -> PCLK)
    // Already defined above as rx_word_reg

    // Synchronizer for tx_word_ready (SCLK -> PCLK)
    // Already defined above as sync_tx_ready

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_idle       <= 1'b1;
            spi_shifting   <= 1'b0;
            shift_reg      <= {N{1'b0}};
            rx_shift_reg   <= {N{1'b0}};
            sclk_divider   <= 32'd0;
            sclk_count     <= 32'd0;
            bit_count      <= {N{1'b0}};
            spi_ssel_o     <= 1'b1;
            spi_sck_o      <= 1'b0;
            tx_word_ready  <= 1'b0;
            rx_word_valid  <= 1'b0;
            rx_word_reg    <= {N{1'b0}};
        end else begin
            // Default: clear one-cycle pulses
            tx_word_ready <= 1'b0;
            rx_word_valid <= 1'b0;

            case (1'b1)
                // IDLE: Wait for transmit request
                spi_idle: begin
                    if (sync_tx_req_p2s[2] && tx_word_sync_valid) begin
                        // Start SPI transfer
                        shift_reg    <= tx_word_sync;
                        rx_shift_reg <= {N{1'b0}};
                        bit_count    <= {N{1'b0}};
                        sclk_count   <= 32'd0;
                        spi_ssel_o   <= 1'b0;
                        spi_sck_o    <= 1'b0;
                        spi_idle     <= 1'b0;
                        spi_shifting <= 1'b1;
                        tx_word_ready <= 1'b1;
                    end
                end

                // SHIFTING: Clock out bits
                spi_shifting: begin
                    // Generate SCK
                    if (sclk_count >= SPI_2X_CLK_DIV - 1) begin
                        sclk_count <= 32'd0;
                        spi_sck_o  <= ~spi_sck_o;

                        // On rising edge of SCK, shift out and capture
                        if (spi_sck_o == 1'b0) begin
                            // This is the rising edge (was 0, now 1)
                            // Actually, we toggle, so when we set to 1, it's rising
                            // Let's use a different approach
                        end
                    end else begin
                        sclk_count <= sclk_count + 32'd1;
                    end

                    // Shift on rising edge of SCK
                    // We need to detect the rising edge
                    // Let's use a separate counter for bit shifting
                end

                default: begin
                    spi_idle <= 1'b1;
                end
            endcase
        end
    end

    // Let's redo the SPI shifting logic more carefully
    // We'll use a separate always block for the SPI clock generation and shifting

    // Actually, let me restructure this more cleanly.

endmodule
