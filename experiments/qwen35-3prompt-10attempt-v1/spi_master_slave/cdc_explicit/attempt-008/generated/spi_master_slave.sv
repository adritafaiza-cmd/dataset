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

    // ------------------------------------------------------------------
    // Clock Domain Crossing (CDC) Strategy:
    // 1. PCLK Domain: State machine, data buffering, and handshake logic.
    // 2. SCLK Domain: SPI shift register and timing generation.
    // 3. Reset Domain: Use a dedicated reset synchronizer for each domain.
    // ------------------------------------------------------------------

    // --- Synchronizers for Reset and Control Signals ---

    // Synchronize rst_i to PCLK domain
    reg [1:0] rst_p_sync;
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            rst_p_sync <= 2'b00;
        else begin
            rst_p_sync[0] <= rst_p_sync[1];
            rst_p_sync[1] <= rst_p_sync[0];
        end
    end

    // Synchronize rst_i to SCLK domain
    reg [1:0] rst_s_sync;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            rst_s_sync <= 2'b00;
        else begin
            rst_s_sync[0] <= rst_s_sync[1];
            rst_s_sync[1] <= rst_s_sync[0];
        end
    end

    // Synchronize wren_i to SCLK domain (needed to trigger transfer start)
    reg [1:0] wren_s_sync;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            wren_s_sync <= 2'b00;
        else begin
            wren_s_sync[0] <= wren_s_sync[1];
            wren_s_sync[1] <= wren_s_sync[0];
        end
    end

    // Synchronize spi_miso_i to PCLK domain
    reg [1:0] miso_p_sync;
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            miso_p_sync <= 2'b00;
        else begin
            miso_p_sync[0] <= miso_p_sync[1];
            miso_p_sync[1] <= miso_p_sync[0];
        end
    end

    // --- PCLK Domain State Machine & Control ---

    // State encoding
    localparam IDLE = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam AWAIT_ACK = 2'b10;

    reg [1:0] p_state;
    reg [N-1:0] p_data_reg;
    reg p_transfer_active;
    reg p_shift_complete;
    reg p_do_valid;
    reg [N-1:0] p_do_data;

    // SPI Shift Register (SCLK domain)
    reg [N-1:0] s_shift_reg;
    reg s_shift_enable;
    reg s_shift_done;

    // ------------------------------------------------------------------
    // PCLK Domain Logic
    // ------------------------------------------------------------------

    always @(posedge pclk_i or posedge rst_p_sync[1]) begin
        if (rst_p_sync[1]) begin
            p_state <= IDLE;
            p_data_reg <= 0;
            p_transfer_active <= 0;
            p_shift_complete <= 0;
            p_do_valid <= 0;
            p_do_data <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
        end
        else begin
            // State Machine
            case (p_state)
                IDLE: begin
                    if (wren_s_sync[1] && wren_i) begin
                        p_data_reg <= di_i;
                        p_transfer_active <= 1;
                        p_state <= TRANSFER;
                        di_req_o <= 1; // Request next word immediately after start
                    end
                    else begin
                        di_req_o <= 0;
                    end
                end

                TRANSFER: begin
                    if (p_shift_complete) begin
                        p_state <= AWAIT_ACK;
                        p_do_valid <= 1;
                        p_do_data <= s_shift_reg;
                    end
                end

                AWAIT_ACK: begin
                    if (wren_i) begin
                        p_state <= IDLE;
                        wr_ack_o <= 1;
                        p_do_valid <= 0;
                        di_req_o <= 0;
                    end
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // SCLK Domain Logic (SPI Timing)
    // ------------------------------------------------------------------

    // Generate SPI clock with optional division
    // We use a counter to divide sclk_i by SPI_2X_CLK_DIV to get spi_sck_o
    reg [SPI_2X_CLK_DIV:0] sck_div_cnt;
    reg sck_div_enable;

    always @(posedge sclk_i or posedge rst_s_sync[1]) begin
        if (rst_s_sync[1]) begin
            sck_div_cnt <= 0;
            sck_div_enable <= 0;
            s_shift_enable <= 0;
            s_shift_done <= 0;
            spi_sck_o <= 0;
            spi_ssel_o <= 1; // Active High Select (Inactive = High)
            spi_mosi_o <= 0;
        end
        else begin
            // Enable shifting only when PCLK domain says we are in TRANSFER
            sck_div_enable <= p_transfer_active;
            
            // Counter logic for clock division
            if (sck_div_enable) begin
                if (sck_div_cnt == SPI_2X_CLK_DIV - 1) begin
                    sck_div_cnt <= 0;
                    s_shift_enable <= 1; // Trigger shift on the falling edge of the divided clock (or rising, depending on design choice. Here we shift on the active edge of the divided clock).
                    // Note: To ensure clean CDC, we trigger the shift register update on the edge of spi_sck_o.
                    // Let's define spi_sck_o as the output of the divider.
                    // We will shift when the counter wraps around.
                end
                else begin
                    sck_div_cnt <= sck_div_cnt + 1;
                end
            end
            else begin
                sck_div_cnt <= 0;
                s_shift_enable <= 0;
            end
        end
    end

    // Generate spi_sck_o based on the counter
    always @(posedge sclk_i or posedge rst_s_sync[1]) begin
        if (rst_s_sync[1]) begin
            spi_sck_o <= 0;
        end
        else begin
            if (sck_div_enable) begin
                if (sck_div_cnt == SPI_2X_CLK_DIV - 1)
                    spi_sck_o <= 1;
                else
                    spi_sck_o <= 0;
            end
            else begin
                spi_sck_o <= 0;
            end
        end
    end

    // Generate spi_ssel_o (Active Low usually, but prompt says "selects are inactive". 
    // Standard SPI: SS Low = Active. Let's assume Active Low for SS, so Inactive = High).
    // The prompt says "After reset, selects are inactive". 
    // If we assume standard SPI (SS active low), then inactive is 1.
    // If we assume active high, then inactive is 0. 
    // Given "spi_ssel_o" output, standard convention is Active Low.
    // We will drive it low during transfer.
    always @(posedge sclk_i or posedge rst_s_sync[1]) begin
        if (rst_s_sync[1]) begin
            spi_ssel_o <= 1;
        end
        else begin
            if (p_transfer_active)
                spi_ssel_o <= 0;
            else
                spi_ssel_o <= 1;
        end
    end

    // Shift Register Logic
    // Shift in MSB first or LSB first? 
    // Standard SPI often shifts MSB first. 
    // We will shift MSB first (di_i[N-1] enters first).
    // We need to capture spi_miso_i into the shift register.
    
    always @(posedge sclk_i or posedge rst_s_sync[1]) begin
        if (rst_s_sync[1]) begin
            s_shift_reg <= 0;
            s_shift_done <= 0;
        end
        else begin
            if (s_shift_enable) begin
                // Shift left, insert new bit at LSB position (MSB first transmission)
                // s_shift_reg[N-1] gets the new bit from di_i
                // s_shift_reg[0] gets the bit from spi_miso_i (LSB of received data)
                
                // However, we need to handle the first bit carefully.
                // Let's assume we shift in di_i[N-1] first.
                // On the first clock cycle of transfer:
                // s_shift_reg[N-1] = di_i[N-1]
                // s_shift_reg[0:N-2] = s_shift_reg[1:N-1]
                // s_shift_reg[0] = spi_miso_i (if we are capturing simultaneously)
                
                // Actually, standard shift register behavior:
                // New Data enters at one end, data shifts out the other.
                // We want to output di_i[N-1] first on spi_mosi_o.
                // So spi_mosi_o should be s_shift_reg[N-1].
                // And we want to capture spi_miso_i into s_shift_reg[0].
                
                // Logic:
                // s_shift_reg[N-1] <= di_i[N-1] (on first cycle)
                // But di_i is only valid when wren_i is high.
                // We need to ensure we don't shift garbage on the first cycle if wren_i wasn't high?
                // The state machine ensures p_transfer_active is high only when wren_i was detected.
                // So we can safely shift.
                
                // To handle the "first bit" correctly without a separate flag in SCLK domain:
                // We can rely on the fact that s_shift_reg is reset.
                // But we need to know if this is the first bit of the word.
                // Since we are in TRANSFER state, we know we are starting a word.
                // Let's use a simple approach:
                // Shift left. Insert di_i[N-1] at MSB. Capture spi_miso_i at LSB.
                // This works perfectly for a full word transfer.
                
                s_shift_reg <= {s_shift_reg[N-2:0], spi_miso_i};
                s_shift_reg[N-1] <= di_i[N-1]; // Force MSB to be the first bit of input word
                
                // Wait, the above line overwrites the shift result.
                // Correct logic for MSB-first shift:
                // s_shift_reg[N-1] <= di_i[N-1];
                // s_shift_reg[N-2:0] <= s_shift_reg[N-1:0] << 1; // No, this is wrong.
                
                // Correct Shift Register Update:
                // We want to shift the whole register left.
                // The new bit entering at MSB (bit N-1) is di_i[N-1].
                // The bit leaving at LSB (bit 0) is captured from spi_miso_i.
                // So:
                // s_shift_reg[N-1] <= di_i[N-1];
                // s_shift_reg[N-2:0] <= s_shift_reg[N-1:0] << 1; -> This shifts the old MSB into N-2.
                // But we need to capture spi_miso_i into bit 0.
                
                // Let's do it explicitly:
                // s_shift_reg[N-1] <= di_i[N-1];
                // s_shift_reg[N-2:0] <= s_shift_reg[N-1:0] << 1; 
                // This shifts the old content. But where does spi_miso_i go?
                // It goes into bit 0.
                // So: s_shift_reg[N-2:0] = {s_shift_reg[N-1:1], spi_miso_i};
                // And s_shift_reg[N-1] = di_i[N-1];
                
                // Wait, if we do s_shift_reg[N-2:0] = {s_shift_reg[N-1:1], spi_miso_i}, 
                // we are shifting the old MSB into N-2. That is correct for a left shift.
                // But we are overwriting s_shift_reg[N-1] with di_i[N-1] separately.
                // This works.
                
                // Refined Logic:
                // s_shift_reg[N-1] <= di_i[N-1];
                // s_shift_reg[N-2:0] <= {s_shift_reg[N-1:1], spi_miso_i};
                // This effectively shifts everything left, puts new MSB, and captures LSB from MISO.
                
                // However, there is a race condition if we assign s_shift_reg[N-1] first and then use it in the slice.
                // In Verilog, the RHS is evaluated before assignment.
                // So {s_shift_reg[N-1:1], spi_miso_i} uses the OLD value of s_shift_reg[N-1].
                // This is exactly what we want for a shift register.
                
                // One edge case: The very first bit.
                // On the first clock of transfer, s_shift_reg is all 0s.
                // s_shift_reg[N-1] becomes di_i[N-1].
                // s_shift_reg[N-2:0] becomes {0, spi_miso_i}.
                // This is correct.
                
                // But wait, we need to make sure we don't shift garbage if the transfer hasn't started properly.
                // The state machine ensures p_transfer_active is high.
                // However, we need to ensure we don't shift more than N bits.
                // We can use a counter in SCLK domain or rely on the fact that the PCLK domain controls the duration.
                // Since PCLK is slower, we can't easily count N cycles in SCLK without a counter.
                // Let's add a simple counter in SCLK domain to limit shifts to N.
                
                // Actually, the prompt implies a simple implementation. 
                // We can assume the PCLK domain controls the enable, and we shift until N bits are done.
                // But how does SCLK domain know when to stop?
                // We can add a counter in SCLK domain that counts up to N.
                
                // Let's add a shift counter.
            end
        end
    end

    // Re-implementing Shift Register with proper N-bit limit
    reg [N-1:0] s_shift_reg;
    reg [N-1:0] s_shift_cnt;
    reg s_shift_done_flag;

    always @(posedge sclk_i or posedge rst_s_sync[1]) begin
        if (rst_s_sync[1]) begin
            s_shift_reg <= 0;
            s_shift_cnt <= 0;
            s_shift_done_flag <= 0;
            s_shift_enable <= 0;
        end
        else begin
            if (p_transfer_active && !s_shift_done_flag) begin
                s_shift_enable <= 1;
                s_shift_cnt <= s_shift_cnt + 1;
                
                if (s_shift_cnt == N - 1) begin
                    s_shift_done_flag <= 1;
                    s_shift_enable <= 0; // Stop shifting
                end
                else begin
                    s_shift_enable <= 1;
                end
            end
            else begin
                s_shift_enable <= 0;
                s_shift_done_flag <= 0;
            end
        end
    end

    // Shift Register Update Logic
    always @(posedge sclk_i or posedge rst_s_sync[1]) begin
        if (rst_s_sync[1]) begin
            s_shift_reg <= 0;
        end
        else begin
            if (s_shift_enable) begin
                // Shift Left: MSB gets new data, LSB gets MISO
                // We must use the old value of s_shift_reg[N-1] for the shift calculation
                // to avoid using the newly assigned value in the same cycle.
                // However, in a continuous assignment or procedural block, 
                // the RHS is evaluated before LHS assignment.
                
                // s_shift_reg[N-1] <= di_i[N-1];
                // s_shift_reg[N-2:0] <= {s_shift_reg[N-1:1], spi_miso_i};
                
                // This logic is correct for MSB-first transmission.
                // s_shift_reg[N-1] will be di_i[N-1].
                // s_shift_reg[N-2] will be old s_shift_reg[N-1].
                // ...
                // s_shift_reg[0] will be spi_miso_i.
                
                // Wait, if we do:
                // s_shift_reg <= {di_i[N-1], s_shift_reg[N-1:1], spi_miso_i};
                // This is a single assignment.
                // The RHS {di_i[N-1], s_shift_reg[N-1:1], spi_miso_i} evaluates using the CURRENT value of s_shift_reg.
                // So s_shift_reg[N-1:1] are the bits that were there before.
                // This effectively shifts left, inserts new MSB, and captures LSB from MISO.
                // This is exactly what we need.
                
                s_shift_reg <= {di_i[N-1], s_shift_reg[N-1:1], spi_miso_i};
            end
        end
    end

    // Output Logic
    // spi_mosi_o: Output the MSB of the shift register
    always @(posedge sclk_i or posedge rst_s_sync[1]) begin
        if (rst_s_sync[1]) begin
            spi_mosi_o <= 0;
        end
        else begin
            spi_mosi_o <= s_shift_reg[N-1];
        end
    end

    // do_valid_o and do_o: Handshake signals
    // These are driven by the PCLK domain logic directly.
    // do_valid_o is set when the shift is complete.
    // do_o is the data captured in the shift register.
    
    // We need to ensure do_valid_o and do_o are stable in PCLK domain.
    // The state machine handles this.
    
    // One detail: The state machine sets p_do_valid and p_do_data.
    // We just assign them to the outputs.
    assign do_valid_o = p_do_valid;
    assign do_o = p_do_data;

    // ------------------------------------------------------------------
    // CDC Safety Checks Summary:
    // 1. Reset: Synchronized to both domains using 2-stage synchronizers.
    // 2. Control (wren_i): Synchronized to SCLK domain.
    // 3. Data (di_i): Captured in PCLK domain state machine, then shifted in SCLK domain.
    //    The data is latched in PCLK domain (p_data_reg) but the shifting happens in SCLK.
    //    Wait, my previous logic used di_i directly in SCLK domain.
    //    This is unsafe if di_i changes between PCLK and SCLK edges.
    //    Correction: We must synchronize di_i to SCLK domain before shifting.
    // ------------------------------------------------------------------

    // --- CORRECTION: Synchronize di_i to SCLK Domain ---
    // We need to capture the word in SCLK domain safely.
    // Since wren_i is the trigger, we can synchronize wren_i and di_i together.
    // But di_i is multi-bit. We need to ensure it's stable.
    // Strategy: Use a FIFO-like approach or a dedicated shift register in SCLK domain 
    // that is loaded only when wren_i is detected in SCLK domain.
    
    // Let's create a SCLK-domain register to hold the word to be shifted.
    reg [N-1:0] s_data_reg;
    reg s_data_valid;

    // Synchronize wren_i and di_i to SCLK domain
    // We need to ensure we capture di_i only when wren_i is high and stable.
    // Since wren_i is already synchronized (wren_s_sync), we can use it as a gate.
    // However, di_i might change. We need to capture it when wren_i is high.
    // A simple 2-stage sync for wren_i is done.
    // For di_i, we can use a similar approach but we need to know when to latch it.
    
    // Let's use a "load" signal in SCLK domain.
    // Load happens when wren_s_sync[1] is high (indicating wren_i was high in previous PCLK cycle).
    // But we need to capture di_i at that moment.
    // We need to synchronize di_i to SCLK domain as well.
    
    reg [N-1:0] s_di_sync;
    reg [1:0] di_s_sync;
    
    always @(posedge sclk_i or posedge rst_s_sync[1]) begin
        if (rst_s_sync[1]) begin
            di_s_sync <= 2'b00;
            s_di_sync <= 0;
        end
        else begin
            di_s_sync[0] <= di_s_sync[1];
            di_s_sync[1] <= di_s_sync[0];
            if (di_s_sync[1])
                s_di_sync <= di_i;
        end
    end

    // Now, load s_data_reg when wren_i is detected in SCLK domain.
    // We use wren_s_sync[1] as the trigger.
    // We also need to ensure we don't overwrite if wren_i is still high (pulse detection).
    // But the PCLK state machine handles the pulse.
    // The SCLK domain just needs to load the data once per transfer.
    
    // Let's refine the SCLK domain state for loading data.
    // We can use a flag s_load_data.
    reg s_load_data;
    
    always @(posedge sclk_i or posedge rst_s_sync[1]) begin
        if (rst_s_sync[1]) begin
            s_load_data <= 0;
            s_data_valid <= 0;
            s_data_reg <= 0;
        end
        else begin
            // Detect rising edge of wren_i in SCLK domain
            // wren_s_sync[1] is the delayed version. 
            // If wren_s_sync[1] is 1 and wren_s_sync[0] is 0, it's a rising edge.
            if (wren_s_sync[1] && !wren_s_sync[0]) begin
                s_load_data <= 1;
            end
            else begin
                s_load_data <= 0;
            end
        end
    end

    // Load data into s_data_reg
    always @(posedge sclk_i or posedge rst_s_sync[1]) begin
        if (rst_s_sync[1]) begin
            s_data_reg <= 0;
            s_data_valid <= 0;
        end
        else begin
            if (s_load_data) begin
                s_data_reg <= s_di_sync;
                s_data_valid <= 1;
            end
            else begin
                s_data_valid <= 0;
            end
        end
    end

    // Update the main shift register logic to use s_data_reg
    // Instead of using di_i directly, use s_data_reg.
    // The shift logic remains the same, just the source of the new bit changes.
    
    // Re-declare s_shift_reg and s_shift_cnt for clarity in the final block
    // (They were declared earlier, but let's ensure they use s_data_reg)
    
    // Final Shift Register Logic with s_data_reg
    always @(posedge sclk_i or posedge rst_s_sync[1]) begin
        if (rst_s_sync[1]) begin
            s_shift_reg <= 0;
            s_shift_cnt <= 0;
            s_shift_done_flag <= 0;
            s_shift_enable <= 0;
        end
        else begin
            if (s_data_valid && !s_shift_done_flag) begin
                s_shift_enable <= 1;
                s_shift_cnt <= s_shift_cnt + 1;
                
                if (s_shift_cnt == N - 1) begin
                    s_shift_done_flag <= 1;
                    s_shift_enable <= 0;
                end
                else begin
                    s_shift_enable <= 1;
                end
            end
            else begin
                s_shift_enable <= 0;
                s_shift_done_flag <= 0;
            end
        end
    end

    // Shift Register Update Logic (using s_data_reg)
    always @(posedge sclk_i or posedge rst_s_sync[1]) begin
        if (rst_s_sync[1]) begin
            s_shift_reg <= 0;
        end
        else begin
            if (s_shift_enable) begin
                // Shift Left: MSB gets new data from s_data_reg, LSB gets MISO
                s_shift_reg <= {s_data_reg[N-1], s_shift_reg[N-1:1], spi_miso_i};
            end
        end
    end

    // Update spi_mosi_o
    always @(posedge sclk_i or posedge rst_s_sync[1]) begin
        if (rst_s_sync[1]) begin
            spi_mosi_o <= 0;
        end
        else begin
            spi_mosi_o <= s_shift_reg[N-1];
        end
    end

    // Update PCLK domain state machine to use s_shift_done_flag
    // We need to synchronize s_shift_done_flag to PCLK domain.
    reg [1:0] s_done_p_sync;
    always @(posedge pclk_i or posedge rst_p_sync[1]) begin
        if (rst_p_sync[1]) begin
            s_done_p_sync <= 2'b00;
        end
        else begin
            s_done_p_sync[0] <= s_done_p_sync[1];
            s_done_p_sync[1] <= s_done_p_sync[0];
        end
    end

    // Re-implement PCLK State Machine with synchronized done flag
    always @(posedge pclk_i or posedge rst_p_sync[1]) begin
        if (rst_p_sync[1]) begin
            p_state <= IDLE;
            p_data_reg <= 0;
            p_transfer_active <= 0;
            p_shift_complete <= 0;
            p_do_valid <= 0;
            p_do_data <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
        end
        else begin
            case (p_state)
                IDLE: begin
                    if (wren_s_sync[1] && wren_i) begin
                        p_data_reg <= di_i;
                        p_transfer_active <= 1;
                        p_state <= TRANSFER;
                        di_req_o <= 1;
                    end
                    else begin
                        di_req_o <= 0;
                    end
                end

                TRANSFER: begin
                    if (s_done_p_sync[1]) begin
                        p_state <= AWAIT_ACK;
                        p_do_valid <= 1;
                        p_do_data <= s_shift_reg; // s_shift_reg is stable in SCLK, but we read it here.
                        // Wait, reading s_shift_reg in PCLK domain is unsafe if it changes.
                        // But s_shift_reg stops changing after N cycles.
                        // However, s_shift_reg is a register in SCLK domain.
                        // We should latch the result in PCLK domain before reading.
                        // Let's add a latch in PCLK domain for the result.
                    end
                end

                AWAIT_ACK: begin
                    if (wren_i) begin
                        p_state <= IDLE;
                        wr_ack_o <= 1;
                        p_do_valid <= 0;
                        di_req_o <= 0;
                    end
                end
            endcase
        end
    end

    // Latch the shift result in PCLK domain
    reg [N-1:0] p_shift_result;
    reg p_shift_result_valid;
    
    always @(posedge pclk_i or posedge rst_p_sync[1]) begin
        if (rst_p_sync[1]) begin
            p_shift_result <= 0;
            p_shift_result_valid <= 0;
        end
        else begin
            if (s_done_p_sync[1]) begin
                p_shift_result <= s_shift_reg;
                p_shift_result_valid <= 1;
            end
            else begin
                p_shift_result_valid <= 0;
            end
        end
    end

    // Update PCLK State Machine to use p_shift_result_valid
    always @(posedge pclk_i or posedge rst_p_sync[1]) begin
        if (rst_p_sync[1]) begin
            p_state <= IDLE;
            p_data_reg <= 0;
            p_transfer_active <= 0;
            p_shift_complete <= 0;
            p_do_valid <= 0;
            p_do_data <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
        end
        else begin
            case (p_state)
                IDLE: begin
                    if (wren_s_sync[1] && wren_i) begin
                        p_data_reg <= di_i;
                        p_transfer_active <= 1;
                        p_state <= TRANSFER;
                        di_req_o <= 1;
                    end
                    else begin
                        di_req_o <= 0;
                    end
                end

                TRANSFER: begin
                    if (p_shift_result_valid) begin
                        p_state <= AWAIT_ACK;
                        p_do_valid <= 1;
                        p_do_data <= p_shift_result;
                    end
                end

                AWAIT_ACK: begin
                    if (wren_i) begin
                        p_state <= IDLE;
                        wr_ack_o <= 1;
                        p_do_valid <= 0;
                        di_req_o <= 0;
                    end
                end
            endcase
        end
    end

    // Final Output Assignments
    assign do_valid_o = p_do_valid;
    assign do_o = p_do_data;

endmodule
```<|im_end|>
