```verilog
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
    /*
     * AXI Stream inputs
     */
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [S_COUNT*KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    output wire [S_COUNT-1:0]               s_axis_tready,
    input  wire [S_COUNT-1:0]               s_axis_tlast,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axis_tid,
    input  wire [S_COUNT*S_DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [S_COUNT*USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI Stream outputs
     */
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
    typedef enum logic [LOG_S_COUNT-1:0] {
        STATE_IDLE,
        STATE_GRANTING
    } arb_state_t;

    // Round Robin counters per output
    logic [LOG_S_COUNT-1:0] rr_counter [M_COUNT-1:0];
    logic [LOG_S_COUNT-1:0] rr_next_counter [M_COUNT-1:0];
    
    // Current grant status
    logic [M_COUNT-1:0] current_grant;
    logic [M_COUNT-1:0] next_grant;
    
    // Internal state for arbitration
    arb_state_t arb_state;
    logic [LOG_S_COUNT-1:0] arb_idx;

    // Input buffers to handle back-to-back beats if output is not ready
    logic [S_COUNT-1:0] s_valid_reg;
    logic [S_COUNT-1:0] s_data_reg [DATA_WIDTH-1:0];
    logic [S_COUNT-1:0] s_keep_reg [KEEP_WIDTH-1:0];
    logic [S_COUNT-1:0] s_last_reg;
    logic [S_COUNT-1:0] s_tid_reg [S_ID_WIDTH-1:0];
    logic [S_COUNT-1:0] s_dest_reg [S_DEST_WIDTH-1:0];
    logic [S_COUNT-1:0] s_user_reg [USER_WIDTH-1:0];

    // Output buffers to handle back-to-back beats if input is not ready
    logic [M_COUNT-1:0] m_valid_reg;
    logic [M_COUNT-1:0] m_data_reg [DATA_WIDTH-1:0];
    logic [M_COUNT-1:0] m_keep_reg [KEEP_WIDTH-1:0];
    logic [M_COUNT-1:0] m_last_reg;
    logic [M_COUNT-1:0] m_tid_reg [M_ID_WIDTH-1:0];
    logic [M_COUNT-1:0] m_dest_reg [M_DEST_WIDTH-1:0];
    logic [M_COUNT-1:0] m_user_reg [USER_WIDTH-1:0];

    // Arbitration Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            arb_state <= STATE_IDLE;
            rr_counter <= '0;
            current_grant <= '0;
        end else begin
            if (arb_state == STATE_IDLE) begin
                // Check if any input is valid
                logic any_valid = 0;
                for (int i = 0; i < S_COUNT; i = i + 1) begin
                    if (s_axis_tvalid[i]) begin
                        any_valid = 1;
                        break;
                    end
                end

                if (any_valid) begin
                    arb_state <= STATE_GRANTING;
                    // Initialize round robin counter based on priority or current state
                    if (ARB_TYPE_ROUND_ROBIN) begin
                        // Find the highest priority (or lowest index if LSB high) input
                        // that is valid and not currently granted.
                        // Since we grant one at a time, we look for the first valid one 
                        // that hasn't been granted in this cycle's sequence.
                        // However, standard RR usually cycles through all valid inputs.
                        // Let's implement a simple RR: find the first valid input index.
                        // If LSB_HIGH_PRIORITY, index 0 is highest.
                        // If LSB_LOW_PRIORITY (implied by !ARB_LSB_HIGH_PRIORITY), index S_COUNT-1 is highest.
                        
                        logic grant_idx = '0;
                        if (ARB_LSB_HIGH_PRIORITY) begin
                            for (int i = 0; i < S_COUNT; i = i + 1) begin
                                if (s_axis_tvalid[i]) begin
                                    grant_idx = i;
                                    break;
                                end
                            end
                        end else begin
                            for (int i = S_COUNT-1; i >= 0; i = i - 1) begin
                                if (s_axis_tvalid[i]) begin
                                    grant_idx = i;
                                    break;
                                end
                            end
                        end
                        rr_counter[grant_idx] <= 0;
                        current_grant <= 1 << grant_idx;
                    end else begin
                        // Static priority: LSB High
                        for (int i = 0; i < S_COUNT; i = i + 1) begin
                            if (s_axis_tvalid[i]) begin
                                current_grant = 1 << i;
                                break;
                            end
                        end
                    end
                end else begin
                    arb_state <= STATE_IDLE;
                    current_grant <= '0;
                end
            end else begin
                // STATE_GRANTING: We have a grant. Check if the output is ready.
                // If ready, forward data and update RR counter.
                // If not ready, hold the grant and wait.
                
                logic grant_idx = 0;
                for (int i = 0; i < S_COUNT; i = i + 1) begin
                    if (current_grant[i]) begin
                        grant_idx = i;
                        break;
                    end
                end

                // Check if the specific output port is ready
                // Note: current_grant might be a vector, we need to check the specific bit corresponding to the grant.
                // Actually, current_grant is a one-hot vector representing which input is granted.
                // We need to check if the corresponding output is ready.
                // But wait, the arbiter grants an INPUT to an OUTPUT.
                // The logic above grants an INPUT index.
                // We need to map Input Index -> Output Index.
                // The problem statement says "Route S_COUNT inputs to M_COUNT outputs using tdest".
                // This implies a many-to-many mapping.
                // However, the standard AXI Switch behavior with these parameters usually implies:
                // Inputs are sources, Outputs are destinations.
                // tdest on input selects the output port.
                // So, Input[i] with tdest[i] = D wants to go to Output[D].
                
                // Let's refine the arbitration state.
                // We need to track which (Input, Output) pairs are active.
                // But typically, an input beat goes to exactly one output.
                // So, Input[i] is granted if Output[tdest[i]] is ready AND Input[i] is valid.
                // If multiple inputs target the same output, we arbitrate among them.
                
                // Revised Arbitration Logic:
                // 1. Identify all inputs that are valid.
                // 2. Group them by their tdest.
                // 3. For each output port that has at least one valid input targeting it:
                //    - If the output is ready, grant one of the valid inputs targeting it.
                //    - If the output is not ready, hold the grant for that output until it becomes ready.
                //    - Use Round Robin among the inputs targeting that specific output.
                
                // Let's restart the state machine logic for clarity.
                // State: IDLE (no active grants), GRANTING (active grants exist).
                
                // Reset grants
                next_grant <= '0;
                
                // Calculate next grant based on current state and output readiness
                if (arb_state == STATE_IDLE) begin
                    // Check all outputs
                    for (int o = 0; o < M_COUNT; o = o + 1) begin
                        // Find valid inputs targeting this output
                        logic has_valid_input = 0;
                        logic [LOG_S_COUNT-1:0] candidate_idx = '0;
                        
                        for (int i = 0; i < S_COUNT; i = i + 1) begin
                            if (s_axis_tvalid[i] && s_axis_tdest[i] == o) begin
                                has_valid_input = 1;
                                candidate_idx = i;
                                break; // Found one, but need to check RR if multiple
                            end
                        end
                        
                        if (has_valid_input && m_axis_tready[o]) begin
                            // Output is ready, grant the first available input (or RR next)
                            // For simplicity in this single-cycle logic, we pick the lowest index
                            // that targets this output and is valid.
                            // In a full RR implementation, we would track the last granted index per output.
                            // Let's assume we just pick the lowest index for now if multiple target same output,
                            // OR we can integrate the RR counter here.
                            
                            // To properly implement RR per output:
                            // We need to know which input was last granted for output 'o'.
                            // Let's store `last_granted_input [M_COUNT-1:0]`.
                            
                            // For this implementation, let's assume we grant the input with the 
                            // lowest index among those targeting 'o' if we don't have persistent state per output.
                            // But the requirement says "ARB_TYPE_ROUND_ROBIN".
                            // So we need persistent state.
                            
                            // Let's define `last_granted_input` array.
                            // If `last_granted_input[o]` is valid and targets `o`, increment its RR counter.
                            // If not, find the lowest index valid input targeting `o`.
                            
                            // Since I cannot redefine variables inside the always block easily without scoping issues,
                            // I will rely on the `rr_counter` array which is already declared.
                            // `rr_counter[o]` will store the index of the next input to grant for output `o`.
                            // Wait, `rr_counter` was declared as `[LOG_S_COUNT-1:0]`.
                            // It should probably be `[LOG_S_COUNT-1:0]` representing the input index.
                            
                            // Let's re-evaluate the `rr_counter` usage.
                            // `rr_counter[o]` holds the index of the next input to grant for output `o`.
                            // When we grant input `i` to output `o`, we update `rr_counter[o]` to the next valid input.
                            
                            // Logic:
                            // 1. Check if `rr_counter[o]` is a valid input targeting `o`.
                            // 2. If yes, grant it.
                            // 3. If no (e.g., input became invalid or we cycled), find the next valid input targeting `o`.
                            
                            logic grant_this_input = 0;
                            logic next_rr_idx = rr_counter[o];
                            
                            // Check if current RR candidate is valid and targets this output
                            if (s_axis_tvalid[next_rr_idx] && s_axis_tdest[next_rr_idx] == o) begin
                                grant_this_input = 1;
                            end else begin
                                // Find next valid input for this output
                                for (int k = next_rr_idx + 1; k < S_COUNT; k = k + 1) begin
                                    if (s_axis_tvalid[k] && s_axis_tdest[k] == o) begin
                                        grant_this_input = 1;
                                        next_rr_idx = k;
                                        break;
                                    end
                                end
                                if (!grant_this_input) begin
                                    // Wrap around
                                    for (int k = 0; k <= next_rr_idx; k = k + 1) begin
                                        if (s_axis_tvalid[k] && s_axis_tdest[k] == o) begin
                                            grant_this_input = 1;
                                            next_rr_idx = k;
                                            break;
                                        end
                                    end
                                end
                            end
                            
                            if (grant_this_input) begin
                                next_grant[next_rr_idx] = 1;
                                rr_counter[o] <= next_rr_idx;
                            end
                        end
                    end
                    arb_state <= STATE_GRANTING;
                end else begin
                    // STATE_GRANTING: Maintain grants for outputs that are not ready,
                    // and potentially switch grants for outputs that become ready.
                    
                    for (int o = 0; o < M_COUNT; o = o + 1) begin
                        if (m_axis_tready[o]) begin
                            // Output is ready, grant the next input in RR sequence
                            logic grant_this_input = 0;
                            logic next_rr_idx = rr_counter[o];
                            
                            if (s_axis_tvalid[next_rr_idx] && s_axis_tdest[next_rr_idx] == o) begin
                                grant_this_input = 1;
                            end else begin
                                for (int k = next_rr_idx + 1; k < S_COUNT; k = k + 1) begin
                                    if (s_axis_tvalid[k] && s_axis_tdest[k] == o) begin
                                        grant_this_input = 1;
                                        next_rr_idx = k;
                                        break;
                                    end
                                end
                                if (!grant_this_input) begin
                                    for (int k = 0; k <= next_rr_idx; k = k + 1) begin
                                        if (s_axis_tvalid[k] && s_axis_tdest[k] == o) begin
                                            grant_this_input = 1;
                                            next_rr_idx = k;
                                            break;
                                        end
                                    end
                                end
                            end
                            
                            if (grant_this_input) begin
                                next_grant[next_rr_idx] = 1;
                                rr_counter[o] <= next_rr_idx;
                            end
                        end else begin
                            // Output not ready, keep current grant if exists
                            // Find current grant for this output
                            logic current_grant_idx = '0;
                            for (int i = 0; i < S_COUNT; i = i + 1) begin
                                if (current_grant[i] && s_axis_tdest[i] == o) begin
                                    current_grant_idx = i;
                                    break;
                                end
                            end
                            if (current_grant_idx != '0) begin
                                next_grant[current_grant_idx] = 1;
                                // Do not update rr_counter, keep waiting
                            end
                        end
                    end
                end
                
                current_grant <= next_grant;
            end
        end
    end

    // Round Robin Counter Update Logic (Simplified integration above)
    // The logic above updates `rr_counter` when a grant is made.
    // We need to ensure `rr_counter` persists correctly.
    // The `always` block handles the update on `posedge clk`.
    
    // Input Buffering
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_valid_reg <= '0;
            s_data_reg <= '0;
            s_keep_reg <= '0;
            s_last_reg <= '0;
            s_tid_reg <= '0;
            s_dest_reg <= '0;
            s_user_reg <= '0;
        end else begin
            for (int i = 0; i < S_COUNT; i = i + 1) begin
                if (s_axis_tvalid[i]) begin
                    s_valid_reg[i] <= 1'b1;
                    s_data_reg[i] <= s_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH];
                    s_keep_reg[i] <= s_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH];
                    s_last_reg[i] <= s_axis_tlast[i];
                    s_tid_reg[i] <= s_axis_tid[i*S_ID_WIDTH +: S_ID_WIDTH];
                    s_dest_reg[i] <= s_axis_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH];
                    s_user_reg[i] <= s_axis_tuser[i*USER_WIDTH +: USER_WIDTH];
                end else begin
                    s_valid_reg[i] <= 1'b0;
                end
            end
        end
    end

    // Output Buffering
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_valid_reg <= '0;
            m_data_reg <= '0;
            m_keep_reg <= '0;
            m_last_reg <= '0;
            m_tid_reg <= '0;
            m_dest_reg <= '0;
            m_user_reg <= '0;
        end else begin
            for (int i = 0; i < M_COUNT; i = i + 1) begin
                if (m_axis_tready[i]) begin
                    m_valid_reg[i] <= 1'b1;
                end else begin
                    m_valid_reg[i] <= 1'b0;
                end
            end
        end
    end

    // Data Forwarding Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tready <= '0;
            m_axis_tvalid <= '0;
            m_axis_tdata <= '0;
            m_axis_tkeep <= '0;
            m_axis_tlast <= '0;
            m_axis_tid <= '0;
            m_axis_tdest <= '0;
            m_axis_tuser <= '0;
        end else begin
            // Calculate output ready signals
            // Output is ready if all inputs targeting it are ready? 
            // No, AXI Stream is point-to-point. Output i is ready if the specific input beat is ready.
            // But we have buffering.
            // m_axis_tready[i] should be 1 if there is a valid beat in the buffer for output i AND the input side is ready.
            // Actually, the standard switch behavior:
            // m_axis_tready[i] = 1 if (buffer[i] is valid) AND (input side is ready).
            // Input side ready means: s_axis_tready[i] is asserted.
            // But we need to map input index to output index.
            
            // Let's compute s_axis_tready first.
            // s_axis_tready[i] = 1 if (current_grant[i] is 1) AND (output port s_axis_tdest[i] is ready).
            
            logic [S_COUNT-1:0] s_ready_calc;
            for (int i = 0; i < S_COUNT; i = i + 1) begin
                if (current_grant[i]) begin
                    s_ready_calc[i] = m_axis_tready[s_axis_tdest[i]];
                end else begin
                    s_ready_calc[i] = 1'b0;
                end
            end
            
            // Assign s_axis_tready
            s_axis_tready <= s_ready_calc;
            
            // Now compute output signals
            for (int i = 0; i < M_COUNT; i = i + 1) begin
                // Find which input is currently granted to this output
                logic [S_COUNT-1:0] grant_idx = '0;
                for (int j = 0; j < S_COUNT; j = j + 1) begin
                    if (current_grant[j] && s_axis_tdest[j] == i) begin
                        grant_idx = j;
                        break;
                    end
                end
                
                if (grant_idx != '0) begin
                    // Check if the input is ready
                    if (s_ready_calc[grant_idx]) begin
                        m_axis_tvalid[i] <= 1'b1;
                        m_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH] <= s_data_reg[grant_idx];
                        m_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH] <= s_keep_reg[grant_idx];
                        m_axis_tlast[i] <= s_last_reg[grant_idx];
                        m_axis_tid[i*M_ID_WIDTH +: M_ID_WIDTH] <= s_tid_reg[grant_idx];
                        m_axis_tdest[i*M_DEST_WIDTH +: M_DEST_WIDTH] <= s_dest_reg[grant_idx];
                        m_axis_tuser[i*USER_WIDTH +: USER_WIDTH] <= s_user_reg[grant_idx];
                    end else begin
                        m_axis_tvalid[i] <= 1'b0;
                        m_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH] <= '0;
                        m_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH] <= '0;
                        m_axis_tlast[i] <= '0;
                        m_axis_tid[i*M_ID_WIDTH +: M_ID_WIDTH] <= '0;
                        m_axis_tdest[i*M_DEST_WIDTH +: M_DEST_WIDTH] <= '0;
                        m_axis_tuser[i*USER_WIDTH +: USER_WIDTH] <= '0;
                    end
                end else begin
                    m_axis_tvalid[i] <= 1'b0;
                    m_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH] <= '0;
                    m_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH] <= '0;
                    m_axis_tlast[i] <= '0;
                    m_axis_tid[i*M_ID_WIDTH +: M_ID_WIDTH] <= '0;
                    m_axis_tdest[i*M_DEST_WIDTH +: M_DEST_WIDTH] <= '0;
                    m_axis_tuser[i*USER_WIDTH +: USER_WIDTH] <= '0;
                end
            end
        end
    end

endmodule
```<|im_end|>
