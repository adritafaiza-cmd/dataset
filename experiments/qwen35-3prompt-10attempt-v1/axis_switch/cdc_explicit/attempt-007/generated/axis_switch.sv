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

    // Internal parameters for arbitration
    localparam LOG_S_COUNT = $clog2(S_COUNT);
    localparam LOG_M_COUNT = $clog2(M_COUNT);
    localparam ARB_STATE_WIDTH = 2**LOG_S_COUNT; // One bit per input for round robin

    // State encoding for Round Robin
    typedef enum logic [LOG_S_COUNT-1:0] {
        RR_STATE_0 = 0,
        RR_STATE_1 = 1,
        RR_STATE_2 = 2,
        RR_STATE_3 = 3,
        RR_STATE_4 = 4,
        RR_STATE_5 = 5,
        RR_STATE_6 = 6,
        RR_STATE_7 = 7
    } rr_state_t;

    // Input buffers to handle potential clock domain differences if needed,
    // though here we assume single clock domain for inputs/outputs as per prompt.
    // We use registers to store the current beat data for the arbitration cycle.
    
    // Input storage
    reg [S_COUNT*DATA_WIDTH-1:0]   s_data_reg;
    reg [S_COUNT*KEEP_WIDTH-1:0]   s_keep_reg;
    reg [S_COUNT-1:0]              s_valid_reg;
    reg [S_COUNT-1:0]              s_last_reg;
    reg [S_COUNT*S_ID_WIDTH-1:0]   s_tid_reg;
    reg [S_COUNT*S_DEST_WIDTH-1:0] s_dest_reg;
    reg [S_COUNT*USER_WIDTH-1:0]   s_user_reg;

    // Output storage
    reg [M_COUNT*DATA_WIDTH-1:0]   m_data_reg;
    reg [M_COUNT*KEEP_WIDTH-1:0]   m_keep_reg;
    reg [M_COUNT-1:0]              m_valid_reg;
    reg [M_COUNT-1:0]              m_last_reg;
    reg [M_COUNT*M_ID_WIDTH-1:0]   m_tid_reg;
    reg [M_COUNT*M_DEST_WIDTH-1:0] m_dest_reg;
    reg [M_COUNT*USER_WIDTH-1:0]   m_user_reg;

    // Arbitration State
    reg [LOG_S_COUNT-1:0] rr_state;
    reg [LOG_S_COUNT-1:0] rr_next_state;
    reg [S_COUNT-1:0]     rr_grant;
    reg [S_COUNT-1:0]     rr_request;
    reg [S_COUNT-1:0]     rr_active; // Tracks if an input is currently active in this state

    // Output selection logic
    wire [S_COUNT-1:0]    sel_input;
    wire [S_COUNT-1:0]    sel_output;

    // ---------------------------------------------------------
    // Input Sampling (Synchronous)
    // ---------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_data_reg      <= {S_COUNT{1'b0}};
            s_keep_reg      <= {S_COUNT{1'b0}};
            s_valid_reg     <= {S_COUNT{1'b0}};
            s_last_reg      <= {S_COUNT{1'b0}};
            s_tid_reg       <= {S_COUNT{S_ID_WIDTH}{1'b0}};
            s_dest_reg      <= {S_COUNT{S_DEST_WIDTH}{1'b0}};
            s_user_reg      <= {S_COUNT{USER_WIDTH}{1'b0}};
        end else begin
            for (integer i = 0; i < S_COUNT; i = i + 1) begin
                if (s_axis_tvalid[i]) begin
                    s_data_reg[i*DATA_WIDTH +: DATA_WIDTH] <= s_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH];
                    s_keep_reg[i*KEEP_WIDTH +: KEEP_WIDTH] <= s_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH];
                    s_valid_reg[i] <= 1'b1;
                    s_last_reg[i]  <= s_axis_tlast[i];
                    s_tid_reg[i*SID_WIDTH +: SID_WIDTH]   <= s_axis_tid[i*SID_WIDTH +: SID_WIDTH];
                    s_dest_reg[i*S_DEST_WIDTH +: S_DEST_WIDTH] <= s_axis_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH];
                    s_user_reg[i*USER_WIDTH +: USER_WIDTH] <= s_axis_tuser[i*USER_WIDTH +: USER_WIDTH];
                end else begin
                    s_valid_reg[i] <= 1'b0;
                end
            end
        end
    end

    // ---------------------------------------------------------
    // Output Sampling (Synchronous)
    // ---------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_data_reg      <= {M_COUNT{1'b0}};
            m_keep_reg      <= {M_COUNT{1'b0}};
            m_valid_reg     <= {M_COUNT{1'b0}};
            m_last_reg      <= {M_COUNT{1'b0}};
            m_tid_reg       <= {M_COUNT{M_ID_WIDTH}{1'b0}};
            m_dest_reg      <= {M_COUNT{M_DEST_WIDTH}{1'b0}};
            m_user_reg      <= {M_COUNT{USER_WIDTH}{1'b0}};
        end else begin
            for (integer i = 0; i < M_COUNT; i = i + 1) begin
                if (m_axis_tready[i]) begin
                    m_data_reg[i*DATA_WIDTH +: DATA_WIDTH] <= m_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH];
                    m_keep_reg[i*KEEP_WIDTH +: KEEP_WIDTH] <= m_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH];
                    m_valid_reg[i] <= 1'b1;
                    m_last_reg[i]  <= m_axis_tlast[i];
                    m_tid_reg[i*M_ID_WIDTH +: M_ID_WIDTH]   <= m_axis_tid[i*M_ID_WIDTH +: M_ID_WIDTH];
                    m_dest_reg[i*M_DEST_WIDTH +: M_DEST_WIDTH] <= m_axis_tdest[i*M_DEST_WIDTH +: M_DEST_WIDTH];
                    m_user_reg[i*USER_WIDTH +: USER_WIDTH] <= m_axis_tuser[i*USER_WIDTH +: USER_WIDTH];
                end else begin
                    m_valid_reg[i] <= 1'b0;
                end
            end
        end
    end

    // ---------------------------------------------------------
    // Arbitration Logic
    // ---------------------------------------------------------
    // Determine requests based on valid inputs
    always @(*) begin
        rr_request = {S_COUNT{1'b0}};
        for (integer i = 0; i < S_COUNT; i = i + 1) begin
            if (s_valid_reg[i]) begin
                rr_request[i] = 1'b1;
            end
        end
    end

    // Round Robin State Machine
    always @(*) begin
        if (ARB_TYPE_ROUND_ROBIN) begin
            rr_next_state = rr_state;
            rr_active = {S_COUNT{1'b0}};
            
            // Check if current state has a request
            if (rr_request[rr_state]) begin
                rr_active[rr_state] = 1'b1;
                // If multiple requests, move to next state
                if (rr_request[rr_state + 1]) begin
                    rr_next_state = rr_state + 1;
                end else if (rr_request[rr_state + 2]) begin
                    rr_next_state = rr_state + 2;
                end else if (rr_request[rr_state + 3]) begin
                    rr_next_state = rr_state + 3;
                end else if (rr_request[rr_state + 4]) begin
                    rr_next_state = rr_state + 4;
                end else if (rr_request[rr_state + 5]) begin
                    rr_next_state = rr_state + 5;
                end else if (rr_request[rr_state + 6]) begin
                    rr_next_state = rr_state + 6;
                end else if (rr_request[rr_state + 7]) begin
                    rr_next_state = rr_state + 7;
                end else begin
                    // No other requests, stay or wrap around logic handled by state transition
                    // Actually, standard RR: if current is granted, next state is current + 1 (wrapping)
                    // But we need to find the next *active* request.
                    // Simplified approach: Iterate to find next set bit.
                    rr_next_state = rr_state;
                    for (integer k = 1; k < S_COUNT; k = k + 1) begin
                        if (rr_request[(rr_state + k) % S_COUNT]) begin
                            rr_next_state = (rr_state + k) % S_COUNT;
                            break;
                        end
                    end
                end
            end else begin
                // No request in current state, find next active request
                for (integer k = 1; k < S_COUNT; k = k + 1) begin
                    if (rr_request[(rr_state + k) % S_COUNT]) begin
                        rr_next_state = (rr_state + k) % S_COUNT;
                        break;
                    end
                end
            end
        end else begin
            // Simple priority arbiter (LSB high priority if ARB_LSB_HIGH_PRIORITY)
            rr_next_state = 0;
            if (ARB_LSB_HIGH_PRIORITY) begin
                for (integer i = 0; i < S_COUNT; i = i + 1) begin
                    if (rr_request[i]) begin
                        rr_next_state = i;
                        break;
                    end
                end
            end else begin
                for (integer i = S_COUNT-1; i >= 0; i = i - 1) begin
                    if (rr_request[i]) begin
                        rr_next_state = i;
                        break;
                    end
                end
            end
        end
    end

    // Update state and generate grant
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rr_state <= 0;
            rr_grant <= {S_COUNT{1'b0}};
        end else begin
            rr_state <= rr_next_state;
            rr_grant <= {S_COUNT{1'b0}};
            rr_grant[rr_state] <= 1'b1;
        end
    end

    // ---------------------------------------------------------
    // Output Selection and Generation
    // ---------------------------------------------------------
    // Determine which input maps to which output based on tdest
    // Since we are doing a switch, we need to map Input -> Output.
    // However, the prompt says "Route S_COUNT inputs to M_COUNT outputs using tdest".
    // This implies a many-to-many or many-to-one mapping based on destination.
    // But AXI Switch typically routes Input[i] to Output[j] where Output[j].tdest == Input[i].tdest.
    // If multiple inputs have same tdest, they go to same output (or different outputs if M_COUNT > S_COUNT and we split).
    // Given "Do not drop or duplicate a beat", if multiple inputs target same output, 
    // we must serialize them onto that output.
    
    // Strategy:
    // 1. Arbitration selects one INPUT (src) to be granted.
    // 2. We check if the granted input's destination (s_dest_reg[src]) matches any OUTPUT that is ready.
    // 3. If match found, we route data to that output.
    // 4. If multiple outputs are ready for the same destination, we pick one (e.g., lowest index).
    // 5. If no output is ready for the destination, the input waits (tready=0).
    
    // We need to track which output is selected for the granted input.
    wire [M_COUNT-1:0] out_ready_for_dest;
    wire [M_COUNT-1:0] out_valid_for_dest;
    
    // Calculate which outputs are ready for a specific destination value
    // Since tdest width varies, we compare the lower bits or full width.
    // Assuming tdest is the routing key.
    
    // Helper: Check if output 'o' is ready AND its destination matches input 'i's destination
    // We will generate a signal 'match[i][o]'
    
    // To avoid combinational explosion with large widths, we iterate in generate or logic.
    // Given Verilog-2001, we use always blocks or generate. Let's use logic for clarity.
    
    // Determine the destination of the granted input
    wire [S_DEST_WIDTH-1:0] granted_dest;
    assign granted_dest = s_dest_reg[rr_state];

    // Find the best output for this granted destination
    // Priority: Lowest index output that is ready and has matching dest.
    wire [M_COUNT-1:0] out_sel;
    assign out_sel = 0; // Default none
    
    // We need to find the first 'o' such that m_axis_tready[o] && (m_axis_tdest[o] == granted_dest)
    // Note: m_axis_tdest is output, but we are generating it. 
    // Wait, the switch logic determines m_axis_tdest based on s_axis_tdest.
    // So we compare s_dest_reg[rr_state] with the target output's expected dest.
    // But the target output's dest is just the input's dest.
    // So we just need to find an output 'o' that is ready.
    // If multiple outputs are ready, we pick one.
    // If the input's dest doesn't match the output's configured dest (if any), we can't route.
    // But in a switch, the output's dest is determined by the input.
    // So any ready output can accept the data, provided we set its tdest correctly.
    // However, if M_CONNECT is used, it might restrict which inputs go to which outputs.
    // M_CONNECT is a matrix. M_CONNECT[o][i] = 1 means input i can go to output o.
    
    // Let's refine the routing logic:
    // 1. Input 'rr_state' is granted.
    // 2. Check M_CONNECT[output][rr_state]. If 0, cannot route to that output.
    // 3. Check m_axis_tready[output].
    // 4. Select the first output that satisfies both.
    
    wire [M_COUNT-1:0] can_route;
    always @(*) begin
        can_route = {M_COUNT{1'b0}};
        for (integer o = 0; o < M_COUNT; o = o + 1) begin
            if (m_axis_tready[o]) begin
                // Check connectivity
                if (M_CONNECT[o][rr_state]) begin
                    can_route[o] = 1'b1;
                end
            end
        end
    end

    // Select the first available output
    wire [M_COUNT-1:0] out_sel_idx;
    assign out_sel_idx = 0;
    for (integer o = 0; o < M_COUNT; o = o + 1) begin
        if (can_route[o]) begin
            out_sel_idx = o;
            break;
        end
    end

    // Generate Output Signals
    always @(*) begin
        // Default values
        m_axis_tdata = {M_COUNT{1'b0}};
        m_axis_tkeep = {M_COUNT{1'b0}};
        m_axis_tvalid = {M_COUNT{1'b0}};
        m_axis_tlast = {M_COUNT{1'b0}};
        m_axis_tid = {M_COUNT{M_ID_WIDTH}{1'b0}};
        m_axis_tdest = {M_COUNT{M_DEST_WIDTH}{1'b0}};
        m_axis_tuser = {M_COUNT{USER_WIDTH}{1'b0}};
        s_axis_tready = {S_COUNT{1'b0}};

        if (rr_grant[rr_state]) begin
            // Check if we found a valid output
            if (out_sel_idx != 0) begin // Assuming 0 is invalid if loop didn't find, but loop starts at 0.
                // Actually if out_sel_idx is found, it will be >=0.
                // Need to distinguish "not found" vs "found 0".
                // Let's use a flag.
            end
        end
    end

    // Re-implement output generation with a flag for "found"
    wire out_found;
    assign out_found = (out_sel_idx != 0) || (out_sel_idx == 0 && can_route[0]); 
    // Wait, if can_route[0] is 1, out_sel_idx becomes 0.
    // So out_found is simply (out_sel_idx != 0) OR (out_sel_idx == 0 && can_route[0]).
    // Simpler: out_found = (out_sel_idx >= 0) is always true if loop runs.
    // We need to know if the loop found anything.
    // Let's use a separate wire.
    
    wire [M_COUNT-1:0] valid_out_sel;
    assign valid_out_sel = {M_COUNT{1'b0}};
    for (integer o = 0; o < M_COUNT; o = o + 1) begin
        if (can_route[o]) begin
            valid_out_sel[o] = 1'b1;
        end
    end
    wire out_has_ready = |valid_out_sel;
    wire [M_COUNT-1:0] final_out_sel;
    assign final_out_sel = 0;
    for (integer o = 0; o < M_COUNT; o = o + 1) begin
        if (valid_out_sel[o]) begin
            final_out_sel = o;
            break;
        end
    end

    // Now generate the outputs
    always @(*) begin
        m_axis_tdata = {M_COUNT{1'b0}};
        m_axis_tkeep = {M_COUNT{1'b0}};
        m_axis_tvalid = {M_COUNT{1'b0}};
        m_axis_tlast = {M_COUNT{1'b0}};
        m_axis_tid = {M_COUNT{M_ID_WIDTH}{1'b0}};
        m_axis_tdest = {M_COUNT{M_DEST_WIDTH}{1'b0}};
        m_axis_tuser = {M_COUNT{USER_WIDTH}{1'b0}};
        s_axis_tready = {S_COUNT{1'b0}};

        if (rr_grant[rr_state] && final_out_sel != 0) begin
            // Route data from input rr_state to output final_out_sel
            m_axis_tdata[final_out_sel*DATA_WIDTH +: DATA_WIDTH] = s_data_reg[rr_state*DATA_WIDTH +: DATA_WIDTH];
            m_axis_tkeep[final_out_sel*KEEP_WIDTH +: KEEP_WIDTH] = s_keep_reg[rr_state*KEEP_WIDTH +: KEEP_WIDTH];
            m_axis_tvalid[final_out_sel] = 1'b1;
            m_axis_tlast[final_out_sel] = s_last_reg[rr_state];
            
            // ID handling
            if (ID_ENABLE) begin
                m_axis_tid[final_out_sel*M_ID_WIDTH +: M_ID_WIDTH] = s_tid_reg[rr_state*M_ID_WIDTH +: M_ID_WIDTH];
            end else begin
                // If ID not enabled, maybe update or keep 0? 
                // Prompt says "See Behavior". Usually if not enabled, output 0 or keep.
                // Let's keep 0 or pass through if width allows. 
                // Standard: if not enabled, output 0.
                m_axis_tid[final_out_sel*M_ID_WIDTH +: M_ID_WIDTH] = 0;
            end

            // Dest handling
            // Convert S_DEST_WIDTH to M_DEST_WIDTH if necessary, or just pass.
            // Assuming M_DEST_WIDTH >= S_DEST_WIDTH or we truncate/extend.
            // Usually M_DEST_WIDTH is the width of the output dest field.
            // We assign the lower bits or the whole thing if widths match.
            // If M_DEST_WIDTH < S_DEST_WIDTH, we might need to truncate.
            // If M_DEST_WIDTH > S_DEST_WIDTH, we might need to zero extend.
            // Let's assume M_DEST_WIDTH covers S_DEST_WIDTH or we just assign the relevant bits.
            // For safety, assign the lower M_DEST_WIDTH bits of the source dest.
            m_axis_tdest[final_out_sel*M_DEST_WIDTH +: M_DEST_WIDTH] = s_dest_reg[rr_state*S_DEST_WIDTH +: S_DEST_WIDTH][S_DEST_WIDTH-M_DEST_WIDTH+:M_DEST_WIDTH];
            
            // User handling
            if (USER_ENABLE) begin
                m_axis_tuser[final_out_sel*USER_WIDTH +: USER_WIDTH] = s_user_reg[rr_state*USER_WIDTH +: USER_WIDTH];
            end else begin
                m_axis_tuser[final_out_sel*USER_WIDTH +: USER_WIDTH] = 0;
            end

            // Grant the input
            s_axis_tready[rr_state] = 1'b1;
        end
    end

    // ---------------------------------------------------------
    // Output Registering (for CDC safety if outputs are registered)
    // The prompt asks for safe CDC. 
    // If the outputs are combinational driven by the arbitration, 
    // and the arbitration is synchronous, the outputs are synchronous to clk.
    // However, AXI Stream usually requires the output registers to be driven by the ready signal.
    // The logic above drives the outputs directly. 
    // To ensure CDC safety and proper handshake, we should register the output signals
    // so that the output registers are updated on the clock edge when ready is asserted.
    // But the current logic updates m_axis_tvalid etc. based on rr_grant and final_out_sel.
    // This is combinational. 
    // To make it synchronous and safe:
    // We need to store the "pending" data in the output registers (m_data_reg, etc.)
    // and only drive the output pins when m_axis_tready is asserted.
    // The current "Output Sampling" block already does this: it updates m_data_reg when m_axis_tready is 1.
    // But wait, the "Output Sampling" block updates m_data_reg based on m_axis_tready.
    // And the combinational logic drives m_axis_tdata from s_data_reg.
    // This creates a path: s_data_reg -> m_axis_tdata (combinational) -> m_axis_tready (input) -> m_data_reg (registered).
    // This is fine for data flow, but the output pins (m_axis_tdata) are driven combinatorially.
    // If m_axis_tready changes, the output data might change combinatorially.
    // To be strictly synchronous and safe, we should register the output data.
    // Let's modify the output generation to be synchronous.
    
    // Revised Output Logic:
    // 1. Determine which input is granted (rr_state).
    // 2. Determine which output is selected (final_out_sel).
    // 3. If granted and selected, update the "pending" output registers (m_data_reg, etc.)
    //    ONLY if the output is ready? 
    //    No, the output registers should hold the data to be sent.
    //    The output pins (m_axis_tdata) should be driven by these registers.
    //    The validity (m_axis_tvalid) should be driven by the arbitration result.
    //    But the arbitration result depends on m_axis_tready (input).
    //    This creates a dependency loop if not careful.
    
    // Correct Synchronous Flow:
    // 1. Arbitration logic (combinational) determines:
    //    - Which input is granted (grant_idx).
    //    - Which output is selected (out_idx) based on ready signals.
    // 2. On clock edge:
    //    - If grant_idx is valid AND out_idx is valid:
    //      - Update the "next" output data registers (m_next_data, etc.) with the input data.
    //      - Set m_axis_tvalid[out_idx] = 1.
    //    - Else:
    //      - Clear m_axis_tvalid[out_idx].
    // 3. The output data pins (m_axis_tdata) are driven by the "next" data registers.
    // 4. The output registers (m_data_reg) are updated on clock edge when ready is asserted?
    //    Actually, the standard way is:
    //    - Store input data in input registers (done).
    //    - Arbitration selects input and output.
    //    - If output is ready, transfer data from input register to output register.
    //    - Drive output pins from output register.
    //    - Assert tvalid on output register.
    
    // Let's restructure the output section to be fully synchronous.
    
    // Input data is already in s_data_reg, s_keep_reg, etc.
    // We need output data registers: m_out_data_reg, m_out_keep_reg, etc.
    // And a valid flag for each output: m_out_valid_reg.
    
    // But the prompt defines m_axis_tdata as output.
    // Let's use the existing m_data_reg as the output register.
    // And m_valid_reg as the output valid register.
    
    // Logic:
    // 1. Combinational: Determine grant (rr_state) and out_sel (final_out_sel).
    // 2. Sequential:
    //    If (rr_grant[rr_state] && final_out_sel != 0) begin
    //       // Transfer data to output register
    //       m_data_reg[final_out_sel*DATA_WIDTH +: DATA_WIDTH] <= s_data_reg[rr_state*DATA_WIDTH +: DATA_WIDTH];
    //       m_keep_reg[final_out_sel*KEEP_WIDTH +: KEEP_WIDTH] <= s_keep_reg[rr_state*KEEP_WIDTH +: KEEP_WIDTH];
    //       m_last_reg[final_out_sel] <= s_last_reg[rr_state];
    //       m_tid_reg[final_out_sel*M_ID_WIDTH +: M_ID_WIDTH] <= s_tid_reg[rr_state*M_ID_WIDTH +: M_ID_WIDTH];
    //       m_dest_reg[final_out_sel*M_DEST_WIDTH +: M_DEST_WIDTH] <= s_dest_reg[rr_state*S_DEST_WIDTH +: S_DEST_WIDTH][S_DEST_WIDTH-M_DEST_WIDTH+:M_DEST_WIDTH];
    //       m_user_reg[final_out_sel*USER_WIDTH +: USER_WIDTH] <= s_user_reg[rr_state*USER_WIDTH +: USER_WIDTH];
    //       m_valid_reg[final_out_sel] <= 1'b1;
    //    end else begin
    //       m_valid_reg[final_out_sel] <= 1'b0;
    //    end
    
    // Wait, if multiple outputs are ready, we pick one. The others should be invalid.
    // The above logic sets m_valid_reg[final_out_sel] = 1.
    // What about other outputs? They should be 0.
    // So we need to clear all m_valid_reg first, then set the selected one.
    
    // Also, we need to ensure that if an output was previously valid but not selected this cycle, it becomes invalid.
    // The "else" block above only clears the selected one.
    // We need to clear ALL outputs if not selected.
    
    // Revised Sequential Logic for Outputs:
    // Always @(posedge clk or posedge rst)
    //   if (rst) ...
    //   else begin
    //      // Clear all valid flags
    //      m_valid_reg = {M_COUNT{1'b0}};
    //      // Clear other regs? No, keep data until valid.
    //      
    //      if (rr_grant[rr_state] && final_out_sel != 0) begin
    //          // Update data for the selected output
    //          m_data_reg[final_out_sel*DATA_WIDTH +: DATA_WIDTH] <= s_data_reg[rr_state*DATA_WIDTH +: DATA_WIDTH];
    //          m_keep_reg[final_out_sel*KEEP_WIDTH +: KEEP_WIDTH] <= s_keep_reg[rr_state*KEEP_WIDTH +: KEEP_WIDTH];
    //          m_last_reg[final_out_sel] <= s_last_reg[rr_state];
    //          m_tid_reg[final_out_sel*M_ID_WIDTH +: M_ID_WIDTH] <= s_tid_reg[rr_state*M_ID_WIDTH +: M_ID_WIDTH];
    //          m_dest_reg[final_out_sel*M_DEST_WIDTH +: M_DEST_WIDTH] <= s_dest_reg[rr_state*S_DEST_WIDTH +: S_DEST_WIDTH][S_DEST_WIDTH-M_DEST_WIDTH+:M_DEST_WIDTH];
    //          m_user_reg[final_out_sel*USER_WIDTH +: USER_WIDTH] <= s_user_reg[rr_state*USER_WIDTH +: USER_WIDTH];
    //          m_valid_reg[final_out_sel] <= 1'b1;
    //      end
    //   end
    
    // But wait, what if the selected output changes? The data should be updated.
    // What if the selected output is the same? The data is updated (no change).
    // What if the selected output was previously valid but now not selected?
    // The "else" clears m_valid_reg[final_out_sel]. But what about other outputs that were valid?
    // They are not cleared.
    // So we must clear ALL m_valid_reg first.
    
    // Also, we need to handle the case where no output is selected.
    // Then all m_valid_reg should be 0.
    
    // Let's rewrite the output sequential block.
    
    // ---------------------------------------------------------
    // Final Implementation Structure
    // ---------------------------------------------------------
    
    // Input Registers (already done)
    
    // Output Registers
    reg [M_COUNT*DATA_WIDTH-1:0]   m_out_data_reg;
    reg [M_COUNT*KEEP_WIDTH-1:0]   m_out_keep_reg;
    reg [M_COUNT-1:0]              m_out_valid_reg;
    reg [M_COUNT-1:0]              m_out_last_reg;
    reg [M_COUNT*M_ID_WIDTH-1:0]   m_out_tid_reg;
    reg [M_COUNT*M_DEST_WIDTH-1:0] m_out_dest_reg;
    reg [M_COUNT*USER_WIDTH-1:0]   m_out_user_reg;

    // Combinational Logic for Arbitration and Selection
    wire [S_COUNT-1:0] rr_grant_comb;
    wire [M_COUNT-1:0] final_out_sel_comb;
    wire out_has_ready_comb;

    // Re-use the logic for rr_grant and final_out_sel
    // We can put this in an always block or generate.
    // Since it depends on s_valid_reg (registered) and m_axis_tready (input), it's combinational.
    
    assign rr_grant_comb = {S_COUNT{1'b0}};
    if (ARB_TYPE_ROUND_ROBIN) begin
        // Logic to find next state and grant
        // We need to implement the state machine logic here or in a separate always block.
        // Let's put the state machine in an always block to keep combinational clean.
    end
    
    // Actually, let's keep the state machine in an always block and drive rr_grant_comb from it.
    // And drive final_out_sel_comb from the connectivity logic.
    
    // ---------------------------------------------------------
    // State Machine and Grant Generation
    // ---------------------------------------------------------
    always @(*) begin
        rr_next_state = 0;
        rr_active = {S_COUNT{1'b0}};
        rr_grant_comb = {S_COUNT{1'b0}};
        
        if (ARB_TYPE_ROUND_ROBIN) begin
            // Find next active request
            for (integer i = 0; i < S_COUNT; i = i + 1) begin
                if (s_valid_reg[i]) begin
                    rr_active[i] = 1'b1;
                    // Check if this is the current state
                    if (i == rr_state) begin
                        rr_grant_comb[i] = 1'b1;
                        // Find next request for next state
                        for (integer k = 1; k < S_COUNT; k = k + 1) begin
                            if (s_valid_reg[(rr_state + k) % S_COUNT]) begin
                                rr_next_state = (rr_state + k) % S_COUNT;
                                break;
                            end
                        end
                    end else if (i > rr_state) begin
                        // If we are past the current state, we might need to jump
                        // But standard RR: if current is granted, next is next request.
                        // If current is not granted (because no request?), then next is first request.
                        // Simplified: Just find the first request >= rr_state.
                        // If found, that's the next state.
                        // If not found, wrap around to first request.
                        rr_next_state = i;
                        break;
                    end
                end
            end
            
            // If no request found in loop (should not happen if s_valid_reg has 1), 
            // or if we need to handle the case where current state has no request.
            // Let's redo the RR logic cleanly.
            
            // Reset next state to current
            rr_next_state = rr_state;
            
            // Check if current state has a request
            if (!s_valid_reg[rr_state]) begin
                // Current state has no request, find next
                for (integer k = 1; k < S_COUNT; k = k + 1) begin
                    if (s_valid_reg[(rr_state + k) % S_COUNT]) begin
                        rr_next_state = (rr_state + k) % S_COUNT;
                        break;
                    end
                end
            end else begin
                // Current state has request, grant it
                rr_grant_comb[rr_state] = 1'b1;
                // Find next state
                for (integer k = 1; k < S_COUNT; k = k + 1) begin
                    if (s_valid_reg[(rr_state + k) % S_COUNT]) begin
                        rr_next_state = (rr_state + k