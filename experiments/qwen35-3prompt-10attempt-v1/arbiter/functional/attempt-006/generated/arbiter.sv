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
    // State = (Current Index)
    reg [LOG_PORTS-1:0] rr_index;
    reg [LOG_PORTS-1:0] rr_next_index;
    reg [LOG_PORTS-1:0] rr_state;

    // Fixed priority logic
    reg [LOG_PORTS-1:0] fixed_priority_idx;
    reg [LOG_PORTS-1:0] fixed_next_priority_idx;

    // Block state
    reg [LOG_PORTS-1:0] block_idx;
    reg block_active;

    // Internal signals
    wire [LOG_PORTS-1:0] current_winner;
    wire [LOG_PORTS-1:0] next_winner;
    wire grant_held;

    // Combinational logic for priority selection
    always @(*) begin
        if (ARB_TYPE_ROUND_ROBIN) begin
            // Round Robin Logic
            if (ARB_LSB_HIGH_PRIORITY) begin
                // LSB High Priority: Lower index has higher priority
                // We want to find the lowest index that is requested
                current_winner = MAX_IDX;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        current_winner = i;
                        break;
                    end
                end
            end else begin
                // MSB High Priority: Higher index has higher priority
                // We want to find the highest index that is requested
                current_winner = 0;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        current_winner = i;
                    end
                end
            end

            // Calculate next index for round robin
            if (ARB_BLOCK) begin
                // If blocking, we rotate only if the current winner acknowledges
                // or if the request drops (handled by block logic below)
                // Actually, standard RR with block: rotate index every cycle unless blocked?
                // Requirement: "hold the grant until acknowledge ... or until request drops"
                // So if we are in a block state, we don't rotate index until ack or req drop.
                // But we need to track which port we are currently serving.
                // Let's use a separate state machine for RR index rotation.
                
                // Simpler approach for RR with Block:
                // Maintain a 'current_rr_index'.
                // If request[current_rr_index] is high AND acknowledge[current_rr_index] is low (and block_ack=1), hold.
                // Else, rotate index to next.
                
                // However, the requirement says: "hold the grant until acknowledge ... OR until request drops".
                // This implies if request drops, we stop holding and can grant someone else.
                
                // Let's refine the RR logic inside the always block below.
                rr_next_index = rr_index;
            end else begin
                // Non-blocking RR: Rotate index every cycle if there is a winner
                if (current_winner != MAX_IDX) begin
                    rr_next_index = rr_index + 1;
                    if (rr_next_index >= PORTS) rr_next_index = 0;
                end else begin
                    rr_next_index = rr_index;
                end
            end
        end else begin
            // Fixed Priority Logic
            if (ARB_LSB_HIGH_PRIORITY) begin
                // Find lowest index
                current_winner = MAX_IDX;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        current_winner = i;
                        break;
                    end
                end
            end else begin
                // Find highest index
                current_winner = 0;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        current_winner = i;
                    end
                end
            end
            
            // Fixed priority does not rotate. Next winner is same as current if request persists.
            fixed_next_priority_idx = current_winner;
        end
    end

    // Sequential logic for Round Robin Index
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rr_index <= 0;
        end else begin
            if (ARB_TYPE_ROUND_ROBIN) begin
                // Determine if we should rotate
                // We rotate if:
                // 1. Not in a block state (ARB_BLOCK=0) -> handled by comb logic setting rr_next_index
                // 2. In block state (ARB_BLOCK=1):
                //    - If current_rr_index has request AND NOT acknowledge -> Hold (don't rotate)
                //    - If current_rr_index has request AND acknowledge -> Grant done, rotate to next
                //    - If current_rr_index has NO request -> Rotate to next (to find new winner)
                
                wire req_active = request[rr_index];
                wire ack_active = acknowledge[rr_index];
                
                if (ARB_BLOCK) begin
                    if (req_active && !ack_active) begin
                        // Still waiting for ack, hold index
                        rr_index <= rr_index;
                    end else begin
                        // Either ack received or request dropped, move to next
                        rr_next_index = rr_index + 1;
                        if (rr_next_index >= PORTS) rr_next_index = 0;
                        rr_index <= rr_next_index;
                    end
                end else begin
                    // Non-blocking RR
                    if (current_winner != MAX_IDX) begin
                        rr_next_index = rr_index + 1;
                        if (rr_next_index >= PORTS) rr_next_index = 0;
                        rr_index <= rr_next_index;
                    end else begin
                        rr_index <= rr_index;
                    end
                end
            end else begin
                // Fixed priority: index doesn't matter for selection, but we can keep it stable
                rr_index <= rr_index;
            end
        end
    end

    // Sequential logic for Block State
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            block_active <= 0;
            block_idx <= 0;
        end else begin
            if (ARB_BLOCK) begin
                // If we granted a port and it hasn't acked, stay in block mode
                // We need to know if we granted last cycle.
                // Since grant is combinational output based on current state, 
                // we can infer block state from (grant was active last cycle AND ack is not active now)
                // But simpler: if ARB_BLOCK is set, we maintain the grant until ack or req drop.
                // The 'rr_index' logic above handles the rotation when not blocked.
                // We just need to ensure we don't overwrite the grant if blocked.
                
                // Actually, the RR logic above already handles the "hold" condition by not updating rr_index.
                // So we just need to make sure the grant output logic respects the block state.
                // Let's rely on the RR logic to manage the index, and the grant logic to output.
                // However, we need to track if we are currently "holding" a grant.
                
                // Re-evaluating Block Logic:
                // If ARB_BLOCK=1:
                //   If request[i] is high and we granted i:
                //     If acknowledge[i] is low -> Keep granting i.
                //     If acknowledge[i] is high -> Stop granting i, look for next.
                //     If request[i] is low -> Stop granting i, look for next.
                //   Else -> Look for next.
                
                // The RR logic above updates rr_index only if (req && !ack) is FALSE.
                // Wait, the logic was: if (req && !ack) hold. Else rotate.
                // This means if (req && !ack) is TRUE, we hold.
                // If (req && !ack) is FALSE (meaning ack came or req dropped), we rotate.
                // This matches the requirement.
                
                // So we don't need an explicit block_active state register if the RR logic handles it.
                // But we need to ensure that when we rotate, we don't accidentally grant the old one again immediately if it's still requested?
                // No, if we rotate, we are looking for the next available.
                
                // One edge case: What if multiple requests exist?
                // RR picks one. If that one acks, we rotate to next.
                // If that one doesn't ack, we stay.
                // This works.
                
                // What about Fixed Priority with Block?
                // If ARB_BLOCK=1 and ARB_TYPE_ROUND_ROBIN=0:
                // We pick highest priority. If it acks or req drops, we pick next highest.
                // This is standard fixed priority with block.
                
                // So the logic in 'always @(*)' for rr_next_index needs to be careful.
                // Let's separate the logic clearly.
                
                // Actually, the previous comb logic for rr_next_index assumed ARB_BLOCK context implicitly?
                // No, it had an if (ARB_BLOCK) branch.
                // Let's rewrite the comb logic to be cleaner.
            end
            block_active <= 0;
            block_idx <= 0;
        end
    end

    // Let's restructure the logic to be more robust and clear.
    // We will calculate the 'selected_port' based on priority/RR.
    // Then we will calculate 'grant' based on 'selected_port' and 'block' constraints.

    reg [LOG_PORTS-1:0] selected_port;
    reg [LOG_PORTS-1:0] next_selected_port;

    always @(*) begin
        if (ARB_TYPE_ROUND_ROBIN) begin
            // Find the current winner based on RR index
            // If LSB High: Winner is lowest index >= rr_index that is requested?
            // No, standard RR: Start at rr_index, go up to PORTS, pick first request.
            // If LSB High Priority: Lower index wins.
            // So we scan from rr_index upwards.
            
            selected_port = MAX_IDX;
            found = 0;
            for (integer i = 0; i < PORTS; i = i + 1) begin
                if (request[i]) begin
                    selected_port = i;
                    found = 1;
                    break;
                end
            end
            // If no request, selected_port remains MAX_IDX (invalid)

            // Calculate next RR index
            if (found) begin
                if (ARB_BLOCK) begin
                    // Check if we are currently holding this port
                    // We hold if request[selected_port] is high AND acknowledge[selected_port] is low
                    if (request[selected_port] && !acknowledge[selected_port]) begin
                        next_selected_port = selected_port;
                    end else begin
                        // Ack received or request dropped, rotate
                        next_selected_port = selected_port + 1;
                        if (next_selected_port >= PORTS) next_selected_port = 0;
                    end
                end else begin
                    // Non-blocking: always rotate after granting
                    next_selected_port = selected_port + 1;
                    if (next_selected_port >= PORTS) next_selected_port = 0;
                end
            end else begin
                // No request, keep index same or reset? Keep same to avoid hunting on next cycle if req appears
                next_selected_port = selected_port;
            end

        end else begin
            // Fixed Priority
            if (ARB_LSB_HIGH_PRIORITY) begin
                // Scan from 0 to PORTS-1
                selected_port = MAX_IDX;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        selected_port = i;
                        break;
                    end
                end
            end else begin
                // Scan from PORTS-1 down to 0
                selected_port = 0;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        selected_port = i;
                    end
                end
            end

            // Fixed priority next selection
            if (selected_port != MAX_IDX) begin
                // If we granted this port, and it acks or req drops, we move to next priority
                if (ARB_BLOCK) begin
                    if (request[selected_port] && !acknowledge[selected_port]) begin
                        next_selected_port = selected_port;
                    end else begin
                        // Move to next priority
                        if (ARB_LSB_HIGH_PRIORITY) begin
                            // Next is selected_port + 1
                            next_selected_port = selected_port + 1;
                            if (next_selected_port >= PORTS) next_selected_port = 0;
                        end else begin
                            // Next is selected_port - 1
                            next_selected_port = selected_port - 1;
                            if (next_selected_port < 0) next_selected_port = PORTS - 1;
                        end
                    end
                end else begin
                    // Non-blocking fixed priority: always move to next priority
                    if (ARB_LSB_HIGH_PRIORITY) begin
                        next_selected_port = selected_port + 1;
                        if (next_selected_port >= PORTS) next_selected_port = 0;
                    end else begin
                        next_selected_port = selected_port - 1;
                        if (next_selected_port < 0) next_selected_port = PORTS - 1;
                    end
                end
            end else begin
                next_selected_port = selected_port;
            end
        end
    end

    // Sequential logic for RR Index (only used if RR is enabled)
    // We need to update rr_index on the clock edge
    reg [LOG_PORTS-1:0] rr_index_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rr_index_reg <= 0;
        end else if (ARB_TYPE_ROUND_ROBIN) begin
            rr_index_reg <= next_selected_port;
        end else begin
            rr_index_reg <= rr_index_reg;
        end
    end

    // Final Grant Logic
    // grant is valid if:
    // 1. There is a selected port (request exists)
    // 2. If ARB_BLOCK is set, we must not grant if (req is high AND ack is low) for the current selected port?
    //    Wait, the requirement says: "hold the grant until acknowledge ... or until request drops".
    //    This means:
    //    - If we are in a block state (meaning we granted previously and haven't acked yet), we continue granting.
    //    - If the request drops, we stop granting.
    //    - If the acknowledge comes, we stop granting and look for next.
    //
    //    My previous comb logic for next_selected_port handled the "when to rotate".
    //    But for the current cycle's grant, we need to decide:
    //    If ARB_BLOCK=1:
    //      If we are currently serving 'selected_port' (which is rr_index_reg for RR, or fixed priority index):
    //        If request[selected_port] is high AND acknowledge[selected_port] is low -> Continue granting.
    //        Else -> Stop granting this port, look for next.
    //      Else -> Look for next.
    //
    //    Actually, the simplest way to implement "Hold until ack or req drop" is:
    //    If ARB_BLOCK=1:
    //      If (request[selected_port] && !acknowledge[selected_port]) -> Grant = selected_port.
    //      Else -> Grant = next_selected_port (which should be the next candidate).
    //
    //    But wait, if request[selected_port] is high and ack is low, we grant it.
    //    If request[selected_port] is high and ack is high, we do NOT grant it (ack done), so we move to next.
    //    If request[selected_port] is low, we do NOT grant it (req dropped), so we move to next.
    //
    //    So the condition to grant 'selected_port' is:
    //      (request[selected_port] == 1) AND (ARB_BLOCK == 0 OR acknowledge[selected_port] == 1)
    //    Wait, if ARB_BLOCK=1 and ack=1, we stop holding. So we don't grant selected_port.
    //    So the condition is:
    //      (request[selected_port] == 1) AND (ARB_BLOCK == 0 OR acknowledge[selected_port] == 0)
    //    No, if ARB_BLOCK=1 and ack=0, we hold (grant).
    //    If ARB_BLOCK=1 and ack=1, we release (don't grant selected_port).
    //    So: Grant = request[selected_port] AND (ARB_BLOCK == 0 OR acknowledge[selected_port] == 0)
    //
    //    However, we also need to consider if 'selected_port' is valid (i.e., we found a request).
    //    If no request anywhere, grant is 0.
    
    wire [LOG_PORTS-1:0] valid_selected_port;
    wire grant_this_port;

    always @(*) begin
        valid_selected_port = MAX_IDX;
        if (ARB_TYPE_ROUND_ROBIN) begin
            // Check if there is any request
            if (request[rr_index_reg] || request[rr_index_reg+1] || ... ) // Need a loop or reduction
                valid_selected_port = rr_index_reg; // Simplified: assume rr_index_reg points to a valid one if any exists?
                // No, rr_index_reg is just the starting point. We need to find the first request >= rr_index_reg.
                // Let's reuse the logic from comb block to find 'current_winner' for RR.
        end
        
        // Let's simplify: Calculate 'current_winner' again here to be safe.
        wire [LOG_PORTS-1:0] current_winner;
        if (ARB_TYPE_ROUND_ROBIN) begin
            if (ARB_LSB_HIGH_PRIORITY) begin
                current_winner = MAX_IDX;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        current_winner = i;
                        break;
                    end
                end
            end else begin
                current_winner = 0;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        current_winner = i;
                    end
                end
            end
        end else begin
            if (ARB_LSB_HIGH_PRIORITY) begin
                current_winner = MAX_IDX;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        current_winner = i;
                        break;
                    end
                end
            end else begin
                current_winner = 0;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        current_winner = i;
                    end
                end
            end
        end

        if (current_winner == MAX_IDX) begin
            grant_this_port = 0;
        end else begin
            if (ARB_BLOCK) begin
                // Hold if request is active and ack is not active
                if (request[current_winner] && !acknowledge[current_winner]) begin
                    grant_this_port = 1;
                end else begin
                    grant_this_port = 0;
                end
            end else begin
                grant_this_port = 1;
            end
        end
    end

    // Assign outputs
    assign grant = (grant_this_port) ? current_winner : 0;
    assign grant_valid = grant_this_port;
    assign grant_encoded = current_winner;

    // Note: The 'next_selected_port' logic in the comb block is used to update rr_index_reg.
    // But we need to ensure rr_index_reg is updated correctly.
    // The 'next_selected_port' variable in the comb block was calculated based on 'selected_port' which was derived from 'rr_index_reg'.
    // This creates a dependency loop if not careful, but since rr_index_reg is sequential and next_selected_port is combinational, it's fine.
    // However, the 'selected_port' variable in the comb block was overwritten by 'current_winner' in the final logic.
    // Let's ensure the RR index update logic is consistent.
    
    // Re-verify RR Index Update Logic:
    // In the comb block, 'selected_port' was calculated as the winner starting from rr_index_reg.
    // Then 'next_selected_port' was calculated based on 'selected_port'.
    // This is correct.
    // But in the final logic, I recalculated 'current_winner' from scratch (0 to PORTS-1).
    // This is also correct for finding the grant, but for the RR index update, we need the winner relative to rr_index_reg.
    // Actually, the standard RR behavior is:
    // 1. Start at rr_index.
    // 2. Find first request >= rr_index.
    // 3. Grant that.
    // 4. Next rr_index = (rr_index + 1) % PORTS.
    //
    // My comb logic for 'selected_port' did exactly this (scanning from 0, but wait).
    // If ARB_LSB_HIGH_PRIORITY: Scan 0..PORTS-1. This finds the global lowest.
    // But RR should scan starting from rr_index.
    //
    // Correction for RR Logic:
    // If ARB_TYPE_ROUND_ROBIN:
    //   If ARB_LSB_HIGH_PRIORITY:
    //     Find first request in range [rr_index, PORTS-1] U [0, rr_index-1]?
    //     No, RR usually means: "The next grant goes to the next requester in a circular buffer".
    //     If LSB High Priority means "Lower index has higher priority", then within the RR cycle, we prefer lower indices.
    //     So we scan from rr_index upwards.
    //     If we find a request, that's the winner.
    //     If we reach PORTS, wrap to 0 and continue until we find one or finish.
    //
    // Let's implement this correctly.
    
    reg [LOG_PORTS-1:0] rr_scan_start;
    reg [LOG_PORTS-1:0] rr_winner;
    reg rr_found;

    always @(*) begin
        rr_scan_start = rr_index_reg;
        rr_winner = MAX_IDX;
        rr_found = 0;
        
        if (ARB_TYPE_ROUND_ROBIN) begin
            if (ARB_LSB_HIGH_PRIORITY) begin
                // Scan from rr_index upwards
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    idx = (rr_index_reg + i) % PORTS;
                    if (request[idx]) begin
                        rr_winner = idx;
                        rr_found = 1;
                        break;
                    end
                end
            end else begin
                // MSB High Priority: Prefer higher indices.
                // Scan from rr_index downwards (wrapping)
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    idx = (rr_index_reg - i + PORTS) % PORTS;
                    if (request[idx]) begin
                        rr_winner = idx;
                        rr_found = 1;
                        break;
                    end
                end
            end
        end else begin
            // Fixed Priority
            if (ARB_LSB_HIGH_PRIORITY) begin
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        rr_winner = i;
                        rr_found = 1;
                        break;
                    end
                end
            end else begin
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        rr_winner = i;
                    end
                end
            end
        end
    end

    // Update rr_index_reg
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rr_index_reg <= 0;
        end else if (ARB_TYPE_ROUND_ROBIN) begin
            if (rr_found) begin
                // If we found a winner, rotate for next cycle
                rr_index_reg <= (rr_index_reg + 1) % PORTS;
            end else begin
                // No request, keep index same
                rr_index_reg <= rr_index_reg;
            end
        end else begin
            rr_index_reg <= rr_index_reg;
        end
    end

    // Final Grant Logic with Block
    wire [LOG_PORTS-1:0] final_winner;
    wire grant_final;

    always @(*) begin
        final_winner = 0;
        grant_final = 0;
        
        if (ARB_TYPE_ROUND_ROBIN) begin
            final_winner = rr_winner;
        end else begin
            // Fixed priority winner
            if (ARB_LSB_HIGH_PRIORITY) begin
                final_winner = MAX_IDX;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        final_winner = i;
                        break;
                    end
                end
            end else begin
                final_winner = 0;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        final_winner = i;
                    end
                end
            end
        end
        
        if (final_winner != MAX_IDX) begin
            if (ARB_BLOCK) begin
                if (request[final_winner] && !acknowledge[final_winner]) begin
                    grant_final = 1;
                end
            end else begin
                grant_final = 1;
            end
        end
    end

    assign grant = grant_final ? final_winner : 0;
    assign grant_valid = grant_final;
    assign grant_encoded = final_winner;

endmodule
```<|im_end|>
