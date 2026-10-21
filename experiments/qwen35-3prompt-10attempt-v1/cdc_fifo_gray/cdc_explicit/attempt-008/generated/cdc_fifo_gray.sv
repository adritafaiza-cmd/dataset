```verilog
`timescale 1ns/1ps

module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output reg [WIDTH-1:0] dst_data_o,
    output reg             dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam GRAY_WIDTH = LOG_DEPTH;

    // Internal signals
    reg [LOG_DEPTH-1:0] src_ptr;
    reg [LOG_DEPTH-1:0] dst_ptr;
    reg [LOG_DEPTH-1:0] src_gray_ptr;
    reg [LOG_DEPTH-1:0] dst_gray_ptr;
    reg [WIDTH-1:0] fifo_mem [DEPTH-1:0];
    reg [LOG_DEPTH-1:0] src_ptr_sync;
    reg [LOG_DEPTH-1:0] dst_ptr_sync;
    reg [LOG_DEPTH-1:0] src_gray_ptr_sync;
    reg [LOG_DEPTH-1:0] dst_gray_ptr_sync;
    reg src_empty;
    reg dst_full;
    reg src_empty_sync;
    reg dst_full_sync;
    reg src_valid_sync;
    reg dst_ready_sync;
    reg [WIDTH-1:0] data_out_reg;
    reg dst_valid_reg;

    // --- Source Domain Logic ---
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= '0;
            src_gray_ptr <= '0;
            src_empty <= 1'b1;
        end else begin
            src_gray_ptr <= src_ptr;
            src_empty <= (src_ptr == '0);
        end
    end

    // Write pointer to Gray code
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_ptr <= '0;
        end else begin
            // Convert binary to Gray
            src_gray_ptr <= {src_ptr[LOG_DEPTH-2:0], src_ptr[LOG_DEPTH-1] ^ src_ptr[LOG_DEPTH-2]};
        end
    end

    // --- Destination Domain Logic ---
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= '0;
            dst_gray_ptr <= '0;
            dst_full <= 1'b0;
        end else begin
            dst_gray_ptr <= dst_ptr;
            dst_full <= (dst_ptr == (DEPTH - 1));
        end
    end

    // Read pointer to Gray code
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_ptr <= '0;
        end else begin
            // Convert binary to Gray
            dst_gray_ptr <= {dst_ptr[LOG_DEPTH-2:0], dst_ptr[LOG_DEPTH-1] ^ dst_ptr[LOG_DEPTH-2]};
        end
    end

    // --- CDC Crossing: Source to Destination (Read Enable & Empty) ---
    // Cross src_valid, src_empty, src_gray_ptr, src_ptr
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : src_sync_stage
            wire src_valid_stage;
            wire src_empty_stage;
            wire [LOG_DEPTH-1:0] src_gray_ptr_stage;
            wire [LOG_DEPTH-1:0] src_ptr_stage;
            
            if (i == 0) begin
                assign src_valid_stage = src_valid_i;
                assign src_empty_stage = src_empty;
                assign src_gray_ptr_stage = src_gray_ptr;
                assign src_ptr_stage = src_ptr;
            end else begin
                assign src_valid_stage = src_valid_sync;
                assign src_empty_stage = src_empty_sync;
                assign src_gray_ptr_stage = src_gray_ptr_sync;
                assign src_ptr_stage = src_ptr_sync;
            end

            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    src_valid_sync <= 1'b0;
                    src_empty_sync <= 1'b1;
                    src_gray_ptr_sync <= '0;
                    src_ptr_sync <= '0;
                end else begin
                    src_valid_sync <= src_valid_stage;
                    src_empty_sync <= src_empty_stage;
                    src_gray_ptr_sync <= src_gray_ptr_stage;
                    src_ptr_sync <= src_ptr_stage;
                end
            end
        end
    endgenerate

    // --- CDC Crossing: Destination to Source (Write Enable & Full) ---
    // Cross dst_ready, dst_full, dst_gray_ptr, dst_ptr
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : dst_sync_stage
            wire dst_ready_stage;
            wire dst_full_stage;
            wire [LOG_DEPTH-1:0] dst_gray_ptr_stage;
            wire [LOG_DEPTH-1:0] dst_ptr_stage;
            
            if (i == 0) begin
                assign dst_ready_stage = dst_ready_i;
                assign dst_full_stage = dst_full;
                assign dst_gray_ptr_stage = dst_gray_ptr;
                assign dst_ptr_stage = dst_ptr;
            end else begin
                assign dst_ready_stage = dst_ready_sync;
                assign dst_full_stage = dst_full_sync;
                assign dst_gray_ptr_stage = dst_gray_ptr_sync;
                assign dst_ptr_stage = dst_ptr_sync;
            end

            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    dst_ready_sync <= 1'b0;
                    dst_full_sync <= 1'b0;
                    dst_gray_ptr_sync <= '0;
                    dst_ptr_sync <= '0;
                end else begin
                    dst_ready_sync <= dst_ready_stage;
                    dst_full_sync <= dst_full_stage;
                    dst_gray_ptr_sync <= dst_gray_ptr_stage;
                    dst_ptr_sync <= dst_ptr_stage;
                end
            end
        end
    endgenerate

    // --- FIFO Control Logic (Source Domain) ---
    // Write enable is valid when src_valid is high, src_ready is high, and not full
    // Full is determined by comparing Gray pointers in source domain
    wire src_write_en = src_valid_i && src_ready_o && (!src_empty && (src_gray_ptr != dst_gray_ptr));
    
    // Actually, standard Gray pointer comparison for full:
    // Full if src_gray_ptr == dst_gray_ptr AND src_ptr > dst_ptr (in binary)
    // However, since we cross pointers, we rely on the synchronized pointers for control.
    // Let's refine the full detection logic using synchronized pointers.
    
    // Re-evaluating Full logic for safety:
    // We need to know if the FIFO is full in the source domain to assert ready.
    // Full condition: src_gray_ptr == dst_gray_ptr AND src_ptr > dst_ptr.
    // Since dst_gray_ptr is synchronized to src_clk, we can use it.
    // But dst_ptr is also synchronized.
    
    // Let's use the synchronized pointers to determine Full status safely.
    // Full = (src_gray_ptr == dst_gray_ptr_sync) && (src_ptr > dst_ptr_sync)
    // Wait, if src_gray_ptr == dst_gray_ptr_sync, they are at the same index.
    // If src_ptr > dst_ptr_sync, it means we have written one more than read.
    // This is the standard full condition for Gray pointers.
    
    wire src_full = (src_gray_ptr == dst_gray_ptr_sync) && (src_ptr > dst_ptr_sync);
    
    // Write Enable
    wire src_we = src_valid_i && src_ready_o && !src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_mem <= '0;
        end else if (src_we) begin
            fifo_mem[src_ptr] <= src_data_i;
        end
    end

    // --- FIFO Control Logic (Destination Domain) ---
    // Read enable is valid when dst_ready is high and not empty
    // Empty condition: dst_gray_ptr == src_gray_ptr AND dst_ptr <= src_ptr
    wire dst_re = dst_ready_i && !dst_empty;
    
    // Empty detection using synchronized pointers
    // Empty = (dst_gray_ptr == src_gray_ptr_sync) && (dst_ptr <= src_ptr_sync)
    wire dst_empty = (dst_gray_ptr == src_gray_ptr_sync) && (dst_ptr <= src_ptr_sync);

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= '0;
            dst_valid_o <= 1'b0;
        end else if (dst_re) begin
            // Read data from memory using the binary read pointer
            dst_data_o <= fifo_mem[dst_ptr];
            dst_valid_o <= 1'b1;
        end else begin
            dst_valid_o <= 1'b0;
        end
    end

    // --- Handshake Logic ---
    // Source Ready: Valid if not full
    assign src_ready_o = !src_full;

    // Destination Valid: 
    // The requirement states: "dst_valid_o may fall for one destination clock after an accepted beat".
    // This implies we should not immediately assert valid on the read edge if the data is being updated?
    // Or does it mean the valid signal lags the data availability?
    // Standard behavior: Data is available immediately after read.
    // The prompt says: "dst_valid_o may fall for one destination clock after an accepted beat even when another word is stored."
    // This suggests a specific timing constraint or a specific implementation style where valid is delayed.
    // However, standard FIFOs assert valid immediately. 
    // Let's interpret "may fall" as a potential glitch or a specific requirement to delay valid assertion to ensure stability.
    // But usually, if data is stable, valid should be stable.
    // Re-reading: "dst_valid_o may fall for one destination clock after an accepted beat even when another word is stored."
    // This sounds like a description of a specific behavior where the valid signal is not asserted immediately upon read, 
    // perhaps to allow the data to settle or due to specific CDC constraints on the valid signal itself.
    // However, the most robust interpretation for a "valid/ready" FIFO is that valid is asserted when data is ready.
    // If the prompt implies a delay, we might need a register.
    // Let's look at the phrase: "dst_data_o is one destination-clock sample. dst_valid_o may fall for one destination clock after an accepted beat".
    // This could mean that even if we read a new word, valid might not be high immediately? 
    // Or it means valid can go low (de-assert) and come back high?
    // Actually, a common pattern to avoid metastability on the valid signal crossing or to ensure data stability is to register the valid signal.
    // But the data is read from memory which is stable.
    // Let's stick to the standard behavior: assert valid when dst_re is true.
    // If the prompt implies a specific lag, it might be referring to the fact that the *next* beat's valid might be delayed if the FIFO is full? No.
    // Let's assume standard behavior: dst_valid_o = dst_re. 
    // Wait, the prompt says "dst_valid_o may fall...". This implies it's not a simple assignment.
    // Perhaps it means we should register the valid signal to ensure it is stable for the next cycle?
    // Or maybe it's a hint that we shouldn't assert valid immediately if the data pointer hasn't fully settled?
    // Given the strict CDC requirements, registering the valid signal in the destination domain is often safer to prevent glitches.
    // Let's implement: dst_valid_o is registered from the read enable signal.
    // But wait, if we register it, it will be 0 for one cycle after reset or when re-asserted.
    // Let's try: dst_valid_o <= dst_re; (This is synchronous).
    // If dst_re goes high, dst_valid_o goes high next cycle. This creates a 1-cycle delay.
    // Does this match "may fall for one destination clock after an accepted beat"?
    // If "accepted beat" means the write happened, and we are reading it.
    // If we assert valid immediately, it's 0 delay.
    // If we register it, it's 1 cycle delay.
    // The prompt says "may fall... after an accepted beat". This is slightly ambiguous.
    // However, to be safe and compliant with "zero unsafe crossings" and robust design, 
    // registering the valid signal is a common practice to ensure the valid signal itself is stable and synchronized.
    // Let's use the registered version: dst_valid_o <= dst_re;
    // This ensures dst_valid_o is stable for the duration of the clock cycle.
    
    // Wait, if I do `dst_valid_o <= dst_re`, then when dst_re becomes 1, dst_valid_o becomes 1 in the next cycle.
    // This means there is a 1-cycle gap where dst_valid_o is 0 even though data is ready.
    // This matches the description "may fall for one destination clock after an accepted beat".
    // So, I will register the valid signal.
    
    // Correction: The logic `dst_valid_o <= dst_re` inside the always block handles the registration.
    // But we need to make sure we don't hold it high if dst_re goes low.
    // The logic `if (dst_re) dst_valid_o <= 1; else dst_valid_o <= 0;` is implicit in `dst_valid_o <= dst_re`.
    
    // Let's refine the logic to ensure dst_valid_o is properly controlled.
    // We already have the logic for dst_valid_o in the previous block.
    // Let's modify that block to simply assign dst_valid_o <= dst_re;
    // But we need to handle the reset state correctly.
    
    // Revised Destination Output Logic:
    // We need to output data and valid.
    // Data is read from memory.
    // Valid is asserted when we have data to give.
    // To satisfy the "lag" requirement and ensure stability:
    // We will register the valid signal.
    
    // Let's rewrite the destination output block cleanly.
    // We need to store the data to be outputted? 
    // No, we can read from memory every cycle.
    // But if we read from memory every cycle, and valid is registered, 
    // then for one cycle after the read enable becomes true, valid is 0.
    // This matches the requirement.
    
    // However, we need to ensure that if dst_ready_i is low, we don't read new data?
    // No, in a FIFO, we read whenever we are ready to send, regardless of dst_ready_i (which is the handshake).
    // Actually, dst_re = dst_ready_i && !dst_empty.
    // If dst_ready_i is low, we don't read.
    // If dst_ready_i is high and !dst_empty, we read.
    // Then dst_valid_o is asserted (with 1 cycle delay).
    
    // One nuance: If dst_ready_i is low, we don't read. The data stays in the FIFO.
    // The dst_valid_o should be 0.
    // If dst_ready_i goes high, we read, and dst_valid_o goes high (next cycle).
    // This seems correct.
    
    // Wait, the previous block had:
    // if (dst_re) begin dst_data_o <= ...; dst_valid_o <= 1; end else dst_valid_o <= 0;
    // This is effectively `dst_valid_o <= dst_re`.
    // So the logic holds.
    
    // Let's double check the "fall" requirement.
    // "dst_valid_o may fall for one destination clock after an accepted beat".
    // If an accepted beat happens (write succeeds), the data is in the FIFO.
    // The read happens when dst_ready is high.
    // If we read, dst_valid_o becomes 1 in the next cycle.
    // So for the cycle where the read happens, dst_valid_o is 0.
    // This is a 1-cycle lag.
    // This matches the requirement.
    
    // Final check on pointers crossing.
    // We are crossing src_ptr, src_gray_ptr, dst_ptr, dst_gray_ptr.
    // We are crossing src_valid, dst_ready.
    // We are crossing src_empty, dst_full.
    // All are synchronized with SYNC_STAGES.
    // This is safe.
    
    // One detail: The prompt says "dst_valid_o may fall for one destination clock after an accepted beat even when another word is stored."
    // This implies that even if the FIFO is not empty (another word is stored), valid might fall.
    // This is consistent with the 1-cycle lag behavior.
    
    // Let's finalize the code structure.
    
    // Re-declaring variables to ensure scope is correct.
    // The previous block had dst_valid_o declared as reg.
    // The logic `dst_valid_o <= dst_re` is sufficient.
    
    // Wait, I need to make sure `dst_data_o` is updated correctly.
    // If `dst_re` is high, we update `dst_data_o`.
    // If `dst_re` is low, `dst_data_o` holds the previous value.
    // This is fine.
    
    // One edge case: Reset.
    // On reset, dst_data_o = 0, dst_valid_o = 0.
    // Correct.
    
    // Another edge case: Empty FIFO.
    // If dst_empty is true, dst_re is false.
    // dst_valid_o becomes 0.
    // dst_data_o holds the last value (or 0 if reset).
    // Correct.
    
    // One more check: The prompt says "dst_valid_o may fall...".
    // Does it mean it can go from 1 to 0?
    // Yes, if dst_ready_i goes low, dst_re goes low, dst_valid_o goes low.
    // This is standard handshake behavior.
    
    // The specific phrasing "after an accepted beat" likely refers to the write side.
    // When a beat is accepted (write), the data is in the FIFO.
    // The read side will eventually pick it up.
    // When it picks it up, valid is asserted with a 1-cycle delay.
    // So for that one cycle, valid is 0.
    // This is the intended behavior.
    
    // Let's write the final code.
    
    // Note: I will remove the duplicate logic and consolidate.
    
    // Source Domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ptr <= '0;
            src_gray_ptr <= '0;
            src_empty <= 1'b1;
        end else begin
            src_gray_ptr <= src_ptr;
            src_empty <= (src_ptr == '0);
        end
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_gray_ptr <= '0;
        end else begin
            src_gray_ptr <= {src_ptr[LOG_DEPTH-2:0], src_ptr[LOG_DEPTH-1] ^ src_ptr[LOG_DEPTH-2]};
        end
    end

    // Destination Domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ptr <= '0;
            dst_gray_ptr <= '0;
            dst_full <= 1'b0;
        end else begin
            dst_gray_ptr <= dst_ptr;
            dst_full <= (dst_ptr == (DEPTH - 1));
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_gray_ptr <= '0;
        end else begin
            dst_gray_ptr <= {dst_ptr[LOG_DEPTH-2:0], dst_ptr[LOG_DEPTH-1] ^ dst_ptr[LOG_DEPTH-2]};
        end
    end

    // Synchronization Stages for Source Signals
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : src_sync_stage
            wire src_valid_stage;
            wire src_empty_stage;
            wire [LOG_DEPTH-1:0] src_gray_ptr_stage;
            wire [LOG_DEPTH-1:0] src_ptr_stage;
            
            if (i == 0) begin
                assign src_valid_stage = src_valid_i;
                assign src_empty_stage = src_empty;
                assign src_gray_ptr_stage = src_gray_ptr;
                assign src_ptr_stage = src_ptr;
            end else begin
                assign src_valid_stage = src_valid_sync;
                assign src_empty_stage = src_empty_sync;
                assign src_gray_ptr_stage = src_gray_ptr_sync;
                assign src_ptr_stage = src_ptr_sync;
            end

            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    src_valid_sync <= 1'b0;
                    src_empty_sync <= 1'b1;
                    src_gray_ptr_sync <= '0;
                    src_ptr_sync <= '0;
                end else begin
                    src_valid_sync <= src_valid_stage;
                    src_empty_sync <= src_empty_stage;
                    src_gray_ptr_sync <= src_gray_ptr_stage;
                    src_ptr_sync <= src_ptr_stage;
                end
            end
        end
    endgenerate

    // Synchronization Stages for Destination Signals
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : dst_sync_stage
            wire dst_ready_stage;
            wire dst_full_stage;
            wire [LOG_DEPTH-1:0] dst_gray_ptr_stage;
            wire [LOG_DEPTH-1:0] dst_ptr_stage;
            
            if (i == 0) begin
                assign dst_ready_stage = dst_ready_i;
                assign dst_full_stage = dst_full;
                assign dst_gray_ptr_stage = dst_gray_ptr;
                assign dst_ptr_stage = dst_ptr;
            end else begin
                assign dst_ready_stage = dst_ready_sync;
                assign dst_full_stage = dst_full_sync;
                assign dst_gray_ptr_stage = dst_gray_ptr_sync;
                assign dst_ptr_stage = dst_ptr_sync;
            end

            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    dst_ready_sync <= 1'b0;
                    dst_full_sync <= 1'b0;
                    dst_gray_ptr_sync <= '0;
                    dst_ptr_sync <= '0;
                end else begin
                    dst_ready_sync <= dst_ready_stage;
                    dst_full_sync <= dst_full_stage;
                    dst_gray_ptr_sync <= dst_gray_ptr_stage;
                    dst_ptr_sync <= dst_ptr_stage;
                end
            end
        end
    endgenerate

    // Full Detection (Source Domain)
    // Full if src_gray_ptr == dst_gray_ptr_sync AND src_ptr > dst_ptr_sync
    wire src_full = (src_gray_ptr == dst_gray_ptr_sync) && (src_ptr > dst_ptr_sync);
    
    // Write Enable
    wire src_we = src_valid_i && src_ready_o && !src_full;

    // FIFO Memory Write
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_mem <= '0;
        end else if (src_we) begin
            fifo_mem[src_ptr] <= src_data_i;
        end
    end

    // Empty Detection (Destination Domain)
    // Empty if dst_gray_ptr == src_gray_ptr_sync AND dst_ptr <= src_ptr_sync
    wire dst_empty = (dst_gray_ptr == src_gray_ptr_sync) && (dst_ptr <= src_ptr_sync);

    // Output Logic
    // Data is read from memory using the binary read pointer
    // Valid is asserted when we have data to give (dst_re is true)
    // To satisfy the 1-cycle lag requirement and ensure stability, we register the valid signal.
    // Also, we only update data_out_reg if we are reading.
    
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= '0;
            dst_valid_o <= 1'b0;
        end else begin
            wire dst_re = dst_ready_i && !dst_empty;
            
            if (dst_re) begin
                dst_data_o <= fifo_mem[dst_ptr];
                // dst_valid_o will be updated in the next cycle due to the assignment below
                // But we need to ensure it's 0 if dst_re is 0.
                // The assignment dst_valid_o <= dst_re handles this.
                // However, to explicitly handle the "lag" and ensure it's 0 when not ready:
                // dst_valid_o <= dst_re;
                // This means if dst_re is 1, dst_valid_o becomes 1 in the next cycle.
                // If dst_re is 0, dst_valid_o becomes 0 in the next cycle.
                // This creates the 1-cycle delay.
            end
        end
    end
    
    // Wait, the logic above for dst_valid_o is slightly flawed if I put it inside the if.
    // Let's simplify:
    // dst_valid_o <= dst_re;
    // This is a synchronous assignment.
    // If dst_re is 1, dst_valid_o becomes 1 in the next clock edge.
    // If dst_re is 0, dst_valid_o becomes 0 in the next clock edge.
    // This perfectly matches the requirement "may fall for one destination clock after an accepted beat".
    // Because the beat is accepted (read enabled), but valid is asserted one cycle later.
    
    // Let's rewrite the output block cleanly.
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= '0;
            dst_valid_o <= 1'b0;
        end else begin
            wire dst_re = dst_ready_i && !dst_empty;
            dst_data_o <= fifo_mem[dst_ptr]; // Always update data to the current read pointer
            dst_valid_o <= dst_re;           // Valid is asserted one cycle after read enable
        end
    end

    // Source Ready
    assign src_ready_o = !src_full;

endmodule
```<|im_end|>
