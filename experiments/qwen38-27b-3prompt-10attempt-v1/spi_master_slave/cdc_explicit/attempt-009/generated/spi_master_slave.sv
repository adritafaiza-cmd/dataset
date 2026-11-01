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
    
    // Sclk domain reset synchronizer
    reg [1:0] sclk_rst_sync;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            sclk_rst_sync <= 2'b11;
        else
            sclk_rst_sync <= {sclk_rst_sync[0], 1'b0};
    end
    wire sclk_rst = sclk_rst_sync[1];

    // Pclk domain reset synchronizer
    reg [1:0] pclk_rst_sync;
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            pclk_rst_sync <= 2'b11;
        else
            pclk_rst_sync <= {pclk_rst_sync[0], 1'b0};
    end
    wire pclk_rst = pclk_rst_sync[1];

    // ========================================================================
    // PCLK Domain: Parallel Interface & Handshake
    // ========================================================================
    
    reg [N-1:0] tx_word_reg;
    reg         tx_valid_reg;
    reg         tx_ready_reg;
    
    reg [N-1:0] rx_word_reg;
    reg         rx_valid_reg;
    reg         rx_ready_reg;

    // Write handshake logic
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            tx_word_reg  <= {N{1'b0}};
            tx_valid_reg <= 1'b0;
            tx_ready_reg <= 1'b1;
            wr_ack_o     <= 1'b0;
            di_req_o     <= 1'b0;
        end else begin
            // Default: no ack
            wr_ack_o <= 1'b0;
            
            if (tx_valid_reg) begin
                // Data is being shifted out, not ready for new data
                tx_ready_reg <= 1'b0;
                di_req_o     <= 1'b0;
            end else begin
                // Ready to accept new data
                tx_ready_reg <= 1'b1;
                di_req_o     <= 1'b1;
                
                if (wren_i) begin
                    tx_word_reg  <= di_i;
                    tx_valid_reg <= 1'b1;
                    wr_ack_o     <= 1'b1;
                end
            end
        end
    end

    // Receive handshake logic
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            rx_word_reg  <= {N{1'b0}};
            rx_valid_reg <= 1'b0;
            rx_ready_reg <= 1'b1;
            do_valid_o   <= 1'b0;
            do_o         <= {N{1'b0}};
        end else begin
            // Default: no valid output
            do_valid_o <= 1'b0;
            
            if (rx_valid_reg) begin
                // Data is available, present it
                do_valid_o <= 1'b1;
                do_o       <= rx_word_reg;
                rx_ready_reg <= 1'b0;
            end else begin
                // Ready to accept new data from SPI
                rx_ready_reg <= 1'b1;
            end
        end
    end

    // ========================================================================
    // CDC: PCLK -> SCLK (TX Data & Valid)
    // ========================================================================
    
    // Use a 2-phase handshake for multi-bit data transfer
    // PCLK side: request
    reg         p2s_req;
    reg [N-1:0] p2s_data;
    
    // SCLK side: acknowledge
    reg         s2p_ack;
    
    // PCLK domain: drive request and data
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            p2s_req  <= 1'b0;
            p2s_data <= {N{1'b0}};
        end else begin
            if (tx_valid_reg && !s2p_ack) begin
                // Send data
                p2s_data <= tx_word_reg;
                p2s_req  <= 1'b1;
            end else if (s2p_ack) begin
                // Ack received, clear request
                p2s_req  <= 1'b0;
                tx_valid_reg <= 1'b0;
            end
        end
    end

    // SCLK domain: synchronize request and data, generate ack
    reg [1:0] sclk_p2s_req_sync;
    reg [1:0] sclk_s2p_ack_sync;
    reg [N-1:0] sclk_p2s_data_sync;
    
    // Synchronize p2s_req
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            sclk_p2s_req_sync <= 2'b00;
        else
            sclk_p2s_req_sync <= {sclk_p2s_req_sync[0], p2s_req};
    end
    wire sclk_p2s_req = sclk_p2s_req_sync[1];

    // Synchronize p2s_data (sample when req is stable)
    reg [N-1:0] sclk_p2s_data_reg;
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            sclk_p2s_data_reg <= {N{1'b0}};
        else if (sclk_p2s_req)
            sclk_p2s_data_reg <= p2s_data;
    end

    // Synchronize s2p_ack back to PCLK
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            sclk_s2p_ack_sync <= 2'b00;
        else
            sclk_s2p_ack_sync <= {sclk_s2p_ack_sync[0], s2p_ack};
    end
    wire sclk_s2p_ack = sclk_s2p_ack_sync[1];

    // SCLK domain: generate ack
    reg sclk_ack_reg;
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            sclk_ack_reg <= 1'b0;
        else if (sclk_p2s_req && !sclk_ack_reg)
            sclk_ack_reg <= 1'b1;
        else if (!sclk_p2s_req)
            sclk_ack_reg <= 1'b0;
    end
    assign s2p_ack = sclk_ack_reg;

    // ========================================================================
    // SCLK Domain: SPI Master Logic
    // ========================================================================
    
    reg [N-1:0] sclk_tx_shift_reg;
    reg [N-1:0] sclk_rx_shift_reg;
    reg [3:0]   sclk_bit_count;
    reg         sclk_tx_active;
    reg         sclk_rx_active;
    reg [1:0]   sclk_phase;
    reg         sclk_clk_div;
    reg [1:0]   sclk_div_counter;

    // Load data when request is received
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            sclk_tx_shift_reg <= {N{1'b0}};
            sclk_rx_shift_reg <= {N{1'b0}};
            sclk_bit_count    <= 4'd0;
            sclk_tx_active    <= 1'b0;
            sclk_rx_active    <= 1'b0;
            sclk_phase        <= 2'b00;
            sclk_clk_div      <= 1'b0;
            sclk_div_counter  <= 2'd0;
            spi_ssel_o        <= 1'b0;
            spi_sck_o         <= 1'b0;
        end else begin
            // Default
            spi_sck_o <= 1'b0;
            
            if (sclk_p2s_req && !sclk_tx_active) begin
                // Start new transfer
                sclk_tx_shift_reg <= sclk_p2s_data_reg;
                sclk_rx_shift_reg <= {N{1'b0}};
                sclk_bit_count    <= 4'd0;
                sclk_tx_active    <= 1'b1;
                sclk_rx_active    <= 1'b1;
                sclk_phase        <= 2'b00;
                sclk_div_counter  <= 2'd0;
                spi_ssel_o        <= 1'b1;
            end else if (sclk_tx_active) begin
                // SPI clock generation and shifting
                // SPI_2X_CLK_DIV determines the division factor
                // For simplicity, we use a fixed 2-phase approach
                
                case (sclk_phase)
                    2'b00: begin
                        // Phase 0: SCK low, prepare MOSI
                        spi_sck_o <= 1'b0;
                        sclk_phase <= 2'b01;
                    end
                    2'b01: begin
                        // Phase 1: SCK high, shift data
                        spi_sck_o <= 1'b1;
                        sclk_phase <= 2'b10;
                    end
                    2'b10: begin
                        // Phase 2: SCK high, sample MISO
                        spi_sck_o <= 1'b1;
                        sclk_phase <= 2'b11;
                    end
                    2'b11: begin
                        // Phase 3: SCK low, shift registers
                        spi_sck_o <= 1'b0;
                        
                        // Shift TX
                        sclk_tx_shift_reg <= {1'b0, sclk_tx_shift_reg[N-1:1]};
                        
                        // Shift RX
                        sclk_rx_shift_reg <= {spi_miso_i, sclk_rx_shift_reg[N-1:1]};
                        
                        // Increment bit count
                        if (sclk_bit_count == N-1) begin
                            // Transfer complete
                            sclk_tx_active <= 1'b0;
                            sclk_rx_active <= 1'b0;
                            spi_ssel_o     <= 1'b0;
                            sclk_phase     <= 2'b00;
                        end else begin
                            sclk_bit_count <= sclk_bit_count + 1'b1;
                            sclk_phase     <= 2'b00;
                        end
                    end
                    default: sclk_phase <= 2'b00;
                endcase
            end
        end
    end

    // MOSI output
    assign spi_mosi_o = sclk_tx_shift_reg[N-1];

    // ========================================================================
    // CDC: SCLK -> PCLK (RX Data & Valid)
    // ========================================================================
    
    // Use a 2-phase handshake for multi-bit data transfer
    // SCLK side: request
    reg         s2p_req;
    reg [N-1:0] s2p_data;
    
    // PCLK side: acknowledge
    reg         p2s_ack;
    
    // SCLK domain: drive request and data
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            s2p_req  <= 1'b0;
            s2p_data <= {N{1'b0}};
        end else begin
            if (sclk_rx_active && !s2p_req) begin
                // Data is ready, send it
                s2p_data <= sclk_rx_shift_reg;
                s2p_req  <= 1'b1;
            end else if (p2s_ack) begin
                // Ack received, clear request
                s2p_req  <= 1'b0;
                sclk_rx_active <= 1'b0;
            end
        end
    end

    // PCLK domain: synchronize request and data, generate ack
    reg [1:0] pclk_s2p_req_sync;
    reg [1:0] pclk_p2s_ack_sync;
    reg [N-1:0] pclk_s2p_data_sync;
    
    // Synchronize s2p_req
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            pclk_s2p_req_sync <= 2'b00;
        else
            pclk_s2p_req_sync <= {pclk_s2p_req_sync[0], s2p_req};
    end
    wire pclk_s2p_req = pclk_s2p_req_sync[1];

    // Synchronize s2p_data (sample when req is stable)
    reg [N-1:0] pclk_s2p_data_reg;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            pclk_s2p_data_reg <= {N{1'b0}};
        else if (pclk_s2p_req)
            pclk_s2p_data_reg <= s2p_data;
    end

    // Synchronize p2s_ack back to SCLK
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            pclk_p2s_ack_sync <= 2'b00;
        else
            pclk_p2s_ack_sync <= {pclk_p2s_ack_sync[0], p2s_ack};
    end
    wire pclk_p2s_ack = pclk_p2s_ack_sync[1];

    // PCLK domain: generate ack
    reg pclk_ack_reg;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            pclk_ack_reg <= 1'b0;
        else if (pclk_s2p_req && !pclk_ack_reg)
            pclk_ack_reg <= 1'b1;
        else if (!pclk_s2p_req)
            pclk_ack_reg <= 1'b0;
    end
    assign p2s_ack = pclk_ack_reg;

    // Update RX registers when data is received
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            rx_word_reg  <= {N{1'b0}};
            rx_valid_reg <= 1'b0;
        end else if (pclk_s2p_req && !rx_valid_reg) begin
            rx_word_reg  <= pclk_s2p_data_reg;
            rx_valid_reg <= 1'b1;
        end
    end

endmodule
