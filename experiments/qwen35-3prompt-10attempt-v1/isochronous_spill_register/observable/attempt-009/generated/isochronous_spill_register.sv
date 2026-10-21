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

    // Internal state registers for the 2-deep buffer
    // We need 2 stages to absorb short bursts of rate mismatch.
    // Stage 0: Captures data from src when src_valid is high and src_ready is asserted.
    // Stage 1: Holds data while waiting for dst to be ready.
    
    reg [WIDTH-1:0] buffer_stage0;
    reg [WIDTH-1:0] buffer_stage1;
    
    // State machine to track the flow of data
    // States:
    // IDLE: No data in buffer, waiting for src_valid.
    // CAPTURE: Data captured in stage0, waiting for stage1 to be filled or dst_ready.
    // TRANSFER: Data in stage1, dst_ready asserted, waiting for dst_valid to be deasserted (or next cycle).
    // Actually, a simpler FSM approach for a FIFO-like behavior:
    // 0: Empty
    // 1: Full (1 item in stage0)
    // 2: Full (1 item in stage1)
    // 3: Full (1 item in stage0 AND 1 item in stage1) -> This is our 2-deep buffer.
    
    reg [1:0] state;
    
    // State encoding
    // 0: EMPTY
    // 1: ONE_ITEM (in stage0)
    // 2: TWO_ITEMS (stage0 and stage1)
    
    // Cross-clock logic for src_ready_o
    // src_ready_o must be asserted when:
    // 1. We are not full (state != 2)
    // 2. src_valid_i is high (to allow capture)
    // Note: In a standard handshake, src_ready is asserted if the buffer can accept data.
    // If the buffer is full, we cannot accept, so src_ready is low.
    
    // Cross-clock logic for dst_valid_o
    // dst_valid_o is asserted when:
    // 1. We have data in stage1 (state == 2 or state == 1 depending on implementation)
    // Let's refine the state logic to be precise for a 2-deep buffer.
    
    // Revised State Logic:
    // State 0: Empty. buffer_stage0 is invalid.
    // State 1: One item in buffer_stage0. buffer_stage1 is invalid.
    // State 2: One item in buffer_stage0, one item in buffer_stage1.
    
    // Transitions:
    // From 0: If src_valid and src_ready (which is 1), move to 1.
    // From 1: 
    //    If src_valid and src_ready (and we have space? No, we have space in stage1? No, stage1 is empty).
    //    Wait, the buffer depth is 2.
    //    If state is 1 (item in stage0), we can accept another item into stage0? 
    //    No, usually a "spill buffer" implies a small FIFO.
    //    Let's assume the structure:
    //    Stage 0 receives from Src.
    //    Stage 1 receives from Stage 0.
    //    Stage 1 sends to Dst.
    //    Depth = 2 means we can hold 2 items total.
    
    // Let's redefine states based on occupancy count:
    // 0: 0 items
    // 1: 1 item (in stage0)
    // 2: 2 items (stage0 and stage1)
    
    // Logic for src_ready_o:
    // Asserted if occupancy < 2.
    
    // Logic for dst_valid_o:
    // Asserted if occupancy >= 1 AND dst_ready_i is high.
    // When dst_valid is high, we are effectively "sending" the item from stage1.
    // Once dst_ready goes low, we stop asserting dst_valid.
    
    // Implementation details:
    // We need to handle the cross-clock transfer carefully.
    // src_ready_o is driven in src_clk domain.
    // dst_valid_o is driven in dst_clk domain.
    
    // State register (in src_clk domain? No, state needs to be consistent with the buffer content).
    // Since the buffer content moves from src to dst, the state machine should ideally run in src_clk 
    // to manage filling, and dst_clk to manage draining? 
    // Or a single state machine running in src_clk that controls both?
    // Standard practice: State machine runs in the clock that controls the "write" side (src) 
    // or a common clock if they were the same. Since they are different, we usually have:
    // - Write logic in src_clk
    // - Read logic in dst_clk
    // - State/Counters can be replicated or synchronized.
    // However, for a simple 2-deep buffer, we can maintain the state in the SRC clock domain 
    // because the "full" condition is primarily determined by the ability to write.
    // But the "empty" condition for reading depends on the read side.
    // To avoid metastability and ensure correct ordering, let's keep the state in the SRC clock domain
    // and synchronize the "read" availability carefully, OR keep state in SRC and use it to drive 
    // the handshake signals.
    
    // Actually, the most robust way for a small buffer between related clocks:
    // Maintain the state in the SRC clock domain.
    // src_ready_o = (state < 2)
    // dst_valid_o = (state >= 1) && dst_ready_i (synchronized)
    
    // Let's trace:
    // Init: state = 0.
    // Src valid, ready (state=0 < 2) -> state becomes 1. Data in stage0.
    // Src valid, ready (state=1 < 2) -> state becomes 2. Data in stage0 and stage1.
    // Src valid, ready (state=2 == 2) -> src_ready = 0. Data lost? No, we wait.
    // Dst ready -> dst_valid = 1. Data moves from stage1 to Dst.
    // Dst ready goes low -> dst_valid goes low.
    // Next cycle in SRC: If state was 2, and we successfully drained one item (how do we know?), 
    // we need to decrement state.
    
    // Problem: How does SRC domain know if Dst consumed the data?
    // We need a flag in SRC domain indicating "Data consumed".
    // Let's add a flag `data_consumed` in src_clk domain.
    
    reg data_consumed;
    
    // State encoding:
    // 0: Empty
    // 1: One item (in stage0)
    // 2: Two items (stage0 and stage1)
    
    // Next state logic (src_clk)
    // If state == 0:
    //    If src_valid and src_ready (which is 1): next_state = 1
    // If state == 1:
    //    If src_valid and src_ready (which is 1): next_state = 2
    // If state == 2:
    //    If src_valid and src_ready (which is 0): next_state = 2 (hold)
    //    If data_consumed is high (meaning we drained stage1): next_state = 1
    //    Else: next_state = 2
    
    // Wait, the `data_consumed` flag needs to be set in dst_clk domain when dst_ready is asserted 
    // and dst_valid was asserted?
    // Actually, simpler:
    // In dst_clk domain:
    // If dst_ready_i is high and we have data (state >= 1), we assert dst_valid_o.
    // We also need to signal back to src_clk that one item was removed.
    // We can use a register in dst_clk domain `ready_ack` which is set when dst_ready is high.
    // Then synchronize `ready_ack` to src_clk domain to decrement the state.
    
    // Let's refine the architecture:
    // 1. State machine in SRC_CLK: Tracks buffer depth (0, 1, 2).
    // 2. Write logic in SRC_CLK:
    //    src_ready_o = (state < 2)
    //    If src_valid && src_ready_o:
    //       If state == 0: buffer_stage0 <= src_data_i; state <= 1;
    //       If state == 1: buffer_stage1 <= buffer_stage0; buffer_stage0 <= src_data_i; state <= 2;
    //       If state == 2: do nothing (wait).
    // 3. Read logic in DST_CLK:
    //    If state (synchronized) >= 1 and dst_ready_i:
    //       dst_valid_o = 1;
    //       dst_data_o = buffer_stage1;
    //       // We need to mark that stage1 is empty so src can decrement state.
    //       // But state is in src_clk.
    //       // We can use a flag `drain_flag` in dst_clk.
    //       drain_flag = 1;
    //    Else:
    //       dst_valid_o = 0;
    //       drain_flag = 0;
    // 4. Synchronization:
    //    Synchronize `drain_flag` to src_clk domain.
    //    In src_clk:
    //       If drain_flag_synced && state == 2: state <= 1;
    //       If drain_flag_synced && state == 1: state <= 0;
    
    // This looks correct and handles the 2-deep requirement.
    
    reg [1:0] state;
    reg [WIDTH-1:0] buffer_stage0;
    reg [WIDTH-1:0] buffer_stage1;
    reg drain_flag;
    
    // Synchronize drain_flag from dst_clk to src_clk
    // We need 2 stages of synchronizer for safety, though related clocks might be close.
    // Given "related clocks", 2 stages is standard for safety.
    reg drain_flag_sync1;
    reg drain_flag_sync2;
    
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            state <= 2'b00;
            buffer_stage0 <= 8'd0;
            buffer_stage1 <= 8'd0;
            drain_flag <= 1'b0;
            drain_flag_sync1 <= 1'b0;
            drain_flag_sync2 <= 1'b0;
        end else begin
            // State Machine Logic
            if (drain_flag_sync2) begin
                if (state == 2'b10) state <= 2'b01; // 2 -> 1
                else if (state == 2'b01) state <= 2'b00; // 1 -> 0
                else state <= state;
            end
            
            // Write Logic
            if (src_valid_i && src_ready_o) begin
                if (state == 2'b00) begin
                    buffer_stage0 <= src_data_i;
                    state <= 2'b01;
                end else if (state == 2'b01) begin
                    buffer_stage1 <= buffer_stage0;
                    buffer_stage0 <= src_data_i;
                    state <= 2'b10;
                end
                // If state == 2'b10, we do nothing (buffer full)
            end
            
            // Output Logic
            src_ready_o = (state < 2'b10);
        end
    end
    
    // Read Logic in dst_clk domain
    // We need to access the state to decide if we have data.
    // Since state is in src_clk, we must synchronize it to dst_clk.
    // Alternatively, we can just check if we have data in buffer_stage1?
    // No, buffer_stage1 is in src_clk. We need to know if it's valid.
    // Validity is determined by state.
    // So we must synchronize `state` to dst_clk domain.
    
    reg [1:0] state_dst_sync1;
    reg [1:0] state_dst_sync2;
    
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            state_dst_sync1 <= 2'b00;
            state_dst_sync2 <= 2'b00;
            dst_valid_o <= 1'b0;
            dst_data_o <= 8'd0;
            drain_flag <= 1'b0;
        end else begin
            state_dst_sync1 <= state_dst_sync2;
            state_dst_sync2 <= state; // Capture current src state
            
            // Check if we have data to send
            // Data is available if state >= 1 (meaning stage1 has data)
            // Note: When state is 1, stage0 has data, stage1 is empty? 
            // Wait, my previous logic:
            // State 0: Empty
            // State 1: Stage0 has data. Stage1 is empty.
            // State 2: Stage0 has data, Stage1 has data.
            // So if state == 1, we cannot send from stage1 yet.
            // We need to move data from stage0 to stage1 in the next src cycle.
            // But the read happens in dst cycle.
            // If state is 1 in src, it means we have 1 item. It is in stage0.
            // Can we send it? No, it's in stage0. We need it in stage1.
            // So we need state >= 2 to have data in stage1?
            // Let's re-evaluate the "2-deep" definition.
            // Usually, a 2-deep buffer means it can hold 2 items.
            // Item 1 arrives -> State 1 (in stage0).
            // Item 2 arrives -> State 2 (in stage0 and stage1).
            // Dst reads -> Takes from stage1. State becomes 1.
            // Dst reads again -> Takes from stage1? No, stage1 is empty.
            // But wait, if state was 2, after one read, state becomes 1.
            // Now we have 1 item in stage0. We need to move it to stage1 before reading again?
            // Yes.
            // So, dst_valid should be asserted only if stage1 has data.
            // Stage1 has data if state == 2.
            // What if state == 1? Then stage1 is empty. We cannot output.
            // So dst_valid = (state_dst_sync2 == 2'b10) && dst_ready_i.
            
            // However, consider the case where the buffer is 1-deep.
            // If the requirement is "2-deep", it implies capacity of 2.
            // My logic holds:
            // State 0: Empty.
            // State 1: 1 item (in stage0).
            // State 2: 2 items (stage0, stage1).
            // Read operation:
            // If state == 2: Move stage1 to output. Decrement state to 1.
            // If state == 1: Cannot read (stage1 empty).
            // But what if the producer sends 1 item, then stops?
            // State is 1. Dst is ready. We cannot output.
            // Producer sends another item. State becomes 2.
            // Now Dst can output.
            // This creates a latency of 2 cycles between src_valid and dst_valid.
            // Is this acceptable? "Buffer a short rate mismatch".
            // Yes, a 2-cycle latency is typical for a 2-deep buffer.
            
            // Wait, is there a way to optimize?
            // If state is 1, we have data in stage0.
            // Can we move it to stage1 immediately in the same clock cycle? No, sequential logic.
            // So the earliest dst can see data is when state transitions to 2.
            // So dst_valid is valid only when state == 2.
            
            // Let's double check the "2-deep" requirement.
            // If I have 2 items, I can output 1, leaving 1.
            // If I have 1 item, I cannot output yet (it's in stage0).
            // This seems correct for a 2-stage pipeline buffer.
            
            if (state_dst_sync2 == 2'b10 && dst_ready_i) begin
                dst_valid_o <= 1'b1;
                dst_data_o <= buffer_stage1; // Note: buffer_stage1 is in src_clk. 
                // We need to read buffer_stage1 safely.
                // Since buffer_stage1 is updated in src_clk, and we are in dst_clk,
                // we are reading a register from a different clock domain.
                // This is a cross-clock read.
                // Is it safe?
                // buffer_stage1 is updated on posedge src_clk.
                // We read it on posedge dst_clk.
                // Since clocks are related, this is generally safe if the update happens before the read.
                // However, to be absolutely safe and professional, we should read the value 
                // that was stable.
                // But wait, if we read buffer_stage1 in dst_clk, and it was just updated in src_clk,
                // we might see the old value if the timing is tight?
                // Actually, the value in buffer_stage1 is stable between src_clk edges.
                // The only risk is if dst_clk samples exactly when src_clk updates.
                // Given "related clocks", this is usually acceptable, but let's add a safety margin.
                // We can read buffer_stage1 into a register in dst_clk domain?
                // No, that would add another stage of latency.
                // Standard practice for small buffers: Read the register directly if clocks are related 
                // and setup/hold are met.
                // However, to be strictly compliant with "professional designer" and avoid any ambiguity:
                // We can assert dst_valid, and the data is valid for one cycle.
                // The value of buffer_stage1 is the one that was written in the previous src cycle.
                // It is stable.
                
                // One correction: 
                // When state is 2, buffer_stage1 contains the older data.
                // buffer_stage0 contains the newer data.
                // We output buffer_stage1.
                // Then we decrement state to 1.
                // Next time, if state is 1, we wait for another write to make it 2.
                
                // Wait, what if the buffer is 1-deep?
                // If the requirement is "2-deep", my logic (State 0, 1, 2) is correct.
                // Capacity = 2.
                
                // Let's re-verify the "leave the destination idle after reset" requirement.
                // Reset sets state to 0. dst_valid_o is 0. Correct.
                
                // One edge case: 
                // If state is 2, we assert dst_valid.
                // If dst_ready is low, we don't assert dst_valid.
                // State remains 2.
                // Next src cycle, if src_valid, we might overwrite?
                // No, src_ready is 0 when state is 2. So src stops writing.
                // So data is preserved.
                
                // What if state is 1?
                // src_ready is 1. src writes to stage0. state becomes 2.
                // Next dst cycle, state is 2. dst_valid asserted.
                // This works.
                
                // Is it possible to have state 1 and dst ready?
                // Yes. But we can't output.
                // This is the "latency" of the buffer.
                
                // Wait, is there a scenario where we want to output immediately if there is 1 item?
                // If the buffer is 2-deep, it means it can hold 2 items.
                // If it holds 1 item, it is not full.
                // But the architecture is 2 stages.
                // Stage 0 -> Stage 1 -> Output.
                // If only 1 item is in Stage 0, it hasn't reached Stage 1 yet.
                // So it cannot be output.
                // This is correct behavior for a 2-stage pipeline.
                
                // However, sometimes "2-deep buffer" might imply a FIFO with depth 2.
                // In a FIFO, if depth is 2, and 1 item is present, you can read it.
                // But here the structure is explicitly "spill buffer" with "related clocks".
                // Usually, this implies a small FIFO implemented with registers.
                // If I implement it as a 2-stage pipeline, the latency is 2 cycles.
                // If I implement it as a true FIFO (pointer based), I can read the 1st item.
                // But pointers require more logic.
                // Given the simplicity of the interface and the "spill" nature, a 2-stage pipeline 
                // (which acts as a depth-2 buffer with 1-cycle latency per stage) is the standard interpretation 
                // for "2-deep" in high-speed interfaces unless "FIFO" is specified.
                // BUT, "2-deep" usually means capacity 2.
                // If capacity is 2, and I have 1 item, I should be able to read it.
                // My current logic requires 2 items to read.
                // Let's adjust the logic to be a true 2-deep FIFO.
                
                // True 2-deep FIFO Logic:
                // We need to track how many items are in the buffer (0, 1, 2).
                // We need to know where the "head" is.
                // Since it's small, we can just use the state as the count.
                // But we need to store the data.
                // If count = 1: Data is in stage0.
                // If count = 2: Data is in stage0 and stage1.
                // Read:
                // If count >= 1: Output stage0? Or stage1?
                // If we output stage0, then stage0 becomes empty.
                // If count was 2, stage1 still has data.
                // If count was 1, stage0 becomes empty.
                // This is a standard FIFO.
                // But the data movement is:
                // Write: stage0 <= data.
                // Read: output stage0.
                // Move: stage0 <= stage1; stage1 <= 0;
                // This is complex to implement with just 2 registers without pointers.
                // With pointers:
                // write_ptr, read_ptr.
                // Depth 2.
                // This is overkill for a simple "spill buffer" request which often implies a pipeline buffer.
                // However, the prompt says "Buffer a short rate mismatch".
                // A pipeline buffer (2 stages) absorbs 1 cycle of mismatch? 
                // No, a 2-stage pipeline absorbs 1 cycle of mismatch if the producer is faster by 1 cycle?
                // If producer is 2x faster, a 2-stage pipeline might overflow if not managed.
                // But with a full check (state < 2), it prevents overflow.
                // And it ensures ordering.
                // The "2-deep" likely refers to the depth of the FIFO.
                // If I use the pipeline approach (Stage0 -> Stage1 -> Out), the effective depth is 2.
                // But the read latency is 2 cycles.
                // Is this what is wanted?
                // "Deliver accepted data once in order".
                // Yes, FIFO order is preserved.
                // "Leave the destination idle after reset".
                // Yes.
                
                // Let's reconsider the "True FIFO" vs "Pipeline".
                // In a pipeline:
                // Cycle 1: Src writes A. State=1. (A in S0)
                // Cycle 2: Src writes B. State=2. (A in S0, B in S1).
                // Cycle 3: Dst reads. Takes B (from S1). State=1. (A in S0).
                // Cycle 4: Dst reads. Takes A (from S0? No, A is in S0, but we need it in S1).
                // In my pipeline logic, A is stuck in S0 until B is read?
                // No, in my pipeline logic:
                // When state=2, we read S1.
                // When state=1, we cannot read.
                // So A is stuck in S0 until B is read?
                // No, if B is read, state becomes 1.
                // Now we have A in S0.
                // Can we read A?
                // My logic says: if state==1, cannot read.
                // So A is stuck in S0 forever?
                // This is a bug in the pipeline logic for a FIFO.
                // In a pipeline, after reading B, we should move A to S1.
                // But we can only move data on the write clock (src_clk).
                // So A moves to S1 in the next src_clk cycle.
                // Then in the next dst_clk cycle, we can read A.
                // So the latency is 2 cycles.
                // This is acceptable for a "spill buffer".
                
                // However, to make it a true 2-deep FIFO where you can read immediately if data is present:
                // We would need to move data from S0 to S1 on the read clock?
                // That requires a read clock domain register for S0.
                // Let's try to implement a true 2-deep FIFO.
                
                // True 2-deep FIFO Implementation:
                // We need 2 storage locations.
                // Let's call them `fifo_data[0]` and `fifo_data[1]`.
                // We need a `read_ptr` and `write_ptr`.
                // Since depth is 2, pointers can be 1 bit (0 or 1).
                // But we need to handle the "full" and "empty" conditions.
                // Empty: read_ptr == write_ptr.
                // Full: (write_ptr + 1) % 2 == read_ptr.
                
                // Write logic (src_clk):
                // If not full:
                //   fifo_data[write_ptr] <= src_data_i;
                //   write_ptr <= (write_ptr + 1) % 2;
                //   src_ready_o = 1;
                // Else:
                //   src_ready_o = 0;
                
                // Read logic (dst_clk):
                // If not empty:
                //   dst_valid_o = 1;
                //   dst_data_o = fifo_data[read_ptr];
                //   read_ptr <= (read_ptr + 1) % 2;
                //   // Note: We need to ensure we don't read stale data.
                //   // Also, we need to handle the case where write_ptr catches up to read_ptr.
                
                // This is a standard small FIFO.
                // It satisfies "2-deep", "in order", "idle after reset".
                // It handles rate mismatch by buffering up to 2 items.
                // This is superior to the pipeline approach because it allows reading the first item immediately.
                
                // Let's implement this True FIFO.
                
                // Registers:
                // reg [1:0] fifo_data[2]; // Array of 2 registers
                // reg [1:0] write_ptr;
                // reg [1:0] read_ptr;
                
                // Wait, Verilog doesn't support 2D arrays of regs easily in synthesis without instantiation.
                // Better to use separate registers:
                // reg [WIDTH-1:0] fifo_reg0;
                // reg [WIDTH-1:0] fifo_reg1;
                // reg [1:0] write_ptr;
                // reg [1:0] read_ptr;
                
                // State logic:
                // Full condition: (write_ptr == 0 && read_ptr == 1) OR (write_ptr == 1 && read_ptr == 0).
                // Empty condition: write_ptr == read_ptr.
                
                // Cross-clock synchronization:
                // write_ptr and read_ptr are in different domains.
                // We need to synchronize them to avoid metastability when checking conditions?
                // Actually, the pointers themselves don't need to be synchronized if we use them locally.
                // But we need to know if the FIFO is full/empty.
                // The "full" check is in src_clk.
                // The "empty" check is in dst_clk.
                // The pointers are updated in their respective domains.
                // This is safe.
                
                // One issue: When read_ptr increments in dst_clk, we need to make sure we don't read 
                // data that hasn't been written yet?
                // No, the FIFO logic ensures we only read what was written.
                // But we need to be careful about the "related clocks" aspect.
                // If the clocks are asynchronous, we need to synchronize the pointers to check the status 
                // of the other side?
                // No, the pointers are local to the domain.
                // src_clk domain knows write_ptr.
                // dst_clk domain knows read_ptr.
                // They don't need to see each other's pointers directly.
                // They just need to know if the buffer is full/empty.
                // Full is determined by write_ptr (local).
                // Empty is determined by read_ptr (local).
                // Wait, "Full" is determined by the relationship between write_ptr and read_ptr.
                // If write_ptr and read_ptr are in different domains, we cannot compute (write_ptr == read_ptr) 
                // reliably in one domain without synchronization.
                // Example:
                // In src_clk: write_ptr is 0. read_ptr (synchronized) is 0. -> Empty?
                // But in dst_clk, read_ptr might be 1.
                // So we cannot determine "Empty" in src_clk.
                // We can only determine "Full" in src_clk?
                // Full condition: (write_ptr == 0 && read_ptr == 1) OR (write_ptr == 1 && read_ptr == 0).
                // If we synchronize read_ptr to src_clk, we can check full.
                // Similarly, synchronize write_ptr to dst_clk to check empty.
                
                // So:
                // 1. Synchronize read_ptr to src_clk -> `read_ptr_sync`.
                //    Check Full: (write_ptr == 0 && read_ptr_sync == 1) || (write_ptr == 1 && read_ptr_sync == 0).
                // 2. Synchronize write_ptr to dst_clk -> `write_ptr_sync`.
                //    Check Empty: write_ptr_sync == read_ptr.
                
                // This is the standard way to implement a cross-clock FIFO.
                
                // Let's refine the pointers.
                // Since depth is 2, we can use 1 bit for pointers.
                // write_ptr: 0 or 1.
                // read_ptr: 0 or 1.
                
                // Data storage:
                // reg [WIDTH-1:0] fifo_data_0;
                // reg [WIDTH-1:0] fifo_data_1;
                
                // Synchronizers:
                // read_ptr_sync1, read_ptr_sync2 (src_clk)
                // write_ptr_sync1, write_ptr_sync2 (dst_clk)
                
                // Logic:
                // src_clk:
                //   if (!full) begin
                //      fifo_data[write_ptr] <= src_data_i;
                //      write_ptr <= !write_ptr;
                //      src_ready_o = 1;
                //   end else src_ready_o = 0;
                
                // dst_clk:
                //   if (!empty) begin
                //      dst_valid_o = 1;
                //      dst_data_o = fifo_data[read_ptr];
                //      read_ptr <= !read_ptr;
                //   end else dst_valid_o = 0;
                
                // This looks solid.
                
                // Wait, one detail: "Leave the destination idle after reset".
                // Reset sets read_ptr=0, write_ptr=0. Empty. dst_valid=0. Correct.
                
                // Implementation details:
                // Use 1-bit pointers.
                // Use 2-stage synchronizers for pointers.
                
                // Let's write the code.
                
                // Note: The prompt asks for "2-deep".
                // My FIFO has depth 2.
                // It buffers up to 2 items.
                // It delivers in order.
                // It handles rate mismatch.
                
                // One potential issue:
                // If the producer is much faster than the consumer, the buffer fills up (2 items).
                // Producer stops (src_ready=0).
                // Consumer drains.
                // When consumer drains one item, buffer has 1 item.
                // Producer resumes.
                // This works perfectly.
                
                // What if the consumer is faster?
                // Consumer tries to read, but buffer is empty.
                // Consumer waits (dst_valid=0).
                // Producer writes.
                // Works perfectly.
                
                // Final check on "related clocks".
                // Synchronizers are sufficient.
                
                // Let's code it.
                
                // Registers
                reg [WIDTH-1:0] fifo_data_0;
                reg [WIDTH-1:0] fifo_data_1;
                reg write_ptr;
                reg read_ptr;
                
                // Synchronizers for read_ptr (to src_clk)
                reg read_ptr_sync1;
                reg read_ptr_sync2;
                
                // Synchronizers for write_ptr (to dst_clk)
                reg write_ptr_sync1;
                reg write_ptr_sync2;
                
                // Always blocks
                // src_clk domain
                always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
                    if (!src_rst_ni) begin
                        write_ptr <= 1'b0;
                        read_ptr_sync1 <= 1'b0;
                        read_ptr_sync2 <= 1'b0;
                        fifo_data_0 <= 8'd0;
                        fifo_data_1 <= 8'd0;
                    end else begin
                        // Synchronize read_ptr
                        read_ptr_sync1 <= read_ptr_sync2;
                        read_ptr_sync2 <= read_ptr; // Capture current read_ptr
                        
                        // Check Full
                        // Full if (write_ptr == 0 && read_ptr_sync2 == 1) || (write_ptr == 1 && read_ptr_sync2 == 0)
                        // Actually, read_ptr_sync2 is the value of read_ptr at the previous src_clk edge?
                        // No, read_ptr_sync2 is the value of read_ptr at the current src_clk edge (sampled).
                        // Wait, read_ptr is in dst_clk.
                        // read_ptr_sync2 is the value of read_ptr at the current src_clk edge.
                        // So we are comparing current write_ptr with current read_ptr (synchronized).
                        // This is correct.
                        
                        reg full_flag;
                        if (write_ptr == 1'b0 && read_ptr_sync2 == 1'b1) full_flag = 1;
                        else if (write_ptr == 1'b1 && read_ptr_sync2 == 1'b0) full_flag = 1;
                        else full_flag = 0;
                        
                        if (!full_flag) begin
                            if (src_valid_i) begin
                                src_ready_o <= 1'b1;
                                if (write_ptr == 1'b0) begin
                                    fifo_data_0 <= src_data_i;
                                    write_ptr <= 1'b1;
                                end else begin
                                    fifo_data_1 <= src_data_i;
                                    write_ptr <= 1'b0