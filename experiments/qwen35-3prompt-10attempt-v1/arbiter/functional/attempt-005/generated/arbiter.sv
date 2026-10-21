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

    // State encoding
    // 0: Idle
    // 1: Granting (Round Robin or Fixed)
    // 2: Blocked (Waiting for Ack)
    localparam [LOG_PORTS-1:0] STATE_IDLE = 0;
    localparam [LOG_PORTS-1:0] STATE_GRANT = 1;
    localparam [LOG_PORTS-1:0] STATE_BLOCK = 2;

    reg [LOG_PORTS-1:0] state, next_state;
    reg [LOG_PORTS-1:0] next_request_idx;
    reg [LOG_PORTS-1:0] current_request_idx;
    reg [LOG_PORTS-1:0] round_robin_idx;
    reg [LOG_PORTS-1:0] fixed_priority_mask; // For LSB/MSB selection
    reg [LOG_PORTS-1:0] priority_vector;     // For fixed priority logic

    // Internal signals for grant logic
    reg [PORTS-1:0] internal_grant;
    reg grant_valid_int;

    // Initialize round robin index
    always @(posedge clk or posedge rst) begin
        if (rst)
            round_robin_idx <= 0;
        else
            round_robin_idx <= round_robin_idx;
    end

    // Priority Vector Generation for Fixed Priority
    // If LSB_HIGH_PRIORITY: 1 means that port has higher priority than lower bits
    // If LSB_HIGH_PRIORITY is 0: MSB has higher priority
    // We construct a vector where bit i is 1 if port i is eligible and has priority over all lower priority ports
    // Actually, simpler approach: Generate a mask of active requests, then select based on priority.
    
    // State Machine Logic
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= STATE_IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        grant_valid_int = 1'b0;
        internal_grant = 0;

        if (state == STATE_IDLE) begin
            // Find the highest priority request
            if (ARB_TYPE_ROUND_ROBIN) begin
                // Round Robin Logic
                // Start checking from round_robin_idx
                // Find first active request starting from round_robin_idx wrapping around
                reg [LOG_PORTS-1:0] start_idx;
                reg [LOG_PORTS-1:0] i;
                reg found;
                
                start_idx = round_robin_idx;
                found = 1'b0;
                
                // Check if current start index is active
                if (request[start_idx]) begin
                    next_request_idx = start_idx;
                    found = 1'b1;
                end else begin
                    // Rotate until we find one
                    for (i = 0; i < PORTS; i = i + 1) begin
                        if (request[start_idx]) begin
                            next_request_idx = start_idx;
                            found = 1'b1;
                            break;
                        end
                        start_idx = start_idx + 1;
                        if (start_idx >= PORTS) start_idx = 0;
                    end
                end

                if (found) begin
                    next_state = STATE_GRANT;
                    internal_grant = 1 << next_request_idx;
                    grant_valid_int = 1'b1;
                    grant_encoded = next_request_idx;
                    
                    // Update round robin index for next time
                    // Move to the next port after the granted one
                    round_robin_idx = next_request_idx + 1;
                    if (round_robin_idx >= PORTS) round_robin_idx = 0;
                end
            end else begin
                // Fixed Priority Logic
                // Determine priority direction
                reg [PORTS-1:0] active_mask;
                active_mask = request;
                
                if (ARB_LSB_HIGH_PRIORITY) begin
                    // LSB has highest priority. 
                    // We want the smallest index i such that request[i] is high.
                    // We can do this by finding the first '1' from LSB side.
                    // However, standard priority encoders usually give MSB.
                    // Let's construct a mask where we shift left or right?
                    // Simpler: Iterate from 0 to PORTS-1. First one found is winner.
                    
                    reg [LOG_PORTS-1:0] i;
                    reg winner_found;
                    winner_found = 1'b0;
                    
                    for (i = 0; i < PORTS; i = i + 1) begin
                        if (request[i]) begin
                            next_request_idx = i;
                            winner_found = 1'b1;
                            break;
                        end
                    end
                    
                    if (winner_found) begin
                        next_state = STATE_GRANT;
                        internal_grant = 1 << next_request_idx;
                        grant_valid_int = 1'b1;
                        grant_encoded = next_request_idx;
                    end
                end else begin
                    // MSB has highest priority.
                    // Iterate from PORTS-1 down to 0.
                    reg [LOG_PORTS-1:0] i;
                    reg winner_found;
                    winner_found = 1'b0;
                    
                    for (i = PORTS-1; i >= 0; i = i - 1) begin
                        if (request[i]) begin
                            next_request_idx = i;
                            winner_found = 1'b1;
                            break;
                        end
                    end
                    
                    if (winner_found) begin
                        next_state = STATE_GRANT;
                        internal_grant = 1 << next_request_idx;
                        grant_valid_int = 1'b1;
                        grant_encoded = next_request_idx;
                    end
                end
            end
        end
        else if (state == STATE_GRANT) begin
            // Grant is held if ARB_BLOCK is set and acknowledge is not received
            // If ARB_BLOCK is 0, grant is released immediately after this cycle (next_state = IDLE)
            // But wait, the requirement says: "hold the grant until acknowledge ... or until request drops"
            // If ARB_BLOCK is 0, we don't hold. We grant once and release.
            
            if (ARB_BLOCK) begin
                if (acknowledge[next_request_idx]) begin
                    // Ack received, release grant
                    next_state = STATE_IDLE;
                end else if (request[next_request_idx] == 1'b0) begin
                    // Request dropped, release grant
                    next_state = STATE_IDLE;
                end else begin
                    // Still waiting
                    next_state = STATE_BLOCK;
                end
            end else begin
                // Non-blocking: Grant for one cycle then release
                next_state = STATE_IDLE;
            end
            
            // Output logic for this cycle
            internal_grant = 1 << next_request_idx;
            grant_valid_int = 1'b1;
            grant_encoded = next_request_idx;
        end
        else if (state == STATE_BLOCK) begin
            // Holding grant
            if (acknowledge[next_request_idx]) begin
                next_state = STATE_IDLE;
            end else if (request[next_request_idx] == 1'b0) begin
                next_state = STATE_IDLE;
            end
            // Else stay in STATE_BLOCK
            
            internal_grant = 1 << next_request_idx;
            grant_valid_int = 1'b1;
            grant_encoded = next_request_idx;
        end
    end

    // Assign outputs
    assign grant = internal_grant;
    assign grant_valid = grant_valid_int;
    assign grant_encoded = next_request_idx;

endmodule
```<|im_end|>
