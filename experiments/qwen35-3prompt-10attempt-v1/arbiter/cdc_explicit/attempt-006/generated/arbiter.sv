```verilog
`timescale 1ns/1ps

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
    // 0: IDLE
    // 1: GRANTING (Grant issued, waiting for ack or request drop)
    parameter IDLE = 2'b00;
    parameter GRANTING = 2'b01;
    parameter BLOCKING = 2'b10;

    reg [1:0] state;
    reg [LOG_PORTS-1:0] next_state;
    reg [LOG_PORTS-1:0] next_grant_encoded;
    reg [PORTS-1:0] next_grant;
    reg [LOG_PORTS-1:0] round_robin_ptr;
    reg [LOG_PORTS-1:0] next_round_robin_ptr;
    reg [PORTS-1:0] next_request;
    reg [PORTS-1:0] next_acknowledge;
    reg [PORTS-1:0] grant_mask; // Mask of ports that have been granted in current block cycle
    reg [PORTS-1:0] next_grant_mask;

    // Synchronous logic for state and pointers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            round_robin_ptr <= 0;
            next_grant_encoded <= 0;
            next_grant <= {PORTS{1'b0}};
            next_grant_valid <= 1'b0;
            next_round_robin_ptr <= 0;
            grant_mask <= {PORTS{1'b0}};
            next_grant_mask <= {PORTS{1'b0}};
        end else begin
            state <= next_state;
            round_robin_ptr <= next_round_robin_ptr;
            next_grant_encoded <= next_grant_encoded;
            next_grant <= next_grant;
            next_grant_valid <= next_grant_valid;
            next_round_robin_ptr <= next_round_robin_ptr;
            grant_mask <= next_grant_mask;
            next_grant_mask <= next_grant_mask;
        end
    end

    // Combinational logic for next state and outputs
    always @(*) begin
        next_state = IDLE;
        next_grant_encoded = 0;
        next_grant = {PORTS{1'b0}};
        next_grant_valid = 1'b0;
        next_round_robin_ptr = round_robin_ptr;
        next_grant_mask = grant_mask;

        if (state == IDLE) begin
            if (ARB_TYPE_ROUND_ROBIN) begin
                // Round Robin Logic
                next_round_robin_ptr = round_robin_ptr;
                next_grant_mask = {PORTS{1'b0}};
                
                // Find first active request starting from round_robin_ptr
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    next_round_robin_ptr = next_round_robin_ptr + 1;
                    if (next_round_robin_ptr >= PORTS)
                        next_round_robin_ptr = 0;
                    
                    if (request[next_round_robin_ptr]) begin
                        next_grant_encoded = next_round_robin_ptr;
                        next_grant[next_round_robin_ptr] = 1'b1;
                        next_grant_valid = 1'b1;
                        next_grant_mask[next_round_robin_ptr] = 1'b1;
                        next_state = GRANTING;
                        break;
                    end
                end
            end else begin
                // Fixed Priority Logic
                // Determine priority direction based on LSB_HIGH_PRIORITY
                integer i;
                integer start_idx;
                integer end_idx;
                
                if (ARB_LSB_HIGH_PRIORITY) begin
                    start_idx = PORTS - 1;
                    end_idx = 0;
                end else begin
                    start_idx = 0;
                    end_idx = PORTS - 1;
                end

                for (i = start_idx; i != end_idx; i = (i == PORTS - 1) ? 0 : i + 1) begin
                    if (request[i]) begin
                        next_grant_encoded = i;
                        next_grant[i] = 1'b1;
                        next_grant_valid = 1'b1;
                        next_grant_mask[i] = 1'b1;
                        next_state = GRANTING;
                        break;
                    end
                end
            end
        end else if (state == GRANTING) begin
            // If blocking is enabled and ack is not received, stay in GRANTING
            if (ARB_BLOCK && ARB_BLOCK_ACK && acknowledge[next_grant_encoded] == 1'b0) begin
                next_state = GRANTING;
                // Keep grant valid and encoded same
                // Update grant mask to reflect that this port is still holding the grant
                next_grant_mask[next_grant_encoded] = 1'b1;
            end else begin
                // Release grant
                next_state = IDLE;
                next_grant_valid = 1'b0;
                next_grant = {PORTS{1'b0}};
                next_grant_mask = {PORTS{1'b0}};
                
                // Update round robin pointer if round robin mode
                if (ARB_TYPE_ROUND_ROBIN) begin
                    next_round_robin_ptr = next_grant_encoded + 1;
                    if (next_round_robin_ptr >= PORTS)
                        next_round_robin_ptr = 0;
                end
            end
        end else if (state == BLOCKING) begin
            // If blocking is enabled and ack is received, move to GRANTING (to check for new requests)
            // Actually, the spec says "hold the grant until acknowledge... or until request drops".
            // If we are in BLOCKING, it means we granted in the previous cycle and are waiting.
            // Once ack comes, we can release.
            if (ARB_BLOCK && ARB_BLOCK_ACK && acknowledge[next_grant_encoded] == 1'b1) begin
                next_state = IDLE;
                next_grant_valid = 1'b0;
                next_grant = {PORTS{1'b0}};
                next_grant_mask = {PORTS{1'b0}};
                
                if (ARB_TYPE_ROUND_ROBIN) begin
                    next_round_robin_ptr = next_grant_encoded + 1;
                    if (next_round_robin_ptr >= PORTS)
                        next_round_robin_ptr = 0;
                end
            end else begin
                // Still waiting for ack or request dropped
                next_state = BLOCKING;
                next_grant_valid = 1'b1;
                next_grant[next_grant_encoded] = 1'b1;
                next_grant_mask[next_grant_encoded] = 1'b1;
            end
        end
    end

    // Output assignments
    assign grant = next_grant;
    assign grant_valid = next_grant_valid;
    assign grant_encoded = next_grant_encoded;

endmodule
```<|im_end|>
