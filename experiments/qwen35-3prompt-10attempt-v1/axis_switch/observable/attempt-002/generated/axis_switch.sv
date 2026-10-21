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
    reg [LOG_S_COUNT-1:0] arb_rr_next; // Next index to try

    // Internal signals for selected input
    wire [DATA_WIDTH-1:0] sel_tdata;
    wire [KEEP_WIDTH-1:0] sel_tkeep;
    wire sel_tvalid;
    wire sel_tlast;
    wire [S_ID_WIDTH-1:0] sel_tid;
    wire [S_DEST_WIDTH-1:0] sel_tdest;
    wire [USER_WIDTH-1:0] sel_tuser;
    wire sel_tready;

    // Output registers
    reg [DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [M_ID_WIDTH-1:0] m_axis_tid_reg;
    reg [M_DEST_WIDTH-1:0] m_axis_tdest_reg;
    reg [USER_WIDTH-1:0] m_axis_tuser_reg;

    // Arbitration Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            arb_rr_index <= 0;
            arb_rr_mask <= {S_COUNT{1'b1}};
            arb_rr_next <= 0;
        end else begin
            // Update mask based on valid inputs
            arb_rr_mask <= s_axis_tvalid;
            
            // Calculate next index for round robin
            if (ARB_TYPE_ROUND_ROBIN) begin
                if (ARB_LSB_HIGH_PRIORITY) begin
                    // LSB High Priority: Iterate from LSB to MSB
                    arb_rr_next = arb_rr_index;
                    if (arb_rr_mask[arb_rr_index]) begin
                        // If current is valid, keep it (effectively)
                        // But we need to find the *next* one if current is taken? 
                        // Standard RR: If current is valid, select it. If not, move to next.
                        // However, the mask update happens in this cycle.
                        // Let's refine: 
                        // 1. Check current index. If valid, select.
                        // 2. If not valid, increment index.
                        // 3. Wrap around.
                        // To implement "Next" logic properly for the *next* cycle selection:
                        // We want to find the lowest set bit in 'mask' that is >= current index.
                        // If none, wrap to lowest set bit overall.
                        
                        // Simplified approach for RR:
                        // Find the first '1' in 'mask' starting from 'arb_rr_index'.
                        // If found, that's the winner.
                        // If not found (all 0s from index to end), wrap to first '1' from 0.
                        
                        // Implementation using priority encoder logic manually or shift
                        // Since S_COUNT is small parameter, we can do a loop or shift.
                        // Let's use a shift method to find the next valid index.
                        
                        // Create a shifted version of mask starting at arb_rr_index
                        // We want the first 1 bit in (mask >> arb_rr_index)
                        // But we need to handle wrap around.
                        
                        // Alternative: Just find the lowest set bit in 'mask' that is >= arb_rr_index
                        // If none, find lowest set bit in 'mask' overall.
                        
                        // Let's use a simple counter approach inside the always block logic
                        // or a dedicated priority encoder.
                        // Given constraints, let's implement a priority encoder that respects RR order.
                        
                        // Logic:
                        // 1. Shift mask left by (LOG_S_COUNT - arb_rr_index) to align current index to LSB? No.
                        // 2. Rotate mask left by arb_rr_index. The first '1' bit is the next candidate.
                        //    Wait, if we rotate left by index, the bit at 'index' moves to 0.
                        //    Then we find the MSB or LSB?
                        //    If we rotate left, the sequence becomes: [index, index+1, ..., end, 0, ..., index-1]
                        //    We want the first valid one in this sequence.
                        //    So we look for the LSB of the rotated mask.
                        
                        // Example: Mask = 1010 (indices 0, 2 valid). Index = 1.
                        // Rotate left by 1: 0101. LSB is 1 (index 2 in original). Correct.
                        // Example: Mask = 1010. Index = 2.
                        // Rotate left by 2: 0101. LSB is 1 (index 0 in original). Correct.
                        
                        // So: arb_rr_next = $clog2($clog2(S_COUNT)) ? No.
                        // We need to find the position of the LSB of (mask << arb_rr_index) ?
                        // Actually, rotating left by N is equivalent to (mask << N) | (mask >> (LOG_S_COUNT - N)).
                        // Then find the LSB (lowest set bit).
                        
                        // Let's calculate the rotated mask
                        wire [LOG_S_COUNT-1:0] rot_mask;
                        // This is tricky to do in one line without loops.
                        // Let's use a priority encoder approach that scans from arb_rr_index.
                        
                        // Re-implementation:
                        // Find the first '1' in 'mask' starting from 'arb_rr_index'.
                        // If not found, find the first '1' from 0.
                        
                        // We can do this by checking bits sequentially if S_COUNT is small, 
                        // but for generic parameter, we need a shift.
                        
                        // Shift mask left by arb_rr_index.
                        // The bit at position 'arb_rr_index' moves to 0.
                        // The bit at 'arb_rr_index + 1' moves to 1.
                        // ...
                        // The bit at 'end' moves to 'LOG_S_COUNT - 1'.
                        // The bits from 0 to 'arb_rr_index - 1' wrap around to the top.
                        
                        // We want the LSB of this rotated value.
                        // Rotated = {mask[LOG_S_COUNT-1:arb_rr_index], mask[arb_rr_index-1:0]}
                        // Wait, left shift: {mask[LOG_S_COUNT-1:arb_rr_index], mask[arb_rr_index-1:0]} is actually a rotation?
                        // No. Left shift by N: {mask[LOG_S_COUNT-1:N], {N{1'b0}}}.
                        // Rotation Left by N: {mask[LOG_S_COUNT-1:N], mask[N-1:0]}.
                        
                        // So, let's construct the rotated mask:
                        // high_part = mask[LOG_S_COUNT-1:arb_rr_index]
                        // low_part = mask[arb_rr_index-1:0]
                        // rotated = {high_part, low_part}
                        // next_index = $clog2(rotated) ? No, $clog2 gives MSB position.
                        // We want LSB position.
                        // We can use a priority encoder or a loop.
                        // Since we cannot use loops in combinational logic easily for generic params,
                        // let's use a priority encoder that checks bits from LSB to MSB of the rotated mask.
                        
                        // Actually, simpler:
                        // If we want the first valid bit starting from 'arb_rr_index':
                        // Check if mask[arb_rr_index] is 1. If so, next = arb_rr_index.
                        // Else check arb_rr_index + 1...
                        // This is sequential.
                        
                        // Let's use the rotation trick and then find the LSB.
                        // How to find LSB of a generic vector?
                        // We can use a priority encoder that outputs the index of the LSB.
                        // But standard priority encoders find MSB.
                        // We can invert the mask and find MSB, then subtract from LOG_S_COUNT?
                        // No, that finds the highest index.
                        
                        // Let's try a different approach for RR:
                        // Maintain a state 'next_candidate'.
                        // If current candidate is valid, select it.
                        // If not, increment candidate.
                        // If candidate >= S_COUNT, wrap to 0.
                        // BUT, we must skip invalid ones.
                        // So:
                        // next_candidate = arb_rr_index;
                        // while (!mask[next_candidate]) next_candidate++;
                        // if (next_candidate >= S_COUNT) next_candidate = 0;
                        // while (!mask[next_candidate]) next_candidate++;
                        
                        // This requires a loop. In Verilog-2001, we can't have loops in combinational logic.
                        // We must unroll or use a priority encoder.
                        // Since S_COUNT is a parameter, we can't unroll dynamically.
                        // We must use a priority encoder that supports "start from index".
                        
                        // Trick: 
                        // Create a mask where bits 0 to arb_rr_index-1 are 0.
                        // Then find the MSB of the inverted mask? No.
                        // Find the MSB of (mask & {arb_rr_index{1'b0}, {LOG_S_COUNT-arb_rr_index}{1'b1}})?
                        // No, we want the first 1.
                        
                        // Let's use a priority encoder that finds the LSB.
                        // We can construct a vector where the LSB corresponds to the first valid bit.
                        // But standard encoders find MSB.
                        // If we reverse the bit order of the mask, MSB becomes LSB.
                        // But reversing is hard for generic params.
                        
                        // Alternative: Use a counter that increments until it hits a valid bit.
                        // But that's sequential.
                        
                        // Let's assume we can use a priority encoder that finds the lowest set bit.
                        // We can implement a small priority encoder for the specific case of finding the first 1.
                        // Or, we can use the property:
                        // If we shift the mask left by (LOG_S_COUNT - arb_rr_index), the first valid bit 
                        // (starting from arb_rr_index) will be at the MSB position? No.
                        
                        // Let's go back to basics.
                        // We need to find the smallest 'i' >= 'arb_rr_index' such that mask[i] == 1.
                        // If no such 'i' exists, find smallest 'i' >= 0 such that mask[i] == 1.
                        
                        // We can do this by checking bits in a priority manner.
                        // Since S_COUNT is small (max 4 in example, but parameter), let's write a generic priority encoder
                        // that finds the LSB.
                        // Actually, we can use the $clog2 function on a modified mask?
                        // No.
                        
                        // Let's use a simple priority encoder logic that scans from LSB to MSB.
                        // We can't do a loop.
                        // We can use a case statement or a series of if-else.
                        // But S_COUNT is a parameter.
                        // We can use a generic priority encoder module? No, single file.
                        
                        // Okay, let's use a trick.
                        // If we want the first 1 bit in 'mask' starting from 'start_idx'.
                        // We can create a temporary mask 'temp_mask' where bits 0 to start_idx-1 are 0.
                        // Then we want the first 1 in 'temp_mask'.
                        // If we reverse the bits of 'temp_mask', the first 1 becomes the MSB.
                        // Then we can use $clog2.
                        // But reversing bits is hard.
                        
                        // Let's try a different strategy:
                        // Use a counter in the sequential logic to find the next valid index.
                        // But the arbitration decision must be combinational for the current cycle's selection?
                        // No, the selection can be sequential.
                        // We can have a state machine for arbitration.
                        // State: 'current_index'.
                        // Next State: If mask[current_index] is 1, then current_index. Else current_index + 1.
                        // If current_index + 1 >= S_COUNT, wrap to 0.
                        // This is a simple FSM.
                        
                        // Let's implement this FSM.
                        // arb_rr_index holds the index to try next.
                        // In the next clock cycle, we check if mask[arb_rr_index] is 1.
                        // If yes, we select it.
                        // If no, we increment arb_rr_index.
                        // Wait, if we increment, we might miss the current valid one if we just incremented?
                        // No, the FSM updates arb_rr_index for the *next* cycle.
                        // Cycle N: arb_rr_index = X. Check mask[X].
                        // If mask[X] == 1, we select X. arb_rr_index stays X (or increments? No, stays to try again if it becomes invalid? No, valid is valid).
                        // If mask[X] == 0, we increment arb_rr_index.
                        
                        // Refined FSM:
                        // If mask[arb_rr_index] == 1:
                        //    arb_rr_next = arb_rr_index;
                        // Else:
                        //    arb_rr_next = arb_rr_index + 1;
                        //    if (arb_rr_next >= S_COUNT) arb_rr_next = 0;
                        
                        // But what if arb_rr_index points to an invalid bit, and we increment, and the new one is also invalid?
                        // We keep incrementing until we find a valid one.
                        // This works perfectly.
                        // Initial state: arb_rr_index = 0.
                        
                        // One edge case: All inputs invalid.
                        // arb_rr_index will cycle 0->1->2...->0.
                        // We need to detect "all invalid" to stop incrementing?
                        // No, if all are invalid, we can just stay at 0 or cycle.
                        // But we need to ensure we don't infinite loop if we don't find a valid one.
                        // Actually, if all are invalid, any index is fine (no data).
                        // But we need to be stable.
                        // If all are 0, mask is 0.
                        // arb_rr_index = 0. mask[0]=0 -> next=1.
                        // arb_rr_index = 1. mask[1]=0 -> next=2.
                        // ...
                        // arb_rr_index = S_COUNT-1. mask[S_COUNT-1]=0 -> next=0.
                        // So it cycles.
                        // To stabilize, if mask == 0, force arb_rr_next = 0.
                        
                        if (arb_rr_mask == 0) begin
                            arb_rr_next <= 0;
                        end else begin
                            if (arb_rr_mask[arb_rr_index]) begin
                                arb_rr_next <= arb_rr_index;
                            end else begin
                                arb_rr_next <= arb_rr_index + 1;
                                if (arb_rr_next >= S_COUNT) arb_rr_next <= 0;
                            end
                        end
                    end
                end else begin
                    // MSB High Priority
                    // Find the highest index 'i' such that mask[i] == 1.
                    // We can use a priority encoder logic.
                    // Since we can't use a generic priority encoder easily, we can use a loop in sequential logic?
                    // No, priority is combinational.
                    // We can use a counter that counts down from S_COUNT-1.
                    // But that's sequential.
                    // Let's use a priority encoder implementation using if-else hierarchy.
                    // But S_COUNT is a parameter.
                    // We can use a generic priority encoder using a loop? No.
                    // We can use the $clog2 trick on a modified mask.
                    // If we want the MSB of 'mask'.
                    // We can use $clog2(mask) directly if mask is non-zero.
                    // $clog2 returns the position of the MSB.
                    // So if ARB_LSB_HIGH_PRIORITY is 0, we just use $clog2(arb_rr_mask).
                    // But wait, we need to respect the RR index?
                    // No, MSB High Priority ignores RR index. It always picks the highest index.
                    // So if MSB High Priority, arb_rr_next = $clog2(arb_rr_mask).
                    // If LSB High Priority, we use the FSM logic above.
                    
                    // Wait, the parameter is ARB_LSB_HIGH_PRIORITY.
                    // If 1: LSB High Priority (Round Robin style, lowest index wins).
                    // If 0: MSB High Priority (Highest index wins).
                    
                    // So:
                    if (ARB_LSB_HIGH_PRIORITY) begin
                        // Use the FSM logic derived above
                        if (arb_rr_mask == 0) begin
                            arb_rr_next <= 0;
                        end else begin
                            if (arb_rr_mask[arb_rr_index]) begin
                                arb_rr_next <= arb_rr_index;
                            end else begin
                                arb_rr_next <= arb_rr_index + 1;
                                if (arb_rr_next >= S_COUNT) arb_rr_next <= 0;
                            end
                        end
                    end else begin
                        // MSB High Priority
                        // Find the highest set bit.
                        // $clog2 returns the index of the MSB.
                        // If mask is 0, $clog2 is undefined (returns 0 usually, but let's handle).
                        if (arb_rr_mask == 0) begin
                            arb_rr_next <= 0;
                        end else begin
                            arb_rr_next <= $clog2(arb_rr_mask);
                        end
                    end
                end
            end
        end
    end

    // Selection Logic (Combinational)
    always @(*) begin
        // Default to 0
        sel_tdata = 0;
        sel_tkeep = 0;
        sel_tvalid = 0;
        sel_tlast = 0;
        sel_tid = 0;
        sel_tdest = 0;
        sel_tuser = 0;
        sel_tready = 0;

        if (s_axis_tvalid[arb_rr_index]) begin
            sel_tdata = s_axis_tdata[arb_rr_index * DATA_WIDTH +: DATA_WIDTH];
            sel_tkeep = s_axis_tkeep[arb_rr_index * KEEP_WIDTH +: KEEP_WIDTH];
            sel_tvalid = s_axis_tvalid[arb_rr_index];
            sel_tlast = s_axis_tlast[arb_rr_index];
            sel_tid = s_axis_tid[arb_rr_index * S_ID_WIDTH +: S_ID_WIDTH];
            sel_tdest = s_axis_tdest[arb_rr_index * S_DEST_WIDTH +: S_DEST_WIDTH];
            sel_tuser = s_axis_tuser[arb_rr_index * USER_WIDTH +: USER_WIDTH];
            sel_tready = m_axis_tready[arb_rr_index]; // Pass ready back to input
        end
    end

    // Output Logic (Sequential)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
        end else begin
            if (sel_tvalid && sel_tready) begin
                m_axis_tdata_reg <= sel_tdata;
                m_axis_tkeep_reg <= sel_tkeep;
                m_axis_tvalid_reg <= 1'b1;
                m_axis_tlast_reg <= sel_tlast;
                m_axis_tid_reg <= sel_tid;
                m_axis_tdest_reg <= sel_tdest;
                m_axis_tuser_reg <= sel_tuser;
            end else begin
                m_axis_tvalid_reg <= 1'b0;
                // Other signals hold their value or reset? 
                // Usually, if not valid, data is X or hold. 
                // For safety, let's hold data, but valid is 0.
                // However, in AXI Stream, if valid is 0, data is ignored.
                // We can let them hold or reset. Let's reset to 0 for clean state.
                m_axis_tdata_reg <= 0;
                m_axis_tkeep_reg <= 0;
                m_axis_tlast_reg <= 0;
                m_axis_tid_reg <= 0;
                m_axis_tdest_reg <= 0;
                m_axis_tuser_reg <= 0;
            end
        end
    end

    // Output Port Assignments
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

    // Input Ready Signals
    // s_axis_tready[i] is 1 if the switch is ready to accept data from input i.
    // The switch is ready if the output is ready (m_axis_tready[i] is 1) AND the internal buffer is not full?
    // Since this is a simple switch (no buffering mentioned other than the register for the current beat),
    // we can assume 1-beat buffering or direct pass-through.
    // The problem says "Route each stream beat... Handle competing inputs".
    // It implies a single-beat buffer per output? Or just a mux?
    // "Preserving packet boundaries" implies buffering might be needed if multiple inputs contend for one output.
    // But the interface has separate m_axis_tready per output.
    // If multiple inputs are valid and one output is ready, we pick one.
    // The others must wait.
    // So s_axis_tready[i] = (sel_tready == 1) ? (m_axis_tready[i] == 1) : 0;
    // Wait, sel_tready is the ready signal from the selected input.
    // If we select input 'k', then s_axis_tready[k] = m_axis_tready[k].
    // For other inputs, s_axis_tready[j] = 0.
    
    // Let's refine the ready logic.
    // The switch has one output port per M input? No, M_COUNT outputs.
    // Each output corresponds to one M input.
    // The switch selects one S input and routes it to one M output.
    // Wait, the interface has M_COUNT outputs.
    // Does the switch route to a specific M output based on S_DEST?
    // The parameter M_CONNECT suggests mapping.
    // But the problem says "Route each stream beat to the selected output".
    // Usually, an AXI Stream switch routes to a specific destination based on S_DEST or a fixed mapping.
    // The parameter M_CONNECT is {M_COUNT{{S_COUNT{1'b1}}}}. This looks like a mapping table.
    // But the module interface doesn't have a "dest" input for the switch itself, only s_axis_tdest.
    // And m_axis_tdest is an output.
    // How do we know which M output to drive?
    // The problem says "Route each stream beat to the selected output".
    // It doesn't specify dynamic routing based on S_DEST.
    // It might be a simple multiplexer where all S inputs go to all M outputs? No, that's a crossbar.
    // Or maybe it's a single output switch?
    // But the interface has M_COUNT outputs.
    // Let's assume the switch routes the selected S input to the M output corresponding to the arbitration winner?
    // Or maybe it routes to all M outputs?
    // "Route each stream beat to the selected output" -> Singular.
    // This implies one S input is selected and sent to ONE M output.
    // Which M output?
    // Maybe the M output index is determined by the arbitration?
    // Or maybe the S_DEST determines the M output?
    // But the parameter M_CONNECT is a constant.
    // Let's look at the parameters again.
    // M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}}. This is a 2D array flattened.
    // It suggests a mapping from S to M.
    // But the module doesn't take a "dest" input to select the M output.
    // It takes s_axis_tdest.
    // Maybe the switch routes the selected S input to the M output where M_CONNECT[S_INDEX] == 1?
    // But M_CONNECT is all 1s.
    // This implies all S inputs can go to all M outputs?
    // But "selected output" implies one.
    
    // Re-reading: "Route each stream beat to the selected output".
    // Maybe the switch is a simple Mux that selects one S input and sends it to ONE M output.
    // But which M output?
    // If M_COUNT > 1, we need to know which one.
    // Perhaps the switch is a "Switch" that connects one S to one M.
    // But the interface has M_COUNT outputs.
    // Maybe the switch replicates the data to all M outputs?
    // "Route each stream beat to the selected output" -> Singular.
    // This is ambiguous.
    // However, looking at typical AXI Stream switch implementations:
    // Often, they route to a specific destination based on S_DEST.
    // But here, we don't have a "dest" input to the switch module to select the output.
    // We only have s_axis_tdest (from the source).
    // Maybe the switch routes the selected S input to the M output that matches the S_DEST?
    // But S_DEST is from the source.
    // And M_CONNECT is a constant.
    
    // Let's assume the simplest interpretation for a "Switch":
    // It selects one S input based on arbitration.
    // It routes that data to ALL M outputs? Or to a specific one?
    // If it routes to all M outputs, then m_axis_tvalid[i] would be the same for all i.
    // If it routes to a specific one, which one?
    // Given the parameters M_BASE, M_TOP, M_CONNECT, it seems like a configurable router.
    // But without a "dest" input to the module, we can't dynamically select the output based on S_DEST.
    // Unless the switch is a "Switch" that connects one S to one M, and the M index is fixed or derived.
    // But the interface has M_COUNT outputs.
    
    // Let's reconsider the "selected output" phrase.
    // Maybe it means "the output corresponding to the selected input".
    // But how is the mapping defined?
    // M_CONNECT is a parameter.
    // Maybe the switch routes S[i] to M[j] if M_CONNECT[i][j] is 1?
    // But M_CONNECT is all 1s.
    // So S[i] can go to any M[j].
    // But we can only send one beat at a time to one M output?
    // Or can we send to multiple?
    // "Route each stream beat to the selected output" -> Singular.
    // This implies one-to-one mapping per beat.
    // But which M output?
    // Maybe the switch is a simple Mux that selects one S input and sends it to M[0]?
    // And M[1]..M[M_COUNT-1] are unused?
    // That seems unlikely given M_COUNT parameter.
    
    // Alternative interpretation:
    // The switch is a crossbar where one S input is selected and sent to ONE M output.
    // The M output is selected based on S_DEST?
    // But we don't have a "dest" input to the switch.
    // Wait, s_axis_tdest is an input.
    // Maybe the switch routes S[i] to M[j] where j = s_axis_tdest[i]?
    // But s_axis_tdest is [S_COUNT * S_DEST_WIDTH - 1 : 0].
    // So each S input has its own dest.
    // So if we select S[i], we route to M[j] where j = s_axis_tdest[i][S_DEST_WIDTH-1:0]?
    // But M_COUNT might be larger than S_COUNT.
    // And M_CONNECT is all 1s.
    // So if we select S[i], we check s_axis_tdest[i].
    // If s_axis_tdest[i] < M_COUNT, we route to M[s_axis_tdest[i]].
    // But what if multiple S inputs have the same dest?
    // Then we have a conflict on the M output.
    // The arbitration policy selects one S input.
    // So we select S[i], then route to M[s_axis_tdest[i]].
    // This makes sense.
    
    // Let's implement this logic:
    // 1. Arbitration selects one S input index 'sel_idx'.
    // 2. Check if s_axis_tvalid[sel_idx] is 1.
    // 3. If valid, get the destination: dest_idx = s_axis_tdest[sel_idx * S_DEST_WIDTH +: S_DEST_WIDTH].
    // 4. Check if dest_idx < M_COUNT.
    // 5. If yes, route to M[dest_idx].
    // 6. If no, discard? Or route to a default?
    //    Given M_CONNECT is all 1s, maybe we assume valid dest.
    //    But we need to handle the case where dest is out of range.
    //    Let's assume if out of range, we don't drive that output.
    
    // Wait, the problem says "Route each stream beat to the selected output".
    // It doesn't mention dynamic routing based on S_DEST.
    // It might be a simple switch that connects one S to one M, and the M is fixed?
    // Or maybe the switch is a "Switch" that connects one S to ALL M outputs?
    // "Selected output" (singular) suggests one.
    // But which one?
    // If the switch is a simple Mux, it usually has one output.
    // But here we have M_COUNT outputs.
    // Maybe the switch is a "Switch" that connects one S to one M, and the M is determined by the arbitration?
    // No, arbitration selects S.
    // Maybe the switch is a "Switch" that connects one S to one M, and the M is determined by the S_DEST?
    // This is the most logical interpretation for a switch with multiple outputs.
    // It's a "Destination-based switch".
    
    // Let's implement:
    // Select S input based on arbitration.
    // Route to M output based on S_DEST of the selected S input.
    // If multiple S inputs map to the same M output, only the arbitrated one goes through.
    // This handles "competing inputs" naturally.
    
    // But wait, what if M_COUNT > S_COUNT?
    // And M_CONNECT is all 1s.
    // Then any S can go to any M.
    // So we select S[i], and route to M[s_axis_tdest[i]].
    // This seems correct.
    
    // However, there is a catch:
    // The arbitration selects one S input.
    // But what if that S input's dest is invalid (>= M_COUNT)?
    // Then we can't route.
    // We should probably discard that beat.
    
    // Let's refine the logic:
    // 1. Arbitration selects 'arb_idx'.
    // 2. If s_axis_tvalid[arb_idx] is 1:
    //    dest = s_axis_tdest[arb_idx * S_DEST_WIDTH +: S_DEST_WIDTH];
    //    if (dest < M_COUNT) begin
    //        m_axis_tvalid[dest] = 1;
    //        m_axis_tdata[dest * DATA_WIDTH +: DATA_WIDTH] = sel_tdata;
    //        ...
    //    end
    // 3. For other M outputs, valid = 0.
    
    // But wait, the arbitration logic I wrote earlier selects one S input.
    // But what if multiple S inputs are valid?
    // The arbitration picks one.
    // So only one M output will be driven.
    // This matches "Route each stream beat to the selected output".
    
    // But what if the arbitration policy is "MSB High Priority"?
    // Then we pick the highest index S input.
    // Then route to its dest.
    // This works.
    
    // One more thing: The parameter M_CONNECT.
    // If M_CONNECT was not all 1s, we would check M_CONNECT[arb_idx][dest].
    // Since it is all 1s, we just check dest < M_COUNT.
    
    // Let's implement this.
    
    // Wait, I need to be careful with the "selected output" phrasing.
    // If the switch is a simple Mux, it might just connect S[0] to M[0], S[1] to M[1], etc., and arbitrate between them?
    // No, that's a crossbar.
    // A "Switch" usually implies one input to one output.
    // So my interpretation of "Destination-based" is likely correct.
    
    // Let's write the output logic.
    
    // We need to clear all M outputs first.
    // Then