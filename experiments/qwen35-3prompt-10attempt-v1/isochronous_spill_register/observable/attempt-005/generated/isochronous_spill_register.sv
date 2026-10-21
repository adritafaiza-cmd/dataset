`timescale 1ns / 1ps

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

    // State encoding for the 2-deep buffer
    // IDLE: Buffer is empty, waiting for data
    // FILL1: One item stored, waiting for second
    // FILL2: Two items stored, waiting for first to be consumed
    localparam IDLE = 2'b00;
    localparam FILL1 = 2'b01;
    localparam FILL2 = 2'b10;

    reg [1:0] state_reg;
    reg [WIDTH-1:0] buffer_reg [0:1]; // 2-deep FIFO
    reg src_valid_reg;
    reg dst_valid_reg;
    reg src_ready_reg;
    reg dst_ready_reg;

    // Synchronize src_valid to dst clock domain
    reg src_valid_synced;
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_valid_synced <= 1'b0;
        else
            src_valid_synced <= src_valid_i;
    end

    // Synchronize dst_ready to src clock domain
    reg dst_ready_synced;
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_synced <= 1'b0;
        else
            dst_ready_synced <= dst_ready_i;
    end

    // State Machine Logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            state_reg <= IDLE;
        else
            case (state_reg)
                IDLE: begin
                    if (src_valid_i && dst_ready_synced)
                        state_reg <= FILL1;
                    else
                        state_reg <= IDLE;
                end
                FILL1: begin
                    if (src_valid_i && dst_ready_synced)
                        state_reg <= FILL2;
                    else
                        state_reg <= FILL1;
                end
                FILL2: begin
                    if (dst_valid_reg)
                        state_reg <= FILL1;
                    else
                        state_reg <= FILL2;
                end
                default: state_reg <= IDLE;
            endcase
    end

    // Data Storage Logic
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            buffer_reg[0] <= 0;
            buffer_reg[1] <= 0;
        end else if (state_reg === FILL1 && src_valid_i) begin
            buffer_reg[0] <= src_data_i;
        end else if (state_reg === FILL2 && src_valid_i) begin
            buffer_reg[1] <= src_data_i;
        end
    end

    // Output Logic (dst_clk domain)
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 1'b0;
            dst_data_o <= 0;
            src_ready_o <= 1'b1;
        end else begin
            // Determine if we have data to output
            // We can output if state is FILL1 or FILL2 and dst_ready is asserted
            // However, the state machine logic above handles the flow control based on dst_valid_reg
            // Here we just need to assert valid and drive data when the state machine allows it.
            
            // Re-evaluating the flow based on the state machine transitions:
            // The state machine in src domain decides when to accept.
            // The output logic in dst domain decides when to push.
            
            // Let's refine the logic to ensure strict ordering and 2-deep buffering.
            // We need to track if the buffer has data available in the dst domain.
            
            // Actually, the previous state machine logic was slightly mixed. 
            // Let's separate concerns:
            // 1. Src domain: Accept data into buffer if space exists and dst is ready (eventually).
            // 2. Dst domain: Push data from buffer if valid and dst is ready.
            
            // Corrected Approach for 2-deep buffer:
            // We need to know how many items are in the buffer from the dst perspective.
            // But since clocks are related, we can sync the "buffer full" status or count.
            
            // Let's stick to the state machine approach but ensure the output logic is clean.
            // The state machine in src_clk domain controls acceptance.
            // The output in dst_clk domain controls delivery.
            
            // To make it robust:
            // We will maintain the state in the src domain to control src_ready.
            // We will maintain a separate "output ready" state in the dst domain to control dst_valid.
            
            // Wait, the requirement is "2-deep". 
            // If we use a single state machine in src domain, we must ensure we don't overfill.
            // If we use a single state machine in dst domain, we must ensure we don't underflow.
            
            // Best practice for related clocks with small depth:
            // Use a counter or state machine in the SRC domain to track buffer occupancy.
            // Use a counter or state machine in the DST domain to track buffer occupancy.
            // Or, simpler: Since depth is fixed at 2, we can just use the state machine in SRC
            // to decide when to stop accepting, and the DST domain to decide when to push.
            
            // Let's re-implement the logic cleanly:
            // Src Domain:
            // - If buffer has < 2 items AND dst is eventually ready (we can't know future dst_ready in src),
            //   we usually wait for dst_ready to be asserted in src domain to accept.
            //   However, if we wait for dst_ready in src domain, we might starve if dst is slow but not stopped.
            //   Standard handshake: src_valid -> dst_valid.
            //   If we buffer 2 items, we can accept 2 items even if dst is not ready, provided we don't overflow.
            //   But we must not accept if dst is permanently stuck? No, we assume related clocks and eventual readiness.
            //   Constraint: "Deliver accepted data once in order".
            
            // Refined Logic:
            // Src Domain State Machine tracks how many items are currently in the buffer.
            // It accepts new data if count < 2.
            // It sets src_ready = 1 if count < 2.
            // It sets src_ready = 0 if count == 2.
            // BUT, we must also consider if the destination is ready to take the next item?
            // If we fill the buffer (2 items) and dst is not ready, we stop accepting.
            // When dst becomes ready, we push one item, decrement count, and src_ready becomes 1 again.
            
            // Dst Domain:
            // It checks if there is data in the buffer (count > 0).
            // If yes, it asserts dst_valid and drives data.
            // It sets dst_ready = 1 (always, or based on handshake? Usually dst_ready is input).
            // The dst_ready input is used by src domain.
            
            // Let's implement the State Machine in SRC domain to manage the buffer depth.
            // We need to sync the "buffer count" or "buffer full" signal to DST domain to know when to push?
            // No, the DST domain needs to know if data is available.
            // Since the buffer is in the SRC domain (logically), the DST domain needs to know the status.
            // We can sync the "buffer not empty" signal to DST domain.
            
            // Let's define:
            // src_domain_state: 0=Empty, 1=One, 2=Full
            // We need to sync this state to dst_clk to allow dst to know when to output.
            
            // Re-architecture:
            // 1. Src Domain State Machine (src_clk):
            //    - Tracks occupancy (0, 1, 2).
            //    - On src_valid & src_ready (from dst sync) & occupancy < 2:
            //      - Store data.
            //      - Increment occupancy.
            //    - src_ready_o = (occupancy < 2).
            //    - Note: We need to know if dst is ready to accept the *next* item to decide if we should fill the buffer?
            //      Actually, standard flow:
            //      If occupancy < 2, we are willing to accept. We assert src_ready.
            //      If dst is ready, it takes it.
            //      If dst is NOT ready, we keep src_ready asserted until dst is ready? 
            //      No, if we have 2 items, we stop accepting. If we have < 2, we accept.
            //      The only risk is if dst is stuck, we fill up to 2 and stop. This is correct behavior for a buffer.
            
            // 2. Dst Domain Logic (dst_clk):
            //    - Needs to know if buffer is empty or not.
            //    - We need to sync the occupancy state from src to dst.
            //    - If synced_occupancy > 0:
            //      - dst_valid_o = 1
            //      - dst_data_o = buffer_data[0] (or whatever index)
            //      - We need to decrement the count in src domain when dst takes data.
            //      - How does src know dst took data?
            //      - We need to sync dst_valid (which indicates a take) back to src?
            //      - Or simpler: The state machine in src domain waits for dst_ready to be asserted in src domain?
            //      - No, that's for 1-deep. For 2-deep, we can fill up to 2 regardless of dst_ready, 
            //        as long as we don't overflow.
            //        But we need to decrement the count when dst consumes.
            //        So we need a signal from dst to src indicating "I consumed one".
            //        Signal: dst_consumed_synced (synced dst_valid to src).
            
            // Let's refine the handshake:
            // Src Domain:
            //   state: 0, 1, 2
            //   if state < 2:
            //     src_ready = 1
            //     if src_valid:
            //       store data
            //       state++
            //   else:
            //     src_ready = 0
            //   if (dst_consumed_synced):
            //     state--
            
            // Dst Domain:
            //   if (src_state_synced > 0):
            //     dst_valid = 1
            //     dst_data = buffer[0]
            //     // We don't need to decrement here, the src domain will see dst_consumed_synced
            //     // But wait, if src_domain decrements on dst_consumed_synced, 
            //     // and dst_domain asserts valid on src_state_synced > 0,
            //     // there is a race if clocks are asynchronous? 
            //     // They are related, so minimal skew.
            //     // However, we need to ensure the buffer data is stable.
            //     // The buffer is written in src domain. Reading in dst domain requires reading the stored value.
            //     // We need to sync the buffer content or the index.
            
            // Simpler approach for 2-deep:
            // Use a counter in SRC domain for occupancy.
            // Sync occupancy to DST domain.
            // DST domain asserts valid if occupancy > 0.
            // DST domain drives data.
            // DST domain asserts a "consumed" signal (synced dst_valid) to SRC domain to decrement occupancy.
            // SRC domain writes data only if occupancy < 2.
            
            // Implementation Details:
            // 1. Src Domain State Machine (occupancy):
            //    reg [1:0] src_occupancy; // 0, 1, 2
            //    reg [WIDTH-1:0] src_buffer [0:1];
            //    Logic:
            //      if (!src_rst_ni) src_occupancy <= 0;
            //      else begin
            //         if (src_valid_i && src_ready_o && src_occupancy < 2) begin
            //             src_buffer[src_occupancy] <= src_data_i;
            //             src_occupancy <= src_occupancy + 1;
            //         end
            //         if (dst_consumed_synced) begin
            //             if (src_occupancy > 0) src_occupancy <= src_occupancy - 1;
            //         end
            //      end
            //      src_ready_o = (src_occupancy < 2);
            
            // 2. Sync src_occupancy to dst_clk:
            //    reg [1:0] dst_occupancy_synced;
            //    always @(posedge dst_clk_i or negedge dst_rst_ni) ...
            
            // 3. Dst Domain Logic:
            //    if (dst_occupancy_synced > 0) begin
            //        dst_valid_o = 1;
            //        dst_data_o = src_buffer[0]; // Wait, src_buffer is in src domain.
            //        // We cannot read src_buffer directly in dst domain without synchronization issues 
            //        // if the write happens in the same cycle as read? 
            //        // But since clocks are related, and we have a buffer, we can sync the data too.
            //        // Or, we can just sync the index and the data.
            //        // Let's sync the data as well.
            //    end
            
            // 4. Sync dst_valid to src_clk to decrement occupancy:
            //    reg dst_valid_synced;
            //    always @(posedge src_clk_i or negedge src_rst_ni) ...
            
            // 5. Sync src_buffer data to dst_clk:
            //    reg [WIDTH-1:0] dst_buffer_data [0:1];
            //    Always update dst_buffer_data when src_buffer changes?
            //    We need to know WHICH entry is valid.
            //    Since it's a 2-deep buffer, we can just sync the whole buffer content.
            //    But we need to know which one is the "head".
            //    Actually, if we sync the occupancy, we know the head is at index 0 relative to the stored data?
            //    No, the buffer is circular or linear? 
            //    Let's assume linear write, circular read or just a small FIFO.
            //    Given "2-deep", let's use a simple array where we write at `occupancy` and read at `0`.
            //    When we decrement occupancy, the new head is still at 0? 
            //    No, if we write at 0, then 1. Head is 0.
            //    If we consume 0, head becomes 1.
            //    So we need to track the read pointer too?
            //    Or, simpler: Just sync the entire buffer content and the occupancy.
            //    In dst domain: if occupancy > 0, data is at buffer[0]? 
            //    No, if we consumed one, the data moves? 
            //    Better: Use a circular buffer logic or just sync the "next data" value.
            
            // Let's simplify:
            // Src Domain:
            //   state: 0, 1, 2 (number of items)
            //   buffer[0], buffer[1]
            //   write_ptr: 0 or 1 (where to write next)
            //   read_ptr: 0 or 1 (where to read next)
            //   Initially: state=0, write_ptr=0, read_ptr=0.
            //   Write: if state < 2, write to buffer[write_ptr], state++, write_ptr = (write_ptr+1)%2.
            //   Read: if state > 0, read from buffer[read_ptr], state--, read_ptr = (read_ptr+1)%2.
            //   But we need to sync state and read_ptr to dst domain.
            
            // Revised Plan:
            // 1. Src Domain State Machine (src_clk):
            //    - Tracks `count` (0, 1, 2).
            //    - Tracks `write_idx` (0, 1).
            //    - `src_ready_o` = (count < 2).
            //    - On `src_valid_i` & `src_ready_o`:
            //        `buffer[write_idx]` = `src_data_i`
            //        `count`++
            //        `write_idx` = `write_idx` ^ 1
            //    - On `dst_consumed_synced` (synced dst_valid):
            //        if `count` > 0:
            //            `count`--
            //            `read_idx` = `read_idx` ^ 1 (Need to track read_idx too)
            
            // 2. Sync `count` and `read_idx` to dst_clk.
            // 3. Dst Domain:
            //    - If `count_synced` > 0:
            //        `dst_valid_o` = 1
            //        `dst_data_o` = `buffer[read_idx]` (Need to sync buffer content too)
            
            // 4. Sync `buffer` content to dst_clk.
            //    - We can sync the whole buffer array.
            //    - `buffer_dst[0]`, `buffer_dst[1]`.
            //    - Update on every src_clk edge where buffer changes?
            //    - Or just sync the values.
            
            // Let's implement this structure.
            
            // Signals
            reg [1:0] src_count;
            reg [1:0] src_write_idx;
            reg [1:0] src_read_idx;
            reg [WIDTH-1:0] src_buffer [0:1];
            
            // Synced signals for Dst domain
            reg [1:0] dst_count_synced;
            reg [1:0] dst_read_idx_synced;
            reg [WIDTH-1:0] dst_buffer_synced [0:1];
            
            // Synced signal for Src domain (from Dst)
            reg dst_valid_synced;
            
            // --- Src Domain Logic ---
            always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    src_count <= 0;
                    src_write_idx <= 0;
                    src_read_idx <= 0;
                    src_buffer[0] <= 0;
                    src_buffer[1] <= 0;
                end else begin
                    // Check for consumption first (to allow immediate refill if possible, though order matters)
                    // Actually, standard FIFO: Read happens, then Write. Or Write then Read?
                    // To prevent race, let's do:
                    // 1. Check if we need to consume (based on synced signal from dst)
                    // 2. Check if we need to produce (based on src_valid)
                    
                    // Note: dst_valid_synced indicates dst took the item.
                    // We should decrement count and advance read_idx.
                    
                    if (dst_valid_synced) begin
                        if (src_count > 0) begin
                            src_count <= src_count - 1;
                            src_read_idx <= src_read_idx ^ 1;
                        end
                    end
                    
                    if (src_valid_i && src_ready_o) begin
                        src_buffer[src_write_idx] <= src_data_i;
                        src_count <= src_count + 1;
                        src_write_idx <= src_write_idx ^ 1;
                    end
                end
            end
            
            // src_ready_o logic
            assign src_ready_o = (src_count < 2);
            
            // --- Sync Src State to Dst Domain ---
            always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    dst_count_synced <= 0;
                    dst_read_idx_synced <= 0;
                    dst_buffer_synced[0] <= 0;
                    dst_buffer_synced[1] <= 0;
                end else begin
                    dst_count_synced <= src_count;
                    dst_read_idx_synced <= src_read_idx;
                    dst_buffer_synced[0] <= src_buffer[0];
                    dst_buffer_synced[1] <= src_buffer[1];
                end
            end
            
            // --- Dst Domain Logic ---
            always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    dst_valid_o <= 0;
                    dst_data_o <= 0;
                    dst_ready_reg <= 1; // Always ready in dst domain? 
                    // Wait, dst_ready_i is an INPUT. We don't control it.
                    // We control dst_valid_o.
                    // The handshake is: dst_ready_i comes from consumer.
                    // We assert dst_valid_o when we have data.
                    // Consumer asserts dst_ready_i.
                    // We need to sync dst_ready_i to src domain to decrement count?
                    // Yes, `dst_valid_synced` was derived from `dst_valid_o`? 
                    // No, `dst_valid_synced` in src domain should be the signal that says "I took the data".
                    // But we don't have a "taken" signal from dst. We have `dst_valid_o` and `dst_ready_i`.
                    // The handshake is:
                    // Src: assert valid, wait for ready.
                    // Dst: assert ready, wait for valid.
                    // But here we have a buffer.
                    // Src asserts valid. Dst asserts ready.
                    // When Dst asserts ready, it means it is willing to take.
                    // But Src might not have data yet (if buffer empty).
                    // So Src asserts valid only if buffer has data.
                    // Dst asserts ready only if it can accept.
                    // The "consumption" happens when both are asserted.
                    // We need to detect the overlap in the SRC domain to decrement the count.
                    // Signal: `dst_ready_synced` (synced dst_ready_i to src).
                    // If `src_valid_i` AND `dst_ready_synced`, then we have a handshake.
                    // But wait, the buffer logic is:
                    // Src fills buffer. Src asserts valid.
                    // Dst sees valid, asserts ready.
                    // Src sees ready, asserts valid (if not already).
                    // This is getting complicated with the 2-deep buffer.
                    
                    // Let's rethink the handshake for the buffer.
                    // The buffer decouples the clocks.
                    // Src Domain:
                    //   - Manages buffer fill level.
                    //   - `src_ready_o` is asserted if buffer is not full (count < 2).
                    //   - When `src_valid_i` is high and `src_ready_o` is high, we store data.
                    //   - We DO NOT wait for dst_ready to store data, UNLESS the buffer is full.
                    //   - If buffer is full, we wait for dst to consume.
                    //   - How do we know dst consumed?
                    //     We need a signal from Dst to Src saying "I consumed one".
                    //     This signal is generated when Dst asserts `dst_ready_i` AND `dst_valid_o` is asserted?
                    //     No, `dst_valid_o` is driven by Src (via sync).
                    //     So in Dst domain:
                    //       if (dst_count_synced > 0) begin
                    //          dst_valid_o = 1;
                    //          dst_data_o = dst_buffer_synced[dst_read_idx_synced];
                    //          // We need to know if the consumer is ready.
                    //          // If consumer is ready (dst_ready_i), we can consider the item "consumed" 
                    //          // and signal back to Src.
                    //          // But we must ensure we don't signal before the handshake is complete.
                    //          // Actually, the standard way:
                    //          // Src asserts valid. Dst asserts ready.
                    //          // The event "handshake complete" is when both are high.
                    //          // We can detect this in Src domain (synced dst_ready) if Src_valid is also high.
                    //          // But Src_valid is internal to Src.
                    //          // So: In Src domain, if (src_valid_i && dst_ready_synced), then we consider the item taken?
                    //          // No, that's for 1-deep.
                    //          // For 2-deep:
                    //          // Src fills buffer. Src asserts valid.
                    //          // Dst sees valid. If Dst is ready, it takes.
                    //          // Src needs to know Dst took it to decrement count.
                    //          // We can use `dst_ready_synced` as the trigger.
                    //          // If `dst_ready_synced` is high, it means Dst is ready.
                    //          // But does Dst take immediately?
                    //          // Yes, if `dst_valid_o` is high.
                    //          // So in Src domain:
                    //          //   if (dst_ready_synced) begin
                    //          //       // This implies Dst is ready.
                    //          //       // But we need to know if Dst actually took the data.
                    //          //       // Since we are in a buffer, Dst might be ready but the data hasn't arrived yet?
                    //          //       // No, `dst_valid_o` is the signal that data is available.
                    //          //       // If `dst_valid_o` is high (driven by Src) and `dst_ready_i` is high,
                    //          //       // then the transaction is complete.
                    //          //       // We can detect this in Src domain by checking `dst_ready_synced` 
                    //          //       // AND ensuring that `dst_valid_o` was asserted?
                    //          //       // But `dst_valid_o` is an output. We can't check it in Src domain directly 
                    //          //       // unless we sync it.
                    //          //       // Let's sync `dst_valid_o` to Src domain.
                    //          //   end
                    //          //   if (dst_valid_synced && dst_ready_synced) begin
                    //          //       // Handshake complete, decrement count.
                    //          //       if (src_count > 0) { src_count--; src_read_idx ^= 1; }
                    //          //   end
                    //          // But wait, if we decrement on `dst_valid_synced && dst_ready_synced`,
                    //          // and `dst_valid_o` is driven by `src_count > 0`,
                    //          // then:
                    //          // 1. Src has data (count > 0). Src asserts valid (via sync).
                    //          // 2. Dst sees valid. Dst asserts ready.
                    //          // 3. Src sees ready (synced). Src sees valid (synced).
                    //          // 4. Src decrements count.
                    //          // This works.
                    
                    // Revised Src Domain Logic:
                    //   - `src_ready_o` = (src_count < 2).
                    //   - On `src_valid_i` & `src_ready_o`: Store data, increment count, toggle write_idx.
                    //   - On `dst_valid_synced` & `dst_ready_synced`: Decrement count, toggle read_idx.
                    
                    // Revised Dst Domain Logic:
                    //   - `dst_valid_o` = (dst_count_synced > 0).
                    //   - `dst_data_o` = dst_buffer_synced[dst_read_idx_synced].
                    
                    // This looks solid.
                    
                    // Let's implement the signals.
                    
                    // Sync dst_valid_o to src domain
                    reg dst_valid_synced_src;
                    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
                        if (!src_rst_ni)
                            dst_valid_synced_src <= 0;
                        else
                            dst_valid_synced_src <= dst_valid_o;
                    end
                    
                    // Sync dst_ready_i to src domain
                    reg dst_ready_synced_src;
                    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
                        if (!src_rst_ni)
                            dst_ready_synced_src <= 0;
                        else
                            dst_ready_synced_src <= dst_ready_i;
                    end
                    
                    // Update Src Domain Logic with the new handshake detection
                    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
                        if (!src_rst_ni) begin
                            src_count <= 0;
                            src_write_idx <= 0;
                            src_read_idx <= 0;
                            src_buffer[0] <= 0;
                            src_buffer[1] <= 0;
                        end else begin
                            // Check handshake completion first
                            if (dst_valid_synced_src && dst_ready_synced_src) begin
                                if (src_count > 0) begin
                                    src_count <= src_count - 1;
                                    src_read_idx <= src_read_idx ^ 1;
                                end
                            end
                            
                            // Check new data arrival
                            if (src_valid_i && src_ready_o) begin
                                src_buffer[src_write_idx] <= src_data_i;
                                src_count <= src_count + 1;
                                src_write_idx <= src_write_idx ^ 1;
                            end
                        end
                    end
                    
                    // Sync dst_count and dst_read_idx to dst domain
                    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
                        if (!dst_rst_ni) begin
                            dst_count_synced <= 0;
                            dst_read_idx_synced <= 0;
                            dst_buffer_synced[0] <= 0;
                            dst_buffer_synced[1] <= 0;
                        end else begin
                            dst_count_synced <= src_count;
                            dst_read_idx_synced <= src_read_idx;
                            dst_buffer_synced[0] <= src_buffer[0];
                            dst_buffer_synced[1] <= src_buffer[1];
                        end
                    end
                    
                    // Dst Domain Output Logic
                    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
                        if (!dst_rst_ni) begin
                            dst_valid_o <= 0;
                            dst_data_o <= 0;
                        end else begin
                            if (dst_count_synced > 0) begin
                                dst_valid_o <= 1;
                                dst_data_o <= dst_buffer_synced[dst_read_idx_synced];
                            end else begin
                                dst_valid_o <= 0;
                                dst_data_o <= 0;
                            end
                        end
                    end
                    
                    // src_ready_o assignment
                    assign src_ready_o = (src_count < 2);
                    
                end
            end

            // Wait, I nested the logic inside a single always block for src_clk?
            // No, I need to separate the state machine updates.
            // Let's restructure the code for clarity and correctness.
            
            // Final Structure:
            // 1. Src Domain State Machine (src_clk)
            // 2. Sync Src State to Dst (dst_clk)
            // 3. Dst Domain Output Logic (dst_clk)
            // 4. Sync Dst Handshake to Src (src_clk)
            
            // Let's write the code cleanly.
            
            // Src Domain State Machine
            always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    src_count <= 0;
                    src_write_idx <= 0;
                    src_read_idx <= 0;
                    src_buffer[0] <= 0;
                    src_buffer[1] <= 0;
                end else begin
                    // Check handshake completion (Dst took data)
                    if (dst_valid_synced_src && dst_ready_synced_src) begin
                        if (src_count > 0) begin
                            src_count <= src_count - 1;
                            src_read_idx <= src_read_idx ^ 1;
                        end
                    end
                    
                    // Check new data arrival
                    if (src_valid_i && src_ready_o) begin
                        src_buffer[src_write_idx] <= src_data_i;
                        src_count <= src_count + 1;
                        src_write_idx <= src_write_idx ^ 1;
                    end
                end
            end
            
            // Sync Src State to Dst Domain
            always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    dst_count_synced <= 0;
                    dst_read_idx_synced <= 0;
                    dst_buffer_synced[0] <= 0;
                    dst_buffer_synced[1] <= 0;
                end else begin
                    dst_count_synced <= src_count;
                    dst_read_idx_synced <= src_read_idx;
                    dst_buffer_synced[0] <= src_buffer[0];
                    dst_buffer_synced[1] <= src_buffer[1];
                end
            end
            
            // Dst Domain Output Logic
            always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
                if (!dst_rst_ni) begin
                    dst_valid_o <= 0;
                    dst_data_o <= 0;
                end else begin
                    if (dst_count_synced > 0) begin
                        dst_valid_o <= 1;
                        dst_data_o <= dst_buffer_synced[dst_read_idx_synced];
                    end else begin
                        dst_valid_o <= 0;
                        dst_data_o <= 0;
                    end
                end
            end
            
            // Sync Dst Handshake to Src Domain
            always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
                if (!src_rst_ni) begin
                    dst_valid_synced_src <= 0;
                    dst_ready_synced_src <= 0;
                end else begin
                    dst_valid_synced_src <= dst_valid_o;
                    dst_ready_synced_src <= dst_ready_i;
                end
            end
            
            // src_ready_o logic
            assign src_ready_o = (src_count < 2);

        end
    end
endmodule
