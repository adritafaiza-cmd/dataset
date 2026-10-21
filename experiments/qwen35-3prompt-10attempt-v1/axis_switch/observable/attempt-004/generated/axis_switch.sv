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
    reg [LOG_S_COUNT-1:0] arb_rr_mask;
    reg [LOG_S_COUNT-1:0] arb_rr_count;
    reg [LOG_S_COUNT-1:0] arb_rr_enable;

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
    reg [M_COUNT*DATA_WIDTH-1:0] reg_m_tdata;
    reg [M_COUNT*KEEP_WIDTH-1:0] reg_m_tkeep;
    reg [M_COUNT-1:0] reg_m_tvalid;
    reg [M_COUNT-1:0] reg_m_tlast;
    reg [M_COUNT*M_ID_WIDTH-1:0] reg_m_tid;
    reg [M_COUNT*M_DEST_WIDTH-1:0] reg_m_tdest;
    reg [M_COUNT*USER_WIDTH-1:0] reg_m_tuser;

    // Wire for output ready
    wire [M_COUNT-1:0] m_ready;

    // Round Robin Arbitration Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            arb_rr_index <= 0;
            arb_rr_mask <= {S_COUNT{1'b1}};
            arb_rr_count <= 0;
            arb_rr_enable <= 0;
        end else begin
            // Check if any input is valid
            if (s_axis_tvalid[0] | s_axis_tvalid[1] | s_axis_tvalid[2] | s_axis_tvalid[3]) begin
                // Determine winner based on policy
                // LSB High Priority: Iterate from LSB to MSB
                // Round Robin: Use index to skip already selected in this cycle
                
                wire [LOG_S_COUNT-1:0] candidate;
                wire [LOG_S_COUNT-1:0] next_index;
                wire [LOG_S_COUNT-1:0] winner;
                wire [LOG_S_COUNT-1:0] mask_val;

                if (ARB_TYPE_ROUND_ROBIN == 1) begin
                    // Round Robin
                    // Find the first valid input starting from current index
                    // If no valid input found from current index, wrap around and find first valid
                    wire [LOG_S_COUNT-1:0] temp_idx;
                    wire [LOG_S_COUNT-1:0] found;
                    wire [LOG_S_COUNT-1:0] temp_winner;
                    
                    // Simple implementation: scan from current index
                    temp_idx = arb_rr_index;
                    found = 1'b0;
                    temp_winner = 0;
                    
                    for (integer i = 0; i < S_COUNT; i = i + 1) begin
                        temp_idx = temp_idx + 1;
                        if (temp_idx >= S_COUNT) temp_idx = 0;
                        
                        if (s_axis_tvalid[temp_idx]) begin
                            found = 1'b1;
                            temp_winner = temp_idx;
                            break;
                        end
                    end
                    
                    if (found) begin
                        arb_rr_index = temp_winner;
                        arb_rr_count = 0;
                        arb_rr_enable = 1'b1;
                        winner = temp_winner;
                    end else begin
                        // No valid input, reset index
                        arb_rr_index = 0;
                        arb_rr_count = 0;
                        arb_rr_enable = 1'b0;
                        winner = 0;
                    end
                end else begin
                    // Default to LSB High Priority if not Round Robin
                    winner = 0;
                    for (integer i = 0; i < S_COUNT; i = i + 1) begin
                        if (s_axis_tvalid[i]) begin
                            winner = i;
                            break;
                        end
                    end
                    arb_rr_index = winner;
                    arb_rr_count = 0;
                    arb_rr_enable = 1'b1;
                end
            end else begin
                arb_rr_count = arb_rr_count + 1;
                if (arb_rr_count >= S_COUNT) begin
                    arb_rr_count = 0;
                    arb_rr_enable = 1'b0;
                end
                winner = 0;
            end
            
            // Update mask for next cycle if needed (simplified RR)
            if (ARB_TYPE_ROUND_ROBIN == 1) begin
                if (arb_rr_enable) begin
                    arb_rr_mask = {S_COUNT{1'b1}};
                end else begin
                    // Clear the bit corresponding to the winner if we want to prevent re-selection
                    // But standard RR usually just rotates index. 
                    // Here we just keep index updated.
                end
            end
        end
    end

    // Select signals based on arbitration winner
    assign sel_tvalid = (arb_rr_enable) ? s_axis_tvalid[arb_rr_index] : 1'b0;
    assign sel_tdata = (arb_rr_enable) ? s_axis_tdata[arb_rr_index*DATA_WIDTH +: DATA_WIDTH] : 0;
    assign sel_tkeep = (arb_rr_enable) ? s_axis_tkeep[arb_rr_index*KEEP_WIDTH +: KEEP_WIDTH] : 0;
    assign sel_tlast = (arb_rr_enable) ? s_axis_tlast[arb_rr_index] : 1'b0;
    assign sel_tid = (arb_rr_enable) ? s_axis_tid[arb_rr_index*S_ID_WIDTH +: S_ID_WIDTH] : 0;
    assign sel_tdest = (arb_rr_enable) ? s_axis_tdest[arb_rr_index*S_DEST_WIDTH +: S_DEST_WIDTH] : 0;
    assign sel_tuser = (arb_rr_enable) ? s_axis_tuser[arb_rr_index*USER_WIDTH +: USER_WIDTH] : 0;
    assign sel_tready = m_ready[arb_rr_index];

    // Output Ready Logic
    assign m_ready = m_axis_tready;

    // Output Valid Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_m_tvalid <= {M_COUNT{1'b0}};
            reg_m_tdata <= {M_COUNT{DATA_WIDTH{1'b0}}};
            reg_m_tkeep <= {M_COUNT{KEEP_WIDTH{1'b0}}};
            reg_m_tlast <= {M_COUNT{1'b0}};
            reg_m_tid <= {M_COUNT*M_ID_WIDTH{1'b0}};
            reg_m_tdest <= {M_COUNT*M_DEST_WIDTH{1'b0}};
            reg_m_tuser <= {M_COUNT*USER_WIDTH{1'b0}};
        end else begin
            // Check if any output port is ready and has valid data
            wire [M_COUNT-1:0] ready_mask = m_ready;
            wire [M_COUNT-1:0] valid_mask = reg_m_tvalid;
            
            // Find first ready output port
            wire [M_COUNT-1:0] sel_out;
            wire sel_out_valid;
            
            // Simple selection logic: find first ready port
            if (ready_mask[0]) sel_out = 0;
            else if (ready_mask[1]) sel_out = 1;
            else if (ready_mask[2]) sel_out = 2;
            else if (ready_mask[3]) sel_out = 3;
            else sel_out = 0; // Should not happen if logic is correct
            
            // Actually, we need to match the input source to the output destination
            // The problem statement says "Route each stream beat to the selected output"
            // This implies a switch where inputs go to specific outputs based on M_CONNECT or simply broadcast?
            // "Route each stream beat to the selected output" usually means Input[i] -> Output[j] where j is determined by config.
            // However, standard switch behavior with M_CONNECT often means Input[i] can go to Output[j] if connected.
            // Given the interface and typical switch behavior:
            // We select the best INPUT source.
            // Then we route that source to the OUTPUT port that is ready.
            // If multiple outputs are ready, we pick one (usually lowest index or based on policy).
            // If the input source is connected to multiple outputs, we might need to replicate.
            // But the prompt says "Route each stream beat to the selected output" (singular).
            // Let's assume a simple mapping: Selected Input -> First Ready Output that accepts it.
            // Or, more likely for a switch: Selected Input -> Output port determined by M_CONNECT logic or simply the first ready one.
            // Let's assume the simplest interpretation: The switch selects one input stream and pushes it to one output stream.
            // Which output? The one that is ready. If multiple are ready, pick the first one (or based on priority).
            // Let's pick the first ready output port.
            
            // Re-evaluating: "Route each stream beat to the selected output".
            // This implies we have a selected input (from arbitration).
            // We need to send it to an output.
            // If M_CONNECT is all 1s, any input can go to any output?
            // Let's assume the output port is selected by the first ready signal.
            
            // Wait, the prompt says "Route each stream beat to the selected output".
            // This might mean we select an output port first? No, arbitration is on inputs.
            // So: Arbitration selects Input Source.
            // Then, we find an Output Destination that is ready.
            // If multiple outputs are ready, we need a policy. Let's use the first ready output.
            
            // Let's refine the output selection logic.
            // We have a selected input (sel_tvalid, etc).
            // We need to drive m_axis_tvalid, etc.
            // We iterate through output ports 0 to M_COUNT-1.
            // If port k is ready, and we decide to send data there, we drive it.
            // But can we send to multiple ports? "Route ... to the selected output" (singular).
            // So we send to ONE output port per beat.
            // Which one? The first one that is ready.
            
            wire [M_COUNT-1:0] out_ready = m_ready;
            wire [M_COUNT-1:0] out_valid = reg_m_tvalid;
            
            // Determine which output port to use
            // Strategy: Find the lowest index output port that is ready.
            // If no output is ready, hold state.
            
            wire [M_COUNT-1:0] target_out;
            wire target_out_valid;
            
            // Check outputs in order 0, 1, 2, 3...
            // If out_ready[0] is high, target is 0.
            // If out_ready[0] is low and out_ready[1] is high, target is 1.
            // ...
            
            if (out_ready[0]) target_out = 0;
            else if (out_ready[1]) target_out = 1;
            else if (out_ready[2]) target_out = 2;
            else if (out_ready[3]) target_out = 3;
            else target_out = 0; // Fallback, should not drive if no ready
            
            // Now update registers for the target output
            // Only update if we are sending data to this target
            // We need to ensure we don't overwrite a valid packet in progress if we switch targets?
            // Since we only send to one target per cycle, and we update the register for that target,
            // we need to be careful.
            // Actually, the register holds the data for the NEXT cycle's transmission.
            // If we select target_out, we update the register for target_out.
            // But what if target_out was already valid from previous cycle?
            // We should only update if we are actively sending.
            
            // Let's simplify:
            // If sel_tvalid is high AND target_out is ready:
            //   Update register for target_out with sel_*
            //   Set reg_m_tvalid[target_out] = 1
            // Else:
            //   Keep register as is?
            //   But if we don't update, the old data stays.
            //   We need to handle the case where we switch targets.
            //   If we switch targets, the old target's register should be cleared or kept?
            //   If the old target is no longer selected, its register should be cleared after it sends?
            //   No, the register holds the data until it is sent.
            //   If we stop selecting an input, the output should stop sending.
            //   So if sel_tvalid is low, we should clear the register for the target?
            //   Or just don't update it.
            //   If we don't update, the data remains. If the output is ready, it will send the old data.
            //   This is bad. We must clear the register if we are not sending.
            
            // Correct logic:
            // 1. Identify target output port (lowest ready index).
            // 2. If sel_tvalid is high:
            //      Update register for target_out with sel_*
            //      Set reg_m_tvalid[target_out] = 1
            //      Clear other outputs? No, other outputs might have been selected in previous cycles?
            //      Wait, we only select ONE input at a time.
            //      So only ONE output should be active at a time.
            //      Therefore, we can clear all other outputs.
            // 3. If sel_tvalid is low:
            //      Clear the register for target_out (if any)
            //      Set reg_m_tvalid[target_out] = 0
            //      Clear others? They should already be 0.
            
            // Refined Logic:
            // We maintain a single "active" output port.
            // If sel_tvalid is high, we pick the first ready output port as the active one.
            // We update its register and set valid.
            // We clear all other output registers and valid flags.
            // If sel_tvalid is low, we clear the active output register and flag.
            
            // Let's implement this.
            
            // First, determine the target output index
            wire [M_COUNT-1:0] target_idx;
            if (out_ready[0]) target_idx = 0;
            else if (out_ready[1]) target_idx = 1;
            else if (out_ready[2]) target_idx = 2;
            else if (out_ready[3]) target_idx = 3;
            else target_idx = 0; // Default, will be cleared
            
            // Update registers
            // Clear all first
            reg_m_tdata <= {M_COUNT{DATA_WIDTH{1'b0}}};
            reg_m_tkeep <= {M_COUNT{KEEP_WIDTH{1'b0}}};
            reg_m_tlast <= {M_COUNT{1'b0}};
            reg_m_tid <= {M_COUNT*M_ID_WIDTH{1'b0}};
            reg_m_tdest <= {M_COUNT*M_DEST_WIDTH{1'b0}};
            reg_m_tuser <= {M_COUNT*USER_WIDTH{1'b0}};
            reg_m_tvalid <= {M_COUNT{1'b0}};
            
            // If we have valid input and a ready output, fill the target
            if (sel_tvalid && out_ready[target_idx]) begin
                reg_m_tdata[target_idx*DATA_WIDTH +: DATA_WIDTH] <= sel_tdata;
                reg_m_tkeep[target_idx*KEEP_WIDTH +: KEEP_WIDTH] <= sel_tkeep;
                reg_m_tlast[target_idx] <= sel_tlast;
                reg_m_tid[target_idx*M_ID_WIDTH +: M_ID_WIDTH] <= sel_tid;
                reg_m_tdest[target_idx*M_DEST_WIDTH +: M_DEST_WIDTH] <= sel_tdest;
                reg_m_tuser[target_idx*USER_WIDTH +: USER_WIDTH] <= sel_tuser;
                reg_m_tvalid[target_idx] <= 1'b1;
            end
        end
    end

    // Output assignments
    assign m_axis_tdata = reg_m_tdata;
    assign m_axis_tkeep = reg_m_tkeep;
    assign m_axis_tvalid = reg_m_tvalid;
    assign m_axis_tlast = reg_m_tlast;
    assign m_axis_tid = reg_m_tid;
    assign m_axis_tdest = reg_m_tdest;
    assign m_axis_tuser = reg_m_tuser;

    // Input Ready assignments
    // s_axis_tready[i] is high if the input port i is selected and the arbitration allows it
    // Actually, s_axis_tready should be high if the input is selected AND the output is ready.
    // In our logic, if arb_rr_enable is high, that input is selected.
    // And if the target output is ready, we are ready to accept.
    // So s_axis_tready[i] = (i == arb_rr_index) && sel_tready;
    // But sel_tready is m_ready[arb_rr_index].
    // So s_axis_tready[i] = (i == arb_rr_index) && m_ready[arb_rr_index];
    
    generate
        genvar i;
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_input_ready
            assign s_axis_tready[i] = (i == arb_rr_index) && m_ready[arb_rr_index];
        end
    endgenerate

endmodule
```<|im_end|>
