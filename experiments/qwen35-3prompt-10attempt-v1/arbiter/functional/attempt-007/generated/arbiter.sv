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
    localparam MAX_IDX = PORTS - 1;

    // State encoding for Round Robin
    // We need to track the "next" port to grant.
    // State 0: Next grant is port 0
    // State 1: Next grant is port 1
    // ...
    // State N: Next grant is port N-1
    localparam NUM_STATES = PORTS;
    localparam STATE_WIDTH = $clog2(NUM_STATES);

    reg [STATE_WIDTH-1:0] rr_state;
    reg [LOG_PORTS-1:0]  rr_next_state;
    reg [LOG_PORTS-1:0]  rr_current_winner;
    reg [LOG_PORTS-1:0]  rr_last_granted;

    // Fixed priority logic
    reg [LOG_PORTS-1:0]  fixed_priority_winner;
    reg                  fixed_priority_valid;

    // Block state
    reg                  block_active;
    reg                  block_pending;

    // Internal signals
    wire [LOG_PORTS-1:0] current_request;
    wire [LOG_PORTS-1:0] current_acknowledge;

    // --- Combinational Logic for Priority Selection ---

    always @(*) begin
        // Determine the winner based on arbitration type
        if (ARB_TYPE_ROUND_ROBIN) begin
            // Round Robin Logic
            // Find the first active request starting from rr_state
            rr_current_winner = MAX_IDX;
            rr_next_state = rr_state;
            
            for (integer i = 0; i < PORTS; i = i + 1) begin
                rr_next_state = rr_next_state + 1;
                if (rr_next_state == PORTS)
                    rr_next_state = 0;
                
                if (current_request[i]) begin
                    rr_current_winner = i;
                    rr_state = rr_next_state;
                    break;
                end
            end
            
            // If no request, keep state or reset? 
            // Usually in RR, if no request, we keep the next state ready for the next request.
            // However, to prevent state drift when all are low, we can hold state.
            // But strictly, if no request, no grant.
            
            grant = 1 << rr_current_winner;
            grant_encoded = rr_current_winner;
            grant_valid = (rr_current_winner != MAX_IDX); // Should not happen if logic is correct, but safety check
        end
        else begin
            // Fixed Priority Logic
            fixed_priority_valid = 1'b0;
            fixed_priority_winner = MAX_IDX;
            
            // Iterate from LSB or MSB based on ARB_LSB_HIGH_PRIORITY
            if (ARB_LSB_HIGH_PRIORITY) begin
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (current_request[i]) begin
                        fixed_priority_winner = i;
                        fixed_priority_valid = 1'b1;
                        break;
                    end
                end
            end
            else begin
                for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                    if (current_request[i]) begin
                        fixed_priority_winner = i;
                        fixed_priority_valid = 1'b1;
                        break;
                    end
                end
            end
            
            grant = 1 << fixed_priority_winner;
            grant_encoded = fixed_priority_winner;
            grant_valid = fixed_priority_valid;
        end
    end

    // --- Block Logic ---

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            block_active <= 1'b0;
            block_pending <= 1'b0;
            rr_state <= 0;
            rr_last_granted <= 0;
        end
        else begin
            // Determine if we should block
            // Block if: ARB_BLOCK is set AND (ARB_BLOCK_ACK is set OR we are waiting for ack)
            // Actually, spec says: "hold the grant until acknowledge (ARB_BLOCK_ACK nonzero) or until request drops (ARB_BLOCK_ACK zero)"
            // This implies:
            // If ARB_BLOCK_ACK == 1: We hold grant until acknowledge[i] is high.
            // If ARB_BLOCK_ACK == 0: We hold grant until request[i] is low.
            
            // Let's refine the block condition logic.
            // We need to know if the current grant is being held.
            
            // First, calculate the raw grant (ignoring block for a moment to see who won)
            // We reuse the logic above but store it in a temp signal or re-evaluate.
            // To avoid double evaluation complexity, let's compute the "raw" winner here.
            
            wire [LOG_PORTS-1:0] raw_winner;
            wire raw_valid;
            
            if (ARB_TYPE_ROUND_ROBIN) begin
                raw_winner = rr_current_winner;
                raw_valid = (raw_winner != MAX_IDX);
            end
            else begin
                if (ARB_LSB_HIGH_PRIORITY) begin
                    raw_valid = 1'b0;
                    raw_winner = MAX_IDX;
                    for (integer i = 0; i < PORTS; i = i + 1) begin
                        if (current_request[i]) begin
                            raw_winner = i;
                            raw_valid = 1'b1;
                            break;
                        end
                    end
                end
                else begin
                    raw_valid = 1'b0;
                    raw_winner = MAX_IDX;
                    for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                        if (current_request[i]) begin
                            raw_winner = i;
                            raw_valid = 1'b1;
                            break;
                        end
                    end
                end
            end

            // Determine if we are currently in a blocked state
            // We are blocked if:
            // 1. We previously granted someone (block_pending is set)
            // 2. ARB_BLOCK is enabled
            // 3. The condition to release is not met.
            
            // Condition to release:
            // If ARB_BLOCK_ACK == 1: Release if acknowledge[raw_winner] is high.
            // If ARB_BLOCK_ACK == 0: Release if request[raw_winner] is low.
            
            wire release_condition;
            if (ARB_BLOCK_ACK) begin
                // Wait for acknowledge
                release_condition = (current_acknowledge[raw_winner] == 1'b1);
            end
            else begin
                // Wait for request drop
                release_condition = (current_request[raw_winner] == 1'b0);
            end

            if (block_active) begin
                if (release_condition) begin
                    block_active <= 1'b0;
                    block_pending <= 1'b0;
                end
                // Else: stay blocked
            end
            else begin
                // Not currently blocked, check if we need to start blocking
                if (ARB_BLOCK && raw_valid) begin
                    // Check if the winner is requesting
                    if (current_request[raw_winner] == 1'b1) begin
                        block_active <= 1'b1;
                        block_pending <= 1'b1;
                    end
                end
            end

            // Update RR state only if not blocked (or if block logic allows state update, 
            // but typically RR state advances only when grant is actually given or cycle completes)
            // Standard RR: Advance state every cycle or only on grant?
            // Usually: Advance state every cycle to ensure fairness, OR advance only when grant is issued.
            // Given "hold grant until...", if we hold, we don't grant.
            // If we don't grant, do we advance the RR pointer?
            // If we don't advance, the next request from the same port might win again immediately if it stays high.
            // If we advance, we skip it.
            // Common behavior: Advance state every cycle regardless of grant, OR advance only on grant.
            // Let's assume standard RR: Advance state every cycle to rotate priority.
            // However, if we are blocked, we are effectively holding the grant.
            // If we advance state while blocked, we might lose the current winner if they are the only one.
            // Let's implement: Advance state every cycle. If blocked, we still hold the grant for the specific port,
            // but the internal RR state rotates. This ensures that once the block releases, the next available port is ready.
            // Wait, if I am blocked on port 0, and port 1 requests. 
            // If I rotate state, next cycle I look for port 1. If port 1 requests, I grant port 1? 
            // But spec says "hold the grant until...". This implies the grant signal stays high for the current winner.
            // So if I am blocked on port 0, grant[0] is high. Even if port 1 requests, grant[0] stays high.
            // So the RR state rotation should probably happen only when the block condition is met?
            // No, if I hold port 0, I am not granting port 1.
            // So the "winner" is fixed until release.
            // Therefore, RR state should NOT advance while blocked? 
            // Or, the "block" mechanism overrides the RR selection.
            // Let's interpret: The arbiter selects a winner. If block is on, it holds that winner.
            // The selection logic (RR vs Fixed) happens every cycle.
            // If Block is active, we force the output to the previously granted port.
            // But how do we know who was previously granted? We need to store it.
            
            // Revised Block Logic:
            // 1. Calculate raw winner based on RR/Fixed.
            // 2. If block_active is high, force grant to the stored 'last_granted' port.
            // 3. If block_active is low, use raw_winner.
            // 4. Update block_active based on current request/ack and ARB_BLOCK settings.
            
            // Let's restructure the always block for clarity.
        end
    end

    // Re-implementing the sequential logic cleanly
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rr_state <= 0;
            rr_last_granted <= 0;
            block_active <= 1'b0;
            block_pending <= 1'b0;
        end
        else begin
            // 1. Calculate Raw Winner
            wire [LOG_PORTS-1:0] raw_winner;
            wire raw_valid;
            
            if (ARB_TYPE_ROUND_ROBIN) begin
                // Advance RR state
                rr_next_state = rr_state + 1;
                if (rr_next_state == PORTS)
                    rr_next_state = 0;
                
                rr_state = rr_next_state;
                
                // Find winner starting from rr_state
                raw_winner = MAX_IDX;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (current_request[i]) begin
                        raw_winner = i;
                        break;
                    end
                end
                raw_valid = (raw_winner != MAX_IDX);
            end
            else begin
                // Fixed Priority
                raw_valid = 1'b0;
                raw_winner = MAX_IDX;
                if (ARB_LSB_HIGH_PRIORITY) begin
                    for (integer i = 0; i < PORTS; i = i + 1) begin
                        if (current_request[i]) begin
                            raw_winner = i;
                            raw_valid = 1'b1;
                            break;
                        end
                    end
                end
                else begin
                    for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                        if (current_request[i]) begin
                            raw_winner = i;
                            raw_valid = 1'b1;
                            break;
                        end
                    end
                end
            end

            // 2. Determine Final Grant
            wire [LOG_PORTS-1:0] final_winner;
            wire final_valid;
            
            if (block_active) begin
                // Hold the last granted port
                final_winner = rr_last_granted;
                final_valid = 1'b1; // Assume valid if we are in block mode and had a winner before
                // Note: If block_active is high, we assume we have a valid grant to hold.
                // If the system resets while blocked, we clear it.
            end
            else begin
                final_winner = raw_winner;
                final_valid = raw_valid;
            end

            // 3. Update Block State
            // We enter block mode if:
            // ARB_BLOCK is set AND
            // We have a valid winner (raw_valid) AND
            // The winner is currently requesting (current_request[raw_winner] == 1)
            // AND
            // We are NOT already in a block state (or we transition into it)
            
            // Actually, if we are already in block mode, we stay there until release.
            // If we are NOT in block mode, we check if we should start blocking.
            
            if (ARB_BLOCK) begin
                if (raw_valid && current_request[raw_winner]) begin
                    // Check if we should release
                    wire release_now;
                    if (ARB_BLOCK_ACK) begin
                        release_now = current_acknowledge[raw_winner];
                    end
                    else begin
                        release_now = 1'b0; // If ARB_BLOCK_ACK is 0, we release when request drops (see below)
                    end
                    
                    if (release_now) begin
                        block_active <= 1'b0;
                        block_pending <= 1'b0;
                    end
                    else begin
                        // Start or continue blocking
                        // Only start if not already blocked
                        if (!block_active) begin
                            block_active <= 1'b1;
                            block_pending <= 1'b1;
                            rr_last_granted = raw_winner;
                        end
                    end
                end
                else if (!raw_valid) begin
                    // No request, release block
                    block_active <= 1'b0;
                    block_pending <= 1'b0;
                end
                else begin
                    // Request is low, but ARB_BLOCK_ACK is 0
                    // Spec: "hold the grant until acknowledge (ARB_BLOCK_ACK nonzero) or until request drops (ARB_BLOCK_ACK zero)"
                    // This implies:
                    // If ARB_BLOCK_ACK == 1: Hold until ack.
                    // If ARB_BLOCK_ACK == 0: Hold until request drops.
                    // So if ARB_BLOCK_ACK == 0 and request drops, we release.
                    if (current_request[raw_winner] == 1'b0) begin
                        block_active <= 1'b0;
                        block_pending <= 1'b0;
                    end
                    else begin
                        // Request is high, ARB_BLOCK_ACK is 0 -> Continue holding
                        if (!block_active) begin
                            block_active <= 1'b1;
                            block_pending <= 1'b1;
                            rr_last_granted = raw_winner;
                        end
                    end
                end
            end
            else begin
                // ARB_BLOCK is 0, never block
                block_active <= 1'b0;
                block_pending <= 1'b0;
            end

            // 4. Update RR Last Granted
            // Only update if we are not blocked? 
            // If we are blocked, we are holding a grant. The "last granted" is the one we are holding.
            // If we are not blocked, the "last granted" is the raw winner.
            // However, if we are blocked, we don't necessarily grant every cycle, we hold.
            // But the variable rr_last_granted should reflect the port that is currently being held/granted.
            if (block_active) begin
                rr_last_granted = final_winner;
            end
            else begin
                rr_last_granted = final_winner;
            end
        end
    end

    // --- Output Assignment ---

    assign grant = 1 << final_winner;
    assign grant_valid = final_valid;
    assign grant_encoded = final_winner;

endmodule
```<|im_end|>
