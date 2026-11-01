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
    
    reg         rx_word_valid;
    reg [N-1:0] rx_word_reg;
    reg         rx_word_ready;

    // Write acknowledge and request logic
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            wr_ack_o   <= 1'b0;
            di_req_o   <= 1'b0;
            tx_word_reg <= {N{1'b0}};
            tx_word_valid <= 1'b0;
        end else begin
            // Default
            wr_ack_o <= 1'b0;
            
            // Handle write request
            if (wren_i && tx_word_ready) begin
                tx_word_reg   <= di_i;
                tx_word_valid <= 1'b1;
                wr_ack_o      <= 1'b1;
            end else begin
                tx_word_valid <= 1'b0; // Clear after one cycle if not re-written
            end
            
            // Request next word when ready
            di_req_o <= tx_word_ready;
        end
    end

    // Output data presentation
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            do_valid_o <= 1'b0;
            do_o       <= {N{1'b0}};
            rx_word_ready <= 1'b0;
        end else begin
            // Default
            do_valid_o <= 1'b0;
            
            if (rx_word_valid) begin
                do_o       <= rx_word_reg;
                do_valid_o <= 1'b1;
                rx_word_ready <= 1'b1; // Acknowledge to SCLK domain
            end else begin
                rx_word_ready <= 1'b0;
            end
        end
    end

    // ========================================================================
    // SCLK Domain: SPI Master Logic
    // ========================================================================
    
    // State machine
    localparam S_IDLE  = 2'd0;
    localparam S_SHIFT = 2'd1;
    localparam S_DONE  = 2'd2;
    
    reg [1:0]  state;
    reg [N-1:0] shift_reg_tx;
    reg [N-1:0] shift_reg_rx;
    reg [31:0] sclk_div_cnt; // Use wide counter for safety, or calculate based on N
    reg [31:0] bit_cnt;
    
    // CDC: TX Data (PCLK -> SCLK)
    // We use a simple 2-phase handshake or a valid/ready with synchronization.
    // Since tx_word_valid is a single bit, we can synchronize it.
    // tx_word_reg is multi-bit, so we need to ensure it's stable when valid is high.
    // We'll use a "data ready" signal that is synchronized, and sample data when it's stable.
    
    reg [2:0] tx_valid_sync;
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            tx_valid_sync <= 3'b111;
        else
            tx_valid_sync <= {tx_valid_sync[1:0], tx_word_valid};
    end
    wire tx_valid_sclk = tx_valid_sync[2];
    
    // We need to know when the data is stable. 
    // A common approach: The PCLK domain holds tx_word_reg stable while tx_word_valid is high.
    // We synchronize tx_word_valid. When it goes high, we wait a few cycles to ensure data is stable, then latch it.
    // Alternatively, use a 2-phase handshake.
    
    // Let's use a simpler approach: 
    // 1. Synchronize tx_word_valid.
    // 2. When tx_word_valid_sclk is high and we are in IDLE, latch the data.
    //    But we need to ensure the data is stable. 
    //    Since tx_word_valid is only high for one PCLK cycle, and the data is held in tx_word_reg,
    //    we can assume the data is stable for at least one SCLK cycle after the valid signal propagates.
    //    To be safe, we'll use a "data ready" flag that is set when we latch the data.
    
    reg tx_data_latched;
    reg [N-1:0] tx_data_sclk;
    
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            tx_data_latched <= 1'b0;
            tx_data_sclk    <= {N{1'b0}};
        end else begin
            if (tx_valid_sclk && !tx_data_latched) begin
                tx_data_sclk    <= tx_word_reg; // Sample data
                tx_data_latched <= 1'b1;
            end
        end
    end
    
    // CDC: RX Data (SCLK -> PCLK)
    // Similar approach. We'll use a valid signal and data.
    reg [2:0] rx_valid_sync;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst)
            rx_valid_sync <= 3'b111;
        else
            rx_valid_sync <= {rx_valid_sync[1:0], rx_word_valid_sclk};
    end
    wire rx_valid_pclk = rx_valid_sync[2];
    
    // We need to generate rx_word_valid_sclk in SCLK domain.
    // And rx_word_reg_sclk in SCLK domain.
    
    reg rx_word_valid_sclk;
    reg [N-1:0] rx_word_reg_sclk;
    
    // CDC: RX Ready (PCLK -> SCLK)
    reg [2:0] rx_ready_sync;
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst)
            rx_ready_sync <= 3'b111;
        else
            rx_ready_sync <= {rx_ready_sync[1:0], rx_word_ready};
    end
    wire rx_ready_sclk = rx_ready_sync[2];

    // SPI Clock Generation
    // SPI_2X_CLK_DIV is the divisor. 
    // We'll generate a clock that is sclk_i / (2 * SPI_2X_CLK_DIV) or similar.
    // Let's assume SPI_2X_CLK_DIV is the number of sclk_i cycles per SPI clock cycle.
    // So SPI clock frequency = sclk_i / SPI_2X_CLK_DIV.
    // We need to generate a square wave.
    
    reg [31:0] sclk_gen_cnt;
    reg        sclk_gen_phase;
    
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            sclk_gen_cnt   <= 32'd0;
            sclk_gen_phase <= 1'b0;
            spi_sck_o      <= 1'b0;
        end else begin
            if (state == S_SHIFT) begin
                if (sclk_gen_cnt == SPI_2X_CLK_DIV - 1) begin
                    sclk_gen_cnt   <= 32'd0;
                    sclk_gen_phase <= ~sclk_gen_phase;
                    spi_sck_o      <= sclk_gen_phase;
                end else begin
                    sclk_gen_cnt   <= sclk_gen_cnt + 1'b1;
                end
            end else begin
                sclk_gen_cnt   <= 32'd0;
                sclk_gen_phase <= 1'b0;
                spi_sck_o      <= 1'b0;
            end
        end
    end

    // SPI State Machine
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            state          <= S_IDLE;
            spi_ssel_o     <= 1'b1; // Active high? Usually active low. Let's assume active low for ssel.
            spi_mosi_o     <= 1'b0;
            shift_reg_tx   <= {N{1'b0}};
            shift_reg_rx   <= {N{1'b0}};
            bit_cnt        <= 32'd0;
            rx_word_valid_sclk <= 1'b0;
            rx_word_reg_sclk   <= {N{1'b0}};
        end else begin
            case (state)
                S_IDLE: begin
                    spi_ssel_o <= 1'b1; // Deselected
                    spi_mosi_o <= 1'b0;
                    rx_word_valid_sclk <= 1'b0;
                    
                    // Check if we have data to send
                    if (tx_data_latched) begin
                        state        <= S_SHIFT;
                        spi_ssel_o   <= 1'b0; // Select
                        shift_reg_tx <= tx_data_sclk;
                        shift_reg_rx <= {N{1'b0}};
                        bit_cnt      <= 32'd0;
                        tx_data_latched <= 1'b0; // Clear latched flag
                    end
                end
                
                S_SHIFT: begin
                    // Shift on rising edge of spi_sck_o (which is generated by sclk_gen_phase)
                    // We'll shift when sclk_gen_phase changes from 0 to 1 (rising edge)
                    // But we need to be careful with the timing.
                    
                    // Let's shift on the falling edge of spi_sck_o for MOSI, and sample MISO on rising edge.
                    // Standard SPI Mode 0: SCK idle low, data changes on falling edge, sampled on rising edge.
                    
                    // We'll use sclk_gen_phase to determine the edge.
                    // When sclk_gen_phase goes from 0 to 1, it's a rising edge.
                    // When sclk_gen_phase goes from 1 to 0, it's a falling edge.
                    
                    // We'll shift MOSI on falling edge (sclk_gen_phase 1->0)
                    // and sample MISO on rising edge (sclk_gen_phase 0->1)
                    
                    if (sclk_gen_phase == 1'b0) begin
                        // Rising edge of spi_sck_o
                        // Sample MISO
                        shift_reg_rx <= {shift_reg_rx[N-2:0], spi_miso_i};
                        
                        // Increment bit counter
                        if (bit_cnt == N - 1) begin
                            state <= S_DONE;
                        end else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end else begin
                        // Falling edge of spi_sck_o
                        // Shift MOSI
                        spi_mosi_o <= shift_reg_tx[N-1];
                        shift_reg_tx <= {shift_reg_tx[N-2:0], 1'b0};
                    end
                end
                
                S_DONE: begin
                    spi_ssel_o <= 1'b1; // Deselect
                    spi_mosi_o <= 1'b0;
                    
                    // Prepare RX data for PCLK domain
                    rx_word_reg_sclk   <= shift_reg_rx;
                    rx_word_valid_sclk <= 1'b1;
                    
                    // Wait for PCLK domain to acknowledge
                    if (rx_ready_sclk) begin
                        state <= S_IDLE;
                        rx_word_valid_sclk <= 1'b0;
                    end
                end
                
                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

    // Update PCLK domain RX data
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            rx_word_reg   <= {N{1'b0}};
            rx_word_valid <= 1'b0;
        end else begin
            if (rx_valid_pclk) begin
                rx_word_reg   <= rx_word_reg_sclk;
                rx_word_valid <= 1'b1;
            end else begin
                rx_word_valid <= 1'b0;
            end
        end
    end

endmodule
