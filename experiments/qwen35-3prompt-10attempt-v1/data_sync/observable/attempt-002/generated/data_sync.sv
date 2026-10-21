```verilog
`timescale 1ns / 1ps

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

    // Internal signals for the pipeline stages
    // We use a shift register approach where data moves from stage 0 to stage STAGES-1
    // Stage 0 receives din directly.
    // Stage STAGES-1 is the final stage that drives dout.
    
    wire [DWIDTH-1:0] stage_data [0:STAGES-1];
    wire [DWIDTH-1:0] stage_next_data [0:STAGES-1];
    wire stage_ready [0:STAGES-1];
    
    // Initialize the pipeline stages
    // stage_data[i] holds the data at stage i
    // stage_next_data[i] holds the data ready to be shifted to stage i+1
    
    // Generate logic for each stage
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : stage_logic
            // Determine the source of data for this stage
            // Stage 0 gets data from din
            // Other stages get data from the previous stage's next_data
            wire [DWIDTH-1:0] src_data;
            if (i == 0) begin
                assign src_data = din;
            end else begin
                assign src_data = stage_next_data[i-1];
            end
            
            // Determine the ready signal for this stage
            // Stage 0 is ready if dready_i is high
            // Other stages are ready if the previous stage's next_data is valid (which is always true once shifted)
            // Actually, in a simple FIFO-like shift register:
            // Stage i is ready to accept data if the previous stage has data.
            // But here we are shifting data forward.
            // Let's redefine the flow:
            // din -> Stage 0 -> Stage 1 -> ... -> Stage N-1 -> dout
            // dready_i indicates the consumer is ready.
            // We need to track if the pipeline is full or if data is available at the output.
            
            // Revised Logic:
            // We will use a simple shift register.
            // stage_data[i] is the current value at stage i.
            // stage_next_data[i] is the value that will move to stage i+1 on the next clock.
            // However, we need to handle the "ready" handshake correctly.
            
            // Standard approach for this specific problem (Data Synchronizer with Handshake):
            // 1. Data enters at stage 0.
            // 2. Data shifts through stages on every clock cycle.
            // 3. The output (dout) is valid when data reaches the last stage AND the consumer is ready.
            // 4. The producer (din) should only send data when the pipeline is not "full" or when the consumer is ready?
            //    Usually, for a simple synchronizer, we assume the producer can push whenever, 
            //    but we need to ensure we don't overwrite valid data before it's consumed.
            //    
            //    Let's implement a standard "shift register with ready" logic:
            //    - Data flows from stage 0 to STAGES-1.
            //    - dready_o is asserted when data is at the last stage AND dready_i is high.
            //    - When dready_o is high, we can pull new data into stage 0.
            //    - If dready_i is low, we hold the data at the last stage (and potentially backpressure).
            
            // To implement backpressure simply:
            // We need a "valid" flag for each stage indicating if that stage has valid data.
            // Since it's a shift register, if stage i has valid data, stage i+1 will get it next cycle.
            // The only constraint is: we cannot shift new data into stage 0 if the last stage is still holding old data 
            // that hasn't been consumed yet? 
            // Actually, the standard pattern is:
            // - Shift data forward every cycle.
            // - If dready_i is high, assert dready_o and allow new data to enter stage 0.
            // - If dready_i is low, do not allow new data to enter stage 0 (hold the pipeline full).
            
            // Let's define:
            // stage_valid[i]: Is stage i currently holding valid data?
            // Initially all 0.
            // On clock edge:
            //   If stage_valid[i-1] is 1, then stage_valid[i] becomes 1 (shifted).
            //   If stage_valid[i-1] is 0, stage_valid[i] stays 0.
            //   Exception: Stage 0. It gets valid data if dready_o was asserted in the previous cycle? 
            //   No, let's simplify.
            
            // Approach:
            // 1. Shift data from stage i to i+1 every clock.
            // 2. Stage 0 receives din only if the pipeline is not "full" or if we are sure the last stage is empty?
            //    Actually, the requirement is "coherently".
            //    Let's assume the producer wants to send as soon as possible.
            //    We assert dready_o when data arrives at the last stage AND dready_i is high.
            //    When dready_o is high, we can accept new data at stage 0.
            //    If dready_i is low, we keep the data at the last stage and do not accept new data at stage 0.
            
            // Implementation details:
            // stage_data[i] stores the data.
            // stage_valid[i] stores the validity.
            
            // Stage 0:
            //   If stage_valid[0] is 0 (empty) AND dready_o_prev was high (meaning we just consumed something? No)
            //   Let's trace:
            //   Cycle T: Data arrives at last stage. dready_i is high. dready_o goes high.
            //   Cycle T+1: Consumer reads data. dready_i goes low. Producer sees dready_o high? 
            //   Wait, dready_o is the signal telling the producer "I am ready".
            //   So, if dready_o is high, the producer can send.
            //   But dready_o depends on dready_i.
            //   
            //   Correct Flow:
            //   1. Data shifts from 0 -> 1 -> ... -> N-1.
            //   2. At stage N-1, if data is present AND dready_i is high, then dready_o is high.
            //   3. If dready_o is high, we can load new data into stage 0.
            //   4. If dready_o is low (either no data at N-1 or dready_i is low), we do NOT load new data into stage 0.
            //      This prevents overwriting data that hasn't reached the output yet.
            
            // Let's refine the "load" condition for stage 0.
            // We need to know if stage 0 is "empty".
            // Since it's a shift register, if stage N-1 has data, stage 0 might also have data (if we keep pushing).
            // But we only push if dready_o is high.
            // So, if dready_o is high, it implies dready_i is high AND stage N-1 has data.
            // If stage N-1 has data, then stage 0 definitely has data (assuming we started with data).
            // This logic is slightly flawed if we want to support "empty" state.
            
            // Better Logic:
            // Use a "full" flag for the pipeline? No, it's a fixed depth shift register.
            // Let's use the standard "shift register with ready" pattern:
            // - stage_valid[i] indicates if stage i has valid data.
            // - Initially all 0.
            // - On clock:
            //   stage_valid[i] = stage_valid[i-1] (for i > 0)
            //   stage_valid[0] = (stage_valid[0] == 0) && dready_o_prev ? No.
            //   
            //   Let's try this specific logic:
            //   dready_o = (stage_valid[STAGES-1] && dready_i)
            //   If dready_o is high, we allow new data into stage 0.
            //   But we must ensure we don't overwrite valid data.
            //   If stage_valid[0] is 1, it means there is data in the pipeline.
            //   If we overwrite it, we lose it.
            //   So, we can only write to stage 0 if stage_valid[0] is 0?
            //   But if stage_valid[0] is 0, it means the pipeline is empty.
            //   If the pipeline is empty, stage_valid[STAGES-1] is 0, so dready_o is 0.
            //   So the condition "dready_o is high" implies the pipeline is NOT empty.
            //   Therefore, we can NEVER write to stage 0 if dready_o is high?
            //   That would mean we can never send new data once the pipeline is full.
            //   
            //   Correction:
            //   The standard synchronizer works like this:
            //   1. Data enters stage 0.
            //   2. Data shifts forward.
            //   3. When data reaches the last stage, if dready_i is high, we assert dready_o.
            //   4. When dready_o is asserted, the producer knows it's safe to send the NEXT piece of data.
            //   5. Crucially, when dready_o is asserted, we should shift the data out of the last stage?
            //      No, the last stage holds the data until the consumer reads it.
            //      The consumer reads it on the same cycle dready_o is high?
            //      Usually, dready_o indicates "Data is ready to be read".
            //      The producer sends new data on the NEXT cycle after dready_o is high.
            //      
            //   Let's re-evaluate the timing:
            //   Cycle T:
            //     - Data is at stage STAGES-1.
            //     - dready_i is high.
            //     - dready_o becomes high.
            //     - Consumer reads data (conceptually).
            //     - Producer sees dready_o high.
            //   Cycle T+1:
            //     - Producer sends new data to stage 0.
            //     - Data shifts: stage 0 gets new, stage 1 gets old stage 0, ..., stage STAGES-1 gets old stage STAGES-2.
            //     - The old data at stage STAGES-1 is gone? No, it shifted out?
            //     - If we shift everything, the data at STAGES-1 is lost unless we capture it.
            //     
            //   Correct Shift Register Logic for Handshake:
            //   We need to hold the data at the last stage until the consumer is ready.
            //   Once the consumer is ready (dready_i high), we assert dready_o.
            //   On the NEXT clock, we shift the data from STAGES-1 to... nowhere? Or we keep it?
            //   Actually, the standard implementation is:
            //   - Data flows 0 -> 1 -> ... -> N-1.
            //   - At stage N-1, if dready_i is high, we assert dready_o.
            //   - We do NOT shift data out of stage N-1 immediately.
            //   - We only shift data from stage i to i+1 if stage i+1 is "ready to accept"?
            //   - No, that's complex.
            //   
            //   Simplest Robust Implementation:
            //   Use a "valid" flag for each stage.
            //   stage_valid[i] = 1 if stage i has valid data.
            //   Logic:
            //     stage_valid[i] = stage_valid[i-1] (for i > 0)
            //     stage_valid[0] = (stage_valid[0] == 0) && dready_o_prev ? 
            //     Wait, if stage_valid[0] is 1, it means there is data in the pipeline.
            //     If we overwrite it, we lose it.
            //     So we can only write to stage 0 if stage_valid[0] is 0.
            //     But if stage_valid[0] is 0, then stage_valid[N-1] is 0, so dready_o is 0.
            //     So we can never write if dready_o is 0? That's a deadlock.
            //     
            //   Let's rethink the "dready_o" meaning.
            //   dready_o = 1 means "Consumer is ready to take data".
            //   Producer sends data when dready_o is 1.
            //   But the data must travel through the pipeline.
            //   If the pipeline is full, we can't send.
            //   If the pipeline is empty, we can send.
            //   How do we know if it's full?
            //   If we assume the producer sends continuously, the pipeline fills up.
            //   Once full, we wait for dready_i.
            //   When dready_i is high, we assert dready_o.
            //   On the next clock, we shift the data from the last stage to... a buffer?
            //   No, the data at the last stage is the one being read.
            //   So, on the clock where dready_o is asserted:
            //     - We keep the data at the last stage (so it's stable for the consumer).
            //     - We shift data from stage N-2 to N-1? No, that would overwrite the data we just made ready.
            //   
            //   Correct Flow for "Ready" Synchronizer:
            //   1. Data enters stage 0.
            //   2. Data shifts 0->1->...->N-1 every clock.
            //   3. At stage N-1, if dready_i is high, we assert dready_o.
            //   4. Crucially, when dready_o is asserted, we must NOT shift the data out of stage N-1 in the next cycle?
            //      Or we shift it, but we need to ensure the consumer gets it.
            //      Usually, the consumer reads on the rising edge when dready_o is high.
            //      So the data must be stable at stage N-1 during that cycle.
            //      If we shift data into stage N-1 on the rising edge, it might be unstable.
            //      So, we should shift data from N-2 to N-1 ONLY if dready_o was NOT asserted in the previous cycle?
            //      No, that's getting complicated.
            //   
            //   Let's use the standard "Shift Register with Ready" pattern found in many IP cores:
            //   - stage_valid[i] indicates if stage i has valid data.
            //   - stage_valid[i] = stage_valid[i-1] (for i > 0).
            //   - stage_valid[0] = (stage_valid[0] == 0) && dready_o_prev ? 
            //     Actually, the condition to write to stage 0 is:
            //     "Is the pipeline empty?" OR "Is the consumer ready and we just shifted the last data out?"
            //     
            //   Let's try a different perspective:
            //   We have STAGES.
            //   We want to delay the data by STAGES cycles.
            //   We want to assert dready_o when the delayed data is ready to be read.
            //   We want to accept new data only when the pipeline is not full.
            //   
            //   Algorithm:
            //   1. Shift data from stage i to i+1 every clock.
            //   2. At stage 0, we can accept new data ONLY IF stage 0 is currently empty (stage_valid[0] == 0).
            //      Wait, if stage_valid[0] is 0, then the whole pipeline is empty (since valid propagates).
            //      So if pipeline is empty, we accept new data.
            //   3. When does the pipeline become empty?
            //      When the last stage (STAGES-1) has valid data AND dready_i is high, we assert dready_o.
            //      But we don't clear the data immediately.
            //      We need to clear the data at stage STAGES-1 when dready_o is asserted?
            //      If we clear it, then stage_valid[STAGES-1] becomes 0.
            //      Then stage_valid[STAGES-2] becomes 0, ..., stage_valid[0] becomes 0.
            //      Then on the next clock, we can accept new data.
            //      
            //   Refined Algorithm:
            //   - stage_valid[i] = stage_valid[i-1] (for i > 0).
            //   - stage_valid[0] = (stage_valid[0] == 0) && dready_o_prev ? 
            //     No, let's look at the "clear" condition.
            //     We clear stage_valid[STAGES-1] when dready_i is high AND stage_valid[STAGES-1] is high.
            //     This effectively removes the data from the pipeline.
            //     Then the validity propagates backwards to 0.
            //     So on the next clock, stage_valid[0] will be 0, allowing new data.
            //   
            //   Let's verify:
            //   T0: Pipeline empty. stage_valid[0..N-1] = 0.
            //   T1: din arrives. stage_valid[0] = 1. stage_valid[1..N-1] = 0.
            //   ...
            //   T(N): Data at stage N-1. stage_valid[N-1] = 1.
            //   T(N): dready_i is high.
            //        We assert dready_o.
            //        We clear stage_valid[N-1] (because it's being consumed).
            //        Now stage_valid[N-1] = 0.
            //        Propagation: stage_valid[N-2] becomes 0, ..., stage_valid[0] becomes 0.
            //   T(N+1): stage_valid[0] is 0. We can accept new data.
            //   
            //   This works perfectly.
            //   
            //   Implementation details:
            //   - We need to store the data in stage_data[i].
            //   - We need to store the validity in stage_valid[i].
            //   - dready_o = stage_valid[STAGES-1] && dready_i.
            //   - Clear logic: If dready_o is high, set stage_valid[STAGES-1] to 0.
            //     Actually, we can just set stage_valid[STAGES-1] = stage_valid[STAGES-2] (shift) 
            //     BUT we must ensure that if dready_o is high, we don't shift the data from N-2 to N-1.
            //     Because the data at N-1 is being consumed.
            //     So, shift happens only if dready_o was NOT high in the previous cycle?
            //     No, the shift happens on the clock edge.
            //     If dready_o is high at time T, it means at time T, data is at N-1 and dready_i is high.
            //     The consumer reads it at time T.
            //     At time T+1, we want to shift the data from N-2 to N-1?
            //     No, if we shift, we lose the data that was just read?
            //     Actually, the data at N-1 is the one being read.
            //     So at T+1, we should shift the data from N-2 to N-1 to replace the consumed data?
            //     Yes.
            //     So the shift logic is:
            //       stage_data[i] = stage_data[i-1] (for i > 0)
            //       stage_valid[i] = stage_valid[i-1] (for i > 0)
            //     BUT, we must NOT shift the data from N-1 to anywhere (it's gone).
            //     And we must NOT shift data from N-2 to N-1 if the data at N-1 was consumed?
            //     Wait, if data at N-1 is consumed, we want to bring new data from N-2 to N-1.
            //     So the shift logic is always: stage[i] = stage[i-1].
            //     The only exception is stage 0.
            //     stage[0] = (stage_valid[0] == 0) ? din : stage[0];
            //     But wait, if stage_valid[0] is 1, it means there is data in the pipeline.
            //     If we overwrite it, we lose it.
            //     So we only write to stage[0] if stage_valid[0] is 0.
            //     When is stage_valid[0] 0? When the pipeline is empty.
            //     When is the pipeline empty? When stage_valid[N-1] was cleared.
            //     When is stage_valid[N-1] cleared? When dready_o was high.
            //     
            //   So the logic is:
            //     1. Calculate dready_o = stage_valid[STAGES-1] && dready_i.
            //     2. Shift data:
            //          stage_data[i] = stage_data[i-1] (for i > 0)
            //          stage_valid[i] = stage_valid[i-1] (for i > 0)
            //     3. Update stage 0:
            //          If stage_valid[0] is 0 (pipeline empty), then stage_data[0] = din, stage_valid[0] = 1.
            //          Else, keep stage_data[0] and stage_valid[0].
            //     4. Clear the last stage if consumed:
            //          If dready_o was high, then stage_valid[STAGES-1] becomes 0.
            //          But wait, if we shift stage_valid[N-2] to N-1, and dready_o was high, 
            //          then stage_valid[N-1] should be 0.
            //          So: stage_valid[N-1] = (dready_o == 0) ? stage_valid[N-2] : 0;
            //          This ensures that if we consumed the data, the last stage becomes invalid, 
            //          which propagates back to stage 0, allowing new data.
            //          
            //   Let's trace again:
            //   T: dready_o = 1 (data at N-1, dready_i=1).
            //   Next Cycle (T+1):
            //     dready_o_prev = 1.
            //     stage_valid[N-1] = 0 (because dready_o_prev was 1).
            //     stage_valid[N-2] shifts to N-1? No, stage_valid[N-1] is forced to 0.
            //     stage_valid[N-2] shifts to N-3? No, stage_valid[i] = stage_valid[i-1].
            //     So stage_valid[N-2] becomes the new stage_valid[N-1]? No.
            //     The shift is: stage_valid[i] = stage_valid[i-1].
            //     So stage_valid[N-1] gets stage_valid[N-2].
            //     But we also have the condition: if dready_o_prev was 1, then stage_valid[N-1] = 0.
            //     So: stage_valid[N-1] = (dready_o_prev == 0) ? stage_valid[N-2] : 0;
            //     This works.
            //     Then stage_valid[N-2] gets stage_valid[N-3], etc.
            //     Finally stage_valid[0] gets stage_valid[-1] (which is 0).
            //     So stage_valid[0] becomes 0.
            //     Then we check stage_valid[0] == 0 -> True.
            //     So we load din into stage_data[0] and set stage_valid[0] = 1.
            //     
            //   This logic holds.
            
            //   One detail: dready_o is an output. It depends on current stage_valid[N-1] and dready_i.
            //   The clearing logic depends on the PREVIOUS dready_o.
            //   So we need to store dready_o in a register or use a non-blocking assignment carefully.
            //   Actually, we can compute dready_o based on current state, and use that to clear the state in the same cycle?
            //   No, if we clear the state in the same cycle, the dready_o calculation for the NEXT cycle will see 0.
            //   But dready_o is the signal for the CURRENT cycle.
            //   So:
            //     wire dready_o_curr = stage_valid[STAGES-1] && dready_i;
            //     assign dready_o = dready_o_curr;
            //     
            //     // Update logic
            //     // stage_valid[N-1] = (dready_o_curr == 0) ? stage_valid[N-2] : 0;
            //     // But wait, if dready_o_curr is 1, it means we are consuming.
            //     // So we clear stage_valid[N-1] to 0.
            //     // And we shift stage_valid[N-2] to N-1? No, if we clear it, we don't shift.
            //     // Correct: stage_valid[N-1] = (dready_o_curr == 0) ? stage_valid[N-2] : 0;
            //     // This means: if we are NOT consuming, shift the validity from N-2 to N-1.
            //     // If we ARE consuming, set N-1 to 0.
            //     // This is correct.
            
            //   Wait, there is a subtle issue.
            //   If dready_o_curr is 1, we set stage_valid[N-1] = 0.
            //   But we also need to shift stage_valid[N-2] to N-1?
            //   No, if we set it to 0, we are saying "this stage is now empty".
            //   The data from N-2 will shift to N-1 in the NEXT cycle?
            //   No, the shift happens on the clock edge.
            //   If we set stage_valid[N-1] = 0, then in the NEXT cycle, stage_valid[N-2] will shift to N-1.
            //   So the logic is:
            //     stage_valid[i] = (i == STAGES-1) ? (dready_o_curr == 0 ? stage_valid[STAGES-2] : 0) : stage_valid[i-1];
            //     But wait, if dready_o_curr is 1, we set stage_valid[N-1] = 0.
            //     Then in the next cycle, stage_valid[N-2] shifts to N-1.
            //     This is correct.
            
            //   However, we need to be careful with the assignment order.
            //   We should calculate dready_o first, then update the registers.
            
            //   Let's write the code.
            
            //   Stage 0:
            //     stage_data[0] = (stage_valid[0] == 0) ? din : stage_data[0];
            //     stage_valid[0] = (stage_valid[0] == 0) ? 1'b1 : stage_valid[0];
            //     Wait, if stage_valid[0] is 0, we set it to 1.
            //     If stage_valid[0] is 1, we keep it 1.
            //     So: stage_valid[0] = (stage_valid[0] == 0) ? 1'b1 : 1'b1; -> Always 1?
            //     No, stage_valid[0] can become 0 if the pipeline empties from the back.
            //     The propagation of 0 comes from the back.
            //     So stage_valid[0] = (stage_valid[0] == 0) ? 1'b1 : stage_valid[0];
            //     This simplifies to: stage_valid[0] = 1'b1; if we are loading.
            //     But we only load if stage_valid[0] is 0.
            //     So:
            //       if (stage_valid[0] == 0) begin
            //         stage_data[0] = din;
            //         stage_valid[0] = 1'b1;
            //       end
            //     This is correct.
            
            //   Stages 1 to STAGES-1:
            //     stage_data[i] = stage_data[i-1];
            //     stage_valid[i] = (i == STAGES-1) ? (dready_o_curr == 0 ? stage_valid[STAGES-2] : 0) : stage_valid[i-1];
            //     Wait, for i < STAGES-1, stage_valid[i] = stage_valid[i-1].
            //     For i = STAGES-1, stage_valid[i] = (dready_o_curr == 0) ? stage_valid[STAGES-2] : 0;
            
            //   Let's refine the loop.
            //   We can do this in a generate block.
            
            //   One more thing: dready_o is an output.
            //   We need to make sure it's stable.
            //   dready_o = stage_valid[STAGES-1] && dready_i;
            
            //   Reset logic:
            //   rstn is active low.
            //   On reset, all stage_data and stage_valid should be 0.
            
            //   Let's implement.
            
            //   Note: We need to handle the case where STAGES is 1.
            //   If STAGES=1:
            //     stage_data[0] = (stage_valid[0] == 0) ? din : stage_data[0];
            //     stage_valid[0] = (stage_valid[0] == 0) ? 1'b1 : stage_valid[0];
            //     dready_o = stage_valid[0] && dready_i;
            //     If dready_o is 1, we clear stage_valid[0]?
            //     Logic: stage_valid[0] = (dready_o == 0) ? stage_valid[-1] (0) : 0; -> 0.
            //     So if dready_o is 1, stage_valid[0] becomes 0.
            //     Then next cycle, we can load din.
            //     This works for STAGES=1 too.
            
            //   So the general logic:
            //     For i = 0 to STAGES-1:
            //       if (i == 0) begin
            //         if (stage_valid[0] == 0) begin
            //           stage_data[0] <= din;
            //           stage_valid[0] <= 1'b1;
            //         end
            //       end else begin
            //         stage_data[i] <= stage_data[i-1];
            //         if (i == STAGES-1) begin
            //           if (dready_o == 0) begin // dready_o is calculated from current state
            //             stage_valid[i] <= stage_valid[i-1];
            //           end else begin
            //             stage_valid[i] <= 1'b0;
            //           end
            //         end else begin
            //           stage_valid[i] <= stage_valid[i-1];
            //         end
            //       end
            //     
            //   Wait, the condition for clearing stage_valid[STAGES-1] is based on dready_o.
            //   But dready_o depends on stage_valid[STAGES-1] and dready_i.
            //   If stage_valid[STAGES-1] is 1 and dready_i is 1, dready_o is 1.
            //   Then we set stage_valid[STAGES-1] to 0.
            //   This is correct.
            
            //   However, there is a race condition if we use non-blocking assignments for both dready_o and the update logic.
            //   dready_o is a wire (or reg if we assign it).
            //   Let's make dready_o a wire.
            //   wire dready_o_wire = stage_valid[STAGES-1] && dready_i;
            //   assign dready_o = dready_o_wire;
            //   
            //   Then in the update logic, we use dready_o_wire.
            
            //   Wait, if STAGES=1, i=0 is the last stage.
            //   The logic for i=0 is special (it's the input stage).
            //   The logic for i=STAGES-1 is special (it's the output stage).
            //   If STAGES=1, i=0 is both.
            //   So we need to handle i=0 separately from the "shift" logic.
            
            //   Revised Plan:
            //   1. Calculate dready_o_wire = stage_valid[STAGES-1] && dready_i.
            //   2. Update stage_valid and stage_data.
            //      For i = 0:
            //        if (stage_valid[0] == 0) begin
            //          stage_data[0] <= din;
            //          stage_valid[0] <= 1'b1;
            //        end
            //      For i = 1 to STAGES-1:
            //        stage_data[i] <= stage_data[i-1];
            //        if (i == STAGES-1) begin
            //          if (dready_o_wire == 0) begin
            //            stage_valid[i] <= stage_valid[i-1];
            //          end else begin
            //            stage_valid[i] <= 1'b0;
            //          end
            //        end else begin
            //          stage_valid[i] <= stage_valid[i-1];
            //        end
            //   
            //   This looks correct.
            
            //   Wait, what if STAGES=1?
            //   i=0:
            //     if (stage_valid[0] == 0) load din.
            //   Loop 1 to 0: doesn't run.
            //   dready_o = stage_valid[0] && dready_i.
            //   If dready_o is 1, stage_valid[0] is 1.
            //   But we never clear stage_valid[0] in the loop because the loop doesn't run.
            //   So stage_valid[0] stays 1 forever?
            //   We need to clear stage_valid[0] if dready_o is 1.
            //   So the logic for i=STAGES-1 must apply to i=0 if STAGES=1.
            //   
            //   Better structure:
            //   For i = 0 to STAGES-1:
            //     if (i == 0) begin
            //       if (stage_valid[0] == 0) begin
            //         stage_data[0] <= din;
            //         stage_valid[0] <= 1'b1;
            //       end
            //       // Check if we need to clear this stage (if it's