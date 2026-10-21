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
    localparam LSB_HIGH = ARB_LSB_HIGH_PRIORITY;
    
    // State encoding
    // 0: IDLE
    // 1: GRANTING (Active grant)
    // 2: BLOCKED (Waiting for release)
    localparam [1:0] STATE_IDLE = 2'b00;
    localparam [1:0] STATE_GRANTING = 2'b01;
    localparam [1:0] STATE_BLOCKED = 2'b10;

    reg [1:0] state, next_state;
    reg [LOG_PORTS-1:0] rr_index;
    reg [PORTS-1:0] grant_mask;
    reg [PORTS-1:0] pending_request;
    reg [PORTS-1:0] last_granted;
    reg grant_valid_reg;
    reg [LOG_PORTS-1:0] next_rr_index;

    // Priority Logic
    function integer get_priority;
        input [PORTS-1:0] req;
        input [PORTS-1:0] port_idx;
        begin
            if (LSB_HIGH)
                get_priority = $countleadingzeros(req) + 1; // Lower index = Higher priority in LSB mode
            else
                get_priority = $counttrailingzeros(req) + 1; // Lower index = Higher priority in MSB mode
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            rr_index <= 0;
            grant_mask <= 0;
            pending_request <= 0;
            last_granted <= 0;
            grant_valid_reg <= 0;
        end
        else begin
            state <= next_state;
            rr_index <= next_rr_index;
            grant_mask <= grant;
            pending_request <= request;
            last_granted <= grant_encoded;
            grant_valid_reg <= grant_valid;
        end
    end

    always @(*) begin
        next_state = state;
        grant_valid_reg = 0;
        grant_mask = 0;
        next_rr_index = rr_index;
        grant_encoded = 0;

        if (state == STATE_IDLE) begin
            if (request != 0) begin
                next_state = STATE_GRANTING;
                grant_valid_reg = 1;
                
                if (ARB_TYPE_ROUND_ROBIN) begin
                    // Find first active request starting from rr_index
                    integer i;
                    reg found = 0;
                    for (i = 0; i < PORTS; i++) begin
                        if (request[rr_index + i]) begin
                            grant_mask = 1 << (rr_index + i);
                            grant_encoded = rr_index + i;
                            next_rr_index = (rr_index + i + 1) % PORTS;
                            found = 1;
                            break;
                        end
                    end
                    if (!found) begin
                        // Wrap around if no request found in the loop (shouldn't happen if request!=0)
                        // But handle case where loop finished without finding due to logic
                        grant_mask = request; 
                        // In strict RR, we pick the lowest index if wrap around fails to find specific pattern,
                        // but standard RR picks the first one encountered in circular scan.
                        // If request != 0, the loop above MUST find something.
                    end
                end
                else begin
                    // Fixed Priority
                    integer p;
                    reg selected = 0;
                    for (p = 0; p < PORTS; p++) begin
                        if (request[p]) begin
                            grant_mask = 1 << p;
                            grant_encoded = p;
                            selected = 1;
                            break;
                        end
                    end
                    if (!selected) begin
                        // Should not happen if request != 0
                        grant_mask = 0;
                    end
                end
            end
        end
        else if (state == STATE_GRANTING) begin
            // Check if grant is acknowledged
            if (acknowledge[grant_encoded]) begin
                if (ARB_BLOCK_ACK) begin
                    // Hold grant until acknowledge is de-asserted
                    // Wait for next cycle where acknowledge is 0
                    // Actually, the requirement says "hold it until the specified release event".
                    // Usually, if ARB_BLOCK_ACK is 1, we wait for acknowledge to go low.
                    // If acknowledge is high, we stay in GRANTING.
                    // If acknowledge is low, we go to BLOCKED or IDLE?
                    // Standard behavior: If ack is valid, we release. If ack is invalid (low), we block.
                    // Let's interpret: If ack is high, we are done with this grant.
                    // If ARB_BLOCK is 1, we might need to wait for ack to go low before releasing the bus?
                    // Re-reading: "If a grant is blocked, hold it until the specified release event."
                    // Release event for ARB_BLOCK_ACK=1 is typically acknowledge going low.
                    // So if ack is high, we stay in GRANTING. If ack is low, we go to BLOCKED (if ARB_BLOCK) or IDLE.
                    
                    if (acknowledge[grant_encoded]) begin
                        // Ack is high, grant is valid
                        next_state = STATE_GRANTING;
                        // Keep grant_valid high
                    end
                    else begin
                        // Ack is low
                        if (ARB_BLOCK) begin
                            next_state = STATE_BLOCKED;
                            // Keep grant_valid high until ack goes high? 
                            // Or does BLOCK mean we block the port from requesting again?
                            // Usually BLOCK means the arbiter holds the grant until ack is received.
                            // If ack is low, we are blocked. We wait for ack to go high.
                            // But the state machine needs to transition.
                            // Let's assume: If ack is low, we stay in GRANTING but effectively blocked?
                            // Or transition to BLOCKED state where we wait for ack to go high.
                            // Let's use STATE_BLOCKED to wait for ack to go high.
                            next_state = STATE_BLOCKED;
                        end
                        else begin
                            next_state = STATE_IDLE;
                            grant_valid_reg = 0;
                        end
                    end
                end
                else begin
                    // ARB_BLOCK_ACK = 0
                    // Grant is released immediately after ack is high? 
                    // Or does it mean we don't block on ack?
                    // If ARB_BLOCK_ACK=0, we usually grant for one cycle or until ack.
                    // If ack is high, we release.
                    if (acknowledge[grant_encoded]) begin
                        next_state = STATE_IDLE;
                        grant_valid_reg = 0;
                    end
                    else begin
                        // Ack is low, but we don't block? 
                        // This implies we might re-grant immediately next cycle if request is still there?
                        // Or we just stay in GRANTING but grant_valid is 0?
                        // Let's assume if ARB_BLOCK_ACK=0, we only care about the current cycle.
                        // If ack is low, we might try again next cycle.
                        // So we stay in GRANTING, but grant_valid_reg becomes 0?
                        // No, grant_valid is an output. If we are in GRANTING state, grant_valid should be 1.
                        // If ARB_BLOCK_ACK=0, maybe we don't care about ack holding the grant.
                        // We grant, and if ack is low, we might grant again next cycle.
                        // So next_state remains GRANTING, but we need to check if we should keep grant_valid.
                        // Let's assume: If ARB_BLOCK_ACK=0, we grant for 1 cycle regardless of ack?
                        // Or we grant until ack is high.
                        // Let's stick to: If ARB_BLOCK_ACK=0, we release immediately after ack is high.
                        // If ack is low, we stay in GRANTING but grant_valid is 0? That contradicts "Grant one requester".
                        // Let's assume standard: ARB_BLOCK_ACK=1 means hold until ack goes low. ARB_BLOCK_ACK=0 means hold until ack goes high.
                        // If ack is low and ARB_BLOCK_ACK=0, we might just stay in GRANTING but not output valid?
                        // Let's simplify: 
                        // If ARB_BLOCK_ACK=1: Wait for ack to go low.
                        // If ARB_BLOCK_ACK=0: Wait for ack to go high.
                        // If condition met, go to IDLE. Else stay in GRANTING.
                        // But if we stay in GRANTING, grant_valid should be 1.
                        // If ack is low and ARB_BLOCK_ACK=0, do we block?
                        // Let's assume: If ARB_BLOCK_ACK=0, we don't block on ack. We just grant once.
                        // So if ack is low, we go to IDLE next cycle?
                        // Let's assume: If ARB_BLOCK_ACK=0, we grant for 1 cycle.
                        // So next_state = STATE_IDLE, grant_valid_reg = 0.
                        // But what if request is still there? We will re-grant next cycle.
                        // This seems reasonable.
                        next_state = STATE_IDLE;
                        grant_valid_reg = 0;
                    end
                end
            end
            else begin
                // Ack is low
                if (ARB_BLOCK) begin
                    next_state = STATE_BLOCKED;
                end
                else begin
                    next_state = STATE_IDLE;
                    grant_valid_reg = 0;
                end
            end
        end
        else if (state == STATE_BLOCKED) begin
            // Wait for release event
            // Release event for ARB_BLOCK_ACK=1 is ack going high.
            // Release event for ARB_BLOCK_ACK=0 is ack going low?
            // Let's assume the release event is the opposite of the blocking condition.
            // If ARB_BLOCK_ACK=1, we blocked because ack was low. We wait for ack to go high.
            // If ARB_BLOCK_ACK=0, we blocked because... wait, if ARB_BLOCK_ACK=0, we don't block on ack low.
            // So STATE_BLOCKED is only reached if ARB_BLOCK=1 and ARB_BLOCK_ACK=1 and ack is low.
            // So we wait for ack to go high.
            if (acknowledge[grant_encoded]) begin
                next_state = STATE_IDLE;
                grant_valid_reg = 0;
            end
            else begin
                // Stay blocked
                next_state = STATE_BLOCKED;
                // grant_valid_reg remains 0? Or do we keep the grant valid but blocked?
                // "If a grant is blocked, hold it". This implies grant_valid should be 1.
                // But if we are in STATE_BLOCKED, we are waiting.
                // Let's assume grant_valid is 1 in STATE_BLOCKED as well, but the port cannot request again?
                // Or grant_valid is 0 because the transaction is not complete?
                // Let's assume grant_valid is 1 in STATE_BLOCKED, but we don't change the grant.
                // Actually, if we are blocked, we are holding the grant. So grant_valid should be 1.
                // But we need to ensure we don't grant to anyone else.
                // So grant_mask remains the same.
                // But wait, if grant_valid is 1, and we are blocked, the master sees it.
                // The master will eventually ack.
                // So in STATE_BLOCKED, grant_valid_reg = 1.
                // And grant_encoded remains the same.
                // But we need to update grant_mask and grant_encoded in the output logic.
                // Let's handle this in the output logic.
                next_state = STATE_BLOCKED;
                grant_valid_reg = 1;
            end
        end
    end

    // Output Logic
    always @(*) begin
        grant = 0;
        grant_encoded = 0;
        grant_valid = 0;

        if (state == STATE_GRANTING || state == STATE_BLOCKED) begin
            grant_valid = 1;
            if (state == STATE_GRANTING) begin
                // Determine grant based on type
                if (ARB_TYPE_ROUND_ROBIN) begin
                    integer i;
                    reg found = 0;
                    for (i = 0; i < PORTS; i++) begin
                        if (request[rr_index + i]) begin
                            grant = 1 << (rr_index + i);
                            grant_encoded = rr_index + i;
                            found = 1;
                            break;
                        end
                    end
                    if (!found) begin
                        // Fallback
                        grant = 0;
                        grant_encoded = 0;
                    end
                end
                else begin
                    // Fixed Priority
                    integer p;
                    reg selected = 0;
                    for (p = 0; p < PORTS; p++) begin
                        if (request[p]) begin
                            grant = 1 << p;
                            grant_encoded = p;
                            selected = 1;
                            break;
                        end
                    end
                    if (!selected) begin
                        grant = 0;
                        grant_encoded = 0;
                    end
                end
            end
            else if (state == STATE_BLOCKED) begin
                // Keep the last granted port
                // We need to store the last granted port in a register
                // But we don't have a separate register for the blocked port index.
                // We can use grant_encoded from the previous cycle?
                // No, we need to store it in the state or a register.
                // Let's add a register for the blocked port index.
                // But the state machine logic above doesn't store it.
                // Let's modify the state machine to store the blocked port index.
                // Or we can use the 'last_granted' signal?
                // 'last_granted' is updated in the sequential block.
                // But we need it in the combinational block for output.
                // Let's use a register 'blocked_port' in the sequential block.
                // But the problem says "complete Verilog-2001 code in one source file".
                // We can add a register.
                // Let's restructure the sequential block to include 'blocked_port'.
            end
        end
    end

    // Re-structuring to include blocked_port register
    reg [LOG_PORTS-1:0] blocked_port;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            blocked_port <= 0;
        end
        else begin
            if (state == STATE_BLOCKED) begin
                blocked_port <= grant_encoded;
            end
            else if (state == STATE_GRANTING) begin
                // Update rr_index for next cycle
                if (ARB_TYPE_ROUND_ROBIN) begin
                    integer i;
                    reg found = 0;
                    for (i = 0; i < PORTS; i++) begin
                        if (request[rr_index + i]) begin
                            next_rr_index = (rr_index + i + 1) % PORTS;
                            found = 1;
                            break;
                        end
                    end
                    if (!found) begin
                        // Should not happen if request != 0
                        next_rr_index = rr_index;
                    end
                end
                else begin
                    next_rr_index = rr_index;
                end
                rr_index <= next_rr_index;
            end
            else begin
                rr_index <= rr_index;
            end
        end
    end

    // Output Logic with blocked_port
    always @(*) begin
        grant = 0;
        grant_encoded = 0;
        grant_valid = 0;

        if (state == STATE_GRANTING || state == STATE_BLOCKED) begin
            grant_valid = 1;
            if (state == STATE_GRANTING) begin
                if (ARB_TYPE_ROUND_ROBIN) begin
                    integer i;
                    reg found = 0;
                    for (i = 0; i < PORTS; i++) begin
                        if (request[rr_index + i]) begin
                            grant = 1 << (rr_index + i);
                            grant_encoded = rr_index + i;
                            found = 1;
                            break;
                        end
                    end
                    if (!found) begin
                        grant = 0;
                        grant_encoded = 0;
                    end
                end
                else begin
                    integer p;
                    reg selected = 0;
                    for (p = 0; p < PORTS; p++) begin
                        if (request[p]) begin
                            grant = 1 << p;
                            grant_encoded = p;
                            selected = 1;
                            break;
                        end
                    end
                    if (!selected) begin
                        grant = 0;
                        grant_encoded = 0;
                    end
                end
            end
            else if (state == STATE_BLOCKED) begin
                grant = 1 << blocked_port;
                grant_encoded = blocked_port;
            end
        end
    end

endmodule
```<|im_end|>
