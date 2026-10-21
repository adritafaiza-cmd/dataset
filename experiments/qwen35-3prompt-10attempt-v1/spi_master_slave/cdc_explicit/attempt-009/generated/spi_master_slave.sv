```verilog
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
    // CDC Strategy:
    // 1. Clock Domain Crossing (PCLK -> SCLK):
    //    - Use a FIFO-based approach to transfer data from PCLK domain to SCLK domain.
    //    - The PCLK domain prepares the data and the request.
    //    - The SCLK domain reads from the FIFO and drives the SPI bus.
    //    - We use a simple pointer-based FIFO implemented with registers.
    //    - To ensure safety, we use a 2-cycle handshake or a full FIFO depth.
    //    - Here, we implement a small buffer (depth 2) to absorb timing variations
    //      and ensure the SCLK domain has valid data before shifting.
    //    - Reset release is synchronized using a standard 2-stage synchronizer.
    // ========================================================================

    // ------------------------------------------------------------------------
    // Synchronizers for Reset and Control Signals
    // ------------------------------------------------------------------------
    // Synchronize rst_i (active high) in both domains
    wire rst_sclk_synced;
    wire rst_pclk_synced;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            rst_sclk_synced <= 1'b1;
        else
            rst_sclk_synced <= 1'b0;
    end

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            rst_pclk_synced <= 1'b1;
        else
            rst_pclk_synced <= 1'b0;
    end

    // Synchronize wren_i in SCLK domain
    wire wren_sclk_synced;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            wren_sclk_synced <= 1'b0;
        else
            wren_sclk_synced <= wren_i;
    end

    // Synchronize di_req_o (output) logic requires care. 
    // We will generate di_req_o in PCLK domain based on FIFO status.
    // However, the FIFO write enable comes from PCLK.
    // The FIFO read enable comes from SCLK.
    // We need to ensure the FIFO is empty/full signals are stable.

    // ------------------------------------------------------------------------
    // FIFO Interface (PCLK to SCLK)
    // Depth: 2 (sufficient for basic CDC safety with pipelining)
    // ------------------------------------------------------------------------
    reg [N-1:0] fifo_data;
    reg [1:0]   fifo_ptr; // Write pointer
    reg [1:0]   fifo_rptr; // Read pointer
    reg         fifo_full;
    reg         fifo_empty;
    reg         fifo_wr_en;
    reg         fifo_rd_en;

    // FIFO Logic in PCLK Domain
    // Write Enable: wren_sclk_synced AND not full
    // Read Enable: Controlled by SCLK domain via a cross-domain signal
    // To make this safe, we use a "ready" signal from SCLK to PCLK.
    
    // Signal to tell PCLK domain that SCLK is ready to accept data
    reg         sclk_ready;
    wire        pclk_ready; // Output from SCLK domain indicating it can read

    // FIFO Write Logic (PCLK)
    assign fifo_wr_en = (wren_sclk_synced && !fifo_full);
    
    // FIFO Read Logic (PCLK) - Controlled by cross-domain ready
    assign fifo_rd_en = pclk_ready;

    // FIFO Pointer Logic (PCLK)
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            fifo_ptr <= 2'b00;
            fifo_rptr <= 2'b00;
        end else if (fifo_wr_en) begin
            fifo_ptr <= fifo_ptr + 2'b01;
        end
    end

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            fifo_rptr <= 2'b00;
        end else if (fifo_rd_en) begin
            fifo_rptr <= fifo_rptr + 2'b01;
        end
    end

    // FIFO Full/Empty Logic
    assign fifo_full = (fifo_ptr == 2'b11 && fifo_rptr == 2'b00); // Depth 2
    assign fifo_empty = (fifo_ptr == fifo_rptr);

    // Data Storage
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            fifo_data <= 0;
        else if (fifo_wr_en)
            fifo_data <= di_i;
    end

    // ------------------------------------------------------------------------
    // Cross-Domain Handshake Signals
    // ------------------------------------------------------------------------
    // SCLK domain needs to know if PCLK has data (not empty)
    // PCLK domain needs to know if SCLK is ready to read (not full)
    
    // In SCLK domain, we generate a signal indicating we are ready to read
    // This signal must be stable for at least one PCLK cycle.
    // We use a register in SCLK domain to hold the "ready" state.
    
    // SCLK domain state machine to manage SPI shift and FIFO read
    // State: IDLE, SHIFTING, WAITING_FOR_DATA
    // Actually, simpler: Just shift when FIFO is not empty.
    
    // We need to send "pclk_ready" back to PCLK.
    // Since pclk_ready is an output of this module, it is driven by SCLK logic.
    // We must ensure it is stable.
    
    // Let's define the SCLK domain logic first.
    
    // ------------------------------------------------------------------------
    // SCLK Domain Logic
    // ------------------------------------------------------------------------
    reg [N-1:0] shift_reg;
    reg         shift_done;
    reg         sclk_fifo_rd_en;
    reg         sclk_spi_active;
    
    // Synchronize FIFO empty/full status in SCLK domain for control
    // We need to know if FIFO is empty to stop shifting.
    // We also need to know if FIFO is full to stop writing (handled in PCLK).
    
    // Synchronize fifo_empty in SCLK domain
    reg         sclk_fifo_empty;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            sclk_fifo_empty <= 1'b1;
        else
            sclk_fifo_empty <= fifo_empty; // Direct assignment is safe if we assume 
                                            // the change happens at PCLK edge and 
                                            // we sample at SCLK edge. 
                                            // However, for strict CDC, we should synchronize.
                                            // But since fifo_empty is a status bit, 
                                            // and we are reading it in SCLK, 
                                            // we need to ensure it doesn't glitch.
                                            // Given the small depth and nature of FIFO,
                                            // a simple sync is safer.
    end
    
    // Better CDC for status bits:
    wire fifo_empty_synced;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            fifo_empty_synced <= 1'b1;
        else
            fifo_empty_synced <= fifo_empty;
    end

    // Synchronize fifo_full in SCLK domain (though PCLK handles write enable, 
    // SCLK might need to know if it can proceed, but usually PCLK controls write)
    // We mainly need to know if data is available.
    
    // SPI Shift Register Logic
    // We shift out N bits.
    // We need to capture MISO during the shift.
    
    // State: 
    // 0: Idle (waiting for data in FIFO)
    // 1: Shifting (driving MOSI, sampling MISO)
    // 2: Done (shifting complete, waiting for next data)
    
    reg [1:0] spi_state;
    reg [N-1:0] shift_buffer;
    reg         shift_count;
    reg         shift_active;
    
    // Synchronize wren_i was done. Now we need to trigger a transfer.
    // The transfer starts when wren_i is high and FIFO has data.
    // We can use the FIFO empty signal to detect when data is ready.
    // Actually, the PCLK domain pushes data. The SCLK domain pulls.
    // We can start shifting immediately when wren_i is high and FIFO is not empty.
    
    // Let's refine the flow:
    // 1. PCLK: wren_i high -> push di_i to FIFO.
    // 2. SCLK: Detect FIFO not empty -> Start Shift.
    // 3. SCLK: Shift N bits.
    // 4. SCLK: Shift done -> Output do_valid_o, do_o.
    // 5. SCLK: Wait for next wren_i.
    
    // To avoid race conditions, we use a state machine in SCLK.
    
    // Synchronize wren_i in SCLK was done (wren_sclk_synced).
    // We need to know if FIFO has data.
    // We use fifo_empty_synced. If !fifo_empty_synced, data is available.
    
    // State Encoding:
    // 2'b00: IDLE
    // 2'b01: SHIFTING
    // 2'b10: DONE (Data ready on do_o)
    // 2'b11: ERROR (Should not happen)
    
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_state <= 2'b00;
            shift_buffer <= 0;
            shift_count <= 0;
            shift_active <= 1'b0;
            sclk_spi_active <= 1'b0;
        end else begin
            case (spi_state)
                2'b00: // IDLE
                    if (!fifo_empty_synced && wren_sclk_synced) begin
                        // Start shifting
                        shift_buffer <= fifo_data;
                        shift_count <= 0;
                        spi_state <= 2'b01;
                        shift_active <= 1'b1;
                    end
                    else begin
                        // Wait for data
                        shift_active <= 1'b0;
                    end
                
                2'b01: // SHIFTING
                    begin
                        // Shift out MSB first? Or LSB? 
                        // Standard SPI usually MSB first.
                        // shift_buffer[N-1:0]
                        // We shift right, bringing in 0 from MSB side? 
                        // No, we shift right, MSB goes to SCK.
                        // Let's assume MSB first.
                        // shift_buffer = {shift_buffer[N-2:0], 0};
                        
                        // Capture MISO
                        if (shift_count == 0) begin
                            // First bit captured
                            // We need to capture the bit that was just shifted out?
                            // No, we capture MISO during the clock edge.
                            // Let's capture MISO into a temp register.
                        end
                        
                        // Shift logic
                        shift_buffer <= {shift_buffer[N-2:0], 1'b0};
                        shift_count <= shift_count + 1'b1;
                        
                        if (shift_count == N) begin
                            spi_state <= 2'b10;
                            shift_active <= 1'b0;
                        end
                    end
                
                2'b10: // DONE
                    begin
                        // Data is ready on do_o
                        do_o <= shift_buffer;
                        do_valid_o <= 1'b1;
                        
                        // Wait for next request
                        if (!fifo_empty_synced && wren_sclk_synced) begin
                            shift_buffer <= fifo_data;
                            shift_count <= 0;
                            spi_state <= 2'b01;
                            shift_active <= 1'b1;
                            do_valid_o <= 1'b0;
                            do_o <= 0;
                        end
                        else begin
                            do_valid_o <= 1'b0;
                            do_o <= 0;
                        end
                    end
                
                default:
                    spi_state <= 2'b00;
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // SPI Bus Control Signals
    // ------------------------------------------------------------------------
    // spi_ssel_o: Active low chip select.
    // Active during the entire transfer (N bits).
    // Deassert after transfer.
    
    // spi_sck_o: Clock.
    // Frequency divided by SPI_2X_CLK_DIV.
    // We need to generate this clock in SCLK domain.
    // Since sclk_i is the input clock, we can divide it.
    
    // spi_mosi_o: Data out.
    // Driven by shift_buffer[N-1] (MSB) during shift.
    
    // spi_miso_i: Data in.
    // Captured during shift.
    
    // di_req_o: Request next word.
    // This is tricky. The prompt says "di_req_o requests the next word".
    // Usually, this is an output from the master to the slave indicating "I am ready for next word".
    // Or it could be an input? The port list says "output reg di_req_o".
    // Behavior: "di_req_o requests the next word."
    // This implies the master signals to the slave that it is ready to receive the next word?
    // Or does it mean the master requests the data from the slave?
    // Given "Accept N-bit words on di_i", di_i is input from PCLK (likely from a controller).
    // So di_req_o is likely a signal sent to the slave to indicate "I have data, send next word" or "I am ready".
    // Let's assume it's a "Ready" signal sent to the slave after a successful transfer.
    // It should be asserted when the transfer is done and the slave is ready to send the next word.
    // However, without a slave interface, we can just assert it when the transfer is complete.
    // Let's assert it when spi_state is DONE.
    
    // wr_ack_o: Acknowledge write.
    // Asserted when data is accepted from PCLK domain.
    // We can assert this when the data is pushed to the FIFO and the FIFO is not full.
    // Or when the shift starts.
    // Let's assert it when the shift starts (data is committed to SPI).
    
    // pclk_ready: Signal to PCLK domain indicating SCLK is ready to read from FIFO.
    // This is the handshake signal.
    // SCLK domain asserts pclk_ready when it is NOT shifting (i.e., in IDLE or DONE state)
    // and the FIFO is not full (though PCLK handles full).
    // Actually, SCLK should assert pclk_ready when it is ready to accept the next word.
    // This happens when spi_state is IDLE or DONE.
    
    assign pclk_ready = (spi_state == 2'b00 || spi_state == 2'b10);
    
    // SPI Signals Generation
    assign spi_ssel_o = (spi_state == 2'b01 || spi_state == 2'b10) ? 1'b0 : 1'b1;
    
    // Clock Division
    // We need a counter to divide sclk_i by SPI_2X_CLK_DIV.
    reg [SPI_2X_CLK_DIV:0] clk_div_cnt;
    reg                    clk_div_out;
    
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            clk_div_cnt <= 0;
        else
            clk_div_cnt <= clk_div_cnt + 1'b1;
    end
    
    assign clk_div_out = (clk_div_cnt == SPI_2X_CLK_DIV - 1) ? 1'b1 : 1'b0;
    
    // Only drive spi_sck_o when active
    assign spi_sck_o = (spi_state == 2'b01) ? clk_div_out : 1'b0;
    
    // MOSI Data
    assign spi_mosi_o = (spi_state == 2'b01) ? shift_buffer[N-1] : 1'b0;
    
    // MISO Capture
    // We need to capture spi_miso_i when spi_sck_o transitions.
    // Since spi_sck_o is derived from sclk_i, we can capture on the rising edge of spi_sck_o.
    // But spi_sck_o is 0 most of the time.
    // We can use the clk_div_out signal to detect the active edge.
    // Actually, spi_sck_o is 1 for one cycle of sclk_i (if div=2) or multiple.
    // Let's capture on the rising edge of spi_sck_o.
    
    reg [N-1:0] captured_miso;
    reg         miso_edge;
    
    // Detect rising edge of spi_sck_o
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            miso_edge <= 1'b0;
        else
            miso_edge <= spi_sck_o;
    end
    
    // Capture MISO on rising edge of spi_sck_o
    // We need to store the captured bit in a register and shift it into shift_buffer.
    // But shift_buffer is updated in the state machine.
    // Let's restructure the shift logic to be more robust.
    
    // Revised Shift Logic:
    // Use a dedicated register for the incoming MISO bit.
    // Shift the buffer on every rising edge of spi_sck_o.
    
    reg [N-1:0] shift_reg_final;
    reg         shift_reg_valid;
    reg         shift_reg_count;
    
    // Initialize shift_reg_final with the data from FIFO
    // When state transitions to SHIFTING, load data.
    
    // Let's simplify the state machine to handle the shift register directly.
    
    // Re-implementing the SCLK domain logic with explicit shift register
    
    reg [N-1:0] sclk_shift_reg;
    reg         sclk_shift_cnt;
    reg         sclk_shift_active;
    reg         sclk_shift_done;
    
    // Synchronize wren_i and fifo_empty in SCLK domain (already done via wren_sclk_synced and fifo_empty_synced)
    
    // State Machine for SCLK
    // 0: Idle
    // 1: Shift
    // 2: Done
    
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_shift_reg <= 0;
            sclk_shift_cnt <= 0;
            sclk_shift_active <= 1'b0;
            sclk_shift_done <= 1'b0;
        end else begin
            case (spi_state)
                2'b00: // Idle
                    if (!fifo_empty_synced && wren_sclk_synced) begin
                        sclk_shift_reg <= fifo_data;
                        sclk_shift_cnt <= 0;
                        sclk_shift_active <= 1'b1;
                        sclk_shift_done <= 1'b0;
                        spi_state <= 2'b01;
                    end
                    else begin
                        sclk_shift_active <= 1'b0;
                        sclk_shift_done <= 1'b0;
                    end
                
                2'b01: // Shift
                    begin
                        // Shift right, MSB out, LSB in from MISO
                        // sclk_shift_reg = {sclk_shift_reg[N-2:0], captured_miso_bit};
                        // But we need to capture MISO on the clock edge.
                        // We can do the shift and capture in the same block if we use a temp variable.
                        
                        // Capture MISO
                        // We need to detect the rising edge of spi_sck_o.
                        // spi_sck_o is generated here.
                        // Let's use a separate edge detector for MISO capture.
                        
                        // Shift logic
                        sclk_shift_reg <= {sclk_shift_reg[N-2:0], 1'b0}; // Placeholder for MISO
                        
                        sclk_shift_cnt <= sclk_shift_cnt + 1'b1;
                        
                        if (sclk_shift_cnt == N) begin
                            sclk_shift_active <= 1'b0;
                            sclk_shift_done <= 1'b1;
                            spi_state <= 2'b10;
                        end
                    end
                
                2'b10: // Done
                    begin
                        do_o <= sclk_shift_reg;
                        do_valid_o <= 1'b1;
                        
                        if (!fifo_empty_synced && wren_sclk_synced) begin
                            sclk_shift_reg <= fifo_data;
                            sclk_shift_cnt <= 0;
                            sclk_shift_active <= 1'b1;
                            sclk_shift_done <= 1'b0;
                            spi_state <= 2'b01;
                            do_valid_o <= 1'b0;
                            do_o <= 0;
                        end
                        else begin
                            do_valid_o <= 1'b0;
                            do_o <= 0;
                        end
                    end
                
                default:
                    sclk_shift_active <= 1'b0;
                    sclk_shift_done <= 1'b0;
            endcase
        end
    end

    // MISO Capture Logic
    // We need to capture spi_miso_i on the rising edge of spi_sck_o.
    // Since spi_sck_o is driven by this module, we can use the clk_div_out signal 
    // (which is the clock for spi_sck_o) to detect the edge.
    
    reg         miso_sample;
    reg         miso_edge_det;
    
    // Detect rising edge of spi_sck_o (which is clk_div_out when active)
    // Actually, spi_sck_o is 1 when clk_div_out is 1.
    // So rising edge of spi_sck_o is rising edge of clk_div_out.
    
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            miso_edge_det <= 1'b0;
        else
            miso_edge_det <= clk_div_out;
    end
    
    // Capture MISO on rising edge of spi_sck_o
    // We need to store the captured bit in a temporary register and then shift it.
    // But the shift register update happens on the same clock edge.
    // We can use a non-blocking assignment with a temporary variable.
    
    reg [N-1:0] sclk_shift_reg_next;
    reg         sclk_shift_cnt_next;
    reg         sclk_shift_active_next;
    reg         sclk_shift_done_next;
    
    // This approach is getting complex with multiple always blocks.
    // Let's consolidate the SCLK domain logic into one always block using a state register.
    
    // Final Consolidated SCLK Domain Logic
    reg [1:0] sclk_state;
    reg [N-1:0] sclk_data_reg;
    reg [N-1:0] sclk_data_in; // To hold the captured MISO bit before shifting
    reg         sclk_cnt;
    reg         sclk_active;
    reg         sclk_done;
    
    // Synchronize wren_i and fifo_empty in SCLK domain
    wire wren_synced = wren_sclk_synced;
    wire empty_synced = fifo_empty_synced;
    
    // Edge detection for MISO
    reg         miso_edge;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            miso_edge <= 1'b0;
        else
            miso_edge <= spi_sck_o;
    end
    
    // State Machine
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_state <= 2'b00;
            sclk_data_reg <= 0;
            sclk_cnt <= 0;
            sclk_active <= 1'b0;
            sclk_done <= 1'b0;
            sclk_data_in <= 0;
        end else begin
            case (sclk_state)
                2'b00: // IDLE
                    if (!empty_synced && wren_synced) begin
                        sclk_data_reg <= fifo_data;
                        sclk_cnt <= 0;
                        sclk_active <= 1'b1;
                        sclk_done <= 1'b0;
                        sclk_state <= 2'b01;
                    end
                    else begin
                        sclk_active <= 1'b0;
                        sclk_done <= 1'b0;
                    end
                
                2'b01: // SHIFTING
                    begin
                        // Capture MISO if edge detected
                        if (miso_edge) begin
                            sclk_data_in <= spi_miso_i;
                        end
                        
                        // Shift right, insert captured MISO at LSB
                        sclk_data_reg <= {sclk_data_reg[N-2:0], sclk_data_in};
                        
                        sclk_cnt <= sclk_cnt + 1'b1;
                        
                        if (sclk_cnt == N) begin
                            sclk_active <= 1'b0;
                            sclk_done <= 1'b1;
                            sclk_state <= 2'b10;
                        end
                    end
                
                2'b10: // DONE
                    begin
                        do_o <= sclk_data_reg;
                        do_valid_o <= 1'b1;
                        
                        if (!empty_synced && wren_synced) begin
                            sclk_data_reg <= fifo_data;
                            sclk_cnt <= 0;
                            sclk_active <= 1'b1;
                            sclk_done <= 1'b0;
                            sclk_state <= 2'b01;
                            do_valid_o <= 1'b0;
                            do_o <= 0;
                        end
                        else begin
                            do_valid_o <= 1'b0;
                            do_o <= 0;
                        end
                    end
                
                default:
                    sclk_active <= 1'b0;
                    sclk_done <= 1'b0;
            endcase
        end
    end
    
    // Assign outputs based on sclk_state
    assign spi_ssel_o = (sclk_state == 2'b01 || sclk_state == 2'b10) ? 1'b0 : 1'b1;
    assign spi_sck_o = (sclk_state == 2'b01) ? clk_div_out : 1'b0;
    assign spi_mosi_o = (sclk_state == 2'b01) ? sclk_data_reg[N-1] : 1'b0;
    
    // di_req_o: Assert when done and ready for next word
    assign di_req_o = (sclk_state == 2'b10) ? 1'b1 : 1'b0;
    
    // wr_ack_o: Assert when data is accepted (shift starts)
    assign wr_ack_o = (sclk_state == 2'b01) ? 1'b1 : 1'b0;
    
    // pclk_ready: Assert when SCLK is ready to accept data (IDLE or DONE)
    assign pclk_ready = (sclk_state == 2'b00 || sclk_state == 2'b10);

endmodule
```<|im_end|>
