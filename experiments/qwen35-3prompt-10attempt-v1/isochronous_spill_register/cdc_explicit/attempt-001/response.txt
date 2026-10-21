```verilog
module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output reg [WIDTH-1:0] dst_data_o
);

    // Internal signals for CDC-safe state storage
    // We use a 2-deep FIFO structure to absorb rate mismatches between related clocks.
    // State 0: Empty
    // State 1: One item available
    // State 2: Two items available (Full)
    
    localparam STATE_EMPTY = 2'b00;
    localparam STATE_ONE   = 2'b01;
    localparam STATE_TWO   = 2'b10; // Effectively full for our 2-deep requirement

    // Source Domain State Machine
    // Tracks how many items are currently in the buffer waiting for the destination.
    reg [1:0] src_state;
    
    // Destination Domain State Machine
    // Tracks how many items are currently in the buffer waiting for the source to push more.
    // Note: In a 2-deep buffer, we need to track if we have 0, 1, or 2 items.
    // However, the standard handshake logic usually tracks "items ready to be popped".
    // Let's define dst_state as the number of items currently held in the buffer 
    // that are valid for the destination domain.
    reg [1:0] dst_state;

    // Data storage
    // We need to store up to 2 items.
    reg [WIDTH-1:0] buffer_data_0;
    reg [WIDTH-1:0] buffer_data_1;

    // CDC Safe State Registers
    // src_state is updated on src_clk, dst_state is updated on dst_clk.
    // We use separate registers for each domain to avoid cross-clock domain latches.

    // --- Source Domain Logic ---
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_state <= STATE_EMPTY;
        end else begin
            case (src_state)
                STATE_EMPTY: begin
                    if (src_valid_i && dst_ready_i) begin
                        // Push data into buffer
                        buffer_data_0 <= src_data_i;
                        src_state <= STATE_ONE;
                    end
                    src_ready_o <= 1'b0;
                end
                STATE_ONE: begin
                    if (src_valid_i && dst_ready_i) begin
                        // Push data into buffer
                        buffer_data_1 <= src_data_i;
                        src_state <= STATE_TWO;
                    end else if (dst_ready_i) begin
                        // Pop data to destination
                        buffer_data_0 <= buffer_data_1;
                        src_state <= STATE_ONE;
                    end
                    src_ready_o <= 1'b0;
                end
                STATE_TWO: begin
                    if (src_valid_i && dst_ready_i) begin
                        // Push data into buffer (Overwriting oldest if we strictly need 2-deep, 
                        // but typically "2-deep" means capacity 2. If full, we wait for pop).
                        // To maintain order and FIFO behavior with capacity 2:
                        // If full, we cannot accept new data until one is popped.
                        // However, the prompt says "2-deep". 
                        // Logic: If state is TWO, we are full. We must wait for dst_ready.
                        // Once dst_ready, we pop, then we can accept.
                        // But wait, if src_valid is high and dst_ready is low, we stay full.
                        // If dst_ready becomes high, we pop, then accept.
                        // Let's refine the logic for strict FIFO behavior.
                        
                        // Actually, simpler logic for 2-deep:
                        // If we have 2 items, we cannot accept new data until we pop one.
                        // So src_ready_o is 0 if src_state == STATE_TWO.
                        // If src_state < STATE_TWO, we accept.
                        
                        // Re-evaluating STATE_TWO logic:
                        // If we are full (2 items), we cannot accept new data.
                        // We must wait for dst_ready to pop one, then we become STATE_ONE, then we can accept.
                        // So if src_valid_i is high and we are full, src_ready_o = 0.
                        // If dst_ready_i is high, we pop, then we check src_valid_i to push.
                        
                        // Corrected flow for STATE_TWO:
                        // 1. Check if we can accept (dst_ready_i). If yes, pop first, then push new if valid.
                        // 2. If we cannot accept (dst_ready_i == 0), src_ready_o = 0.
                        
                        // Let's restructure the case statement for clarity and correctness.
                        // We will handle the pop/push sequence carefully.
                        
                        // If dst_ready_i is high:
                        //   Pop one item.
                        //   If src_valid_i is high, push new item.
                        //   Update state accordingly.
                        // If dst_ready_i is low:
                        //   src_ready_o = 0.
                        //   State remains STATE_TWO.
                        
                        // Wait, the previous STATE_ONE logic had a flaw if we don't handle the pop/push order correctly.
                        // Let's rewrite the always block logic to be sequential and unambiguous.
                        
                        // Actually, let's use a unified logic:
                        // If dst_ready_i:
                        //   Pop data to dst.
                        //   Decrement count.
                        //   If src_valid_i and count < 2:
                        //     Push data.
                        //     Increment count.
                        //   Else if src_valid_i and count == 2:
                        //     We are full, so we can't push. Count stays 2.
                        // Else (not dst_ready):
                        //   src_ready_o = 0.
                        //   Count stays same.
                        
                        // Let's implement this logic cleanly.
                    end
                end
                default: begin
                    src_state <= STATE_EMPTY;
                    src_ready_o <= 1'b0;
                end
            endcase
        end
    end

    // --- Destination Domain Logic ---
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_state <= STATE_EMPTY;
            dst_valid_o <= 1'b0;
            dst_data_o <= 0;
        end else begin
            // Determine which data to output based on current dst_state
            // dst_state represents the number of items currently in the buffer available for dst.
            // However, my src_state logic tracks the buffer content.
            // Let's align dst_state with src_state conceptually but updated on dst_clk.
            // Actually, the standard way is:
            // src_state tracks "items in buffer".
            // dst_valid_o should be 1 if src_state > 0.
            // dst_data_o should be the oldest item.
            
            // But we need to update the buffer content on dst_clk when we pop.
            // So dst_state should track the number of items currently in the buffer.
            
            // Let's restart the state definition to be purely local to each domain for clarity.
            // src_domain_buffer_count: Number of items in buffer (0, 1, 2).
            // dst_domain_buffer_count: Number of items in buffer (0, 1, 2).
            // These must be synchronized via the handshake.
            
            // Revised Approach:
            // Use a single register for buffer content in each domain? No, data is multi-bit.
            // Use a single register for "count" in each domain.
            // src_count: Updated on src_clk.
            // dst_count: Updated on dst_clk.
            // They must always be consistent.
            
            // Let's stick to the previous variable names but fix the logic.
            // src_state: Count of items in buffer (0, 1, 2).
            // dst_state: Count of items in buffer (0, 1, 2).
            // They are updated in their respective clocks.
            
            // Logic for src_clk:
            // If dst_ready_i:
            //   Pop item (move data_1 to data_0, or clear if empty).
            //   Update src_state (decrement).
            //   If src_valid_i:
            //     Push item.
            //     Update src_state (increment).
            // Else:
            //   src_ready_o = 0.
            //   src_state unchanged.
            
            // Logic for dst_clk:
            // If src_valid_i (which is a CDC signal, so we must sample it safely? 
            // Wait, src_valid_i is an input to the module. It is valid in src domain.
            // We cannot sample src_valid_i directly in dst domain without a flip-flop chain or handshake.
            // BUT, the handshake mechanism (src_ready_o / dst_ready_i) solves this.
            // The state machine in src domain drives src_ready_o.
            // The state machine in dst domain drives dst_valid_o.
            // The data transfer happens when both are ready.
            
            // Correct CDC pattern for this specific module:
            // 1. src_domain tracks buffer fullness.
            // 2. dst_domain tracks buffer fullness.
            // 3. When src pushes, it updates its local count.
            // 4. When dst pops, it updates its local count.
            // 5. The data movement must be safe.
            
            // Since we are storing data in the module, we need to store it in a way that is safe.
            // Option A: Store data in src domain, read in dst domain.
            //   - Data is written on src_clk.
            //   - Data is read on dst_clk.
            //   - This is safe as long as we don't read stale data.
            //   - We need to know WHICH data to read.
            //   - We can use a pointer or just shift.
            //   - Since depth is small (2), we can use two registers in src domain:
            //     src_buf[0], src_buf[1].
            //   - On dst_clk, we read src_buf[0] if count > 0.
            //   - On src_clk, we write to src_buf[count].
            //   - This requires no cross-clock domain sampling of data, only control signals.
            
            // Let's implement this "Dual Register" approach.
            
            // Source Domain Registers
            reg [WIDTH-1:0] src_buf_0;
            reg [WIDTH-1:0] src_buf_1;
            reg [1:0] src_count; // 0, 1, 2
            
            // Destination Domain Registers
            reg [WIDTH-1:0] dst_buf_0;
            reg [WIDTH-1:0] dst_buf_1;
            reg [1:0] dst_count; // 0, 1, 2
            
            // We need to synchronize the counts.
            // Actually, the simplest safe way for a small buffer is:
            // Store data in the source domain registers.
            // Read data from the source domain registers in the destination domain.
            // This avoids cross-clock domain data hazards entirely.
            
            // Source Domain Logic
            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    src_count <= 2'b00;
                    src_buf_0 <= 0;
                    src_buf_1 <= 0;
                end else begin
                    // Determine if we can accept new data
                    // We can accept if src_count < 2 AND dst_ready_i is high (to make room eventually)
                    // Actually, if dst is not ready, we just wait. We don't block src_valid unless buffer is full.
                    // But if buffer is full, we must wait for dst to pop.
                    
                    // Logic:
                    // If dst_ready_i is high:
                    //   Pop data (move to dst_valid_o logic later, but here we just decrement count and shift data)
                    //   If src_valid_i is high:
                    //     Push data (increment count, write to buffer)
                    
                    // Wait, we can't pop and push in the same clock edge if we want to be strictly FIFO?
                    // Yes we can. Pop old, push new. Net change 0.
                    
                    if (dst_ready_i) begin
                        // Pop operation
                        if (src_count > 0) begin
                            if (src_count == 2) begin
                                // Move data_1 to data_0
                                src_buf_0 <= src_buf_1;
                                src_count <= 2'b01;
                            end else if (src_count == 1) begin
                                // Clear data_0
                                src_buf_0 <= 0;
                                src_count <= 2'b00;
                            end
                        end
                        
                        // Push operation (only if valid and we have space after pop)
                        if (src_valid_i) begin
                            if (src_count == 0) begin
                                src_buf_0 <= src_data_i;
                                src_count <= 2'b01;
                            end else if (src_count == 1) begin
                                src_buf_1 <= src_data_i;
                                src_count <= 2'b10;
                            end
                        end
                    end
                    
                    // If dst_ready_i is low, we cannot pop.
                    // If buffer is full (count==2), we cannot push.
                    // So src_ready_o = (src_count < 2) ? 1 : 0.
                    // But we only push if dst_ready_i is high.
                    // So:
                    // If src_count < 2:
                    //   If dst_ready_i: push.
                    //   Else: wait.
                    // If src_count == 2:
                    //   Wait for dst_ready_i to pop, then push.
                    
                    // Let's simplify:
                    // src_ready_o = (src_count < 2) && dst_ready_i;
                    // But wait, if src_count < 2 and dst_ready_i is 0, we don't push.
                    // If src_count == 2 and dst_ready_i is 1, we pop, then if src_valid, we push.
                    
                    // Revised Logic:
                    if (src_count == 2'b10) begin
                        // Full
                        if (dst_ready_i) begin
                            // Pop
                            src_buf_0 <= src_buf_1;
                            src_count <= 2'b01;
                            // Then try to push
                            if (src_valid_i) begin
                                src_buf_1 <= src_data_i;
                                src_count <= 2'b10;
                            end
                        end
                        src_ready_o <= 1'b0;
                    end else begin
                        // Not full (0 or 1)
                        if (dst_ready_i) begin
                            // Pop if needed
                            if (src_count == 2'b01) begin
                                src_buf_0 <= 0;
                                src_count <= 2'b00;
                            end else if (src_count == 2'b10) begin
                                // Should not happen here due to case above, but safety
                                src_buf_0 <= src_buf_1;
                                src_count <= 2'b01;
                            end
                            
                            // Push if valid
                            if (src_valid_i) begin
                                if (src_count == 2'b00) begin
                                    src_buf_0 <= src_data_i;
                                    src_count <= 2'b01;
                                end else if (src_count == 2'b01) begin
                                    src_buf_1 <= src_data_i;
                                    src_count <= 2'b10;
                                end
                            end
                        end else begin
                            // dst not ready, cannot push
                            src_ready_o <= 1'b0;
                        end
                    end
                end
            end
            
            // Destination Domain Logic
            // We read from src_buf registers. This is safe because we only read when we have a valid token.
            // We need to know which index to read.
            // We can maintain a local count in dst domain that mirrors src_count.
            // Or simpler: Just check the src_count registers? No, that's cross-domain.
            // We must maintain dst_count.
            
            // How to keep dst_count in sync with src_count?
            // When src pushes, it increments src_count.
            // When dst pops, it decrements dst_count.
            // They must match.
            // We can use the handshake to update dst_count.
            // When dst_ready_i is asserted, it means dst is ready to accept.
            // But dst doesn't know if src pushed or not in the same cycle.
            // Actually, the standard way:
            // dst_valid_o is driven by dst_count > 0.
            // When dst_valid_o is high and dst_ready_i is high, dst pops.
            // But how does dst know to pop? It sees dst_ready_i.
            // But src might not have pushed yet.
            // This is the tricky part of a 2-deep buffer.
            
            // Alternative Architecture:
            // Use a single register for the "head" pointer in src domain? No.
            // Let's use the "Gray Code" or "Synchronizer" approach for the count?
            // No, for a small fixed depth, we can just use the fact that the buffer is small.
            // But we need to ensure dst_count matches src_count.
            
            // Let's try a different approach:
            // Store data in BOTH domains? No, redundant.
            // Store data in SRC domain.
            // DST domain reads SRC domain data.
            // To do this safely, we need to know WHICH data to read.
            // We can use a 2-bit pointer in SRC domain (src_ptr) and DST domain (dst_ptr).
            // They must be synchronized.
            // Since depth is 2, we can just use the count.
            
            // Let's refine the logic to ensure count consistency.
            // We will use a "handshake" to update the count in the destination domain.
            // When dst_ready_i is high, dst is ready.
            // If src_valid_i is high, src pushes.
            // The transition of the count happens on the clock edge where the data moves.
            
            // Correct Logic for Count Synchronization:
            // src_count is updated on src_clk.
            // dst_count is updated on dst_clk.
            // They are coupled by the data movement.
            // When src pushes, src_count increments.
            // When dst pops, dst_count decrements.
            // The issue is: if src pushes, dst_count doesn't know immediately.
            // If dst pops, src_count doesn't know immediately.
            // This creates a race condition if we rely solely on counts.
            
            // Solution: Use the data registers themselves to determine validity.
            // In dst domain:
            // If we have data in src_buf_0 (and we know it's valid), we output it.
            // But how do we know it's valid?
            // We can use a "valid" flag in the src domain that is synchronized?
            // No, multi-bit data.
            
            // Let's go back to basics.
            // A 2-deep FIFO between two clocks.
            // We can implement this as a standard FIFO where the pointers are synchronized.
            // But since depth is 2, we can hardcode the logic.
            
            // Let's use a "Synchronizer" for the count.
            // src_count is 2 bits.
            // We create a 2-bit register in dst domain that samples src_count.
            // But sampling a 2-bit value requires 2 stages of flip-flops to be safe.
            // Given the constraint "Do not include ... vendor primitives", we can use standard FFs.
            // But we need to ensure the count is stable.
            
            // Better approach for small depth:
            // Use a "valid" bit for each slot in the buffer, synchronized across domains.
            // Slot 0: valid_0 (synced)
            // Slot 1: valid_1 (synced)
            // Data is stored in src domain.
            // dst_valid_o = valid_0 | valid_1.
            // dst_data_o = (valid_0) ? src_buf_0 : src_buf_1.
            // src_ready_o = !(valid_0 | valid_1).
            
            // How to sync valid_0 and valid_1?
            // In src domain, we set valid_0 or valid_1 based on src_count.
            // In dst domain, we sample these signals.
            // Since valid_0 and valid_1 are single bits, we can use a 2-stage synchronizer.
            
            // Implementation Plan:
            // 1. src_domain:
            //    - Stores data in src_buf_0, src_buf_1.
            //    - Generates valid_0, valid_1 (single bits).
            //    - Updates src_count (internal logic).
            // 2. dst_domain:
            //    - Samples valid_0, valid_1 using 2-stage synchronizers.
            //    - Generates dst_valid_o = sync_valid_0 | sync_valid_1.
            //    - Generates dst_data_o based on which is valid.
            //    - Updates dst_count (internal logic) to drive dst_ready_o? No, dst_ready_i is input.
            //    - Wait, dst_ready_i is input. We don't drive it.
            //    - We drive dst_valid_o.
            //    - We need to know when to pop.
            //    - Pop happens when dst_valid_o is high and dst_ready_i is high.
            //    - But we don't have a "pop" signal going back to src.
            //    - The pop is implicit: when dst_valid_o is high, the data is consumed.
            //    - But src doesn't know it's consumed until the next cycle?
            //    - This is the problem. src needs to know when to stop pushing to a slot.
            
            // Revised Plan:
            // Use a "pointer" approach with synchronization.
            // src_domain has a pointer `src_ptr` (0 or 1).
            // dst_domain has a pointer `dst_ptr` (0 or 1).
            // We synchronize `src_ptr` to dst domain and `dst_ptr` to src domain.
            // Since it's 2-deep, the pointer is 1 bit (0 for slot 0, 1 for slot 1).
            // Actually, we need to track how many items are in the buffer.
            // Let's use a 1-bit pointer for the "next write" and "next read".
            // But we need to handle the count.
            
            // Let's try the "Synchronized Count" approach again, but carefully.
            // src_count (2 bits) is updated on src_clk.
            // We create a 2-bit register in dst domain: `dst_count_sync`.
            // We update `dst_count_sync` on dst_clk by sampling `src_count`.
            // To make it safe, we use a 2-stage synchronizer for the 2-bit value.
            // Then dst_domain uses `dst_count_sync` to decide dst_valid_o and dst_data_o.
            // And src_domain uses `src_count` to decide src_ready_o.
            // But we need to ensure `src_count` and `dst_count_sync` are consistent.
            // They will be consistent if the buffer logic is correct.
            
            // Let's implement the 2-stage synchronizer for the count.
            // src_count is 2 bits.
            // dst_count_sync is 2 bits.
            
            // src_domain logic:
            // - Maintain src_count (0, 1, 2).
            // - Maintain src_buf_0, src_buf_1.
            // - src_ready_o = (src_count < 2) ? 1 : 0.
            // - On src_clk:
            //   If src_valid_i and src_count < 2 and dst_ready_i:
            //     Write data to src_buf[src_count].
            //     src_count <= src_count + 1.
            //   Else if dst_ready_i:
            //     Pop data (shift).
            //     src_count <= src_count - 1.
            
            // dst_domain logic:
            // - Maintain dst_count_sync (samples src_count).
            // - On dst_clk:
            //   Sample src_count into dst_count_sync (using 2-stage sync).
            //   dst_valid_o = (dst_count_sync > 0).
            //   dst_data_o = (dst_count_sync == 1) ? src_buf_0 : src_buf_1.
            //   Wait, we need to know which buffer to read.
            //   If dst_count_sync == 1, it means 1 item is in buffer. It must be in slot 0.
            //   If dst_count_sync == 2, it means 2 items are in buffer. Slot 0 and Slot 1.
            //   So dst_data_o = (dst_count_sync == 1) ? src_buf_0 : src_buf_1.
            //   But what if src_buf_1 is stale?
            //   We need to ensure we only read valid data.
            //   If dst_count_sync == 2, both are valid.
            //   If dst_count_sync == 1, only slot 0 is valid.
            //   If dst_count_sync == 0, neither is valid.
            
            // This looks consistent.
            // Now, how to sample src_count safely?
            // We need a 2-stage synchronizer for the 2-bit `src_count`.
            // Let's call them `sync_count_1` and `sync_count_2`.
            // `sync_count_2` is the value used in dst_domain.
            
            // Wait, there's a subtle issue.
            // If src pushes, src_count increments.
            // If dst pops, dst_count_sync doesn't change immediately.
            // So dst_valid_o might be high even if src hasn't pushed yet?
            // No, dst_valid_o is driven by dst_count_sync.
            // If src pushes, src_count goes up.
            // Eventually, dst_count_sync catches up.
            // If dst_count_sync is 0, dst_valid_o is 0.
            // If src pushes, src_count becomes 1.
            // dst_count_sync eventually becomes 1.
            // dst_valid_o becomes 1.
            // This works.
            
            // What about the pop?
            // When dst_valid_o is 1 and dst_ready_i is 1, dst consumes the data.
            // But src doesn't know it's consumed.
            // src keeps pushing until src_count == 2.
            // If src_count == 2, src stops pushing (src_ready_o = 0).
            // dst consumes, dst_count_sync becomes 1.
            // src_count is still 2.
            // src_ready_o is 0.
            // dst consumes again, dst_count_sync becomes 0.
            // src_count is still 2.
            // src_ready_o is 0.
            // This is a deadlock?
            // No, because src_count is 2, meaning 2 items are in the buffer.
            // dst consumes one, dst_count_sync becomes 1.
            // src_count is 2.
            // src_ready_o is 0.
            // dst consumes another, dst_count_sync becomes 0.
            // src_count is 2.
            // src_ready_o is 0.
            // But wait, if src_count is 2, it means 2 items are in the buffer.
            // If dst consumes both, the buffer should be empty.
            // But src_count is still 2.
            // This means src_count is not updated when dst pops.
            // We need to update src_count when dst pops.
            // But how?
            // We need a signal from dst to src indicating "I popped".
            // Or we need to update src_count based on dst activity.
            
            // This implies we need a "pop" signal from dst to src.
            // But we can't send a signal from dst to src directly without CDC.
            // We can send a "pop" signal that is synchronized.
            // Let's add a `dst_pop` signal in src domain.
            // `dst_pop` is high when dst consumes data.
            // `dst_pop` is generated in dst domain and synchronized to src domain.
            
            // Revised Plan with Pop Signal:
            // src_domain:
            //   - src_count (0, 1, 2).
            //   - src_buf_0, src_buf_1.
            //   - src_ready_o = (src_count < 2).
            //   - On src_clk:
            //     If src_valid_i and src_count < 2:
            //       Write data.
            //       src_count <= src_count + 1.
            //     If dst_pop (synced):
            //       Pop data.
            //       src_count <= src_count - 1.
            
            // dst_domain:
            //   - dst_count_sync (samples src_count).
            //   - dst_valid_o = (dst_count_sync > 0).
            //   - dst_data_o = (dst_count_sync == 1) ? src_buf_0 : src_buf_1.
            //   - On dst_clk:
            //     Sample src_count into dst_count_sync (2-stage).
            //     If dst_valid_o and dst_ready_i:
            //       Generate `dst_pop` signal (to be sent to src).
            //       But we can't send a signal back to src directly.
            //       We need to store the fact that we popped in a register that src can see.
            //       We can use a "pop" flag in dst domain that is synchronized to src.
            
            // Let's define `dst_pop_sync` in src domain.
            // In dst domain, we generate `dst_pop_req` when we pop.
            // `dst_pop_req` is a single bit.
            // We synchronize `dst_pop_req` to src domain using 2-stage synchronizer.
            // In src domain, if `dst_pop_sync` is high, we pop.
            
            // This seems robust.
            
            // Implementation Details:
            // 1. src_domain registers: src_count, src_buf_0, src_buf_1.
            // 2. dst_domain registers: dst_count_sync (2 bits), dst_pop_req (1 bit).
            // 3. Synchronizers:
            //    - src_count -> dst_count_sync (2 stages).
            //    - dst_pop_req -> dst_pop_sync (2 stages).
            
            // Wait, if we use 2 stages for src_count -> dst_count_sync, 
            // and 2 stages for dst_pop_req -> dst_pop_sync,
            // we need to ensure the logic is correct.
            
            // Let's write the code.
            
            // Source Domain
            reg [1:0] src_count;
            reg [WIDTH-1:0] src_buf_0;
            reg [WIDTH-1:0] src_buf_1;
            reg src_pop_flag; // Flag to indicate pop happened in this cycle (for sync)
            
            // Destination Domain
            reg [1:0] dst_count_sync;
            reg dst_pop_req;
            
            // Synchronizer for src_count -> dst_count_sync
            // We need 2 stages.
            reg [1:0] sync_count_1;
            reg [1:0] sync_count_2;
            
            // Synchronizer for dst_pop_req -> src_pop_flag
            // We need 2 stages.
            reg sync_pop_req_1;
            reg sync_pop_req_2;
            
            // --- Source Domain Logic ---
            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    src_count <= 2'b00;
                    src_buf_0 <= 0;
                    src_buf_1 <= 0;
                    src_pop_flag <= 1'b0;
                end else begin
                    // Check for pop request from destination
                    if (sync_pop_req_2) begin
                        // Pop data
                        if (src_count == 2'b10) begin
                            src_buf_0 <= src_buf_1;
                            src_count <= 2'b01;
                        end else if (src_count == 2'b01) begin
                            src_buf_0 <= 0;
                            src_count <= 2'b00;
                        end
                        src_pop_flag <= 1'b0; // Clear flag after processing
                    end
                    
                    // Push data
                    if (src_valid_i && src_count < 2'b10 && dst_ready_i) begin
                        if (src_count == 2'b00) begin
                            src_buf_0 <= src_data_i;
                            src_count <= 2'b01;
                        end else if (src_count == 2'b01) begin
                            src_buf_1 <= src_data_i;
                            src_count <= 2'b10;
                        end
                    end
                    
                    src_ready_o <= (src_count < 2'b10) ? 1'b1 : 1'b0;
                end
            end
            
            // --- Destination Domain Logic ---
            always @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    dst_count_sync <= 2'b00;
                    dst_pop_req <= 1'b0;
                end else begin
                    // Update sync_count_1
                    sync_count_1 <= src_count;
                    
                    // Update sync_count_2 (this is the value we use)
                    sync_count_2 <= sync_count_1;
                    
                    // Update dst_count_sync
                    dst_count_sync <= sync_count_2;
                    
                    // Determine validity
                    dst_valid_o <= (dst_count_sync > 2'b00);
                    
                    // Determine data
                    if (dst_count_sync == 2'b01) begin
                        dst_data_o <= src_buf_0;
                    end else if (dst_count_sync == 2'b10) begin
                        dst_data_o <= src_buf_1;
                    end else begin
                        dst_data_o <= 0;
                    end
                    
                    // Generate pop request if valid and ready
                    if (dst_valid_o && dst_ready_i) begin
                        dst_pop_req <= 1'b1;
                    end else begin
                        dst_pop_req <= 1'b0;
                    end
                end
            end
            
            // --- Synchronizer Logic ---
            // Synchronize dst_pop_req to src domain
            always @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    sync_pop_req_1 <= 1'b0;
                    sync_pop_req_2 <= 1'b0;
                end else begin
                    sync_pop_req_1 <= dst_pop_req;
                    sync_pop_req_2 <= sync_pop_req_1;
                end
            end
            
            // Synchronize src_count to dst domain (already done in dst logic above)
            // But we need to make sure the registers are declared correctly.
            // The logic above uses `src_count` directly in the dst always block.
            // This is safe because `src_count` is a register in src domain.
            // The dst always block samples it on dst_clk.
            // This is a standard cross-clock domain sampling.
            // However, we need to ensure `src_count` is stable.
            // Since `src_count` is updated on src_clk, it might change between dst_clk edges.
            // But we are using a 2-stage synchronizer (sync_count_1, sync_count_2) to sample it.
            // So `dst_count_sync` is the stable value.
            
            // Wait, in the dst logic above:
            // sync_count_1 <= src_count;