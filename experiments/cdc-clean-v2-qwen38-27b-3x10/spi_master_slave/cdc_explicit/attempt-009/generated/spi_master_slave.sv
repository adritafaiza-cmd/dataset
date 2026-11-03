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
    // Reset Synchronization (RDC safe)
    // ========================================================================
    // Sclk domain reset
    reg [1:0] rst_sclk_sync;
    wire rst_sclk = rst_sclk_sync[1];

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            rst_sclk_sync <= 2'b00;
        else
            rst_sclk_sync <= {rst_sclk_sync[0], 1'b0};
    end

    // Pclk domain reset
    reg [1:0] rst_pclk_sync;
    wire rst_pclk = rst_pclk_sync[1];

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            rst_pclk_sync <= 2'b00;
        else
            rst_pclk_sync <= {rst_pclk_sync[0], 1'b0};
    end

    // ========================================================================
    // Pclk Domain: Parallel Interface & Handshake
    // ========================================================================
    // State machine for parallel side
    // IDLE: waiting for wren_i
    // ACK:  pulse wr_ack_o, capture di_i
    // WAIT: wait for sclk domain to signal transfer complete
    // REQ:  pulse di_req_o, wait for wren_i to deassert (return-to-zero)
    //       Actually, di_req_o indicates we can accept another word.
    //       The contract says: "di_req_o advertises that the complete 
    //       return-to-zero handshake has finished and another word can be accepted"
    //       and "Re-arm serial acceptance only after observing the request return low."
    //       This implies a handshake where di_req_o goes high, then we wait for
    //       the next wren_i? Or does di_req_o pulse and then we go back to IDLE?
    //       
    // Let's re-read: "di_req_o requests the next word." and "di_req_o advertises 
    // that the complete return-to-zero handshake has finished and another word 
    // can be accepted". 
    // 
    // Typical handshake:
    // 1. IDLE: di_req_o = 0. Wait for wren_i.
    // 2. When wren_i is high, capture di_i, pulse wr_ack_o.
    // 3. Send word to sclk domain.
    // 4. Wait for sclk domain to finish.
    // 5. Pulse do_valid_o with received data.
    // 6. Pulse di_req_o to indicate ready for next word.
    // 7. Wait for di_req_o to be "acknowledged" or for the next wren_i?
    //    The contract says "Re-arm serial acceptance only after observing the 
    //    request return low." This suggests di_req_o is a level that must return
    //    to low before we can accept another word. But di_req_o is an output.
    //    Perhaps the external logic drives something? No, di_req_o is output.
    //    
    //    Maybe the handshake is:
    //    - di_req_o goes high to indicate "I'm ready for next word"
    //    - The external logic sees di_req_o high and then asserts wren_i with new data
    //    - We detect wren_i and start next transfer
    //    - But "observing the request return low" - maybe di_req_o is pulsed
    //      and we wait for it to be low again? That doesn't make sense for an output.
    //
    //    Alternative interpretation: The "request" is the wren_i signal.
    //    "di_req_o requests the next word" - maybe di_req_o is high when we are
    //    requesting/ready for the next word.
    //    "Re-arm serial acceptance only after observing the request return low"
    //    - The "request" might refer to wren_i. So we wait for wren_i to go low
    //    before re-arming.
    //
    //    Let's assume:
    //    - di_req_o is high when the module is ready to accept a new word.
    //    - When wren_i is high and di_req_o is high, we accept the word.
    //    - After accepting, di_req_o goes low.
    //    - After transfer complete, di_req_o goes high again.
    //    - "observing the request return low" means we wait for wren_i to go low
    //      before we can accept another word (i.e., we don't accept while wren_i
    //      is still high from previous transaction).
    //
    //    Actually, simpler: 
    //    - IDLE: di_req_o = 1 (ready). Wait for wren_i.
    //    - When wren_i=1, capture di_i, wr_ack_o=1 for 1 cycle, di_req_o=0.
    //    - Start transfer.
    //    - When transfer done, do_valid_o=1 for 1 cycle, di_req_o=1.
    //    - Back to IDLE.
    //    - "Re-arm serial acceptance only after observing the request return low"
    //      - This might mean we need to see wren_i go low before we set di_req_o=1.
    //      - So after transfer done, we wait for wren_i to be low, then set di_req_o=1.

    reg [1:0] pstate;
    localparam P_IDLE = 2'd0;
    localparam P_ACK  = 2'd1;
    localparam P_WAIT = 2'd2;
    localparam P_DONE = 2'd3;

    reg [N-1:0] tx_word_pclk;
    reg [N-1:0] rx_word_pclk;
    reg         tx_valid_pclk;
    reg         rx_valid_pclk;

    // Synchronizers for control signals crossing to sclk domain
    // tx_valid: pclk -> sclk
    reg [1:0] tx_valid_sync;
    wire tx_valid_sclk = tx_valid_sync[1];

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            tx_valid_sync <= 2'b00;
        else
            tx_valid_sync <= {tx_valid_sync[0], tx_valid_pclk};
    end

    // rx_valid: sclk -> pclk
    reg [1:0] rx_valid_sync;
    wire rx_valid_pclk_sync = rx_valid_sync[1];

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            rx_valid_sync <= 2'b00;
        else
            rx_valid_sync <= {rx_valid_sync[0], rx_valid_sclk};
    end

    // Data crossing: tx_word pclk -> sclk
    // Use a 2-phase handshake or a simple synchronizer with valid
    // Since we have tx_valid, we can use a data synchronizer
    reg [N-1:0] tx_word_sync;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            tx_word_sync <= {N{1'b0}};
        else if (tx_valid_sclk)
            tx_word_sync <= tx_word_pclk;
    end

    // Data crossing: rx_word sclk -> pclk
    reg [N-1:0] rx_word_sync;
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            rx_word_sync <= {N{1'b0}};
        else if (rx_valid_pclk_sync)
            rx_word_sync <= rx_word_sclk;
    end

    // rx_valid from sclk domain
    reg [1:0] rx_valid_sclk_reg;
    wire rx_valid_sclk = rx_valid_sclk_reg[1];

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            rx_valid_sclk_reg <= 2'b00;
        else
            rx_valid_sclk_reg <= {rx_valid_sclk_reg[0], rx_valid_sclk_out};
    end

    // rx_word from sclk domain
    reg [N-1:0] rx_word_sclk;

    // Pclk domain state machine
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pstate      <= P_IDLE;
            wr_ack_o    <= 1'b0;
            di_req_o    <= 1'b0;
            do_valid_o  <= 1'b0;
            do_o        <= {N{1'b0}};
            tx_word_pclk <= {N{1'b0}};
            tx_valid_pclk <= 1'b0;
            rx_valid_pclk <= 1'b0;
        end else begin
            case (pstate)
                P_IDLE: begin
                    di_req_o <= 1'b1; // Ready to accept
                    wr_ack_o <= 1'b0;
                    do_valid_o <= 1'b0;
                    if (wren_i) begin
                        tx_word_pclk <= di_i;
                        tx_valid_pclk <= 1'b1;
                        pstate <= P_ACK;
                    end
                end
                P_ACK: begin
                    wr_ack_o <= 1'b1;
                    di_req_o <= 1'b0;
                    pstate <= P_WAIT;
                end
                P_WAIT: begin
                    wr_ack_o <= 1'b0;
                    tx_valid_pclk <= 1'b0;
                    if (rx_valid_pclk_sync) begin
                        do_o <= rx_word_sync;
                        do_valid_o <= 1'b1;
                        pstate <= P_DONE;
                    end
                end
                P_DONE: begin
                    do_valid_o <= 1'b0;
                    // Wait for wren_i to be low before re-arming
                    if (!wren_i) begin
                        di_req_o <= 1'b1;
                        pstate <= P_IDLE;
                    end
                end
                default: pstate <= P_IDLE;
            endcase
        end
    end

    // ========================================================================
    // Sclk Domain: SPI Serial Interface
    // ========================================================================
    // SPI state machine
    // IDLE: ssel high (inactive), sck low
    // START: ssel low (active), prepare to shift
    // SHIFT: shift out N bits, shift in N bits
    // DONE: ssel high, signal rx_valid

    reg [1:0] sstate;
    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_SHIFT = 2'd2;
    localparam S_DONE  = 2'd3;

    reg [N-1:0] tx_shift_reg;
    reg [N-1:0] rx_shift_reg;
    reg [31:0]  sck_div_cnt;
    reg [31:0]  bit_cnt;
    reg         sck_phase;

    // rx_valid output to pclk domain
    reg rx_valid_sclk_out;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sstate          <= S_IDLE;
            spi_ssel_o      <= 1'b1; // Inactive high
            spi_sck_o       <= 1'b0;
            spi_mosi_o      <= 1'b0;
            tx_shift_reg    <= {N{1'b0}};
            rx_shift_reg    <= {N{1'b0}};
            sck_div_cnt     <= 32'd0;
            bit_cnt         <= 32'd0;
            sck_phase       <= 1'b0;
            rx_valid_sclk_out <= 1'b0;
            rx_word_sclk    <= {N{1'b0}};
        end else begin
            case (sstate)
                S_IDLE: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o  <= 1'b0;
                    spi_mosi_o <= 1'b0;
                    rx_valid_sclk_out <= 1'b0;
                    if (tx_valid_sclk) begin
                        tx_shift_reg <= tx_word_sync;
                        sstate <= S_START;
                    end
                end
                S_START: begin
                    spi_ssel_o <= 1'b0; // Active low
                    spi_sck_o  <= 1'b0;
                    spi_mosi_o <= tx_shift_reg[N-1];
                    bit_cnt    <= 32'd0;
                    sck_div_cnt <= 32'd0;
                    sck_phase  <= 1'b0;
                    sstate     <= S_SHIFT;
                end
                S_SHIFT: begin
                    // Generate SCK
                    if (sck_div_cnt >= SPI_2X_CLK_DIV - 1) begin
                        sck_div_cnt <= 32'd0;
                        sck_phase   <= ~sck_phase;
                        if (sck_phase) begin
                            // Rising edge of SCK: capture MISO, advance
                            rx_shift_reg <= {spi_miso_i, rx_shift_reg[N-1:1]};
                            spi_mosi_o   <= tx_shift_reg[N-2:0] & {N-1{1'b1}, 1'b0};
                            if (bit_cnt >= N - 1) begin
                                sstate <= S_DONE;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end else begin
                            // Falling edge of SCK: update MOSI
                            spi_mosi_o <= tx_shift_reg[N-2:0] & {N-1{1'b1}, 1'b0};
                        end
                    end else begin
                        sck_div_cnt <= sck_div_cnt + 1'b1;
                    end
                    spi_sck_o <= sck_phase;
                end
                S_DONE: begin
                    spi_ssel_o <= 1'b1; // Deassert
                    spi_sck_o  <= 1'b0;
                    spi_mosi_o <= 1'b0;
                    rx_word_sclk <= rx_shift_reg;
                    rx_valid_sclk_out <= 1'b1;
                    sstate <= S_IDLE;
                end
                default: sstate <= S_IDLE;
            endcase
        end
    end

endmodule
