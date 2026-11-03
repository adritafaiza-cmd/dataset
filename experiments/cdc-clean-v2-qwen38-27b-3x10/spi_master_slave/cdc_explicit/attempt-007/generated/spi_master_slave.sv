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

    // =========================================================================
    // Reset Synchronizers
    // =========================================================================
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

    // =========================================================================
    // PCLK Domain: Parallel Interface
    // =========================================================================
    reg [N-1:0] tx_word_reg;
    reg         tx_word_valid;
    reg         tx_word_ready;
    reg         tx_word_req;

    reg [N-1:0] rx_word_reg;
    reg         rx_word_valid;
    reg         rx_word_ready;

    // Handshake signals to SCLK domain
    reg         pclk_tx_req;
    reg         pclk_tx_ack;
    reg         pclk_rx_req;
    reg         pclk_rx_ack;

    // Synchronizers for control signals from SCLK domain
    reg [2:0] tx_ack_sync;
    reg [2:0] rx_ack_sync;

    always @(posedge pclk_i or posedge rst_pclk) begin
        if (rst_pclk) begin
            tx_ack_sync <= 3'b000;
        end else begin
            tx_ack_sync <= {tx_ack_sync[1:0], pclk_tx_ack};
        end
    end

    always @(posedge pclk_i or posedge rst_pclk) begin
        if (rst_pclk) begin
            rx_ack_sync <= 3'b000;
        end else begin
            rx_ack_sync <= {rx_ack_sync[1:0], pclk_rx_ack};
        end
    end

    wire tx_ack_synced = tx_ack_sync[2];
    wire rx_ack_synced = rx_ack_sync[2];

    // PCLK state machine for parallel interface
    // States: IDLE, WAIT_TX_ACK, WAIT_RX_ACK
    localparam P_IDLE       = 2'd0;
    localparam P_WAIT_TX    = 2'd1;
    localparam P_WAIT_RX    = 2'd2;

    reg [1:0] p_state;
    reg [1:0] p_state_next;

    always @(*) begin
        p_state_next = p_state;
        case (p_state)
            P_IDLE: begin
                if (wren_i && tx_word_ready)
                    p_state_next = P_WAIT_TX;
            end
            P_WAIT_TX: begin
                if (tx_ack_synced)
                    p_state_next = P_WAIT_RX;
            end
            P_WAIT_RX: begin
                if (rx_ack_synced)
                    p_state_next = P_IDLE;
            end
            default: p_state_next = P_IDLE;
        endcase
    end

    always @(posedge pclk_i or posedge rst_pclk) begin
        if (rst_pclk)
            p_state <= P_IDLE;
        else
            p_state <= p_state_next;
    end

    // TX word register
    always @(posedge pclk_i or posedge rst_pclk) begin
        if (rst_pclk) begin
            tx_word_reg     <= {N{1'b0}};
            tx_word_valid   <= 1'b0;
            tx_word_ready   <= 1'b1;
            tx_word_req     <= 1'b0;
        end else begin
            case (p_state)
                P_IDLE: begin
                    if (wren_i && tx_word_ready) begin
                        tx_word_reg   <= di_i;
                        tx_word_valid <= 1'b1;
                        tx_word_ready <= 1'b0;
                        tx_word_req   <= 1'b1;
                    end
                end
                P_WAIT_TX: begin
                    if (tx_ack_synced) begin
                        tx_word_req   <= 1'b0;
                        tx_word_valid <= 1'b0;
                    end
                end
                default: ;
            endcase
        end
    end

    // RX word register
    always @(posedge pclk_i or posedge rst_pclk) begin
        if (rst_pclk) begin
            rx_word_reg   <= {N{1'b0}};
            rx_word_valid <= 1'b0;
            rx_word_ready <= 1'b1;
        end else begin
            case (p_state)
                P_WAIT_RX: begin
                    if (rx_ack_synced) begin
                        rx_word_valid <= 1'b0;
                        rx_word_ready <= 1'b1;
                    end
                end
                default: ;
            endcase
        end
    end

    // Control signals to SCLK domain
    always @(posedge pclk_i or posedge rst_pclk) begin
        if (rst_pclk) begin
            pclk_tx_req <= 1'b0;
            pclk_tx_ack <= 1'b0;
            pclk_rx_req <= 1'b0;
            pclk_rx_ack <= 1'b0;
        end else begin
            case (p_state)
                P_IDLE: begin
                    pclk_tx_req <= 1'b0;
                    pclk_tx_ack <= 1'b0;
                    pclk_rx_req <= 1'b0;
                    pclk_rx_ack <= 1'b0;
                end
                P_WAIT_TX: begin
                    pclk_tx_req <= 1'b1;
                    pclk_tx_ack <= 1'b0;
                    pclk_rx_req <= 1'b0;
                    pclk_rx_ack <= 1'b0;
                end
                P_WAIT_RX: begin
                    pclk_tx_req <= 1'b0;
                    pclk_tx_ack <= 1'b0;
                    pclk_rx_req <= 1'b1;
                    pclk_rx_ack <= 1'b0;
                end
                default: begin
                    pclk_tx_req <= 1'b0;
                    pclk_tx_ack <= 1'b0;
                    pclk_rx_req <= 1'b0;
                    pclk_rx_ack <= 1'b0;
                end
            endcase
        end
    end

    // Synchronizers for control signals from PCLK domain
    reg [2:0] tx_req_sync;
    reg [2:0] rx_req_sync;

    always @(posedge sclk_i or posedge rst_sclk) begin
        if (rst_sclk)
            tx_req_sync <= 3'b000;
        else
            tx_req_sync <= {tx_req_sync[1:0], pclk_tx_req};
    end

    always @(posedge sclk_i or posedge rst_sclk) begin
        if (rst_sclk)
            rx_req_sync <= 3'b000;
        else
            rx_req_sync <= {rx_req_sync[1:0], pclk_rx_req};
    end

    wire tx_req_synced = tx_req_sync[2];
    wire rx_req_synced = rx_req_sync[2];

    // =========================================================================
    // SCLK Domain: SPI Serial Interface
    // =========================================================================
    reg [N-1:0] tx_shift_reg;
    reg [N-1:0] rx_shift_reg;
    reg [N-1:0] bit_count;
    reg         sclk_phase;
    reg         spi_active;

    // Synchronizers for data from PCLK domain (multi-bit, use handshake)
    // We use a simple approach: capture tx_word when tx_req_synced goes high
    // and hold it until the transfer is complete.

    reg [N-1:0] tx_word_latch;
    reg         tx_word_latched;

    // Synchronizers for control signals to PCLK domain
    reg [2:0] tx_ack_sync_sclk;
    reg [2:0] rx_ack_sync_sclk;

    always @(posedge sclk_i or posedge rst_sclk) begin
        if (rst_sclk)
            tx_ack_sync_sclk <= 3'b000;
        else
            tx_ack_sync_sclk <= {tx_ack_sync_sclk[1:0], sclk_tx_ack};
    end

    always @(posedge sclk_i or posedge rst_sclk) begin
        if (rst_sclk)
            rx_ack_sync_sclk <= 3'b000;
        else
            rx_ack_sync_sclk <= {rx_ack_sync_sclk[1:0], sclk_rx_ack};
    end

    // SCLK state machine
    localparam S_IDLE       = 3'd0;
    localparam S_WAIT_TX    = 3'd1;
    localparam S_SHIFT      = 3'd2;
    localparam S_WAIT_RX    = 3'd3;

    reg [2:0] s_state;
    reg [2:0] s_state_next;

    always @(*) begin
        s_state_next = s_state;
        case (s_state)
            S_IDLE: begin
                if (tx_req_synced)
                    s_state_next = S_WAIT_TX;
            end
            S_WAIT_TX: begin
                if (tx_word_latched)
                    s_state_next = S_SHIFT;
            end
            S_SHIFT: begin
                if (bit_count == N-1)
                    s_state_next = S_WAIT_RX;
            end
            S_WAIT_RX: begin
                if (rx_req_synced)
                    s_state_next = S_IDLE;
            end
            default: s_state_next = S_IDLE;
        endcase
    end

    always @(posedge sclk_i or posedge rst_sclk) begin
        if (rst_sclk)
            s_state <= S_IDLE;
        else
            s_state <= s_state_next;
    end

    // TX word latch
    always @(posedge sclk_i or posedge rst_sclk) begin
        if (rst_sclk) begin
            tx_word_latch   <= {N{1'b0}};
            tx_word_latched <= 1'b0;
        end else begin
            case (s_state)
                S_IDLE: begin
                    if (tx_req_synced) begin
                        tx_word_latch   <= tx_word_reg;
                        tx_word_latched <= 1'b1;
                    end
                end
                S_SHIFT: begin
                    if (bit_count == N-1)
                        tx_word_latched <= 1'b0;
                end
                default: ;
            endcase
        end
    end

    // SPI shift logic
    always @(posedge sclk_i or posedge rst_sclk) begin
        if (rst_sclk) begin
            tx_shift_reg <= {N{1'b0}};
            rx_shift_reg <= {N{1'b0}};
            bit_count    <= {N{1'b0}};
            sclk_phase   <= 1'b0;
            spi_active   <= 1'b0;
        end else begin
            case (s_state)
                S_WAIT_TX: begin
                    if (tx_word_latched) begin
                        tx_shift_reg <= tx_word_latch;
                        bit_count    <= {N{1'b0}};
                        spi_active   <= 1'b1;
                    end
                end
                S_SHIFT: begin
                    // Toggle sclk_phase to generate clock
                    sclk_phase <= ~sclk_phase;
                    
                    // On rising edge of sclk_phase (i.e., when sclk_phase was 0 and becomes 1)
                    // We shift out MSB and shift in MISO
                    if (sclk_phase == 1'b0) begin
                        // Prepare for next bit
                        tx_shift_reg <= {tx_shift_reg[N-2:0], 1'b0};
                        rx_shift_reg <= {spi_miso_i, rx_shift_reg[N-1:0]};
                        bit_count    <= bit_count + 1'b1;
                    end
                end
                S_WAIT_RX: begin
                    spi_active <= 1'b0;
                end
                default: ;
            endcase
        end
    end

    // SPI outputs
    always @(*) begin
        spi_ssel_o = spi_active;
        spi_sck_o  = sclk_phase && spi_active;
        spi_mosi_o = tx_shift_reg[N-1];
    end

    // Control signals to PCLK domain
    always @(posedge sclk_i or posedge rst_sclk) begin
        if (rst_sclk) begin
            sclk_tx_ack <= 1'b0;
            sclk_rx_ack <= 1'b0;
        end else begin
            case (s_state)
                S_WAIT_TX: begin
                    sclk_tx_ack <= 1'b0;
                    sclk_rx_ack <= 1'b0;
                end
                S_SHIFT: begin
                    if (bit_count == N-1)
                        sclk_tx_ack <= 1'b1;
                    else
                        sclk_tx_ack <= 1'b0;
                    sclk_rx_ack <= 1'b0;
                end
                S_WAIT_RX: begin
                    sclk_tx_ack <= 1'b0;
                    sclk_rx_ack <= 1'b1;
                end
                default: begin
                    sclk_tx_ack <= 1'b0;
                    sclk_rx_ack <= 1'b0;
                end
            endcase
        end
    end

    // RX word output to PCLK domain
    always @(posedge sclk_i or posedge rst_sclk) begin
        if (rst_sclk) begin
            rx_word_reg <= {N{1'b0}};
        end else begin
            if (s_state == S_SHIFT && bit_count == N-1)
                rx_word_reg <= rx_shift_reg;
        end
    end

    // =========================================================================
    // PCLK Domain: Output Handshake
    // =========================================================================
    // di_req_o: advertise that the complete return-to-zero handshake has finished
    // wr_ack_o: acknowledges acceptance
    // do_valid_o: pulses for each completed word
    // do_o: presents the received word

    reg         di_req_int;
    reg         wr_ack_int;
    reg         do_valid_int;
    reg [N-1:0] do_int;

    always @(posedge pclk_i or posedge rst_pclk) begin
        if (rst_pclk) begin
            di_req_int   <= 1'b0;
            wr_ack_int   <= 1'b0;
            do_valid_int <= 1'b0;
            do_int       <= {N{1'b0}};
        end else begin
            case (p_state)
                P_IDLE: begin
                    di_req_int   <= 1'b1;
                    wr_ack_int   <= 1'b0;
                    do_valid_int <= 1'b0;
                end
                P_WAIT_TX: begin
                    di_req_int   <= 1'b0;
                    wr_ack_int   <= 1'b1;
                    do_valid_int <= 1'b0;
                end
                P_WAIT_RX: begin
                    di_req_int   <= 1'b0;
                    wr_ack_int   <= 1'b0;
                    do_valid_int <= 1'b1;
                    do_int       <= rx_word_reg;
                end
                default: begin
                    di_req_int   <= 1'b0;
                    wr_ack_int   <= 1'b0;
                    do_valid_int <= 1'b0;
                end
            endcase
        end
    end

    assign di_req_o   = di_req_int;
    assign wr_ack_o   = wr_ack_int;
    assign do_valid_o = do_valid_int;
    assign do_o       = do_int;

endmodule
