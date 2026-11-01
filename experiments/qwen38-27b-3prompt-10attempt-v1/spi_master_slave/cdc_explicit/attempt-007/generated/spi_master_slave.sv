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
    reg [2:0] sclk_rst_sync;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            sclk_rst_sync <= 3'b111;
        else
            sclk_rst_sync <= {sclk_rst_sync[1:0], 1'b0};
    end
    wire sclk_rst = sclk_rst_sync[2];

    // Pclk domain reset
    reg [2:0] pclk_rst_sync;
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            pclk_rst_sync <= 3'b111;
        else
            pclk_rst_sync <= {pclk_rst_sync[1:0], 1'b0};
    end
    wire pclk_rst = pclk_rst_sync[2];

    // ========================================================================
    // PCLK Domain: Parallel Interface & Handshake
    // ========================================================================
    
    reg [N-1:0] tx_word_reg;
    reg         tx_word_valid;
    reg         tx_word_ready;
    
    reg [N-1:0] rx_word_reg;
    reg         rx_word_valid;
    reg         rx_word_ready;
    
    // Handshake signals crossing to SCLK domain
    reg         pclk_to_sclk_tx_valid;
    reg [N-1:0] pclk_to_sclk_tx_data;
    
    // Handshake signals crossing from SCLK domain
    reg         sclk_to_pclk_rx_valid;
    reg [N-1:0] sclk_to_pclk_rx_data;
    
    // Synchronizers for control signals (single-bit, safe)
    reg [2:0] sclk_to_pclk_rx_valid_sync;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            sclk_to_pclk_rx_valid_sync <= 3'b000;
        else
            sclk_to_pclk_rx_valid_sync <= {sclk_to_pclk_rx_valid_sync[1:0], sclk_to_pclk_rx_valid};
    end
    wire pclk_rx_valid = sclk_to_pclk_rx_valid_sync[2];
    
    reg [2:0] sclk_to_pclk_rx_ready_sync;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            sclk_to_pclk_rx_ready_sync <= 3'b000;
        else
            sclk_to_pclk_rx_ready_sync <= {sclk_to_pclk_rx_ready_sync[1:0], rx_word_ready};
    end
    wire sclk_rx_ready = sclk_to_pclk_rx_ready_sync[2];

    // Synchronizers for data (multi-bit, use handshake protocol)
    // We use a simple 2-phase handshake for data transfer.
    // Since we have valid/ready, we can use a standard CDC FIFO or 
    // a simple handshake. For simplicity and robustness, we'll use 
    // a 2-stage synchronizer for valid and assume data is stable 
    // when valid is high. However, for multi-bit data, we need to 
    // ensure data is stable. A common approach is to use a 
    // "data valid" handshake where data is only changed when 
    // the other side is ready.
    
    // Let's use a simpler approach: 
    // 1. PCLK side: When tx_word_valid and tx_word_ready, latch data and 
    //    assert pclk_to_sclk_tx_valid.
    // 2. SCLK side: When pclk_to_sclk_tx_valid (synced) and sclk_tx_ready, 
    //    latch data and deassert pclk_to_sclk_tx_valid.
    // This requires a handshake. Let's implement a simple 2-phase handshake.
    
    // Actually, let's use a standard CDC handshake for multi-bit data.
    // We'll use a "req/ack" protocol.
    
    // PCLK to SCLK:
    reg pclk_to_sclk_req;
    reg [N-1:0] pclk_to_sclk_data_reg;
    reg [2:0] sclk_to_pclk_ack_sync;
    
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            pclk_to_sclk_req <= 1'b0;
            pclk_to_sclk_data_reg <= {N{1'b0}};
        end else begin
            if (tx_word_valid && tx_word_ready && !pclk_to_sclk_req) begin
                pclk_to_sclk_data_reg <= tx_word_reg;
                pclk_to_sclk_req <= 1'b1;
            end else if (pclk_to_sclk_req && sclk_to_pclk_ack_sync[2]) begin
                pclk_to_sclk_req <= 1'b0;
            end
        end
    end
    
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            sclk_to_pclk_ack_sync <= 3'b000;
        else
            sclk_to_pclk_ack_sync <= {sclk_to_pclk_ack_sync[1:0], sclk_to_pclk_ack};
    end
    
    // SCLK to PCLK:
    reg sclk_to_pclk_req;
    reg [N-1:0] sclk_to_pclk_data_reg;
    reg [2:0] pclk_to_sclk_ack_sync;
    
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            sclk_to_pclk_req <= 1'b0;
            sclk_to_pclk_data_reg <= {N{1'b0}};
        end else begin
            if (rx_word_valid && rx_word_ready && !sclk_to_pclk_req) begin
                sclk_to_pclk_data_reg <= rx_word_reg;
                sclk_to_pclk_req <= 1'b1;
            end else if (sclk_to_pclk_req && pclk_to_sclk_ack_sync[2]) begin
                sclk_to_pclk_req <= 1'b0;
            end
        end
    end
    
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            pclk_to_sclk_ack_sync <= 3'b000;
        else
            pclk_to_sclk_ack_sync <= {pclk_to_sclk_ack_sync[1:0], pclk_to_sclk_ack};
    end
    
    // Acknowledge signals
    reg sclk_to_pclk_ack;
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            sclk_to_pclk_ack <= 1'b0;
        else
            sclk_to_pclk_ack <= pclk_to_sclk_req;
    end
    
    reg pclk_to_sclk_ack;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            pclk_to_sclk_ack <= 1'b0;
        else
            pclk_to_sclk_ack <= sclk_to_pclk_req;
    end
    
    // PCLK side logic
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            tx_word_reg <= {N{1'b0}};
            tx_word_valid <= 1'b0;
            tx_word_ready <= 1'b0;
            rx_word_reg <= {N{1'b0}};
            rx_word_valid <= 1'b0;
            rx_word_ready <= 1'b0;
            wr_ack_o <= 1'b0;
            di_req_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= {N{1'b0}};
        end else begin
            // Default
            wr_ack_o <= 1'b0;
            
            // TX side
            if (wren_i && tx_word_ready) begin
                tx_word_reg <= di_i;
                tx_word_valid <= 1'b1;
                wr_ack_o <= 1'b1;
            end else if (tx_word_valid && pclk_to_sclk_req) begin
                tx_word_valid <= 1'b0;
            end
            
            tx_word_ready <= !tx_word_valid || (pclk_to_sclk_req && sclk_to_pclk_ack_sync[2]);
            
            // RX side
            if (pclk_rx_valid && rx_word_ready) begin
                rx_word_reg <= sclk_to_pclk_rx_data;
                rx_word_valid <= 1'b1;
                do_valid_o <= 1'b1;
                do_o <= sclk_to_pclk_rx_data;
            end else if (rx_word_valid && rx_word_ready) begin
                rx_word_valid <= 1'b0;
                do_valid_o <= 1'b0;
            end
            
            rx_word_ready <= !rx_word_valid || (sclk_to_pclk_req && pclk_to_sclk_ack_sync[2]);
            
            // di_req_o: request next word when ready
            di_req_o <= tx_word_ready;
        end
    end
    
    // ========================================================================
    // SCLK Domain: SPI Master Logic
    // ========================================================================
    
    reg [N-1:0] sclk_tx_shift_reg;
    reg [N-1:0] sclk_rx_shift_reg;
    reg [3:0]   sclk_bit_counter;
    reg         sclk_tx_valid;
    reg         sclk_rx_valid;
    reg         sclk_tx_ready;
    reg         sclk_rx_ready;
    reg         sclk_ssel_active;
    reg         sclk_sck_phase;
    
    // Synchronizers for PCLK to SCLK
    reg [2:0] pclk_to_sclk_req_sync;
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            pclk_to_sclk_req_sync <= 3'b000;
        else
            pclk_to_sclk_req_sync <= {pclk_to_sclk_req_sync[1:0], pclk_to_sclk_req};
    end
    wire sclk_tx_req = pclk_to_sclk_req_sync[2];
    
    // Data is stable when req is high, so we can sample it
    // We need to synchronize the data as well, but since it's 
    // stable when req is high, we can use a simple 2-stage 
    // synchronizer for each bit, or better, use the handshake 
    // to ensure data is stable.
    
    // For multi-bit data, we need to ensure all bits are synchronized.
    // A common approach is to use a "data valid" signal and 
    // synchronize the data when valid is high.
    
    // Let's use a simple approach: synchronize the data bits 
    // individually. This is safe if the data is stable.
    
    reg [N-1:0] pclk_to_sclk_data_sync1;
    reg [N-1:0] pclk_to_sclk_data_sync2;
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            pclk_to_sclk_data_sync1 <= {N{1'b0}};
            pclk_to_sclk_data_sync2 <= {N{1'b0}};
        end else begin
            pclk_to_sclk_data_sync1 <= pclk_to_sclk_data_reg;
            pclk_to_sclk_data_sync2 <= pclk_to_sclk_data_sync1;
        end
    end
    
    // SCLK side logic
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            sclk_tx_shift_reg <= {N{1'b0}};
            sclk_rx_shift_reg <= {N{1'b0}};
            sclk_bit_counter <= 4'd0;
            sclk_tx_valid <= 1'b0;
            sclk_rx_valid <= 1'b0;
            sclk_tx_ready <= 1'b0;
            sclk_rx_ready <= 1'b0;
            sclk_ssel_active <= 1'b0;
            sclk_sck_phase <= 1'b0;
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
        end else begin
            // Default
            spi_sck_o <= 1'b0;
            
            // TX side
            if (sclk_tx_req && sclk_tx_ready && !sclk_tx_valid) begin
                sclk_tx_shift_reg <= pclk_to_sclk_data_sync2;
                sclk_tx_valid <= 1'b1;
                sclk_bit_counter <= 4'd0;
                sclk_ssel_active <= 1'b1;
                spi_ssel_o <= 1'b0;
            end
            
            if (sclk_tx_valid) begin
                // Shift out
                spi_mosi_o <= sclk_tx_shift_reg[N-1];
                
                // Clock generation
                if (sclk_bit_counter < N-1) begin
                    sclk_bit_counter <= sclk_bit_counter + 1'b1;
                    sclk_sck_phase <= ~sclk_sck_phase;
                    spi_sck_o <= sclk_sck_phase;
                    sclk_tx_shift_reg <= {sclk_tx_shift_reg[N-2:0], 1'b0};
                end else begin
                    // Last bit
                    sclk_sck_phase <= ~sclk_sck_phase;
                    spi_sck_o <= sclk_sck_phase;
                    sclk_tx_valid <= 1'b0;
                    sclk_ssel_active <= 1'b0;
                    spi_ssel_o <= 1'b1;
                    sclk_tx_ready <= 1'b1;
                end
            end else begin
                sclk_tx_ready <= 1'b1;
            end
            
            // RX side
            if (sclk_ssel_active) begin
                // Sample MISO on rising edge of SCK
                if (sclk_sck_phase) begin
                    sclk_rx_shift_reg <= {spi_miso_i, sclk_rx_shift_reg[N-1:1]};
                end
            end
            
            if (sclk_tx_valid && sclk_bit_counter == N-1) begin
                sclk_rx_valid <= 1'b1;
                sclk_rx_shift_reg <= {spi_miso_i, sclk_rx_shift_reg[N-1:1]};
            end
            
            if (sclk_rx_valid && sclk_rx_ready) begin
                sclk_rx_valid <= 1'b0;
                sclk_rx_ready <= 1'b0;
            end
            
            sclk_rx_ready <= !sclk_rx_valid || (sclk_to_pclk_req && pclk_to_sclk_ack_sync[2]);
        end
    end
    
    // Assign RX data to handshake
    assign sclk_to_pclk_rx_data = sclk_rx_shift_reg;
    assign sclk_to_pclk_rx_valid = sclk_rx_valid;
    
    // MOSI output
    assign spi_mosi_o = sclk_tx_shift_reg[N-1];

endmodule
