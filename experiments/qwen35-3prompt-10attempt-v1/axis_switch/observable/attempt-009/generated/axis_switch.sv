```verilog
`timescale 1ns/1ps

module axis_switch #
(
    parameter S_COUNT = 4,
    parameter M_COUNT = 4,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter S_ID_WIDTH = 8,
    parameter M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
    parameter M_DEST_WIDTH = 1,
    parameter S_DEST_WIDTH = M_DEST_WIDTH+$clog2(M_COUNT),
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter M_BASE = 0,
    parameter M_TOP = 0,
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    parameter UPDATE_TID = 0,
    parameter S_REG_TYPE = 0,
    parameter M_REG_TYPE = 2,
    parameter ARB_TYPE_ROUND_ROBIN = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
    input  wire                             clk,
    input  wire                             rst,
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [S_COUNT*KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    output wire [S_COUNT-1:0]               s_axis_tready,
    input  wire [S_COUNT-1:0]               s_axis_tlast,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axis_tid,
    input  wire [S_COUNT*S_DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [S_COUNT*USER_WIDTH-1:0]    s_axis_tuser,
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [M_COUNT*KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire [M_COUNT-1:0]               m_axis_tvalid,
    input  wire [M_COUNT-1:0]               m_axis_tready,
    output wire [M_COUNT-1:0]               m_axis_tlast,
    output wire [M_COUNT*M_ID_WIDTH-1:0]    m_axis_tid,
    output wire [M_COUNT*M_DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [M_COUNT*USER_WIDTH-1:0]    m_axis_tuser
);

    localparam LOG_S_COUNT = $clog2(S_COUNT);
    localparam LOG_M_COUNT = $clog2(M_COUNT);

    // State for Round Robin Arbitration
    reg [LOG_S_COUNT-1:0] arb_rr_index;
    reg [LOG_S_COUNT-1:0] arb_rr_mask; // Mask of available inputs
    reg [LOG_S_COUNT-1:0] arb_rr_next; // Next candidate index

    // Input buffers to handle backpressure and packet boundaries
    // We need to buffer at least one beat to handle ready/valid mismatches
    // and to correctly route sidebands (TID, TDEST, TUSER) and TLAST.
    // Since we route beat-by-beat based on selection, we need to store the 
    // selected input's data and metadata until it is pushed to output.
    
    // Buffer depth: 1 is sufficient if we process beat-by-beat, 
    // but to handle the case where multiple inputs are valid and we need 
    // to switch, a simple FIFO-like structure per input or a shared buffer 
    // is needed. Given the requirement to preserve packet boundaries, 
    // we will implement a simple "head" pointer for the selected input.
    // However, a more robust approach for a switch is to buffer the selected 
    // input data in a register until m_axis_tready is asserted.
    
    // Let's use a single beat buffer for the selected input.
    // If m_axis_tvalid is high but m_axis_tready is low, we hold the data.
    // If we switch inputs, we need to ensure we don't lose the current beat.
    // Strategy: 
    // 1. Arbitrate to find the winning input index (win_idx).
    // 2. If win_idx is valid and we have data ready to send:
    //    - If m_axis_tready is high, push data to output and clear buffer.
    //    - If m_axis_tready is low, hold data in buffer.
    // 3. If we switch from input A to input B while holding A's data:
    //    - We must keep holding A's data until it is sent.
    //    - The arbiter should ideally not switch if the current buffer is not empty,
    //      OR we need a deeper buffer. 
    //    - To strictly preserve packet boundaries without complex buffering logic 
    //      that might violate timing or complexity constraints in a single file,
    //      we assume the switch operates on a "store-and-forward" basis per beat 
    //      but with a 1-beat buffer to handle backpressure.
    //    - If the arbiter selects a new input while the buffer is full (holding old data),
    //      we simply ignore the new input for that cycle (or wait).
    //    - To support this, we need a "buffer_valid" flag.
    
    reg [LOG_S_COUNT-1:0] buf_idx; // Index of input currently in buffer
    reg buf_valid;                 // Buffer is full and waiting for output ready
    reg [DATA_WIDTH-1:0] buf_data;
    reg [KEEP_WIDTH-1:0] buf_keep;
    reg buf_last;
    reg [S_ID_WIDTH-1:0] buf_tid;
    reg [S_DEST_WIDTH-1:0] buf_dest;
    reg [USER_WIDTH-1:0] buf_user;

    // Output registers for the current beat being pushed
    reg [DATA_WIDTH-1:0] out_data;
    reg [KEEP_WIDTH-1:0] out_keep;
    reg out_last;
    reg [M_ID_WIDTH-1:0] out_tid;
    reg [M_DEST_WIDTH-1:0] out_dest;
    reg [USER_WIDTH-1:0] out_user;
    reg out_valid;

    // Wire declarations for inputs
    wire [S_COUNT-1:0] s_valid;
    wire [S_COUNT-1:0] s_ready;
    wire [S_COUNT-1:0] s_last;
    wire [S_COUNT-1:0] s_tid;
    wire [S_COUNT-1:0] s_dest;
    wire [S_COUNT-1:0] s_user;

    assign s_valid = s_axis_tvalid;
    assign s_ready = s_axis_tready;
    assign s_last = s_axis_tlast;
    assign s_tid = s_axis_tid;
    assign s_dest = s_axis_tdest;
    assign s_user = s_axis_tuser;

    // --- Arbitration Logic ---
    
    // Calculate mask of valid inputs
    reg [LOG_S_COUNT-1:0] valid_mask;
    genvar i;
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_valid_mask
            assign valid_mask[i] = s_valid[i];
        end
    endgenerate

    // Round Robin Logic
    // If buffer is valid, we must continue serving the buffered input until it is sent.
    // The arbiter selects the next input to fill the buffer.
    
    reg [LOG_S_COUNT-1:0] arb_candidate;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            arb_rr_index <= 0;
            arb_rr_mask <= 0;
            arb_rr_next <= 0;
        end else begin
            // Update mask based on current valid inputs
            // Note: In a real switch, we might want to consider the buffer state.
            // If buffer is full, we only care about filling it.
            // If buffer is empty, we care about any valid input.
            
            // Simple RR: cycle through inputs.
            // If buffer is valid, we are effectively "locked" to the current input 
            // until it is pushed. The arbiter should ideally not change the source 
            // until the buffer is empty, OR we accept that the new input waits.
            // To simplify: The arbiter selects the next source. If the buffer is full,
            // the selection doesn't matter until the buffer is popped.
            
            // Let's implement standard RR on the valid inputs.
            // If buffer is valid, we force the selection to be the current buffer source?
            // No, the buffer source is already selected. We just need to find the next one 
            // to fill the buffer when it becomes empty.
            
            // Actually, the simplest robust way:
            // 1. Identify all valid inputs.
            // 2. If buffer is valid, the "next" input to load is the one after the current buffer source.
            // 3. If buffer is invalid, pick the first valid input in RR order.
            
            // Let's refine:
            // We need a pointer to the "next available slot" in the RR sequence.
            // If buffer is valid, we ignore the RR sequence for selection purposes until buffer is empty?
            // No, that's not how switches work. The switch selects an input. 
            // If the output is not ready, the selected input's data stays in the switch (buffer).
            // The arbiter should continue to select the SAME input until the buffer is empty 
            // to avoid starvation or complex state.
            // So, if buf_valid, arb_rr_index = buf_idx.
            // If !buf_valid, arb_rr_index follows the RR counter.
            
            if (buf_valid) begin
                arb_rr_index <= buf_idx;
            end else begin
                // Standard Round Robin
                // Find the next valid input starting from arb_rr_index
                arb_rr_next = arb_rr_index;
                repeat (S_COUNT) begin
                    if (valid_mask[arb_rr_next]) begin
                        arb_rr_index <= arb_rr_next;
                        break;
                    end
                    arb_rr_next = arb_rr_next + 1;
                    if (arb_rr_next == S_COUNT) arb_rr_next = 0;
                end
                // If no valid input found, keep current index (or reset to 0)
                if (arb_rr_next == S_COUNT) arb_rr_index <= 0;
                else arb_rr_index <= arb_rr_next;
            end
            
            // Update global RR index for next cycle if buffer is not valid
            if (!buf_valid) begin
                arb_rr_index <= arb_rr_index + 1;
                if (arb_rr_index == S_COUNT) arb_rr_index <= 0;
            end
        end
    end

    // Determine the winning input index
    wire [LOG_S_COUNT-1:0] win_idx;
    assign win_idx = buf_valid ? buf_idx : arb_rr_index;

    // --- Buffer Logic ---
    
    // Load buffer if:
    // 1. Buffer is not valid
    // 2. Winning input is valid
    // 3. Winning input is ready (s_ready[win_idx])
    // Note: s_ready is driven by the output logic below.
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_valid <= 1'b0;
            buf_idx <= 0;
            buf_data <= 0;
            buf_keep <= 0;
            buf_last <= 1'b0;
            buf_tid <= 0;
            buf_dest <= 0;
            buf_user <= 0;
        end else begin
            if (buf_valid) begin
                // Buffer is full, wait for output to clear it
                // Do not overwrite
            end else begin
                // Try to load
                if (s_valid[win_idx] && s_ready[win_idx]) begin
                    buf_valid <= 1'b1;
                    buf_idx <= win_idx;
                    buf_data <= s_axis_tdata[win_idx * DATA_WIDTH +: DATA_WIDTH];
                    buf_keep <= s_axis_tkeep[win_idx * KEEP_WIDTH +: KEEP_WIDTH];
                    buf_last <= s_axis_tlast[win_idx];
                    buf_tid <= s_axis_tid[win_idx * S_ID_WIDTH +: S_ID_WIDTH];
                    buf_dest <= s_axis_tdest[win_idx * S_DEST_WIDTH +: S_DEST_WIDTH];
                    buf_user <= s_axis_tuser[win_idx * USER_WIDTH +: USER_WIDTH];
                end
            end
        end
    end

    // --- Output Logic ---
    
    // Determine output valid
    // Output is valid if:
    // 1. Buffer is valid
    // 2. Output is ready (m_axis_tready)
    // Note: If buffer is not valid, output cannot be valid.
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_data <= 0;
            out_keep <= 0;
            out_last <= 1'b0;
            out_tid <= 0;
            out_dest <= 0;
            out_user <= 0;
        end else begin
            if (buf_valid && m_axis_tready) begin
                // Push data from buffer to output
                out_valid <= 1'b1;
                out_data <= buf_data;
                out_keep <= buf_keep;
                out_last <= buf_last;
                out_tid <= buf_tid;
                out_dest <= buf_dest;
                out_user <= buf_user;
                
                // Clear buffer
                buf_valid <= 1'b0;
                buf_idx <= 0;
                buf_data <= 0;
                buf_keep <= 0;
                buf_last <= 1'b0;
                buf_tid <= 0;
                buf_dest <= 0;
                buf_user <= 0;
            end else begin
                out_valid <= 1'b0;
                out_data <= 0;
                out_keep <= 0;
                out_last <= 1'b0;
                out_tid <= 0;
                out_dest <= 0;
                out_user <= 0;
            end
        end
    end

    // --- Output Port Assignments ---
    
    // Data
    assign m_axis_tdata = out_valid ? out_data : 0;
    
    // Keep
    assign m_axis_tkeep = out_valid ? out_keep : 0;
    
    // Valid
    assign m_axis_tvalid = out_valid;
    
    // Ready (Input)
    assign s_axis_tready = out_valid ? m_axis_tready : 1'b0;
    // Wait, s_axis_tready should be driven by the logic above.
    // In the output logic block, we set out_valid based on m_axis_tready.
    // But s_axis_tready needs to be the signal that tells the input if it can push.
    // If out_valid is high, it means we are holding a beat and waiting for m_axis_tready.
    // So s_axis_tready should be m_axis_tready.
    // If out_valid is low, we are ready to accept new data, so s_axis_tready should be 1.
    // Correction:
    // s_axis_tready[i] = 1 if we can accept input i.
    // We can accept input i if:
    // 1. We are not currently holding a beat (buf_valid == 0)
    // 2. OR we are holding a beat but the winning input is the same as the buffered one?
    //    No, if we are holding a beat, we cannot accept a NEW beat from ANY input 
    //    because we don't have a second buffer slot.
    //    So s_axis_tready is 1 only if buf_valid == 0.
    
    // Re-evaluating s_axis_tready logic:
    // The switch has 1 beat buffer.
    // If buf_valid == 1, we are full. s_axis_tready = 0 for all inputs.
    // If buf_valid == 0, we are empty. s_axis_tready = 1 for all inputs.
    
    // Wait, the output logic sets out_valid based on m_axis_tready.
    // If m_axis_tready is 0, out_valid stays 0 (assuming we just cleared it).
    // But if we just loaded a beat, buf_valid becomes 1.
    // Then s_axis_tready becomes 0.
    // This creates a stable state: Input sees ready=0, stops driving. Buffer holds data.
    // When m_axis_tready becomes 1, output logic sets out_valid=1, pushes data, clears buffer.
    // Buffer becomes 0. s_axis_tready becomes 1. Input can drive again.
    // This logic holds.
    
    // Let's fix the s_axis_tready assignment.
    // It must be driven by the buffer state.
    // s_axis_tready[i] = !buf_valid;
    
    // However, we need to be careful with the output logic.
    // In the output logic:
    // if (buf_valid && m_axis_tready) -> push and clear.
    // This works.
    
    // But wait, what if m_axis_tready is 0?
    // Then out_valid becomes 0.
    // But buf_valid is still 1.
    // So s_axis_tready remains 0.
    // This is correct.
    
    // One edge case: What if we switch inputs while buf_valid is 1?
    // The arbiter selects a new input. But since buf_valid is 1, we don't load it.
    // We keep the old data.
    // When m_axis_tready comes, we push the old data.
    // Then buf_valid becomes 0.
    // Then we load the new data (if valid).
    // This preserves packet boundaries correctly.
    
    // So s_axis_tready is simply !buf_valid.
    // But we need to drive it per input index? No, it's the same for all inputs.
    // assign s_axis_tready = {S_COUNT{!buf_valid}};
    
    // Wait, the interface says s_axis_tready is an output wire [S_COUNT-1:0].
    // So we assign each bit.
    
    // Let's re-verify the output logic block.
    // In the always block:
    // if (buf_valid && m_axis_tready) ...
    // This implies that if m_axis_tready is 0, we do nothing.
    // But we need to ensure that if buf_valid is 1, we don't accidentally clear it 
    // if m_axis_tready is 0. The logic `if (buf_valid && m_axis_tready)` handles this.
    // If m_axis_tready is 0, the condition is false, so we go to else.
    // In else: out_valid <= 0.
    // But buf_valid is NOT cleared in the else block.
    // So buf_valid remains 1.
    // This is correct.
    
    // One detail: The output logic block sets out_valid, out_data, etc.
    // If buf_valid is 1 and m_axis_tready is 0:
    // out_valid <= 0.
    // out_data <= 0 (from else).
    // This means the output port sees 0 data.
    // This is correct for AXI Stream.
    
    // Now, let's refine the s_axis_tready assignment.
    // It should be driven by the current state of buf_valid.
    // assign s_axis_tready = {S_COUNT{!buf_valid}};
    
    // Wait, there is a potential race condition or logic error in the output block.
    // If buf_valid is 1, and m_axis_tready is 0.
    // We set out_valid = 0.
    // We do NOT clear buf_valid.
    // Next cycle: buf_valid is still 1. m_axis_tready is 0.
    // Same thing.
    // Next cycle: m_axis_tready becomes 1.
    // Condition (buf_valid && m_axis_tready) is true.
    // We push data, clear buf_valid.
    // This works perfectly.
    
    // However, we need to make sure s_axis_tready is updated correctly.
    // If buf_valid is 1, s_axis_tready is 0.
    // If buf_valid is 0, s_axis_tready is 1.
    // This is independent of m_axis_tready.
    // Correct.
    
    // Let's rewrite the output logic to be cleaner and ensure s_axis_tready is assigned correctly.
    
    // Actually, the previous logic for s_axis_tready was implicit in my thought process.
    // I need to explicitly assign it.
    
    // Revised Output Logic Block:
    // We need to handle the case where we are waiting for m_axis_tready.
    // If buf_valid is 1, we are waiting. s_axis_tready = 0.
    // If buf_valid is 0, we are ready. s_axis_tready = 1.
    
    // But wait, what if we want to support multiple beats in flight?
    // The problem statement says "single-clock AXI-Stream switch".
    // Usually, this implies a simple switch.
    // If we need to buffer more than 1 beat, we need a FIFO.
    // Given the constraints and typical "switch" implementations in such contexts,
    // a 1-beat buffer is the minimum required to handle backpressure without dropping packets.
    // If the downstream is slower than the upstream, we buffer 1 beat.
    // If the downstream is faster, we don't buffer.
    // This is sufficient for "preserving packet boundaries" as long as we don't drop beats.
    // With 1 beat buffer, we never drop.
    
    // So the logic holds.
    
    // Let's finalize the code structure.
    
    // Assignments for s_axis_tready
    // We can generate this with a loop or just assign the vector.
    // Since S_COUNT is a parameter, we can use a generate block or just assign the vector directly if we assume the width matches.
    // But to be safe and generic, let's use a generate block for s_axis_tready assignment too?
    // Or just `assign s_axis_tready = {S_COUNT{!buf_valid}};` works if the width matches.
    // The parameter S_COUNT defines the width.
    
    // Wait, one more thing: The output logic block sets `out_valid`.
    // If `buf_valid` is 1 and `m_axis_tready` is 0, `out_valid` becomes 0.
    // But `out_data` also becomes 0.
    // This means the output port is idle.
    // This is correct.
    
    // One subtle issue:
    // If `buf_valid` is 1, and `m_axis_tready` is 0.
    // `out_valid` is 0.
    // `out_data` is 0.
    // `s_axis_tready` is 0.
    // Next cycle: `m_axis_tready` is still 0.
    // `out_valid` stays 0.
    // `buf_valid` stays 1.
    // This is stable.
    
    // If `m_axis_tready` becomes 1.
    // `out_valid` becomes 1.
    // `out_data` becomes `buf_data`.
    // `buf_valid` becomes 0.
    // `s_axis_tready` becomes 1.
    // This is correct.
    
    // What if `buf_valid` is 0?
    // `s_axis_tready` is 1.
    // If `s_valid[win_idx]` and `s_ready[win_idx]` (which is 1), we load buffer.
    // `buf_valid` becomes 1.
    // `out_valid` becomes 0 (since `buf_valid` was 0 at start of cycle? No, sequential logic).
    // In the same cycle, `buf_valid` updates to 1.
    // But `out_valid` logic uses the OLD `buf_valid`?
    // In Verilog, `always @(posedge clk)` updates registers.
    // So `buf_valid` in the `if` condition is the value at the beginning of the cycle.
    // If `buf_valid` was 0, we load it.
    // Then `out_valid` logic checks `buf_valid` (which is now 1? No, it's the old value).
    // Wait, the `always` block for `out_valid` and the `always` block for `buf_valid` are separate.
    // So `buf_valid` in the `out_valid` block is the value from the previous cycle.
    // If previous cycle `buf_valid` was 0, then `out_valid` becomes 0.
    // Then in the same cycle, `buf_valid` becomes 1.
    // So `out_valid` is 0, `buf_valid` is 1.
    // `s_axis_tready` becomes 0.
    // This is correct. We loaded a beat, now we are waiting for output ready.
    
    // So the logic is sound.
    
    // Let's write the code.
    
    // Generate block for s_axis_tready
    genvar j;
    generate
        for (j = 0; j < S_COUNT; j = j + 1) begin : gen_s_ready
            assign s_axis_tready[j] = !buf_valid;
        end
    endgenerate

    // Generate block for m_axis_tdata, m_axis_tkeep, etc.
    // We need to replicate the output logic for each output port.
    // Since we have a single buffer, we can only serve one output port at a time?
    // No, the problem says "Route each stream beat to the selected output".
    // M_COUNT is the number of outputs.
    // If M_COUNT > 1, and we have only 1 buffer, we can only serve one output at a time.
    // But the interface has M_COUNT outputs.
    // If we have 1 buffer, we can only push to ONE output at a time.
    // If multiple outputs are ready, we can only serve one.
    // This implies a multiplexer at the output.
    // But the problem says "Route each stream beat to the selected output".
    // This implies the switch selects ONE input and routes it to ONE output.
    // If M_COUNT > 1, we need to decide which output to use.
    // Usually, in such switches, if M_COUNT > 1, the switch might be a "fan-out" switch?
    // No, "Route each stream beat to the selected output" implies a single destination per beat.
    // So if M_COUNT > 1, we need to select which output port to drive.
    // But the problem doesn't specify an output selection logic (like a dest filter).
    // It says "Handle competing inputs using the configured arbitration policy."
    // This refers to input arbitration.
    // What about output selection?
    // If M_COUNT > 1, and we have 1 buffer, we can only drive one output.
    // If multiple outputs are ready, we can pick any.
    // If no outputs are ready, we wait.
    // But how do we know which output to drive?
    // Maybe the switch is designed such that M_COUNT = 1?
    // Or maybe we drive all outputs? No, "selected output".
    // Let's assume we need to select one output.
    // If M_COUNT == 1, it's trivial.
    // If M_COUNT > 1, we need a policy.
    // Since no policy is specified for output selection, we might assume:
    // 1. M_COUNT is always 1.
    // 2. Or we drive the first ready output.
    // 3. Or we drive all outputs (fan-out)? But the interface says "selected output".
    // Given the ambiguity, and the fact that M_COUNT is a parameter, 
    // let's assume we need to select one output.
    // A simple policy: Select the first output (index 0) if it is ready?
    // Or select the output corresponding to the input?
    // The parameter `M_CONNECT` suggests a mapping from inputs to outputs?
    // `M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}}`
    // This looks like a matrix where M_CONNECT[output][input] = 1 means input can go to output.
    // If all are 1, any input can go to any output.
    // So we need to select an output.
    // Let's use a simple policy: Select the lowest index output that is ready.
    // If multiple are ready, pick the first one.
    // If none are ready, wait.
    
    // Wait, if we have 1 buffer, we can only serve one output.
    // If output 0 is ready and output 1 is ready, we pick output 0.
    // If output 0 is not ready, we wait for it? Or try output 1?
    // If we wait for output 0, output 1 starves.
    // Better policy: Pick the first ready output.
    // If output 0 is ready, use it.
    // If output 0 is not ready, check output 1.
    // If none are ready, wait.
    // But if output 0 becomes ready later, we switch back?
    // This is complex.
    // Alternative: If M_COUNT > 1, we might need multiple buffers?
    // But the problem says "single-clock AXI-Stream switch" and doesn't specify buffer depth.
    // Usually, a switch with M outputs needs M buffers if we want to serve all simultaneously.
    // But if we only have 1 buffer, we can only serve one.
    // Let's assume the simplest case: M_COUNT = 1.
    // But the code must handle M_COUNT > 1.
    // Let's implement a policy: Select the first ready output.
    // If multiple are ready, pick the lowest index.
    // If the selected output is not ready, we wait.
    // This might cause starvation for higher indices if lower indices are slow.
    // But without a specific policy, this is a reasonable default.
    
    // Wait, re-reading the problem: "Route each stream beat to the selected output".
    // This implies the switch selects an output.
    // How is the output selected?
    // Maybe the `M_CONNECT` parameter defines the routing?
    // If `M_CONNECT` is all 1s, any input can go to any output.
    // We need to select one.
    // Let's assume we select the first ready output.
    
    // However, there's a simpler interpretation:
    // Maybe the switch is a "fan-out" switch where one input goes to multiple outputs?
    // "Route each stream beat to the selected output" (singular).
    // So it's a single destination.
    
    // Let's implement the "First Ready Output" policy.
    // We need to find the lowest index `out_idx` such that `m_axis_tready[out_idx]` is 1.
    // If found, we drive that output.
    // If not found, we wait.
    
    // But wait, if we have 1 buffer, and we select output 0.
    // Output 0 is not ready. We wait.
    // Output 1 is ready. We still wait for output 0.
    // This is bad.
    // Better: If output 0 is not ready, try output 1.
    // But if we switch outputs, we need to ensure we don't lose the data.
    // With 1 buffer, we can only hold 1 beat.
    // So we can only serve 1 output at a time.
    // If we switch from output 0 to output 1, we lose the beat for output 0.
    // So we must stick to one output until it is served?
    // Or we need multiple buffers.
    // Given the constraints, let's assume M_COUNT = 1 for the most common case, 
    // but implement the logic to handle M_COUNT > 1 by selecting the first ready output 
    // and sticking with it until it is served?
    // No, that's not robust.
    
    // Let's reconsider the buffer.
    // If we have M outputs, we need M buffers to serve all simultaneously.
    // But the problem doesn't specify buffer depth.
    // Maybe the "switch" is just a multiplexer at the input and a demultiplexer at the output?
    // If we have 1 buffer, we can only serve 1 output.
    // If M_COUNT > 1, we might need to assume that the switch is used in a context where 
    // only one output is active, or we accept that we can only serve one at a time.
    // Let's implement the logic to select the first ready output.
    // If multiple are ready, pick the lowest index.
    // If the selected output is not ready, we wait.
    // This is a simple policy.
    
    // Wait, what if we use the `M_CONNECT` parameter to determine the output?
    // If `M_CONNECT` is all 1s, we can pick any.
    // Let's pick the first ready one.
    
    // Implementation details:
    // We need to find `out_sel`.
    // If `m_axis_tready[0]` is 1, `out_sel = 0`.
    // Else if `m_axis_tready[1]` is 1, `out_sel = 1`.
    // ...
    // If none, `out_sel` is undefined (or we don't drive anything).
    
    // But we need to handle the case where we are already serving an output.
    // If we are serving output 0, and output 0 is not ready, we wait.
    // If output 1 becomes ready, do we switch?
    // If we switch, we lose the beat for output 0.
    // So we should stick to the current output until it is served?
    // But if the current output is never ready, we starve others.
    // This is a deadlock risk.
    // To avoid deadlock, we might need to switch if the current output is not ready for N cycles?
    // Or simply, if the current output is not ready, try the next one.
    // But with 1 buffer, we can't hold the beat for both.
    // So we must drop the beat for the non-ready output.
    // This is not ideal.
    
    // Given the ambiguity, and the fact that this is a "switch", 
    // let's assume the standard behavior:
    // 1. Arbitrate inputs.
    // 2. Select an output.
    // 3. If output is ready, push.
    // 4. If output is not ready, wait.
    // For output selection, if multiple are ready, pick the lowest index.
    // If the lowest index is not ready, pick the next ready one.
    // This ensures we don't starve a ready output.
    // But if we pick output 1 (because 0 is not ready), and 0 becomes ready later, 
    // we might switch back?
    // Let's implement a simple "First Ready" policy.
    // Find the lowest index `i` where `m_axis_tready[i]` is 1.
    // If found, use it.
    // If not found, don't drive any output.
    // This is simple and avoids starvation of ready outputs.
    // If we are currently serving output 0, and 0 is not ready, we wait.
    // If 1 becomes ready, we still wait for 0?
    // No, if we wait for 0, 1 starves.
    // So we should switch to 1 if 0 is not ready?
    // But then we lose the beat for 0.
    // This is a trade