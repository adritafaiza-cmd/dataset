```verilog
`timescale 1ns/1ps

module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam GRAY_WIDTH = LOG_DEPTH;

    // --- Source Side (Write) ---
    // Write Pointer (Gray encoded)
    reg [GRAY_WIDTH-1:0] src_gray_ptr;
    reg [GRAY_WIDTH-1:0] src_gray_ptr_next;
    reg src_write_en;
    reg src_clear_active;
    
    // Read Pointer (Gray encoded)
    reg [GRAY_WIDTH-1:0] dst_gray_ptr;
    reg [GRAY_WIDTH-1:0] dst_gray_ptr_next;
    reg dst_read_en;
    reg dst_clear_active;

    // Status
    reg [LOG_DEPTH-1:0] full_cnt;
    reg [LOG_DEPTH-1:0] empty_cnt;
    reg [LOG_DEPTH-1:0] full_cnt_next;
    reg [LOG_DEPTH-1:0] empty_cnt_next;
    reg clear_pending;
    reg clear_pending_next;

    // Data Storage
    reg [WIDTH-1:0] mem [DEPTH-1:0];
    reg [WIDTH-1:0] dst_data_reg; // Single register for output data

    // --- Synchronizers for Clear Signals ---
    // We need to synchronize clear signals across domains to ensure atomicity
    // and prevent metastability on the pointers.
    
    // Source Clear Sync
    reg src_clear_sync1, src_clear_sync2;
    always @(posedge src_clk_i or posedge src_rst_ni) begin
        if (src_rst_ni) begin
            src_clear_sync1 <= 1'b0;
            src_clear_sync2 <= 1'b0;
        end else begin
            src_clear_sync1 <= src_clear_i;
            src_clear_sync2 <= src_clear_sync1;
        end
    end

    // Destination Clear Sync
    reg dst_clear_sync1, dst_clear_sync2;
    always @(posedge dst_clk_i or posedge dst_rst_ni) begin
        if (dst_rst_ni) begin
            dst_clear_sync1 <= 1'b0;
            dst_clear_sync2 <= 1'b0;
        end else begin
            dst_clear_sync1 <= dst_clear_i;
            dst_clear_sync2 <= dst_clear_sync1;
        end
    end

    // --- Pointer Logic (Gray Encoding) ---
    // Helper function to generate next Gray code
    // Gray(n) = n ^ (n >> 1)
    // Next Gray: We can compute next binary, then convert to Gray, 
    // or use the property that only one bit changes.
    // Simpler approach: Compute next binary pointer, then convert to Gray.
    
    assign src_gray_ptr_next = src_gray_ptr + (src_write_en ? 1 : 0);
    assign dst_gray_ptr_next = dst_gray_ptr + (dst_read_en ? 1 : 0);

    // Convert Binary to Gray
    assign src_gray_ptr = src_gray_ptr_next ^ (src_gray_ptr_next >> 1);
    assign dst_gray_ptr = dst_gray_ptr_next ^ (dst_gray_ptr_next >> 1);

    // --- Full/Empty Counters ---
    // Counters are in binary. They are updated based on write/read enable.
    // Clear resets them to 0.
    
    always @(posedge src_clk_i or posedge src_rst_ni) begin
        if (src_rst_ni) begin
            full_cnt <= {LOG_DEPTH{1'b0}};
            empty_cnt <= {LOG_DEPTH{1'b0}};
            clear_pending <= 1'b0;
        end else begin
            // Clear logic: If clear is active, force counters to 0 and set pending flag
            if (src_clear_sync2) begin
                full_cnt <= {LOG_DEPTH{1'b0}};
                empty_cnt <= {LOG_DEPTH{1'b0}};
                clear_pending <= 1'b1;
            end else begin
                // Normal operation
                if (src_write_en) begin
                    if (full_cnt == (DEPTH - 1)) begin
                        full_cnt_next = full_cnt;
                    end else begin
                        full_cnt_next = full_cnt + 1;
                    end
                end else begin
                    full_cnt_next = full_cnt;
                end

                if (dst_read_en) begin
                    if (empty_cnt == 0) begin
                        empty_cnt_next = empty_cnt;
                    end else begin
                        empty_cnt_next = empty_cnt - 1;
                    end
                end else begin
                    empty_cnt_next = empty_cnt;
                end
            end
        end
    end

    // --- Clear Pending Output Logic ---
    // The clear is considered "pending" until both sides have processed the reset state.
    // We use a handshake-like mechanism or simply wait for the clear pulse to be acknowledged.
    // However, the requirement says "A clear request should flush pending data together".
    // We will assert clear_pending_o when the clear signal is active on the source side 
    // and has been synchronized, until the destination side also acknowledges the clear 
    // (or until the FIFO is empty and pointers are reset).
    
    // To ensure "nothing stale appears afterward", we must ensure that once clear is asserted,
    // no new data is written, and no old data is read until the pointers are reset.
    // The pointers are reset on the same edge as the clear.
    
    // Let's define clear_pending_o as high when the clear operation is in progress 
    // (i.e., clear signal is active on source, and we haven't confirmed the destination 
    // has caught up or the system is stable).
    // A simple interpretation: Assert when src_clear is active. De-assert when the 
    // destination side also sees the clear and the pointers are reset.
    
    // Actually, a robust way for "flush together":
    // 1. Source sees clear -> stops writing, resets write ptr.
    // 2. Destination sees clear -> stops reading, resets read ptr.
    // 3. Output clear_pending_o until both sides have reset their pointers.
    
    // We can track if the destination has seen the clear and reset its pointer.
    reg dst_clear_seen;
    reg dst_ptr_reset;
    
    always @(posedge dst_clk_i or posedge dst_rst_ni) begin
        if (dst_rst_ni) begin
            dst_clear_seen <= 1'b0;
            dst_ptr_reset <= 1'b0;
        end else begin
            if (dst_clear_sync2) begin
                dst_clear_seen <= 1'b1;
                // Check if pointer is effectively reset (all zeros)
                // Since we reset on the same edge, we can check the next cycle or use a flag.
                // Let's assume the pointer logic above handles the reset.
                // We need to know if the pointer is currently 0.
                if (dst_gray_ptr == 0) begin
                    dst_ptr_reset <= 1'b1;
                end
            end else begin
                dst_clear_seen <= 1'b0;
                dst_ptr_reset <= 1'b0;
            end
        end
    end

    // Assign clear_pending_o
    // It is high if source clear is active OR if destination has seen clear but hasn't fully reset yet.
    // Actually, the spec says "A clear resets each binary pointer and the Gray register... on the same edge".
    // So the reset happens immediately. The "pending" state is the time between the request 
    // and the completion of the flush.
    // Let's define: clear_pending_o = src_clear_sync2 && (dst_clear_seen || dst_gray_ptr != 0);
    // But since dst_gray_ptr resets to 0 on the same edge, dst_gray_ptr != 0 implies not fully reset.
    // Simpler: clear_pending_o is high while the clear signal is active on either side 
    // until both pointers are zero.
    
    assign src_clear_pending_o = src_clear_sync2;
    assign dst_clear_pending_o = (dst_clear_sync2) | (dst_gray_ptr != 0);

    // --- Handshake Logic ---
    
    // Source Side
    // src_ready_o is high when FIFO is not full.
    // During clear, we must force ready low to stop writing.
    assign src_ready_o = (!src_clear_sync2) && (full_cnt != (DEPTH - 1));

    // Destination Side
    // dst_valid_o is high when FIFO is not empty.
    // During clear, we must force valid low to stop reading.
    // Also, we need to handle the "one registered sample" requirement.
    // The data is stored in `dst_data_reg`.
    
    // Read Enable Logic
    // We read if: Not cleared, Not empty, and Destination is ready.
    // Note: The problem states "dst_valid_o may fall for one destination clock after an accepted beat".
    // This implies we might have a case where we read, but the next cycle we don't output valid 
    // even if data is there? No, usually it means the handshake might stall one cycle.
    // Standard FIFO behavior: valid is asserted when data is ready.
    // The note "may fall for one destination clock after an accepted beat" suggests that 
    // if dst_ready_i goes low immediately after accepting a beat, valid might de-assert 
    // before the next data is available, or it's just describing the latency.
    // We will implement standard FIFO: valid is asserted when !empty and !clear.
    
    // However, to strictly follow "dst_valid_o may fall for one destination clock after an accepted beat",
    // we might need to consider that the read enable is granted, but the output valid 
    // is delayed or the handshake allows a gap.
    // Let's stick to standard FIFO logic which naturally handles this:
    // If dst_ready_i is low, we don't read. If dst_ready_i is high, we read and assert valid.
    // The "fall for one clock" is a natural consequence if the consumer takes a cycle to process.
    
    // Wait, re-reading: "dst_valid_o may fall for one destination clock after an accepted beat even when another word is stored."
    // This sounds like a specific constraint where valid is not continuously asserted.
    // Perhaps it means: We accept a beat (dst_ready_i=1, dst_valid_o=1). In the next cycle, 
    // even if data is available, valid might be 0?
    // This is unusual for a standard FIFO. It might imply a specific protocol.
    // However, without a specific protocol definition (like "valid is only asserted on rising edge of ready"),
    // standard behavior is: valid = !empty && !clear.
    // If the consumer says "I'm not ready" (ready=0), we hold valid=1 (or de-assert depending on protocol).
    // Usually: valid=1, ready=0 -> hold valid=1.
    // If the requirement implies valid can drop even if data is there, it might be to prevent double buffering issues 
    // or specific timing.
    // Given the ambiguity, I will implement the standard robust FIFO where valid is asserted 
    // whenever data is available and not cleared. The "fall for one clock" is likely a description 
    // of the latency in a specific usage scenario (e.g., if ready goes low, valid stays high, 
    // but if ready goes high then low, valid might drop).
    // Actually, let's interpret it as: The output valid is registered. If the consumer accepts 
    // a beat, the next cycle valid might be 0 if the consumer didn't assert ready again? 
    // No, that's just standard handshake.
    // Let's assume standard FIFO logic: valid = (!empty && !clear).
    
    // One nuance: "The destination word is one registered sample."
    // This means dst_data_o comes from a register.
    
    // Logic for dst_read_en:
    // We enable read if: !dst_clear_sync2 && !empty_cnt && dst_ready_i
    // But we must ensure we don't read during clear.
    
    // Let's refine the clear logic for pointers.
    // The problem says: "A clear resets each binary pointer and the Gray register that feeds its synchronizer on the same edge."
    // My current pointer logic:
    // src_gray_ptr_next = src_gray_ptr + (src_write_en ? 1 : 0);
    // If src_write_en is 0 (due to clear), the pointer doesn't increment.
    // But we need to RESET it to 0.
    // So, if src_clear_sync2 is active, src_gray_ptr_next = 0.
    // Same for dst.
    
    // Revised Pointer Logic with Reset:
    // We need to calculate the next pointer value.
    // If clear is active, next = 0.
    // Else if write/read enabled, next = current + 1.
    // Else next = current.
    
    // Let's restructure the pointer assignment to be combinational for the next state, 
    // then assign the register.
    
    reg [GRAY_WIDTH-1:0] src_gray_ptr_calc;
    reg [GRAY_WIDTH-1:0] dst_gray_ptr_calc;
    
    always @(*) begin
        src_gray_ptr_calc = src_gray_ptr;
        if (src_clear_sync2) begin
            src_gray_ptr_calc = 0;
        end else if (src_write_en) begin
            src_gray_ptr_calc = src_gray_ptr + 1;
        end
        
        dst_gray_ptr_calc = dst_gray_ptr;
        if (dst_clear_sync2) begin
            dst_gray_ptr_calc = 0;
        end else if (dst_read_en) begin
            dst_gray_ptr_calc = dst_gray_ptr + 1;
        end
    end

    // Update registers on clock edge
    always @(posedge src_clk_i or posedge src_rst_ni) begin
        if (src_rst_ni) begin
            src_gray_ptr <= 0;
        end else begin
            src_gray_ptr <= src_gray_ptr_calc;
        end
    end

    always @(posedge dst_clk_i or posedge dst_rst_ni) begin
        if (dst_rst_ni) begin
            dst_gray_ptr <= 0;
        end else begin
            dst_gray_ptr <= dst_gray_ptr_calc;
        end
    end

    // Re-calculate Full/Empty based on the NEW pointers (after reset logic)
    // Full = (src_ptr - dst_ptr) == DEPTH - 1
    // Empty = (src_ptr - dst_ptr) == 0
    // Since we are using Gray codes, we can't subtract directly.
    // We must use the counters (full_cnt, empty_cnt) which we already updated.
    // The counters were updated based on the OLD pointers' enable signals.
    // We need to ensure the counters are updated AFTER the pointer reset decision?
    // No, the counters track the difference.
    // If clear happens, we force counters to 0.
    // The logic for full_cnt_next and empty_cnt_next needs to be careful.
    // If clear is active, counters go to 0.
    // If not clear:
    //   If write_en: full_cnt increments (unless full)
    //   If read_en: empty_cnt decrements (unless empty)
    
    // This logic was already implemented in the `always` block for full_cnt/empty_cnt.
    // It used `src_write_en` and `dst_read_en`.
    // We need to define `src_write_en` and `dst_read_en` correctly.
    
    // src_write_en: Valid if src_valid_i, src_ready_o, and not clearing.
    // But src_ready_o depends on full_cnt.
    // This is a combinational loop if not careful.
    // Standard solution: Use a flag for "clearing" to break the loop.
    
    reg src_write_req;
    reg dst_read_req;
    
    assign src_write_req = src_valid_i && !src_clear_sync2;
    assign dst_read_req = dst_ready_i && !dst_clear_sync2;

    // Now define src_ready_o and dst_valid_o
    // src_ready_o: High if not full and not clearing.
    // But we need to handle the case where we are clearing.
    // If clearing, src_ready_o must be 0 to stop writes.
    assign src_ready_o = (!src_clear_sync2) && (full_cnt != (DEPTH - 1));

    // dst_valid_o: High if not empty and not clearing.
    // Also, the problem says "dst_valid_o may fall for one destination clock after an accepted beat".
    // This might imply that if dst_ready_i was 1 in the previous cycle, we might not assert valid 
    // if the consumer didn't pull it down? No, that's not standard.
    // Let's assume standard: valid = !empty && !clear.
    // However, to be safe about the "fall" comment, we can add a small delay or check 
    // if the consumer is ready. But standard FIFO is: valid is asserted, consumer asserts ready, 
    // then valid is de-asserted.
    // If the consumer asserts ready, then de-asserts ready in the same cycle (glitch?), 
    // valid might stay high.
    // Let's stick to: dst_valid_o = (!dst_clear_sync2) && (empty_cnt != 0);
    
    assign dst_valid_o = (!dst_clear_sync2) && (empty_cnt != 0);

    // --- Data Write Logic ---
    // Write data to memory when src_write_en is high.
    // src_write_en = src_write_req && src_ready_o;
    // But src_ready_o depends on full_cnt.
    // If full, src_ready_o is 0, so no write.
    // If not full, src_ready_o is 1, so write.
    
    reg [WIDTH-1:0] src_data_reg;
    reg src_write_pulse;
    
    // We need to detect the edge of write enable to write data once.
    // Or simply write on every cycle where write_en is high.
    // Since it's a FIFO, we write on every cycle we have data and space.
    
    always @(posedge src_clk_i or posedge src_rst_ni) begin
        if (src_rst_ni) begin
            src_data_reg <= 0;
        end else begin
            if (src_write_en) begin
                src_data_reg <= src_data_i;
            end
        end
    end

    // Memory Write
    always @(posedge src_clk_i or posedge src_rst_ni) begin
        if (src_rst_ni) begin
            // Clear memory on reset
            for (integer i = 0; i < DEPTH; i = i + 1)
                mem[i] <= 0;
        end else begin
            if (src_write_en) begin
                // Calculate address from Gray pointer
                // We need a function to convert Gray to Binary for addressing
                // Or we can maintain a binary pointer internally for addressing.
                // Let's maintain a binary pointer `src_bin_ptr` for addressing.
                // But the spec says "resets each binary pointer and the Gray register".
                // This implies there is a binary pointer.
                // Let's add `src_bin_ptr` and `dst_bin_ptr`.
            end
        end
    end

    // --- Binary Pointers for Addressing ---
    reg [LOG_DEPTH-1:0] src_bin_ptr;
    reg [LOG_DEPTH-1:0] dst_bin_ptr;
    
    // Convert Gray to Binary
    // Binary = Gray ^ (Binary >> 1) ^ (Binary >> 2) ...
    // Iterative approach:
    // bin[0] = gray[0]
    // bin[i] = gray[i] ^ bin[i-1]
    
    assign src_bin_ptr = src_gray_ptr ^ (src_gray_ptr >> 1);
    assign dst_bin_ptr = dst_gray_ptr ^ (dst_gray_ptr >> 1);

    // Re-evaluate Write Logic with Binary Pointer
    // We need to write to mem[src_bin_ptr]
    
    // Update full_cnt and empty_cnt logic again to ensure consistency with binary pointers?
    // No, full_cnt and empty_cnt are derived from the difference between src_bin_ptr and dst_bin_ptr.
    // But we are using counters.
    // Let's ensure the counters are updated correctly.
    // The previous logic for full_cnt/empty_cnt used `src_write_en` and `dst_read_en`.
    // This is correct.
    
    // Memory Write Block
    always @(posedge src_clk_i or posedge src_rst_ni) begin
        if (src_rst_ni) begin
            for (integer i = 0; i < DEPTH; i = i + 1)
                mem[i] <= 0;
        end else begin
            if (src_write_en) begin
                mem[src_bin_ptr] <= src_data_i;
            end
        end
    end

    // --- Data Read Logic ---
    // Read data from memory when dst_read_en is high.
    // Store in dst_data_reg.
    
    always @(posedge dst_clk_i or posedge dst_rst_ni) begin
        if (dst_rst_ni) begin
            dst_data_reg <= 0;
        end else begin
            if (dst_read_en) begin
                dst_data_reg <= mem[dst_bin_ptr];
            end
        end
    end

    // Output Assignment
    assign dst_data_o = dst_data_reg;

    // --- Final Logic Checks ---
    // Ensure src_write_en and dst_read_en are defined consistently.
    // src_write_en = src_write_req && src_ready_o
    // dst_read_en = dst_read_req && dst_valid_o
    
    // Wait, dst_valid_o depends on empty_cnt.
    // empty_cnt depends on dst_read_en.
    // This is a combinational loop if not careful.
    // Solution: Use a flag for "clearing" to break the loop, or use non-blocking assignments carefully.
    // Actually, the dependency is:
    // empty_cnt_next depends on dst_read_en.
    // dst_read_en depends on dst_valid_o.
    // dst_valid_o depends on empty_cnt (current).
    // This is a standard FIFO loop. It resolves because dst_valid_o is based on CURRENT empty_cnt,
    // and empty_cnt_next is based on CURRENT dst_read_en.
    // So in the next cycle, empty_cnt updates.
    
    // Let's define the enables:
    reg src_write_en;
    reg dst_read_en;
    
    assign src_write_en = src_write_req && src_ready_o;
    assign dst_read_en = dst_read_req && dst_valid_o;

    // Re-verify the full/empty counter logic with the enables.
    // The `always` block for full_cnt/empty_cnt uses `src_write_en` and `dst_read_en`.
    // This is correct.

    // One detail: "A clear resets each binary pointer and the Gray register that feeds its synchronizer on the same edge."
    // My implementation:
    // 1. `src_clear_sync2` is active.
    // 2. `src_bin_ptr` and `src_gray_ptr` are reset to 0 in the `always` blocks.
    // 3. `full_cnt` and `empty_cnt` are reset to 0 in the `always` block.
    // 4. `src_write_en` becomes 0 (because src_ready_o becomes 0 due to clear).
    // 5. `dst_read_en` becomes 0 (because dst_valid_o becomes 0 due to clear).
    // This ensures no new data is written or read during the clear cycle.
    // The pointers are reset to 0.
    // The counters are reset to 0.
    // This satisfies the requirement.

    // One more check: "dst_valid_o may fall for one destination clock after an accepted beat".
    // If dst_ready_i is 1, dst_valid_o is 1. Data is read.
    // Next cycle, if dst_ready_i is 0, dst_valid_o should be 0 (if data is gone) or 1 (if data remains).
    // Standard FIFO: If data remains, valid stays 1.
    // The phrase "may fall for one destination clock" might refer to the case where the consumer 
    // accepts a beat (ready=1), then in the next cycle, if the consumer is slow or the FIFO logic 
    // dictates, valid might drop?
    // Actually, this might be a hint to implement a specific behavior where valid is not asserted 
    // continuously if the consumer is not ready? No, that's standard.
    // Perhaps it means: If the consumer asserts ready, we read. In the next cycle, even if data is there, 
    // we might not assert valid if the consumer didn't assert ready again?
    // No, that would starve the FIFO.
    // Let's assume the standard behavior is sufficient, and the comment describes a potential 
    // timing scenario where valid de-asserts if the consumer doesn't hold ready.
    // My implementation: dst_valid_o = (!clear) && (!empty).
    // If empty is 0, valid is 1. If consumer doesn't assert ready, we just wait.
    // If consumer asserts ready, we read, empty becomes 1, valid becomes 0.
    // Next cycle, if data is available, empty becomes 0, valid becomes 1.
    // This seems correct.

    // One edge case: Clear pending output.
    // src_clear_pending_o = src_clear_sync2;
    // dst_clear_pending_o = dst_clear_sync2 | (dst_gray_ptr != 0);
    // This ensures dst_clear_pending_o stays high until the destination side has fully reset.
    // This matches the requirement "flush pending data together".

    // Final check on parameters.
    // WIDTH = 8, LOG_DEPTH = 3, SYNC_STAGES = 3.
    // SYNC_STAGES is used for the clear signal synchronizers.
    // I used 2 stages in the code (sync1, sync2). 
    // If SYNC_STAGES > 2, we need more stages.
    // Let's generalize the synchronizer.
    
    // Generalized Synchronizer
    // We need SYNC_STAGES flip-flops.
    // Since SYNC_STAGES is a parameter, we can't easily unroll in a simple way without generating code.
    // But for a single bit signal, we can use a loop or a fixed number of stages if we assume >= 2.
    // The problem says SYNC_STAGES = 3.
    // I will implement a generic synchronizer using a loop or a fixed structure if possible.
    // Since it's Verilog-2001, we can use a for-loop to generate the stages if we use a generate block,
    // but the module interface is fixed.
    // Alternatively, since the requirement is just to synchronize, and SYNC_STAGES=3 is given,
    // I can hardcode 3 stages or use a dynamic approach.
    // Given the constraint "Do not include... vendor primitives", I should avoid `generate` if it makes the code complex,
    // but `generate` is standard Verilog-2001.
    // However, to keep it simple and clear, I will implement the synchronizer with a loop using a generate block 
    // if SYNC_STAGES is known at compile time (which it is).
    // But wait, the prompt says "Do not include... the reference implementation". It doesn't forbid generate.
    // But to be safe and concise, I'll implement a 3-stage synchronizer explicitly since the parameter is 3.
    // Or better, I can write a function-like structure.
    // Let's use a generate block to create the synchronizer chain.
    
    // Actually, the simplest way for a single bit signal with parameter SYNC_STAGES is:
    // reg [SYNC_STAGES-1:0] sync_chain;
    // But we need to chain them.
    // Let's just hardcode 3 stages as per the example parameter, but make it parameterized if possible.
    // Since I cannot use generate easily in a single block without making it verbose, 
    // and the parameter is fixed to 3 in the example, I will implement 3 stages explicitly.
    // Wait, the parameter is `parameter SYNC_STAGES = 3`.
    // I should respect the parameter.
    // I will use a generate block to create the synchronizer.
    
    // Re-writing the synchronizer part with generate.
    
    // Source Clear Sync
    reg [SYNC_STAGES-1:0] src_clear_chain;
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : src_clear_sync_gen
            always @(posedge src_clk_i or posedge src_rst_ni) begin
                if (src_rst_ni) begin
                    src_clear_chain[i] <= 1'b0;
                end else begin
                    src_clear_chain[i] <= src_clear_chain[i-1];
                end
            end
        end
    endgenerate
    assign src_clear_sync2 = src_clear_chain[SYNC_STAGES-1]; // Last stage

    // Destination Clear Sync
    reg [SYNC_STAGES-1:0] dst_clear_chain;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : dst_clear_sync_gen
            always @(posedge dst_clk_i or posedge dst_rst_ni) begin
                if (dst_rst_ni) begin
                    dst_clear_chain[i] <= 1'b0;
                end else begin
                    dst_clear_chain[i] <= dst_clear_chain[i-1];
                end
            end
        end
    endgenerate
    assign dst_clear_sync2 = dst_clear_chain[SYNC_STAGES-1];

    // Wait, the generate block for the first stage needs a default value.
    // src_clear_chain[0] <= src_clear_i;
    // src_clear_chain[1] <= src_clear_chain[0];
    // ...
    // This works.

    // One issue: The `always` block inside generate for the first stage (i=0) needs to handle the input.
    // For i=0: src_clear_chain[0] <= src_clear_i;
    // For i>0: src_clear_chain[i] <= src_clear_chain[i-1];
    
    // Let's refine the generate block.
    
    // Source Clear Sync
    reg [SYNC_STAGES-1:0] src_clear_reg;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : src_clear_sync_gen
            always @(posedge src_clk_i or posedge src_rst_ni) begin
                if (src_rst_ni) begin
                    src_clear_reg[i] <= 1'b0;
                end else begin
                    if (i == 0)
                        src_clear_reg[i] <= src_clear_i;
                    else
                        src_clear_reg[i] <= src_clear_reg[i-1];
                end
            end
        end
    endgenerate
    assign src_clear_sync2 = src_clear_reg[SYNC_STAGES-1];

    // Destination Clear Sync
    reg [SYNC_STAGES-1:0] dst_clear_reg;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : dst_clear_sync_gen
            always @(posedge dst_clk_i or posedge dst_rst_ni) begin
                if (dst_rst_ni) begin
                    dst_clear_reg[i] <= 1'b0;
                end else begin
                    if (i == 0)
                        dst_clear_reg[i] <= dst_clear_i;
                    else
                        dst_clear_reg[i] <= dst_clear_reg[i-1];
                end
            end
        end
    endgenerate
    assign dst_clear_sync2 = dst_clear_reg[SYNC_STAGES-1];

    // Final check on logic flow.
    // 1. Clear signals are synchronized.
    // 2. Pointers (Gray and Binary) are reset on the synchronized clear edge.
    // 3. Counters are reset on the synchronized clear edge.
    // 4. Write/Read enables are disabled during clear.
    // 5. Data is written/read only when enabled.
    // 6. Outputs are driven correctly.
    
    // One small detail: `src_clear_pending_o` and `dst_clear_pending_o`.
    // The logic `dst_clear_pending_o = dst_clear_sync2 | (dst_gray_ptr != 0);`
    // If dst_clear_sync2 is 1, dst_gray_ptr is being reset to 0 on the same edge.
    // So in the same cycle, dst_gray_ptr might still be the old value (non-blocking assignment).
    // So `dst_gray_ptr != 0` will be true if the old value was non-zero.
    // This means `dst_clear_pending_o` will be 1.
    // In the next cycle, dst_gray_ptr becomes 0, so `dst_clear_pending_o` becomes 0 (if sync2 is 0).
    // This correctly indicates the clear is pending until the destination side has reset.
    
    // Similarly for source. `src_clear_pending_o = src_clear_sync2`.
    // This is high while the source sees the clear.
    
    // The requirement "flush pending data together" is satisfied because both sides reset pointers 
    // and counters on the same edge (after synchronization).
    
    // One potential issue: The `full_cnt` and `empty_cnt` logic.
    // If clear is active, we force them to 0.
    // If not clear, we update them based on write/read enables.
    // This is correct.
    
    // One more thing: The `src_write_en` and `dst_read_en` are used in the `always` blocks for pointers and counters.
    // They are also used in the `always` blocks for memory and data registers.
    // This is consistent.
    
    // Final check on `dst_valid_o`.
    // `assign dst_valid_o = (!dst_clear_sync2) && (empty_cnt != 0);`
    // If `dst_clear_sync2` is 1, `dst_valid_o` is 0.
    // If `empty_cnt` is 0, `dst_valid_o` is 0.
    // This is correct.
    
    // One detail: "dst_valid_o may fall for one destination clock after an accepted beat".
    // This might imply that if the consumer accepts a beat (ready=1), the FIFO might not assert valid 
    // in the next cycle if the consumer doesn't assert ready again?
    // No, that's not how FIFOs work.
    // Maybe it means: If the consumer asserts ready, we read. In the next cycle, if the consumer 
    // doesn't assert ready, valid stays high? No, that's standard.
    // Maybe it means: If the consumer asserts ready, we read. In the next cycle, if the consumer 
    // asserts ready again, valid is high. If not, valid is high (if data available).
    // The phrase "may fall for one destination clock" is confusing.
    // It might refer to the case where the FIFO is empty after a read, so valid falls.
    // Or it might refer to a specific protocol where valid is not asserted continuously.
    // Given the ambiguity, I will stick to the standard FIFO behavior which is robust.
    // The standard behavior naturally allows valid to fall if the FIFO becomes empty.
    // If the FIFO is not empty, valid stays high.
    // The "one clock" might be a red herring or a