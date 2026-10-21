```verilog
module arbiter #
(
    parameter PORTS = 4,
    parameter ARB_TYPE_ROUND_ROBIN = 0,
    parameter ARB_BLOCK = 0,
    parameter ARB_BLOCK_ACK = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 0
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [PORTS-1:0]         request,
    input  wire [PORTS-1:0]         acknowledge,
    output wire [PORTS-1:0]         grant,
    output wire                     grant_valid,
    output wire [$clog2(PORTS)-1:0] grant_encoded
);

    localparam LOG_PORTS = $clog2(PORTS);
    localparam LOG_ACK = $clog2(PORTS);

    // State encoding for Round Robin
    // We need to track the current "head" of the queue.
    // State 0: No request active (or just reset)
    // State 1..PORTS: Current head index
    localparam STATE_IDLE = 0;
    localparam STATE_ACTIVE = 1;

    reg [LOG_PORTS-1:0] current_head;
    reg [LOG_PORTS-1:0] next_head;
    reg state;
    reg [PORTS-1:0] last_grant;
    reg [PORTS-1:0] pending_grant;
    reg grant_valid_reg;

    // Determine priority logic based on type
    // If Round Robin: Priority is determined by rotating the head pointer.
    // If Fixed: Priority is determined by LSB/MSB selection.

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_head <= 0;
            next_head <= 0;
            state <= STATE_IDLE;
            last_grant <= 0;
            pending_grant <= 0;
            grant_valid_reg <= 0;
        end
        else begin
            // 1. Calculate Next Head for Round Robin
            if (ARB_TYPE_ROUND_ROBIN) begin
                if (state == STATE_IDLE) begin
                    // Find the first active request based on LSB/MSB priority
                    if (ARB_LSB_HIGH_PRIORITY) begin
                        next_head <= $clog2(request); // Returns index of MSB if LSB high priority logic implies MSB wins? 
                        // Wait, standard interpretation:
                        // LSB_HIGH_PRIORITY = 1: The requestor with the lowest index (LSB of the vector) has highest priority.
                        // LSB_HIGH_PRIORITY = 0: The requestor with the highest index (MSB of the vector) has highest priority.
                        // $clog2 returns the index of the MSB. 
                        // If LSB_HIGH_PRIORITY is 1, we want the smallest index. 
                        // If LSB_HIGH_PRIORITY is 0, we want the largest index.
                        
                        // Let's refine the initial selection logic.
                        if (ARB_LSB_HIGH_PRIORITY) begin
                            // Find smallest index i where request[i] == 1
                            next_head <= 0;
                            for (integer i = 0; i < PORTS; i = i + 1) begin
                                if (request[i]) begin
                                    next_head <= i;
                                    break;
                                end
                            end
                        end
                        else begin
                            // Find largest index i where request[i] == 1
                            next_head <= PORTS - 1;
                            for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                                if (request[i]) begin
                                    next_head <= i;
                                    break;
                                end
                            end
                        end
                    end
                    else begin
                        // Default Fixed Priority (MSB wins if LSB_HIGH_PRIORITY=0, LSB wins if =1)
                        // Actually, the parameter name suggests:
                        // LSB_HIGH_PRIORITY = 1 -> LSB (index 0) is highest priority.
                        // LSB_HIGH_PRIORITY = 0 -> MSB (index PORTS-1) is highest priority.
                        
                        if (ARB_LSB_HIGH_PRIORITY) begin
                            next_head <= 0;
                            for (integer i = 0; i < PORTS; i = i + 1) begin
                                if (request[i]) begin
                                    next_head <= i;
                                    break;
                                end
                            end
                        end
                        else begin
                            next_head <= PORTS - 1;
                            for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                                if (request[i]) begin
                                    next_head <= i;
                                    break;
                                end
                            end
                        end
                    end
                    state <= STATE_ACTIVE;
                end
                else begin
                    // Round Robin rotation
                    next_head <= current_head + 1;
                    if (next_head >= PORTS) begin
                        next_head <= 0;
                    end
                end
            end
            else begin
                // Fixed Priority Mode
                if (ARB_LSB_HIGH_PRIORITY) begin
                    // LSB (lowest index) wins
                    next_head <= 0;
                    for (integer i = 0; i < PORTS; i = i + 1) begin
                        if (request[i]) begin
                            next_head <= i;
                            break;
                        end
                    end
                end
                else begin
                    // MSB (highest index) wins
                    next_head <= PORTS - 1;
                    for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                        if (request[i]) begin
                            next_head <= i;
                            break;
                        end
                    end
                end
                state <= STATE_ACTIVE;
            end
        end
    end

    // State Machine for Blocking
    // State 0: Idle / Waiting for request
    // State 1: Granting (holding grant)
    
    // Re-architecting state machine for clarity and blocking behavior
    // State: 0 = No active grant, 1 = Active grant (waiting for ack or req drop)
    
    reg [LOG_PORTS-1:0] candidate;
    reg state_fsm; // 0: Idle, 1: Holding Grant

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_fsm <= 0;
            candidate <= 0;
            grant_valid_reg <= 0;
            pending_grant <= 0;
        end
        else begin
            // Determine Candidate
            if (ARB_TYPE_ROUND_ROBIN) begin
                if (state_fsm == 0) begin
                    // Find first active request
                    if (ARB_LSB_HIGH_PRIORITY) begin
                        candidate <= 0;
                        for (integer i = 0; i < PORTS; i = i + 1) begin
                            if (request[i]) begin
                                candidate <= i;
                                break;
                            end
                        end
                    end
                    else begin
                        candidate <= PORTS - 1;
                        for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                            if (request[i]) begin
                                candidate <= i;
                                break;
                            end
                        end
                    end
                    if (candidate == 0) begin
                        // No request found, reset head to 0 for next cycle
                        // But we need to track the head for RR. 
                        // If no request, we just stay idle.
                        // However, for RR, we need to know where to start next time.
                        // If no request, we can assume head stays at 0 or we need a separate head register.
                        // Let's use a separate head register for RR.
                    end
                end
                else begin
                    // Rotate head
                    candidate <= current_head;
                    if (candidate == 0) begin
                        // Check if request[0] is still there
                        if (request[0]) begin
                            // Grant 0
                        end
                        else begin
                            // Move to next
                            current_head <= 1;
                            candidate <= 1;
                            if (request[1]) begin
                                // Grant 1
                            end
                            else begin
                                // Continue searching... this logic is getting complex in combinational inside sequential.
                                // Better approach: Maintain a 'next_head' register that updates every cycle.
                            end
                        end
                    end
                end
            end
            else begin
                // Fixed Priority
                if (ARB_LSB_HIGH_PRIORITY) begin
                    candidate <= 0;
                    for (integer i = 0; i < PORTS; i = i + 1) begin
                        if (request[i]) begin
                            candidate <= i;
                            break;
                        end
                    end
                end
                else begin
                    candidate <= PORTS - 1;
                    for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                        if (request[i]) begin
                            candidate <= i;
                            break;
                        end
                    end
                end
            end
        end
    end

    // Revised State Machine with explicit Head Tracking for RR
    reg [LOG_PORTS-1:0] rr_head;
    reg state_fsm; // 0: Idle, 1: Holding

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rr_head <= 0;
            state_fsm <= 0;
            grant_valid_reg <= 0;
            pending_grant <= 0;
        end
        else begin
            // 1. Determine Candidate based on current state and logic
            reg [LOG_PORTS-1:0] temp_candidate;
            
            if (ARB_TYPE_ROUND_ROBIN) begin
                if (state_fsm == 0) begin
                    // No grant active, find first request starting from rr_head
                    temp_candidate = rr_head;
                    if (temp_candidate >= PORTS) temp_candidate = 0;
                    
                    // Search for request starting from temp_candidate
                    reg found = 0;
                    for (integer i = 0; i < PORTS; i = i + 1) begin
                        if (request[temp_candidate]) begin
                            temp_candidate <= temp_candidate;
                            found <= 1;
                            break;
                        end
                        temp_candidate <= temp_candidate + 1;
                        if (temp_candidate >= PORTS) temp_candidate <= 0;
                    end
                    
                    if (found) begin
                        candidate <= temp_candidate;
                        // Update rr_head to the next port for next time
                        rr_head <= temp_candidate + 1;
                        if (rr_head >= PORTS) rr_head <= 0;
                        state_fsm <= 1;
                    end
                    else begin
                        // No request found, keep rr_head as is (or reset to 0? Usually keep to resume)
                        // If no request, we stay idle.
                        state_fsm <= 0;
                        candidate <= 0;
                    end
                end
                else begin
                    // Holding state: Grant the current rr_head if requested
                    if (request[rr_head]) begin
                        candidate <= rr_head;
                    end
                    else begin
                        // Request dropped, move head
                        rr_head <= rr_head + 1;
                        if (rr_head >= PORTS) rr_head <= 0;
                        candidate <= 0;
                        state_fsm <= 0;
                    end
                end
            end
            else begin
                // Fixed Priority
                if (ARB_LSB_HIGH_PRIORITY) begin
                    temp_candidate = 0;
                    for (integer i = 0; i < PORTS; i = i + 1) begin
                        if (request[i]) begin
                            temp_candidate <= i;
                            break;
                        end
                    end
                    candidate <= temp_candidate;
                end
                else begin
                    temp_candidate = PORTS - 1;
                    for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                        if (request[i]) begin
                            temp_candidate <= i;
                            break;
                        end
                    end
                    candidate <= temp_candidate;
                end
                // In fixed priority, if request drops, priority recalculates immediately next cycle.
                // So state_fsm is not strictly needed for blocking unless ARB_BLOCK is set.
                // But if ARB_BLOCK is set, we need to hold the grant.
                // The logic below handles the holding via state_fsm.
                
                if (state_fsm == 0) begin
                    if (candidate != 0) begin
                        state_fsm <= 1;
                    end
                end
                else begin
                    // Check if the current candidate is still requesting
                    if (ARB_BLOCK && ARB_BLOCK_ACK) begin
                        // If acknowledge is high, we might release? 
                        // Spec: "hold the grant until acknowledge (ARB_BLOCK_ACK nonzero) or until request drops"
                        // This phrasing is slightly ambiguous. 
                        // Interpretation A: Hold until (Ack is received) OR (Request drops).
                        // Interpretation B: Hold until (Ack is received) AND (Request drops)? No, "or".
                        // Usually "Block" means: Grant is given. It is removed ONLY if Ack comes (if ARB_BLOCK_ACK=1) 
                        // OR if the requestor releases (if ARB_BLOCK_ACK=0).
                        
                        // Let's assume:
                        // If ARB_BLOCK_ACK == 1: Grant persists until Ack signal is seen.
                        // If ARB_BLOCK_ACK == 0: Grant persists until Request signal is seen (dropped).
                        
                        if (ARB_BLOCK_ACK) begin
                            if (acknowledge[candidate]) begin
                                // Ack received, release grant
                                state_fsm <= 0;
                                candidate <= 0;
                            end
                            // Else keep holding
                        end
                        else begin
                            if (!request[candidate]) begin
                                // Request dropped, release grant
                                state_fsm <= 0;
                                candidate <= 0;
                            end
                            // Else keep holding
                        end
                    end
                    else begin
                        // Non-blocking mode
                        if (!request[candidate]) begin
                            state_fsm <= 0;
                            candidate <= 0;
                        end
                    end
                end
            end
        end
    end

    // Output Logic
    always @(*) begin
        grant = 0;
        grant_encoded = 0;
        grant_valid = 0;
        
        if (state_fsm == 1) begin
            grant[candidate] = 1;
            grant_encoded = candidate;
            grant_valid = 1;
        end
    end

    // Assign pending_grant for internal use if needed, but outputs are direct.
    // The spec asks for grant_valid and grant_encoded to match grant.
    // grant_valid indicates if any bit in grant is 1.
    // grant_encoded is the index of the set bit.
    
    // Re-verify the "Block" logic interpretation.
    // "hold the grant until acknowledge (ARB_BLOCK_ACK nonzero) or until request drops (ARB_BLOCK_ACK zero)"
    // This implies:
    // If ARB_BLOCK_ACK == 1: The arbiter waits for an ACK from the grantee to release.
    // If ARB_BLOCK_ACK == 0: The arbiter waits for the request to drop to release.
    // In both cases, if the condition isn't met, it holds.
    
    // Let's refine the FSM logic for the 'else' branch (Fixed Priority) to ensure it covers the block logic correctly.
    
    // Re-writing the FSM block for clarity and correctness.
    
    reg [LOG_PORTS-1:0] selected_port;
    reg hold_flag;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hold_flag <= 0;
            rr_head <= 0;
            selected_port <= 0;
        end
        else begin
            // Step 1: Determine the port to grant (Candidate)
            reg [LOG_PORTS-1:0] cand;
            
            if (ARB_TYPE_ROUND_ROBIN) begin
                if (hold_flag) begin
                    // We are holding a grant. Check if we should release.
                    if (ARB_BLOCK_ACK) begin
                        if (acknowledge[cand]) begin
                            hold_flag <= 0;
                        end
                    end
                    else begin
                        if (!request[cand]) begin
                            hold_flag <= 0;
                        end
                    end
                    // If hold_flag remains 1, selected_port stays as 'cand' (which is rr_head)
                end
                else begin
                    // Not holding. Find next request.
                    cand = rr_head;
                    if (cand >= PORTS) cand = 0;
                    
                    reg found = 0;
                    for (integer i = 0; i < PORTS; i = i + 1) begin
                        if (request[cand]) begin
                            found = 1;
                            break;
                        end
                        cand = cand + 1;
                        if (cand >= PORTS) cand = 0;
                    end
                    
                    if (found) begin
                        selected_port <= cand;
                        // Update head for next time
                        rr_head = cand + 1;
                        if (rr_head >= PORTS) rr_head = 0;
                        hold_flag <= 1;
                    end
                    else begin
                        hold_flag <= 0;
                        selected_port <= 0;
                    end
                end
            end
            else begin
                // Fixed Priority
                if (hold_flag) begin
                    // Check release conditions
                    if (ARB_BLOCK_ACK) begin
                        if (acknowledge[selected_port]) begin
                            hold_flag <= 0;
                        end
                    end
                    else begin
                        if (!request[selected_port]) begin
                            hold_flag <= 0;
                        end
                    end
                end
                else begin
                    // Find highest priority request
                    if (ARB_LSB_HIGH_PRIORITY) begin
                        cand = 0;
                        for (integer i = 0; i < PORTS; i = i + 1) begin
                            if (request[i]) begin
                                cand = i;
                                break;
                            end
                        end
                    end
                    else begin
                        cand = PORTS - 1;
                        for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                            if (request[i]) begin
                                cand = i;
                                break;
                            end
                        end
                    end
                    
                    if (cand != 0) begin
                        selected_port <= cand;
                        hold_flag <= 1;
                    end
                    else begin
                        hold_flag <= 0;
                        selected_port <= 0;
                    end
                end
            end
        end
    end

    // Output Assignment
    assign grant = 1 << selected_port; // Shift left to set the bit
    assign grant_encoded = selected_port;
    assign grant_valid = (selected_port != 0);

    // Note: The above logic `1 << selected_port` works if selected_port is treated as a shift amount.
    // In Verilog, `1 << n` shifts the 1 to the left by n positions.
    // If PORTS=4, selected_port=3 (binary 11), 1<<3 = 8 (1000). Correct.
    // If selected_port=0, 1<<0 = 1 (0001). Correct.
    
    // One edge case: If PORTS is not a power of 2, $clog2 might be smaller than PORTS-1.
    // The problem statement implies PORTS is likely a power of 2 given the use of $clog2 for grant_encoded width.
    // If PORTS is not a power of 2, the shift logic `1 << selected_port` might overflow or behave unexpectedly if selected_port >= width of 1.
    // Assuming standard power-of-2 PORTS as implied by $clog2 usage for encoding.
    
    // Final check on ARB_BLOCK_ACK logic interpretation.
    // "hold the grant until acknowledge (ARB_BLOCK_ACK nonzero) or until request drops (ARB_BLOCK_ACK zero)"
    // This means:
    // Case 1: ARB_BLOCK_ACK = 1. Hold until Ack is received. (Request dropping doesn't matter, we wait for Ack).
    // Case 2: ARB_BLOCK_ACK = 0. Hold until Request drops. (Ack doesn't matter, we wait for Req drop).
    // My logic:
    // if (ARB_BLOCK_ACK) { if (ack) release; }
    // else { if (!req) release; }
    // This matches the "OR" condition in the release criteria: Release if (Ack AND BlockAck) OR (!Req AND !BlockAck).
    // Wait, the text says "until A or until B".
    // If A happens, release. If B happens, release.
    // My logic: If BlockAck=1, check A. If A true, release. If BlockAck=0, check B. If B true, release.
    // This is correct.

endmodule
```<|im_end|>
