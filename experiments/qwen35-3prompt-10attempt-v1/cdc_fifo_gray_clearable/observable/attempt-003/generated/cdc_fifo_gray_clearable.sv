```verilog
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
    localparam GRAY_WIDTH = $clog2(DEPTH);

    // --- Source Side (Write Side) ---
    // State machine for clear pending indication
    reg src_clear_pending;
    reg src_clear_req;
    reg src_clear_ack;

    // Write pointers
    reg [LOG_DEPTH-1:0] src_gray_ptr;
    reg [LOG_DEPTH-1:0] src_bin_ptr;
    reg [LOG_DEPTH-1:0] src_gray_ptr_sync [SYNC_STAGES-1:0];

    // Data buffer
    reg [WIDTH-1:0] src_data_buf [DEPTH-1:0];

    // --- Destination Side (Read Side) ---
    // State machine for clear pending indication
    reg dst_clear_pending;
    reg dst_clear_req;
    reg dst_clear_ack;

    // Read pointers
    reg [LOG_DEPTH-1:0] dst_gray_ptr;
    reg [LOG_DEPTH-1:0] dst_bin_ptr;
    reg [LOG_DEPTH-1:0] dst_gray_ptr_sync [SYNC_STAGES-1:0];

    // Read data register
    reg [WIDTH-1:0] dst_data_reg;

    // --- Synchronizers for Clear Signals ---
    // We need to synchronize clear requests across domains to ensure atomicity
    // and prevent metastability on the pointer reset logic.

    // Source Clear Sync
    reg src_clear_sync [SYNC_STAGES-1:0];
    always @(posedge src_clk_i or posedge src_rst_ni) begin
        if (src_rst_ni)
            src_clear_sync <= '{1'b0};
        else begin
            src_clear_sync[0] <= src_clear_i;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_clear_sync[i] <= src_clear_sync[i-1];
        end
    end

    // Destination Clear Sync
    reg dst_clear_sync [SYNC_STAGES-1:0];
    always @(posedge dst_clk_i or posedge dst_rst_ni) begin
        if (dst_rst_ni)
            dst_clear_sync <= '{1'b0};
        else begin
            dst_clear_sync[0] <= dst_clear_i;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_clear_sync[i] <= dst_clear_sync[i-1];
        end
    end

    // --- Synchronizers for Pointers (Gray to Binary conversion happens on source side, 
    // but we need to sync the Gray pointer value to destination side for read logic)
    // Actually, standard practice: 
    // 1. Source generates Gray pointer.
    // 2. Destination syncs Source's Gray pointer.
    // 3. Destination converts Synced Gray to Binary for reading.
    // 4. Source syncs Destination's Gray pointer.
    // 5. Source converts Synced Gray to Binary for writing.

    // Sync Source Gray Pointer to Destination
    reg [LOG_DEPTH-1:0] src_gray_synced [SYNC_STAGES-1:0];
    always @(posedge dst_clk_i or posedge dst_rst_ni) begin
        if (dst_rst_ni)
            src_gray_synced <= '{1'b0};
        else begin
            src_gray_synced[0] <= src_gray_ptr;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_gray_synced[i] <= src_gray_synced[i-1];
        end
    end

    // Sync Destination Gray Pointer to Source
    reg [LOG_DEPTH-1:0] dst_gray_synced [SYNC_STAGES-1:0];
    always @(posedge src_clk_i or posedge src_rst_ni) begin
        if (src_rst_ni)
            dst_gray_synced <= '{1'b0};
        else begin
            dst_gray_synced[0] <= dst_gray_ptr;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_gray_synced[i] <= dst_gray_synced[i-1];
        end
    end

    // --- Source Logic (Write) ---
    always @(posedge src_clk_i or posedge src_rst_ni) begin
        if (src_rst_ni) begin
            src_clear_pending <= 1'b0;
            src_clear_req <= 1'b0;
            src_clear_ack <= 1'b0;
            src_gray_ptr <= 1'b0;
            src_bin_ptr <= 1'b0;
            src_clear_pending_o <= 1'b0;
        end
        else begin
            // Handle Clear Request
            // The clear request is active when the synchronized clear signal is high
            // AND the FIFO is not already empty (or we just flush everything).
            // To ensure "nothing stale appears", we set a flag that persists until the 
            // destination catches up and acknowledges the clear.
            
            if (src_clear_sync[SYNC_STAGES-1]) begin
                src_clear_req <= 1'b1;
            end else begin
                src_clear_req <= 1'b0;
            end

            // Update Clear Ack: We acknowledge clear when the destination pointer 
            // (synchronized) has caught up to the source pointer (synchronized).
            // Note: We compare the synchronized destination pointer to the current source pointer.
            // However, to be safe against race conditions during the clear transition,
            // we usually wait until the destination pointer >= source pointer.
            
            // Let's refine the clear logic:
            // 1. Clear Request is asserted by source when it sees a clear signal.
            // 2. Clear Ack is asserted when dst_ptr >= src_ptr (meaning all data written 
            //    before clear is consumed).
            // 3. Clear Pending is asserted from Clear Request until Clear Ack.
            
            // Synchronize dst_gray_ptr to src domain for comparison
            // We already have dst_gray_synced.
            
            // Determine if we should acknowledge clear
            // We need to compare the synchronized destination pointer with the current source pointer.
            // Since dst_gray_synced is stable in src domain, we can compare it directly.
            // However, we must ensure we don't ack clear if the destination hasn't actually 
            // read the data corresponding to the current src_ptr yet.
            // Condition: dst_gray_ptr_synced >= src_gray_ptr implies all data up to src_ptr is read.
            
            // Wait, the requirement says: "A clear resets each binary pointer and the Gray register 
            // that feeds its synchronizer on the same edge."
            // This implies the reset happens immediately on the clear signal in the respective domain,
            // but the "Clear Pending" signal indicates to the other side that data is being flushed.
            
            // Revised Clear Logic:
            // Source sees clear -> sets src_clear_req.
            // Source sets src_clear_pending = 1.
            // Source resets src_gray_ptr and src_bin_ptr immediately? 
            // If we reset immediately, the FIFO becomes empty instantly in source domain.
            // But destination might still have old data.
            // So src_clear_pending_o tells destination "I am clearing, wait for me".
            // Destination sees src_clear_pending_o -> sets dst_clear_pending.
            // Destination resets its pointers when it sees dst_clear_pending.
            
            // Let's implement the handshake for clear:
            // 1. Source asserts src_clear_req (synchronized).
            // 2. Source sets src_clear_pending_o = 1.
            // 3. Destination sees src_clear_pending_o (synchronized).
            // 4. Destination sets dst_clear_pending_o = 1.
            // 5. Destination resets dst_gray_ptr and dst_bin_ptr.
            // 6. Destination sets dst_clear_ack (internal) = 1.
            // 7. Source sees dst_clear_ack (synchronized).
            // 8. Source resets src_gray_ptr and src_bin_ptr.
            // 9. Source sets src_clear_pending_o = 0.
            
            // Implementation details:
            // src_clear_pending_o is driven by src_clear_req until dst_clear_ack is seen.
            
            // Sync dst_clear_ack to source domain
            reg dst_clear_ack_sync [SYNC_STAGES-1:0];
            always @(posedge src_clk_i or posedge src_rst_ni) begin
                if (src_rst_ni)
                    dst_clear_ack_sync <= '{1'b0};
                else begin
                    dst_clear_ack_sync[0] <= dst_clear_ack;
                    for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                        dst_clear_ack_sync[i] <= dst_clear_ack_sync[i-1];
                end
            end

            // Sync src_clear_req to destination domain
            reg src_clear_req_sync [SYNC_STAGES-1:0];
            always @(posedge dst_clk_i or posedge dst_rst_ni) begin
                if (dst_rst_ni)
                    src_clear_req_sync <= '{1'b0};
                else begin
                    src_clear_req_sync[0] <= src_clear_req;
                    for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                        src_clear_req_sync[i] <= src_clear_req_sync[i-1];
                end
            end

            // Logic for src_clear_pending_o
            if (src_rst_ni)
                src_clear_pending <= 1'b0;
            else if (src_clear_req)
                src_clear_pending <= 1'b1;
            else if (dst_clear_ack_sync[SYNC_STAGES-1])
                src_clear_pending <= 1'b0;
            else
                src_clear_pending <= src_clear_pending;

            src_clear_pending_o <= src_clear_pending;

            // Write Pointer Logic
            if (src_rst_ni) begin
                src_gray_ptr <= 1'b0;
                src_bin_ptr <= 1'b0;
            end
            else if (src_clear_req) begin
                // Reset pointers immediately on clear request in source domain
                src_gray_ptr <= 1'b0;
                src_bin_ptr <= 1'b0;
            end
            else if (src_valid_i && src_ready_o) begin
                src_gray_ptr <= src_gray_ptr + 1'b1;
                // Convert Gray to Binary for internal bin_ptr usage if needed, 
                // but usually we just increment Gray and convert on read/write boundary.
                // Here we maintain both for clarity or just use Gray for addressing.
                // Let's keep src_bin_ptr as the binary equivalent of src_gray_ptr.
                // Actually, simpler: just increment Gray. Convert to Bin when accessing buffer.
                // But the prompt asks to reset binary pointer too. So we maintain it.
                // Incrementing Gray:
                // new_gray = old_gray ^ (1 << (floor(log2(old_gray + 1))))
                // But since we are incrementing, we can just do:
                // src_gray_ptr = src_gray_ptr + 1; // This is arithmetic, not Gray.
                // We need Gray code increment.
                
                // Correct Gray Increment:
                // If we have a Gray pointer, adding 1 in binary and converting to Gray is complex.
                // Standard way: Maintain a binary counter, convert to Gray for output/sync.
                // OR: Maintain Gray counter. To increment Gray:
                // Find the position of the least significant '1' bit. Flip that bit and all bits to its right? No.
                // Gray code sequence: 0, 1, 3, 2, 6, 7, 5, 4...
                // Increment logic: 
                // g = gray; 
                // bin = gray ^ (gray >> 1);
                // bin = bin + 1;
                // new_gray = bin ^ (bin >> 1);
                
                // Let's use a binary counter internally for the pointer logic to make increment easy,
                // and convert to Gray only for the synchronizer input.
                // Wait, the prompt says "resets each binary pointer and the Gray register that feeds its synchronizer".
                // This implies we have a Gray register specifically for the CDC.
                
                // Approach:
                // 1. Internal binary counter `src_bin_ptr`.
                // 2. Convert `src_bin_ptr` to Gray `src_gray_calc`.
                // 3. Assign `src_gray_ptr` <= `src_gray_calc`.
                // 4. Sync `src_gray_ptr` to dest.
                // 5. Dest converts synced Gray back to Bin.
                // 6. Src syncs Dest's Gray back to Src.
                
                // Let's restructure slightly for clarity and correctness.
                // We will maintain `src_bin_ptr` as the actual address counter.
                // `src_gray_ptr` is derived from `src_bin_ptr` for the CDC path.
                
                // Increment binary pointer
                src_bin_ptr <= src_bin_ptr + 1'b1;
                // Update Gray pointer for CDC
                src_gray_ptr <= src_bin_ptr ^ (src_bin_ptr >> 1);
            end
            else begin
                // Keep pointers stable if not writing
                // src_gray_ptr and src_bin_ptr hold their values
            end
        end
    end

    // --- Destination Logic (Read) ---
    always @(posedge dst_clk_i or posedge dst_rst_ni) begin
        if (dst_rst_ni) begin
            dst_clear_pending <= 1'b0;
            dst_clear_req <= 1'b0;
            dst_clear_ack <= 1'b0;
            dst_gray_ptr <= 1'b0;
            dst_bin_ptr <= 1'b0;
            dst_clear_pending_o <= 1'b0;
            dst_valid_o <= 1'b0;
            dst_data_reg <= 1'b0;
        end
        else begin
            // Handle Clear Request
            if (src_clear_req_sync[SYNC_STAGES-1]) begin
                dst_clear_req <= 1'b1;
            end else begin
                dst_clear_req <= 1'b0;
            end

            // Acknowledge clear when our pointer has caught up to the source pointer
            // We compare our synchronized source pointer (dst_gray_synced) with our current pointer (dst_gray_ptr).
            // If dst_gray_synced >= dst_gray_ptr, it means the source has written up to a point 
            // that we have already read (or are reading).
            // Actually, we need to ensure we have read everything the source wrote before the clear.
            // Since source resets on clear_req, the source pointer stays at 0 (or last value before reset).
            // If we reset our pointer too, we are fine.
            // The condition to set dst_clear_ack is when dst_gray_ptr >= dst_gray_synced (synchronized src pointer).
            // Wait, if src resets to 0, dst_gray_synced becomes 0.
            // If dst is at 5, and src resets to 0. dst_gray_synced is 0.
            // 5 >= 0 is true. So dst_clear_ack becomes true.
            // This seems correct. The destination has read everything the source wrote before the reset.
            
            if (dst_gray_ptr >= dst_gray_synced[SYNC_STAGES-1])
                dst_clear_ack <= 1'b1;
            else
                dst_clear_ack <= 1'b0;

            // Logic for dst_clear_pending_o
            if (dst_rst_ni)
                dst_clear_pending <= 1'b0;
            else if (dst_clear_req)
                dst_clear_pending <= 1'b1;
            else if (dst_clear_ack)
                dst_clear_pending <= 1'b0;
            else
                dst_clear_pending <= dst_clear_pending;

            dst_clear_pending_o <= dst_clear_pending;

            // Read Pointer Logic
            if (dst_rst_ni) begin
                dst_gray_ptr <= 1'b0;
                dst_bin_ptr <= 1'b0;
            end
            else if (dst_clear_req) begin
                // Reset pointers immediately on clear request in destination domain
                dst_gray_ptr <= 1'b0;
                dst_bin_ptr <= 1'b0;
            end
            else if (dst_valid_i && dst_ready_i) begin
                // Increment binary pointer
                dst_bin_ptr <= dst_bin_ptr + 1'b1;
                // Update Gray pointer for CDC
                dst_gray_ptr <= dst_bin_ptr ^ (dst_bin_ptr >> 1);
            end
            else begin
                // Hold pointers
            end

            // Data Output Logic
            // Calculate address from synchronized source pointer
            // We need the binary version of the synchronized source pointer to index the buffer.
            // dst_gray_synced is the Gray code of src_bin_ptr.
            // Convert dst_gray_synced to binary to get the address.
            reg [LOG_DEPTH-1:0] src_bin_synced;
            always @(posedge dst_clk_i or posedge dst_rst_ni) begin
                if (dst_rst_ni)
                    src_bin_synced <= 1'b0;
                else
                    src_bin_synced <= dst_gray_synced[SYNC_STAGES-1] ^ (dst_gray_synced[SYNC_STAGES-1] >> 1);
            end

            if (dst_valid_i && dst_ready_i) begin
                dst_data_reg <= src_data_buf[src_bin_synced];
                dst_valid_o <= 1'b1;
            end
            else begin
                dst_valid_o <= 1'b0;
            end
        end
    end

    // --- Handshake Logic ---

    // Source Ready
    // Ready if:
    // 1. FIFO is not full.
    // 2. Not clearing (or clearing is handled by the pointers resetting, but we need to ensure we don't overwrite unread data if dest is slow? 
    //    Actually, if we clear, we overwrite. But we must ensure dest has read everything before we overwrite.
    //    The clear logic above handles the "flush" by waiting for dst_clear_ack.
    //    So during normal operation, we just check fullness.
    //    During clear, src_ready_o should be 0 until the clear is acknowledged? 
    //    No, the clear request is external. The internal state machine handles the transition.
    //    If src_clear_req is active, we are in clear mode. We should not accept new data until clear is done?
    //    Or can we accept data while clearing? 
    //    "A clear request should flush pending data together on both sides so nothing stale appears afterward."
    //    This implies we stop accepting new data until the clear is complete.
    
    reg src_full;
    reg dst_empty;

    // Calculate Full/Empty
    // Full: src_bin_ptr == dst_bin_ptr (synchronized)
    // Empty: src_bin_ptr == dst_bin_ptr (synchronized)
    // Wait, we need to compare synchronized pointers.
    // src_bin_ptr is local. dst_bin_ptr is local.
    // We need to compare src_bin_ptr with dst_bin_ptr_synced (synchronized to src).
    // And dst_bin_ptr with src_bin_ptr_synced (synchronized to dst).
    
    // Sync dst_bin_ptr to src
    reg [LOG_DEPTH-1:0] dst_bin_synced [SYNC_STAGES-1:0];
    always @(posedge src_clk_i or posedge src_rst_ni) begin
        if (src_rst_ni)
            dst_bin_synced <= '{1'b0};
        else begin
            dst_bin_synced[0] <= dst_bin_ptr;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                dst_bin_synced[i] <= dst_bin_synced[i-1];
        end
    end

    // Sync src_bin_ptr to dst
    reg [LOG_DEPTH-1:0] src_bin_synced [SYNC_STAGES-1:0];
    always @(posedge dst_clk_i or posedge dst_rst_ni) begin
        if (dst_rst_ni)
            src_bin_synced <= '{1'b0};
        else begin
            src_bin_synced[0] <= src_bin_ptr;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                src_bin_synced[i] <= src_bin_synced[i-1];
        end
    end

    // Full Condition: src_bin_ptr == dst_bin_ptr_synced
    // Empty Condition: src_bin_ptr_synced == dst_bin_ptr
    
    // Note: During clear, pointers are reset.
    // If src_clear_req is high, src_bin_ptr is 0.
    // If dst_clear_req is high, dst_bin_ptr is 0.
    // We need to ensure we don't write if we are clearing and haven't finished.
    
    // src_ready_o logic:
    // 1. If clearing (src_clear_req), we are flushing. We should not accept new data until clear is done.
    //    Actually, if we accept new data while clearing, it might be lost if the clear logic overwrites.
    //    But the clear logic waits for dst_clear_ack. So if dst hasn't acked, we shouldn't write.
    //    However, the simplest interpretation: 
    //    If src_clear_req is active, src_ready_o = 0.
    //    Once dst_clear_ack is active, src_clear_req becomes 0 (eventually), and we resume.
    //    But wait, src_clear_req is driven by src_clear_i. If src_clear_i is held high, src_clear_req is high.
    //    So we must block writes while src_clear_i is high AND dst hasn't acked.
    //    Actually, the requirement says "flush pending data". 
    //    If we block writes, the FIFO fills up with nothing? No, we just don't write.
    //    But what if the producer keeps sending valid data? 
    //    We must assert src_ready_o = 0 to stop the producer.
    //    When do we assert src_ready_o = 1?
    //    When NOT clearing AND NOT full.
    
    // Let's refine the "Clear" state.
    // State 1: Normal.
    // State 2: Clearing (src_clear_req=1). We reset pointers. We stop writing.
    // State 3: Clear Done (dst_clear_ack=1). We reset pointers (already done). We resume writing.
    
    // Is it possible that dst_clear_ack is 1 but src_clear_req is still 1?
    // Yes, if src_clear_i is still high.
    // In this case, we should still not write? 
    // "A clear request should flush pending data together on both sides".
    // If src_clear_i is high, the user wants a clear. We should not accept new data until the clear is fully processed.
    // So src_ready_o = 0 if (src_clear_req || src_full).
    // But wait, if src_clear_req is 1, we reset pointers. The FIFO is effectively empty in source domain.
    // But destination might have old data.
    // If we assert src_ready_o=1, the producer sends data. We write it.
    // But if dst hasn't acked, dst might read old data?
    // No, dst reads based on its own pointer. If dst hasn't acked, it means dst_ptr < src_ptr (before reset).
    // After reset, src_ptr=0. dst_ptr is still > 0.
    // So dst will read from index 0, 1, 2... which are the new data we just wrote?
    // No, dst_bin_ptr is still at the old value. It will read old data until it catches up.
    // So if we write new data while dst is still reading old data, we overwrite old data with new data.
    // This is fine for the "new" data, but the "old" data is lost.
    // The requirement says "flush pending data". This means the old data must be consumed before we write new data.
    // So we must wait until dst_clear_ack is 1 before we can write new data.
    
    // Therefore:
    // src_ready_o = 1 if (!src_clear_req && !src_full)
    // src_ready_o = 0 if (src_clear_req || src_full)
    
    // Similarly for dst_valid_o:
    // dst_valid_o = 1 if (!dst_clear_req && !dst_empty && dst_ready_i)
    // dst_valid_o = 0 if (dst_clear_req || dst_empty || !dst_ready_i)
    
    // Wait, if dst_clear_req is 1, we reset dst pointers.
    // If we reset dst pointers, dst_bin_ptr becomes 0.
    // Then dst_valid_o should be 1 (if data available) to read the new data?
    // But the data is not there yet (src hasn't written).
    // So dst_valid_o should be 0.
    
    // Let's re-evaluate the "Clear" sequence.
    // 1. src_clear_i goes high.
    // 2. src_clear_req becomes 1. src_gray_ptr resets to 0. src_bin_ptr resets to 0.
    // 3. src_ready_o becomes 0 (blocking new writes).
    // 4. src_clear_pending_o becomes 1.
    // 5. dst sees src_clear_pending_o. dst_clear_req becomes 1. dst_gray_ptr resets to 0. dst_bin_ptr resets to 0.
    // 6. dst_clear_pending_o becomes 1.
    // 7. dst_valid_o becomes 0 (no data yet).
    // 8. dst reads nothing.
    // 9. Eventually, dst_bin_ptr catches up to src_bin_ptr (which is 0).
    //    Wait, if both are 0, dst_bin_ptr == src_bin_ptr_synced.
    //    So dst_clear_ack becomes 1.
    // 10. dst_clear_pending_o becomes 0.
    // 11. src sees dst_clear_ack. src_clear_pending_o becomes 0.
    // 12. src_ready_o becomes 1 (if not full).
    // 13. Producer sends data. src writes.
    // 14. dst reads.
    
    // This logic holds.
    
    // One edge case: What if src_clear_i is high, but dst is very fast and already caught up?
    // Then dst_clear_ack is 1 immediately.
    // src_clear_pending_o becomes 0 immediately.
    // src_ready_o becomes 1.
    // This is fine. The clear was a "no-op" effectively because there was no pending data.
    
    // Another edge case: What if src_clear_i is high, and dst is slow.
    // src_clear_req=1. src_bin_ptr=0.
    // dst_clear_req=1. dst_bin_ptr=0.
    // dst_bin_ptr (0) == src_bin_ptr_synced (0).
    // dst_clear_ack=1.
    // dst_clear_pending_o=0.
    // src_clear_pending_o=0.
    // src_ready_o=1.
    // This works.
    
    // What if src_clear_i is high, and dst is slow (has pending data).
    // src_clear_req=1. src_bin_ptr=0.
    // dst_clear_req=1. dst_bin_ptr=5 (example).
    // dst_bin_ptr (5) > src_bin_ptr_synced (0).
    // dst_clear_ack=0.
    // dst_clear_pending_o=1.
    // src_clear_pending_o=1.
    // src_ready_o=0.
    // dst_valid_o=0 (because dst_clear_req is 1? Or because dst_bin_ptr is reset to 0? 
    // If dst_bin_ptr is reset to 0, and src_bin_ptr_synced is 0.
    // Then dst_bin_ptr (0) == src_bin_ptr_synced (0).
    // So dst_clear_ack becomes 1.
    // This creates a race condition.
    // If dst resets its pointer to 0, and src pointer is 0, they match.
    // But dst hasn't read the data at indices 0..4 yet!
    // So dst_clear_ack should NOT be 1 just because pointers match.
    // The pointers match because we reset them.
    // We need to ensure that dst_clear_ack is only 1 if the pointers matched BEFORE the reset, 
    // OR if the reset happened and the pointers are now aligned AND we have consumed the gap.
    // But the gap is the data we are flushing.
    // The logic "dst_clear_ack = (dst_bin_ptr >= src_bin_ptr_synced)" is flawed during reset.
    
    // Correct Logic for Clear Ack:
    // We need to know if the destination has consumed all data written BEFORE the clear.
    // Let's introduce a "clear_in_progress" flag.
    // Or simpler: The clear logic should be:
    // 1. Source asserts clear_req.
    // 2. Source sets a flag "clear_active".
    // 3. Destination sees clear_active (via sync).
    // 4. Destination sets "clear_active_ack" when it has read up to the point where source was before clear?
    //    No, source resets immediately.
    //    So destination must read until it reaches the point where source reset.
    //    But source reset to 0.
    //    So destination must read until it reaches 0? No, destination pointer moves forward.
    //    Destination pointer starts at 5. Source pointer resets to 0.
    //    Destination pointer moves 5->6->7...
    //    It will never reach 0.
    //    So the comparison "dst_ptr >= src_ptr" will never be true if src_ptr is 0 and dst_ptr is 5.
    //    This is the problem.
    
    // Solution:
    // The "Clear" operation is a special state.
    // When src_clear_req is asserted:
    //   src_bin_ptr is reset to 0.
    //   src_clear_pending_o is asserted.
    // When dst sees src_clear_pending_o:
    //   dst_clear_req is asserted.
    //   dst_bin_ptr is reset to 0.
    //   dst_clear_pending_o is asserted.
    // Now both pointers are 0.
    // But dst has not read the data that was at 0..4.
    // So dst_clear_ack should NOT be generated yet.
    // We need a separate mechanism to indicate "Clear Complete".
    // The "Clear Complete" is when dst has read all the data that was in the FIFO before the clear.
    // How do we know how much data was there?
    // We can store the "pre-clear" pointer value.
    // Let's add `src_pre_clear_ptr` and `dst_pre_clear_ptr`.
    
    // Revised Plan:
    // 1. Store `src_ptr_before_clear` when `src_clear_req` is asserted.
    // 2. Store `dst_ptr_before_clear` when `dst_clear_req` is asserted.
    // 3. `dst_clear_ack` is asserted when `dst_bin_ptr >= src_ptr_before_clear`.
    // 4. `src_clear_ack` is asserted when `src_bin_ptr >= dst_ptr_before_clear`.
    
    // Wait, if src resets to 0, and dst resets to 0.
    // src_ptr_before_clear = 5.
    // dst_ptr_before_clear = 5.
    // dst_bin_ptr starts at 5.
    // dst_bin_ptr >= 5 is true immediately.
    // So dst_clear_ack is true immediately.
    // This means dst thinks it has read everything.
    // But dst_bin_ptr is 5. It hasn't read index 5 yet (it reads index 5 on the next cycle).
    // So we need `dst_bin_ptr > src_ptr_before_clear`?
    // No, if dst_bin_ptr is 5, it is about to read index 5.
    // If src_ptr_before_clear is 5, it means src wrote up to index 4.
    // So dst has read 0..4. It is ready to read 5.
    // So `dst_bin_ptr >= src_ptr_before_clear` is correct.
    // But wait, if dst_bin_ptr is 5, and we assert dst_clear_ack, then dst_clear_pending_o goes low.
    // Then src sees dst_clear_ack, and src_clear_pending_o goes low.
    // Then src_ready_o goes high.
    // But dst_bin_ptr is 5. It will read index 5.
    // Is index 5 valid?
    // src_ptr_before_clear was 5. This means src wrote index 0..4.
    // Index 5 was NOT written before clear.
    // So index 5 is invalid (or contains garbage).
    // But dst will read index 5.
    // This is a problem.
    
    // The issue is that resetting both pointers to 0 makes them equal, triggering the ack immediately.
    // We need to ensure that the pointers only reset AFTER the ack is generated?
    // No, the requirement says "resets each binary pointer ... on the same edge".
    // This implies the reset happens immediately.
    // So we must rely on the "pre-clear" pointers to determine when the flush is done.
    
    // Let's re-evaluate the "pre-clear" logic.
    // When src_clear_req is asserted:
    //   src_ptr_before_clear = src_bin_ptr;
    //   src_bin_ptr = 0;
    //   src_clear_pending_o = 1;
    // When dst sees src_clear_pending_o:
    //   dst_ptr_before_clear = dst_bin_ptr;
    //   dst_bin_ptr = 0;
    //   dst_clear_pending_o = 1;
    // Now, dst_bin_ptr is 0. src_ptr_before_clear is 5.
    // dst_bin_ptr (0) >= src_ptr_before_clear (5) is FALSE.
    // So dst_clear_ack is FALSE.
    // dst_clear_pending_o remains 1.
    // src_clear_pending_o remains 1.
    // src_ready_o is 0.
    // dst_valid_o is 0 (because dst_clear_req is 1? Or because dst_bin_ptr is 0 and src_bin_ptr_synced is 0? 
    // If dst_bin_ptr is 0, and src_bin_ptr_synced is 0.
    // Then dst_bin_ptr >= src_bin_ptr_synced is TRUE.
    // But we are in clear mode. We should not read.
    // So we must block reading while dst_clear_req is 1.
    
    // Now, dst reads data. dst_bin_ptr increments: 0->1->2->3->4->5.
    // When dst_bin_ptr becomes 5.
    // Check: dst_bin_ptr (5) >= src_ptr_before_clear (5). TRUE.
    // So dst_clear_ack becomes TRUE.
    // dst_clear_pending_o becomes 0.
    // src sees dst_clear_ack. src_clear_pending_o becomes 0.
    // src_ready_o becomes 1.
    // dst_bin_ptr is 5. It will read index 5.
    // Is index 5 valid?
    // src_ptr_before_clear was 5. This means src wrote 0..4.
    // Index 5 was written AFTER the clear request (or during the reset).
    // If src wrote index 5 AFTER the clear request, then it is valid.
    // If src wrote index 5 BEFORE the clear request, then src_ptr_before_clear would be >= 6