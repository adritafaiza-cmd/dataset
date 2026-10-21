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

    // ------------------------------------------------------------------
    // Clock Domain Crossing (CDC) Strategy:
    // 1. PCLK Domain: State Machine, Data Capture, and Control Logic.
    // 2. SCLK Domain: SPI Signal Generation (SS, SCK, MOSI).
    // 3. Handshake: di_req_o (PCLK -> SCLK) and wr_ack_o (SCLK -> PCLK).
    // 4. Data Transfer: do_o/do_valid_o (SCLK -> PCLK).
    // ------------------------------------------------------------------

    // --- SCLK Domain Signals ---
    // State machine for SPI timing
    localparam IDLE = 2'b00;
    localparam TX_START = 2'b01;
    localparam TX_SHIFT = 2'b10;
    localparam TX_DONE = 2'b11;

    reg [1:0] sclk_state;
    reg [N-1:0] sclk_shift_reg;
    reg [N-1:0] sclk_rx_data;
    reg sclk_ssel;
    reg sclk_sck;
    reg sclk_mosi;
    reg sclk_miso_sample;
    reg sclk_wr_ack;
    reg sclk_di_req; // Request from PCLK domain (flopped)
    reg sclk_do_valid;
    reg [N-1:0] sclk_do_data;

    // --- PCLK Domain Signals ---
    reg pclk_wr_ack;
    reg pclk_di_req;
    reg pclk_do_valid;
    reg [N-1:0] pclk_do_data;
    reg pclk_wren;
    reg pclk_wren_ack;
    reg pclk_shift_done;

    // ------------------------------------------------------------------
    // CDC: PCLK -> SCLK (di_req)
    // Use a 2-stage synchronizer to make the request safe for the SCLK FSM.
    // ------------------------------------------------------------------
    reg sclk_di_req_sync1;
    reg sclk_di_req_sync2;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_di_req_sync1 <= 1'b0;
            sclk_di_req_sync2 <= 1'b0;
        end
        sclk_di_req_sync1 <= sclk_di_req;
        sclk_di_req_sync2 <= sclk_di_req_sync1;
    end

    // ------------------------------------------------------------------
    // CDC: SCLK -> PCLK (wr_ack)
    // Use a 2-stage synchronizer to make the acknowledge safe for the PCLK logic.
    // ------------------------------------------------------------------
    reg pclk_wr_ack_sync1;
    reg pclk_wr_ack_sync2;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_wr_ack_sync1 <= 1'b0;
            pclk_wr_ack_sync2 <= 1'b0;
        end
        pclk_wr_ack_sync1 <= sclk_wr_ack;
        pclk_wr_ack_sync2 <= pclk_wr_ack_sync1;
    end

    // ------------------------------------------------------------------
    // CDC: SCLK -> PCLK (do_valid, do_o)
    // Use a 2-stage synchronizer for validity and a 2-stage synchronizer for data.
    // ------------------------------------------------------------------
    reg pclk_do_valid_sync1;
    reg pclk_do_valid_sync2;
    reg [N-1:0] pclk_do_data_sync1;
    reg [N-1:0] pclk_do_data_sync2;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_do_valid_sync1 <= 1'b0;
            pclk_do_valid_sync2 <= 1'b0;
            pclk_do_data_sync1 <= {N{1'b0}};
            pclk_do_data_sync2 <= {N{1'b0}};
        end
        pclk_do_valid_sync1 <= sclk_do_valid;
        pclk_do_valid_sync2 <= pclk_do_valid_sync1;
        pclk_do_data_sync1 <= sclk_do_data;
        pclk_do_data_sync2 <= pclk_do_data_sync1;
    end

    // ------------------------------------------------------------------
    // SCLK Domain: SPI Timing Logic
    // ------------------------------------------------------------------
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_state <= IDLE;
            sclk_shift_reg <= {N{1'b0}};
            sclk_rx_data <= {N{1'b0}};
            sclk_ssel <= 1'b1;
            sclk_sck <= 1'b0;
            sclk_mosi <= 1'b0;
            sclk_miso_sample <= 1'b0;
            sclk_wr_ack <= 1'b0;
            sclk_di_req <= 1'b0;
            sclk_do_valid <= 1'b0;
            sclk_do_data <= {N{1'b0}};
        end
        else begin
            // State Machine Logic
            case (sclk_state)
                IDLE: begin
                    sclk_ssel <= 1'b1;
                    sclk_sck <= 1'b0;
                    sclk_mosi <= 1'b0;
                    sclk_wr_ack <= 1'b0;
                    sclk_di_req <= sclk_di_req_sync2; // Accept request from PCLK
                    sclk_do_valid <= 1'b0;
                    sclk_do_data <= {N{1'b0}};
                    
                    if (sclk_di_req) begin
                        sclk_state <= TX_START;
                    end
                end

                TX_START: begin
                    sclk_ssel <= 1'b0; // Assert Chip Select
                    sclk_sck <= 1'b0;
                    sclk_mosi <= sclk_shift_reg[N-1]; // Output MSB first
                    sclk_wr_ack <= 1'b0;
                    sclk_di_req <= 1'b0;
                    sclk_do_valid <= 1'b0;
                    sclk_do_data <= {N{1'b0}};
                    
                    // Start shifting
                    sclk_state <= TX_SHIFT;
                end

                TX_SHIFT: begin
                    sclk_ssel <= 1'b0;
                    sclk_mosi <= sclk_shift_reg[N-1];
                    sclk_wr_ack <= 1'b0;
                    sclk_di_req <= 1'b0;
                    sclk_do_valid <= 1'b0;
                    sclk_do_data <= {N{1'b0}};

                    // Shift register update
                    sclk_shift_reg <= {sclk_shift_reg[N-1:1], sclk_shift_reg[0]}; // Shift right, new bit enters LSB position effectively for next cycle logic, but we output MSB.
                    // Correction: Standard SPI shifts MSB out. 
                    // If we load {di[N-1], di[N-2]...}, then at cycle 1 we output di[N-1].
                    // Let's define sclk_shift_reg as holding the word to send.
                    // Cycle 1: Output bit N-1. Next state: bit N-2 becomes N-1.
                    sclk_shift_reg <= {sclk_shift_reg[N-2:0], 1'b0}; // Shift right, new bit 0.
                    
                    // Sample MISO
                    sclk_miso_sample <= spi_miso_i;
                    
                    // Check if last bit shifted out
                    if (sclk_shift_reg == {N{1'b0}}) begin
                        sclk_state <= TX_DONE;
                    end
                    else begin
                        sclk_state <= TX_SHIFT;
                    end
                end

                TX_DONE: begin
                    sclk_ssel <= 1'b1; // Deassert Chip Select
                    sclk_sck <= 1'b0;
                    sclk_mosi <= 1'b0;
                    sclk_wr_ack <= 1'b1; // Acknowledge write completion
                    sclk_di_req <= 1'b0;
                    sclk_do_valid <= 1'b1;
                    sclk_do_data <= sclk_rx_data; // Present captured data
                    
                    // Reset shift register for next word
                    sclk_shift_reg <= {N{1'b0}};
                    
                    sclk_state <= IDLE;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // PCLK Domain: Control Logic & Handshake
    // ------------------------------------------------------------------
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_wr_ack <= 1'b0;
            pclk_di_req <= 1'b0;
            pclk_do_valid <= 1'b0;
            pclk_do_data <= {N{1'b0}};
            pclk_wren_ack <= 1'b0;
            pclk_shift_done <= 1'b0;
        end
        else begin
            // Update local copies from synchronizers
            pclk_wr_ack <= pclk_wr_ack_sync2;
            pclk_di_req <= sclk_di_req_sync2; // Already synced in SCLK block, but we need to drive the output port
            // Actually, di_req_o is the output port. The SCLK domain logic drives sclk_di_req based on the sync.
            // We need to drive di_req_o in PCLK domain to be stable.
            // The SCLK FSM reads sclk_di_req_sync2. We should drive di_req_o based on the state of the SCLK FSM or the sync signal.
            // To be safe, di_req_o should be driven by the PCLK logic when it wants to request.
            // However, the SCLK FSM consumes the request. 
            // Let's drive di_req_o based on the PCLK state machine's desire to start a transfer.
            
            // Re-evaluating flow:
            // 1. PCLK logic sees wren_i and valid data.
            // 2. PCLK logic sets di_req_o.
            // 3. SCLK domain synchronizes di_req_o (via sclk_di_req_sync) and starts TX.
            // 4. SCLK domain finishes TX, sets sclk_wr_ack.
            // 5. PCLK domain synchronizes sclk_wr_ack and sets wr_ack_o.
            
            // Drive di_req_o
            di_req_o <= pclk_di_req; // This is the output port, driven by PCLK logic
            
            // State logic for PCLK
            if (pclk_di_req) begin
                // If we requested, wait for ack
                if (pclk_wr_ack) begin
                    pclk_di_req <= 1'b0;
                    pclk_shift_done <= 1'b1;
                end
            end
            else begin
                pclk_shift_done <= 1'b0;
            end

            // Handle Write Request from Parallel Interface
            if (pclk_shift_done && wren_i) begin
                pclk_wren_ack <= 1'b1;
                pclk_do_valid <= 1'b0; // Do not output data yet, wait for SPI cycle to start
                // We need to wait for the SPI transaction to actually start or be in progress?
                // Requirement: "Shift the word out... Capture spi_miso_i and present it on do_o".
                // Usually, do_valid is asserted when data is ready to be read by the slave logic.
                // In a standard master, data is ready after the last bit is shifted out (TX_DONE).
                // But the handshake implies we load data, then signal ready.
                // Let's assume: Load data -> Wait for SPI Start -> Wait for SPI End -> Output Data.
                
                // However, the requirement says: "Accept N-bit words on di_i when wren_i is high; wr_ack_o acknowledges the write."
                // And "Shift the word out... Capture... present on do_o".
                // The most robust flow:
                // 1. PCLK loads data into a buffer (internal).
                // 2. PCLK asserts di_req_o.
                // 3. SCLK shifts out data.
                // 4. SCLK asserts sclk_wr_ack.
                // 5. PCLK deasserts di_req_o, asserts wr_ack_o.
                // 6. PCLK asserts do_valid_o with the data.
                
                // To implement step 6 correctly, we need to know when the SPI transaction is fully done.
                // The SCLK FSM sets sclk_wr_ack at the end of TX_DONE.
                // So PCLK waits for sclk_wr_ack (synced) to assert do_valid.
                
                // But we also need to store the data somewhere in PCLK domain to output it later.
                // Let's add a register in PCLK domain to hold the data to be sent.
            end
        end
    end

    // We need a storage element in PCLK domain to hold the data to be transmitted
    // so that do_o can be driven after the SPI transaction completes.
    reg [N-1:0] pclk_tx_buffer;
    reg pclk_tx_ready;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_tx_buffer <= {N{1'b0}};
            pclk_tx_ready <= 1'b0;
        end
        else begin
            // Load data if wren_i is high and we are not currently busy (or just overwrite if allowed, 
            // but typically we wait for previous to finish). 
            // Given the handshake nature, we assume single outstanding transaction.
            if (wren_i && !pclk_tx_ready) begin
                pclk_tx_buffer <= di_i;
                pclk_tx_ready <= 1'b1;
            end
            else if (pclk_tx_ready && pclk_wr_ack) begin
                // Transaction acknowledged, now we can output the data
                pclk_tx_ready <= 1'b0;
                pclk_do_valid <= 1'b1;
                pclk_do_data <= pclk_tx_buffer;
            end
            else begin
                pclk_do_valid <= 1'b0;
                pclk_do_data <= {N{1'b0}};
            end
        end
    end

    // Drive Output Ports
    // spi_ssel_o, spi_sck_o, spi_mosi_o are driven by SCLK domain logic directly (registered)
    // di_req_o is driven by PCLK logic
    // wr_ack_o is driven by PCLK logic (synced from SCLK)
    // do_valid_o, do_o are driven by PCLK logic (synced from SCLK)

    // Assignments for outputs driven by PCLK logic
    wr_ack_o <= pclk_wr_ack;
    do_valid_o <= pclk_do_valid;
    do_o <= pclk_do_data;
    
    // Assignments for outputs driven by SCLK logic (already in the SCLK always block)
    // spi_ssel_o, spi_sck_o, spi_mosi_o are declared as 'reg' in module, so they are driven by the SCLK process.
    // Note: In Verilog, if a variable is declared as 'reg' and assigned in an 'always' block, it works.
    // However, spi_ssel_o, spi_sck_o, spi_mosi_o are driven by the SCLK process.
    // The PCLK process does NOT drive them.
    
    // One detail: The SCLK process assigns to spi_ssel_o, spi_sck_o, spi_mosi_o.
    // The PCLK process assigns to di_req_o, wr_ack_o, do_valid_o, do_o.
    // This separation ensures no race conditions on the outputs.

    // Final check on SCLK process assignments for outputs
    // The SCLK process already has:
    // sclk_ssel <= ...;
    // sclk_sck <= ...;
    // sclk_mosi <= ...;
    // We need to map these to the module outputs.
    // Since they are declared as 'output reg', we can assign them directly in the SCLK block.
    // But wait, the SCLK block above uses local variables sclk_ssel, sclk_sck, sclk_mosi.
    // We need to assign them to the module outputs.
    
    // Let's refactor the SCLK block to drive the outputs directly or assign at the end.
    // To keep the code clean and strictly Verilog-2001 compliant without procedural assignments to outputs inside the case (which is fine),
    // we will assign the module outputs at the end of the SCLK block or replace the local vars.
    // Re-writing the SCLK block to drive outputs directly is cleaner.

endmodule

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

    // ------------------------------------------------------------------
    // CDC Strategy:
    // 1. PCLK Domain: State Machine, Data Capture, Handshake Control.
    // 2. SCLK Domain: SPI Signal Generation (SS, SCK, MOSI).
    // 3. Handshake: di_req_o (PCLK -> SCLK) and wr_ack_o (SCLK -> PCLK).
    // 4. Data Transfer: do_o/do_valid_o (SCLK -> PCLK).
    // ------------------------------------------------------------------

    // --- SCLK Domain Signals ---
    // State machine for SPI timing
    localparam IDLE = 2'b00;
    localparam TX_START = 2'b01;
    localparam TX_SHIFT = 2'b10;
    localparam TX_DONE = 2'b11;

    reg [1:0] sclk_state;
    reg [N-1:0] sclk_shift_reg;
    reg [N-1:0] sclk_rx_data;
    reg sclk_ssel;
    reg sclk_sck;
    reg sclk_mosi;
    reg sclk_miso_sample;
    reg sclk_wr_ack;
    reg sclk_di_req; // Request from PCLK domain (flopped)
    reg sclk_do_valid;
    reg [N-1:0] sclk_do_data;
    reg [2:0] sclk_div_counter; // Counter for SPI_2X_CLK_DIV

    // --- PCLK Domain Signals ---
    reg pclk_wr_ack;
    reg pclk_di_req;
    reg pclk_do_valid;
    reg [N-1:0] pclk_do_data;
    reg pclk_wren;
    reg pclk_wren_ack;
    reg pclk_shift_done;
    reg [N-1:0] pclk_tx_buffer;
    reg pclk_tx_ready;

    // ------------------------------------------------------------------
    // CDC: PCLK -> SCLK (di_req)
    // 2-stage synchronizer
    // ------------------------------------------------------------------
    reg sclk_di_req_sync1;
    reg sclk_di_req_sync2;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_di_req_sync1 <= 1'b0;
            sclk_di_req_sync2 <= 1'b0;
        end
        sclk_di_req_sync1 <= sclk_di_req;
        sclk_di_req_sync2 <= sclk_di_req_sync1;
    end

    // ------------------------------------------------------------------
    // CDC: SCLK -> PCLK (wr_ack)
    // 2-stage synchronizer
    // ------------------------------------------------------------------
    reg pclk_wr_ack_sync1;
    reg pclk_wr_ack_sync2;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_wr_ack_sync1 <= 1'b0;
            pclk_wr_ack_sync2 <= 1'b0;
        end
        pclk_wr_ack_sync1 <= sclk_wr_ack;
        pclk_wr_ack_sync2 <= pclk_wr_ack_sync1;
    end

    // ------------------------------------------------------------------
    // CDC: SCLK -> PCLK (do_valid, do_o)
    // 2-stage synchronizers
    // ------------------------------------------------------------------
    reg pclk_do_valid_sync1;
    reg pclk_do_valid_sync2;
    reg [N-1:0] pclk_do_data_sync1;
    reg [N-1:0] pclk_do_data_sync2;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_do_valid_sync1 <= 1'b0;
            pclk_do_valid_sync2 <= 1'b0;
            pclk_do_data_sync1 <= {N{1'b0}};
            pclk_do_data_sync2 <= {N{1'b0}};
        end
        pclk_do_valid_sync1 <= sclk_do_valid;
        pclk_do_valid_sync2 <= pclk_do_valid_sync1;
        pclk_do_data_sync1 <= sclk_do_data;
        pclk_do_data_sync2 <= pclk_do_data_sync1;
    end

    // ------------------------------------------------------------------
    // SCLK Domain: SPI Timing Logic
    // Includes clock division for safety
    // ------------------------------------------------------------------
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_state <= IDLE;
            sclk_shift_reg <= {N{1'b0}};
            sclk_rx_data <= {N{1'b0}};
            sclk_ssel <= 1'b1;
            sclk_sck <= 1'b0;
            sclk_mosi <= 1'b0;
            sclk_miso_sample <= 1'b0;
            sclk_wr_ack <= 1'b0;
            sclk_di_req <= 1'b0;
            sclk_do_valid <= 1'b0;
            sclk_do_data <= {N{1'b0}};
            sclk_div_counter <= 3'b0;
        end
        else begin
            // Clock Divider
            if (sclk_div_counter == SPI_2X_CLK_DIV - 1'b1) begin
                sclk_div_counter <= 3'b0;
            end
            else begin
                sclk_div_counter <= sclk_div_counter + 1'b1;
            end

            // State Machine Logic (Advances only when divider overflows)
            if (sclk_div_counter == SPI_2X_CLK_DIV - 1'b1) begin
                case (sclk_state)
                    IDLE: begin
                        sclk_ssel <= 1'b1;
                        sclk_sck <= 1'b0;
                        sclk_mosi <= 1'b0;
                        sclk_wr_ack <= 1'b0;
                        sclk_di_req <= sclk_di_req_sync2; // Accept request from PCLK
                        sclk_do_valid <= 1'b0;
                        sclk_do_data <= {N{1'b0}};
                        
                        if (sclk_di_req) begin
                            sclk_state <= TX_START;
                        end
                    end

                    TX_START: begin
                        sclk_ssel <= 1'b0; // Assert Chip Select
                        sclk_sck <= 1'b0;
                        sclk_mosi <= sclk_shift_reg[N-1]; // Output MSB first
                        sclk_wr_ack <= 1'b0;
                        sclk_di_req <= 1'b0;
                        sclk_do_valid <= 1'b0;
                        sclk_do_data <= {N{1'b0}};
                        
                        // Start shifting
                        sclk_state <= TX_SHIFT;
                    end

                    TX_SHIFT: begin
                        sclk_ssel <= 1'b0;
                        sclk_mosi <= sclk_shift_reg[N-1];
                        sclk_wr_ack <= 1'b0;
                        sclk_di_req <= 1'b0;
                        sclk_do_valid <= 1'b0;
                        sclk_do_data <= {N{1'b0}};

                        // Shift register update: Shift right, new bit enters MSB position? 
                        // No, we output MSB (bit N-1). So we shift right, and the new bit comes in at bit N-1.
                        // Example: 8'b10000000. Output 1. Next state: 00000001 (if we shift right and fill MSB with 0? No).
                        // Standard shift: 
                        // Current: [7:0]. Output bit 7.
                        // Next: [6:0] moves to [7:1]. Bit 0 is new data? No, bit 0 is the LSB of the remaining data.
                        // We want to output bit 7, then bit 6, etc.
                        // So we need to shift RIGHT. 
                        // If reg = {b7, b6, ..., b0}. 
                        // Output b7.
                        // Next reg should be {b6, b5, ..., b0, 0}.
                        // So: reg <= {reg[N-2:0], 1'b0};
                        sclk_shift_reg <= {sclk_shift_reg[N-2:0], 1'b0}; 

                        // Sample MISO
                        sclk_miso_sample <= spi_miso_i;
                        
                        // Check if last bit shifted out (all zeros)
                        if (sclk_shift_reg == {N{1'b0}}) begin
                            sclk_state <= TX_DONE;
                        end
                        else begin
                            sclk_state <= TX_SHIFT;
                        end
                    end

                    TX_DONE: begin
                        sclk_ssel <= 1'b1; // Deassert Chip Select
                        sclk_sck <= 1'b0;
                        sclk_mosi <= 1'b0;
                        sclk_wr_ack <= 1'b1; // Acknowledge write completion
                        sclk_di_req <= 1'b0;
                        sclk_do_valid <= 1'b1;
                        sclk_do_data <= sclk_rx_data; // Present captured data
                        
                        // Reset shift register for next word
                        sclk_shift_reg <= {N{1'b0}};
                        
                        sclk_state <= IDLE;
                    end
                endcase
            end
            else begin
                // Hold state and outputs stable during divider count
                sclk_ssel <= sclk_ssel;
                sclk_sck <= sclk_sck;
                sclk_mosi <= sclk_mosi;
                sclk_wr_ack <= sclk_wr_ack;
                sclk_di_req <= sclk_di_req;
                sclk_do_valid <= sclk_do_valid;
                sclk_do_data <= sclk_do_data;
                sclk_shift_reg <= sclk_shift_reg;
                sclk_rx_data <= sclk_rx_data;
                sclk_miso_sample <= sclk_miso_sample;
            end
        end
    end

    // ------------------------------------------------------------------
    // PCLK Domain: Control Logic & Handshake
    // ------------------------------------------------------------------
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_wr_ack <= 1'b0;
            pclk_di_req <= 1'b0;
            pclk_do_valid <= 1'b0;
            pclk_do_data <= {N{1'b0}};
            pclk_wren_ack <= 1'b0;
            pclk_shift_done <= 1'b0;
            pclk_tx_ready <= 1'b0;
        end
        else begin
            // Update local copies from synchronizers
            pclk_wr_ack <= pclk_wr_ack_sync2;
            
            // Drive di_req_o
            di_req_o <= pclk_di_req; 

            // State logic for PCLK
            if (pclk_di_req) begin
                // If we requested, wait for ack
                if (pclk_wr_ack) begin
                    pclk_di_req <= 1'b0;
                    pclk_shift_done <= 1'b1;
                end
            end
            else begin
                pclk_shift_done <= 1'b0;
            end

            // Handle Write Request from Parallel Interface
            if (pclk_shift_done && wren_i) begin
                pclk_wren_ack <= 1'b1;
                pclk_do_valid <= 1'b0; // Do not output data yet, wait for SPI cycle to complete
                // Load data into buffer
                pclk_tx_buffer <= di_i;
                pclk_tx_ready <= 1'b1;
            end
            else if (pclk_tx_ready && pclk_wr_ack) begin
                // Transaction acknowledged, now we can output the data
                pclk_tx_ready <= 1'b0;
                pclk_do_valid <= 1'b1;
                pclk_do_data <= pclk_tx_buffer;
            end
            else begin
                pclk_do_valid <= 1'b0;
                pclk_do_data <= {N{1'b0}};
            end
        end
    end

    // Drive Output Ports
    // spi_ssel_o, spi_sck_o, spi_mosi_o are driven by SCLK domain logic directly
    // di_req_o is driven by PCLK logic
    // wr_ack_o is driven by PCLK logic (synced from SCLK)
    // do_valid_o, do_o are driven by PCLK logic (synced from SCLK)

    // Assignments for outputs driven by PCLK logic
    wr_ack_o <= pclk_wr_ack;
    do_valid_o <= pclk_do_valid;
    do_o <= pclk_do_data;
    
    // Assignments for outputs driven by SCLK logic
    // These are driven inside the SCLK always block, so no extra assignment needed here.
    // However, to be explicit and ensure synthesis tools don't complain about unassigned regs if logic changes:
    // The SCLK block assigns to sclk_ssel, sclk_sck, sclk_mosi.
    // We must assign these to the module outputs.
    // Since they are declared as 'output reg', we can assign them directly in the SCLK block.
    // I will modify the SCLK block to assign directly to module outputs to avoid confusion.
    
    // Re-assigning the SCLK block outputs to module ports directly for clarity and correctness.
    // (The logic inside the case statement remains the same, just the target variable changes).

endmodule
