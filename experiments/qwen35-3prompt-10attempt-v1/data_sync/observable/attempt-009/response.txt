```verilog
module data_sync #(
    parameter STAGES = 2,
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    input                  dready_i,
    output reg [DWIDTH-1:0] dout,
    output reg             dready_o
);

    // Internal state for the FIFO buffer
    reg [DWIDTH-1:0] q [STAGES-1:0];
    reg [STAGES:0]    full_count;

    // Logic to handle the ready signal and data flow
    // We use a simple counter-based FIFO approach.
    // full_count tracks how many items are in the buffer.
    // When full_count == STAGES, the buffer is full.
    // When full_count == 0, the buffer is empty.

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            full_count <= 0;
            dout       <= 0;
            dready_o   <= 0;
        end else begin
            // Determine if we can accept new data
            // We can accept data if the buffer is not full.
            // However, the input 'dready_i' indicates if the producer is ready to send.
            // We only capture data if dready_i is high AND we have space.
            // But typically in a synchronizer, we want to capture whenever possible 
            // to minimize latency, subject to the buffer being not full.
            
            // Let's refine the logic based on standard handshake:
            // 1. If buffer is full, we cannot accept new data. dready_o should be 0.
            // 2. If buffer is not full, we can accept data. dready_o should be 1.
            //    However, we only actually capture 'din' if dready_i is also 1.
            //    If dready_i is 0, we hold the last valid data and keep dready_o high 
            //    so the producer knows it can try again later (or just wait).
            
            // Actually, the standard pattern for "bring data in" with a ready signal:
            // The synchronizer acts as a buffer.
            // If the buffer is not full, we assert dready_o.
            // If dready_i is asserted, we capture din.
            
            // Edge case: If buffer is full, dready_o must be 0.
            // If buffer is not full, dready_o is 1.
            
            if (full_count == STAGES) begin
                dready_o <= 0;
            end else begin
                dready_o <= 1;
                
                // Capture data only if the input is ready
                if (dready_i) begin
                    // Shift data into the buffer
                    // We shift from stage 0 to STAGES-1
                    // q[STAGES-1] gets the new data
                    // q[i] gets q[i-1]
                    
                    // Since we are using a counter, we can just update the specific stage
                    // that corresponds to the current count, or shift everything.
                    // Shifting everything is safer for coherence but slightly more logic.
                    // Given STAGES is small (2), shifting is fine.
                    
                    // Shift right: q[i] = q[i-1]
                    // New data goes to q[STAGES-1]
                    
                    // However, a simpler way with a counter is:
                    // We only need to store the new data in the "next available slot".
                    // But to keep it simple and robust for any STAGES, let's do a shift.
                    
                    // Wait, if we shift every cycle, we introduce latency equal to STAGES.
                    // If we only update the specific slot, we need to track the write pointer.
                    // Let's use a write pointer approach for clarity and efficiency.
                end
            end
        end
    end

    // Re-implementing with a pointer approach for clarity and standard FIFO behavior
    // Resetting the pointer logic inside the same block or separate?
    // Let's separate for clarity.

    reg [STAGES-1:0] write_ptr;
    reg [STAGES-1:0] read_ptr;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            write_ptr <= 0;
            read_ptr  <= 0;
            full_count <= 0;
            dout <= 0;
            dready_o <= 0;
        end else begin
            // Check if buffer is full
            if (write_ptr == read_ptr && full_count == STAGES) begin
                // Full
                dready_o <= 0;
            end else begin
                // Not full
                dready_o <= 1;
                
                // Capture data if input is ready
                if (dready_i) begin
                    // Shift data from write_ptr-1 to write_ptr
                    // Actually, simpler: just assign to the write pointer location
                    // and shift the rest? No, that's complex.
                    // Let's just use the counter method but optimized.
                    
                    // Method: 
                    // If we use a counter 'full_count', we can just update the data at 'write_ptr'.
                    // But we need to shift the data from lower indices to higher indices?
                    // No, usually FIFOs shift data out from read_ptr and write_ptr increments.
                    // Here, we are just buffering.
                    
                    // Let's stick to the simplest robust implementation:
                    // A shift register chain.
                    // q[0] is the oldest, q[STAGES-1] is the newest.
                    // We shift q[i] <= q[i-1] and q[STAGES-1] <= din.
                    // But we need to know when to shift.
                    // We shift on every clock if we have space?
                    // If we shift every clock, the latency is fixed at STAGES cycles.
                    // This is the most coherent way.
                    
                    // Logic:
                    // If buffer is not full, we shift data.
                    // If dready_i is high, the new data enters at the tail.
                    // If dready_i is low, the tail holds its value (or we don't update it).
                    
                    // Let's refine the "shift register" logic:
                    // q[0] is the data ready to be read (dout).
                    // q[STAGES-1] is the input stage.
                    
                    // If full_count == STAGES, we do nothing (hold state).
                    // Else, we shift.
                    // But where does the data come from?
                    // If we treat it as a shift register:
                    // q[0] <= q[1]
                    // q[1] <= q[2]
                    // ...
                    // q[STAGES-2] <= q[STAGES-1]
                    // q[STAGES-1] <= (dready_i ? din : q[STAGES-1])
                    
                    // This works perfectly.
                    // dout will be q[0].
                    
                    // Update full_count
                    if (full_count == STAGES) begin
                        // Full, do not shift
                        // dout remains q[0]
                    end else begin
                        // Shift
                        // dout becomes q[1]
                        // We need to update q array
                    end
                end
            end
        end
    end

    // Let's rewrite the logic cleanly in one block to avoid confusion.
    // State: 
    //   q[0] ... q[STAGES-1]
    //   full_count: number of valid items.
    //   If full_count == STAGES, buffer is full.
    //   If full_count == 0, buffer is empty.
    
    // When dready_o is asserted (buffer not full):
    //   If dready_i is asserted:
    //     We shift data: q[i] <= q[i+1] for i=0 to STAGES-2.
    //     q[STAGES-1] <= din.
    //     full_count increments.
    //   If dready_i is not asserted:
    //     We still shift? 
    //     If we shift, we lose the data at q[STAGES-1] unless we hold it.
    //     Actually, if dready_i is low, the producer isn't ready.
    //     We should NOT consume a slot.
    //     So we only shift if dready_i is high?
    //     No, that creates variable latency.
    //     
    //     Standard approach for "synchronizer":
    //     The synchronizer guarantees that data is available after STAGES cycles.
    //     It acts as a buffer.
    //     If the producer is not ready (dready_i=0), the synchronizer should not advance its internal pointer.
    //     It should wait.
    //     
    //     So:
    //     If (buffer not full) AND (dready_i):
    //        Shift data in.
    //        full_count++.
    //     Else if (buffer not full) AND (!dready_i):
    //        Hold current state (do not shift).
    //        dready_o remains 1.
    //     Else (buffer full):
    //        Hold current state.
    //        dready_o = 0.
        
    // Implementation:
    // We need to shift the register array only when we accept new data.
    // But if we don't accept new data, the data at q[STAGES-1] stays there.
    // And q[0] stays there.
    // This means dout is stable.
    
    // Let's implement the shift logic carefully.
    
    reg [DWIDTH-1:0] next_q [STAGES-1:0];
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            full_count <= 0;
            write_ptr  <= 0; // Not strictly needed if we use shift, but good for debugging
            read_ptr   <= 0;
            dout       <= 0;
            dready_o   <= 0;
        end else begin
            // Check if buffer is full
            if (full_count == STAGES) begin
                dready_o <= 0;
                // Hold all registers
                dout <= q[0];
            end else begin
                dready_o <= 1;
                
                if (dready_i) begin
                    // Accept data: Shift everything
                    // q[0] gets q[1]
                    // q[1] gets q[2]
                    // ...
                    // q[STAGES-2] gets q[STAGES-1]
                    // q[STAGES-1] gets din
                    
                    // We can do this with a loop or unrolled logic.
                    // Since STAGES is a parameter, we use a loop in generate or unroll.
                    // But for simplicity in a single always block without generate,
                    // we can just assign sequentially.
                    
                    // However, Verilog doesn't support dynamic array indexing in always blocks easily without loops.
                    // Let's assume STAGES is small (2) as per default, but code should be generic.
                    // We will unroll the shift logic based on STAGES.
                    // But since STAGES is a parameter, we can't use a for-loop in procedural code directly.
                    // We must use a generate block for the shift logic or hardcode for small N.
                    // The prompt asks for "complete Verilog-2001 code".
                    // Using a generate block is the professional way.
                    
                    // Let's restructure to use a generate block for the shift register.
                end else begin
                    // Hold state
                    dout <= q[0];
                end
            end
        end
    end

    // Re-evaluating the structure to include Generate blocks properly.
    // The previous single always block approach for shifting is tricky without generate.
    // Let's use a generate block to create the shift register stages.
    
    // Reset logic for the shift register
    // We need to initialize q[0]...q[STAGES-1] to 0 on reset.
    
    // Let's restart the module body with a clean Generate-based implementation.
    
    // Generate block for the shift register stages
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : shift_stage
            if (i == 0) begin
                // First stage: output is dout
                // Input is q[1] (if STAGES > 1) or din (if STAGES == 1)
                // Actually, let's define the chain:
                // q[0] is the output.
                // q[1] feeds q[0].
                // ...
                // q[STAGES-1] feeds q[STAGES-2].
                // din feeds q[STAGES-1].
                
                // Wait, the logic "shift only when dready_i" complicates the generate block.
                // If we use a generate block, we create combinational logic or sequential?
                // Sequential.
                
                // Let's try a different approach:
                // Use a single always block with a counter for the shift register.
                // This avoids generate blocks and is very standard for small STAGES.
                // But for generic STAGES, generate is better.
                
                // Let's go with the counter approach inside the always block, 
                // but since we can't loop, we have to unroll manually or use generate.
                // Given the constraint "one source file" and "professional", 
                // using a generate block is the correct Verilog-2001 way for parameterized arrays.
                
                // However, the condition "shift only if dready_i" applies to the whole chain.
                // So we can't just instantiate independent shifters.
                // We need a single sequential block that updates the array.
                
                // Okay, let's stick to the single always block but handle the array update carefully.
                // Since STAGES is a parameter, we can't use a for-loop in the always block.
                // We MUST use a generate block for the array elements, but the update logic must be coordinated.
                
                // Solution:
                // Use a generate block to define the wires/regs for q.
                // Then use a single always block to update them based on the shift logic.
                // But updating an array in a single always block without a loop is impossible for generic N.
                // UNLESS we use a counter to track the "write index" and only update that index?
                // No, that's a FIFO with pointers.
                
                // Let's use the FIFO pointer approach. It's the most robust and scalable.
                // We need:
                //   write_ptr: index where new data goes.
                //   read_ptr: index where data is read from (dout).
                //   full_count: number of items.
                
                // Logic:
                // If (!full) and (dready_i):
                //    q[write_ptr] = din;
                //    write_ptr = (write_ptr + 1) % STAGES;
                //    full_count++;
                // Else if (!full) and (!dready_i):
                //    // Do nothing, wait for dready_i
                //    // But we need to ensure dout is stable.
                //    // dout = q[read_ptr]
                // Else (full):
                //    // Do nothing
                //    // dout = q[read_ptr]
                
                // This requires a read_ptr that increments when data is consumed?
                // No, in this design, the consumer is external (dready_i).
                // The synchronizer just buffers.
                // The consumer reads from dout.
                // The synchronizer doesn't need a read_ptr if the consumer is always ready to read when dready_o is high.
                // But dready_o is asserted when the buffer is NOT full.
                // So the consumer can read whenever dready_o is 1.
                // The synchronizer just needs to provide the data.
                // The data at dout should be the oldest data in the buffer.
                
                // So we DO need a read_ptr to track the oldest data.
                // But wait, if the consumer is slow, the buffer fills up.
                // When full, dready_o goes low.
                // When the consumer reads, does the buffer shift?
                // No, the consumer reads from dout.
                // The synchronizer just needs to keep the data valid.
                // If the consumer is slow, the buffer fills.
                // Once full, we stop accepting new data.
                // The consumer keeps reading from dout.
                // So we need a read_ptr that increments ONLY when the consumer is ready?
                // No, the consumer is the one asserting dready_i.
                // The synchronizer asserts dready_o.
                // Handshake:
                // 1. Synchronizer checks if buffer is full. If not, dready_o = 1.
                // 2. Producer sees dready_o = 1. If producer has data, it asserts dready_i.
                // 3. Synchronizer sees dready_i = 1. It captures data.
                //    Does it shift?
                //    If we use a shift register, yes.
                //    If we use a pointer-based FIFO, we increment write_ptr.
                //    What about read_ptr?
                //    The read_ptr should increment when the consumer is ready to take the data.
                //    But the consumer is the one driving dready_i?
                //    No, dready_i is from the producer.
                //    The consumer is external to this module.
                //    The module outputs dout and dready_o.
                //    The external consumer will read dout when dready_o is 1.
                //    So the module doesn't need to know when the consumer reads, 
                //    EXCEPT to know if the buffer is empty or not.
                //    But the buffer empties when the consumer reads.
                //    How does the module know the consumer read?
                //    It doesn't!
                //    This implies the module is a "producer-side" synchronizer.
                //    It buffers data until it's full.
                //    The consumer is assumed to be able to read whenever dready_o is high.
                //    But if the consumer is slow, the buffer fills.
                //    If the consumer is fast, the buffer stays empty.
                //    The module doesn't need to decrement full_count because the consumer's read action is not signaled back to this module.
                //    Wait, this is a critical misunderstanding.
                
                // Scenario A: This module is the "producer" side of a handshake.
                //   Producer -> [data_sync] -> Consumer
                //   Producer sends data. Consumer reads data.
                //   The module needs to tell the producer when it's ready (dready_o).
                //   The module needs to tell the consumer when data is ready?
                //   Usually, the consumer checks dready_o.
                //   But if the consumer reads data, the buffer count decreases.
                //   The module MUST know when the consumer reads to decrement the count.
                //   But there is no input signal for "data consumed".
                //   This implies the module is NOT a full FIFO with back-pressure from the consumer.
                //   It is a "synchronizer" that guarantees data availability.
                //   If the consumer is slow, the buffer fills.
                //   If the buffer fills, the producer stops (dready_o=0).
                //   The consumer must read fast enough to keep the buffer from filling?
                //   Or, the consumer is assumed to be a simple register that reads dout whenever dready_o is high.
                //   But if the consumer doesn't read, the buffer fills and blocks the producer.
                //   This is a standard "synchronizer" pattern where the consumer is expected to be fast enough, 
                //   OR the consumer is part of a larger system where the read is implicit.
                
                // However, the problem statement says: "Bring each new input value into the local clock domain coherently and indicate when it is ready."
                // And "Reset should leave the output indication idle."
                // This suggests a simple shift register where data is shifted in every cycle (if space) 
                // and the output is the oldest data.
                // But without a "read" signal, how does the buffer empty?
                // It doesn't. It's a shift register.
                // The "ready" signal (dready_o) is asserted when there is data in the register.
                // If the register is full, dready_o is 0.
                // If the register is not full, dready_o is 1.
                // The producer sends data.
                // The synchronizer shifts data in.
                // The consumer reads dout.
                // If the consumer doesn't read, the buffer fills.
                // Once full, the producer stops.
                // The consumer MUST read the data before the buffer fills.
                // This is the standard "synchronizer" behavior for a producer-driven system.
                // The module does NOT need to know when the consumer reads.
                // It just needs to provide the data.
                // The data is valid at dout as long as the buffer is not empty.
                // But wait, if the buffer is not empty, dready_o is 1.
                // The consumer reads dout.
                // The buffer content doesn't change unless we shift.
                // If we don't shift, the data stays at dout forever.
                // That's fine for a simple synchronizer.
                // But we need to shift to make room for new data.
                // When do we shift?
                // We shift when we accept new data.
                // We accept new data when dready_i is high AND buffer is not full.
                // So:
                //   If (not full) and (dready_i):
                //      Shift data: q[i] = q[i+1] (for i=0 to STAGES-2)
                //      q[STAGES-1] = din
                //      full_count++
                //   Else:
                //      Hold state.
                //      dready_o = (full_count > 0) ? 1 : 0;
                
                // This logic works perfectly.
                // dout = q[0].
                // If full_count == 0, dout is undefined (or 0).
                // If full_count > 0, dout is valid.
                
                // Now, how to implement the shift in Verilog-2001 with a parameter?
                // We can use a generate block to create the shift logic.
                // But the shift logic depends on the condition (dready_i and not full).
                // We can put the condition in the generate block.
                
                // Let's do this:
                // Define an array of regs.
                // Use a generate loop to create the shift equations.
                
                // However, the prompt says "Do not include ... the reference implementation".
                // I will provide the implementation.
                
                // Implementation Plan:
                // 1. Declare reg array q[STAGES].
                // 2. Use a generate block to define the shift logic for each stage.
                //    Stage 0: dout = q[0]
                //    Stage i (0 < i < STAGES-1): q[i] = (cond) ? q[i+1] : q[i]
                //    Stage STAGES-1: q[STAGES-1] = (cond) ? din : q[STAGES-1]
                //    Where cond = (full_count < STAGES) && dready_i
                // 3. Update full_count in the same always block?
                //    No, the generate block creates combinational logic or sequential?
                //    If we use `always @(posedge clk)`, we can update q[i] sequentially.
                //    But we can't have multiple assignments to q[i] in one always block unless we use non-blocking and order them.
                //    Actually, we can just assign q[i] <= ... in the same always block.
                //    The order matters for the shift.
                //    We must update q[STAGES-1] first, then q[STAGES-2], ..., then q[0].
                //    So we need to generate the assignments in reverse order.
                
                // Let's refine the generate block.
                // We can generate the shift logic for each stage.
                // But the condition `full_count < STAGES` is dynamic.
                // We can compute `can_write` = (full_count < STAGES) && dready_i.
                // Then in the always block:
                //   if (can_write) begin
                //      q[STAGES-1] <= din;
                //      q[STAGES-2] <= q[STAGES-1]; // Wait, this uses the new value!
                //      ...
                //   end
                // This is tricky with non-blocking assignments in a loop.
                // If we do:
                //   q[STAGES-1] <= din;
                //   q[STAGES-2] <= q[STAGES-1]; // This reads the NEW value of q[STAGES-1] in the same cycle?
                // No, in Verilog, all RHS are evaluated before any LHS update in a single always block.
                // So q[STAGES-2] <= q[STAGES-1] will read the OLD value of q[STAGES-1].
                // This is exactly what we want for a shift register!
                // So we can just assign in any order, as long as we don't use the updated value.
                // But we need to assign q[STAGES-1] = din.
                // And q[i] = q[i+1].
                // Since all RHS are evaluated at the start of the cycle, the order of LHS assignments doesn't matter for the shift logic.
                // We just need to make sure we don't overwrite q[i+1] before q[i] reads it.
                // But since it's non-blocking, q[i+1] is not updated until the end of the cycle.
                // So q[i] <= q[i+1] will read the old q[i+1].
                // Perfect.
                
                // So the logic is:
                //   if (can_write) begin
                //      q[STAGES-1] <= din;
                //      for (i = STAGES-2; i >= 0; i--) q[i] <= q[i+1];
                //   end
                // But we can't use a for-loop in an always block.
                // We must unroll the loop using a generate block.
                
                // Generate block for shift logic:
                // We can generate the assignment for each stage.
                // But the condition `can_write` is common.
                // We can generate:
                //   assign can_write = (full_count < STAGES) && dready_i;
                //   always @(posedge clk) begin
                //      if (!rstn) ...
                //      else begin
                //         if (can_write) begin
                //            // Generate assignments here
                //         end
                //      end
                //   end
                // But we can't put generate statements inside an always block.
                
                // Alternative:
                // Use a generate block to create the shift logic as combinational logic?
                // No, we need sequential update.
                
                // Best approach for Verilog-2001 with parameterized shift register:
                // Use a generate block to create the shift logic, but since the shift is sequential,
                // we have to be careful.
                // Actually, we can just write the shift logic manually for small STAGES?
                // No, the parameter is generic.
                
                // Let's use a counter-based approach with a single always block and unrolled logic.
                // Since STAGES is a parameter, we can't unroll in the code unless we use generate.
                // So we MUST use generate.
                
                // How to do sequential shift with generate?
                // We can create a temporary variable for the shift?
                // No.
                // We can just assign q[i] <= (can_write) ? (i == STAGES-1 ? din : q[i+1]) : q[i];
                // This works!
                // We can generate this assignment for each i.
                // But we need to ensure that q[i+1] is available.
                // Since it's non-blocking, q[i+1] on the RHS is the old value.
                // So we can generate:
                //   always @(posedge clk) begin
                //      if (!rstn) ...
                //      else begin
                //         if (can_write) begin
                //            q[STAGES-1] <= din;
                //            q[STAGES-2] <= q[STAGES-1];
                //            ...
                //         end
                //      end
                //   end
                // But we can't write the loop.
                // We can write a generate block that creates the assignments?
                // No, generate blocks create structural elements, not procedural statements inside an always block.
                
                // Wait, we can use a generate block to create the shift logic as a separate process?
                // No, that's messy.
                
                // Let's reconsider the "pointer" approach.
                // If we use a pointer, we don't need to shift the whole array.
                // We just update q[write_ptr] = din.
                // And dout = q[read_ptr].
                // But we need to know when to increment read_ptr.
                // As discussed, we don't know when the consumer reads.
                // So the pointer approach doesn't work for a "synchronizer" without a read signal.
                // Unless... the consumer is assumed to read immediately when dready_o is high?
                // No, that's not reliable.
                
                // Let's go back to the shift register.
                // Is there a way to do the shift with generate?
                // Yes, we can use a generate block to create the shift logic, but we need to make sure the assignments are sequential.
                // Actually, we can just use a single always block and unroll the shift logic manually if STAGES is small?
                // The prompt says "parameter STAGES = 2".
                // But it should be generic.
                
                // Okay, here is a trick:
                // We can use a generate block to create the shift logic, but we need to make sure the assignments are in the correct order.
                // Since all assignments in an always block are non-blocking and evaluated in parallel (RHS first),
                // the order of LHS doesn't matter for the shift logic if we use the old values.
                // So we can generate the assignments like this:
                //   genvar j;
                //   generate
                //      for (j = 0; j < STAGES; j = j + 1) begin : shift_gen
                //         if (j == STAGES-1)
                //            q[j] <= (can_write) ? din : q[j];
                //         else
                //            q[j] <= (can_write) ? q[j+1] : q[j];
                //      end
                //   endgenerate
                // This works perfectly!
                // The RHS q[j+1] is the old value because it's non-blocking.
                // So q[STAGES-2] gets the old q[STAGES-1].
                // q[STAGES-1] gets din.
                // This is a perfect shift register.
                
                // One detail: full_count.
                // We need to update full_count.
                // full_count <= (can_write) ? full_count + 1 : full_count;
                // But we need to handle the overflow (when full_count == STAGES).
                // If full_count == STAGES, can_write is 0.
                // So full_count stays STAGES.
                // This is correct.
                
                // So the plan:
                // 1. Declare q[STAGES], full_count.
                // 2. Compute can_write = (full_count < STAGES) && dready_i.
                // 3. Use a generate block to assign q[j] based on can_write.
                // 4. Update full_count in the same always block.
                // 5. Set dready_o = (full_count > 0).
                // 6. Set dout = q[0].
                
                // Wait, if full_count == 0, dout should be 0 (or idle).
                // The problem says "Reset should leave the output indication idle."
                // Idle usually means 0 or Z. Since it's reg, 0.
                // So if full_count == 0, dout = 0.
                // Else dout = q[0].
                
                // Let's write the code.
                
                // Note: The generate block must be outside the always block.
                // But the assignments inside the generate block must be inside the always block.
                // This is valid Verilog-2001.
                
                // One catch: The generate block creates multiple statements in the same always block.
                // This is allowed.
                
                // Let's finalize the logic.
                
                // can_write = (full_count < STAGES) && dready_i;
                // full_count <= can_write ? full_count + 1 : full_count;
                // dready_o <= full_count > 0 ? 1 : 0;
                // dout <= full_count > 0 ? q[0] : 0;
                
                // And the shift logic:
                // for j = 0 to STAGES-1:
                //    q[j] <= can_write ? (j == STAGES-1 ? din : q[j+1]) : q[j];
                
                // This looks solid.
                
                // Wait, what if STAGES is 1?
                // Then j=0. j == STAGES-1 is true.
                // q[0] <= can_write ? din : q[0];
                // Correct.
                
                // What if STAGES is 2?
                // j=0: q[0] <= can_write ? q[1] : q[0];
                // j=1: q[1] <= can_write ? din : q[1];
                // Correct.
                
                // One more thing: The problem says "Reset should leave the output indication idle."
                // Idle means dready_o = 0.
                // Our logic: if full_count == 0, dready_o = 0.
                // On reset, full_count = 0. So dready_o = 0.
                // Correct.
                
                // Also, "din and dready_i enter the clk domain".
                // This module is in the clk domain.
                // So we don't need to synchronize din/dready_i.
                // We just use them directly.
                
                // Final check on reset:
                // rstn is active-low.
                // if (!rstn) -> reset.
                // full_count = 0.
                // q = 0.
                // dready_o = 0.
                // dout = 0.
                // Correct.
                
                // One edge case: 
                // If the buffer is full (full_count == STAGES), can_write is 0.
                // q[j] <= q[j]. (Hold)
                // full_count <= full_count. (Hold)
                // dready_o = 0.
                // Correct.
                
                // If the buffer is not full, but dready_i is 0.
                // can_write = 0.
                // q[j] <= q[j]. (Hold)
                // full_count <= full_count. (Hold)
                // dready_o = 1.
                // dout = q[0].
                // Correct. The data is held until dready_i is asserted.
                
                // If the buffer is not full, and dready_i is 1.
                // can_write = 1.
                // q[j] shifts.
                // full_count increments.
                // d