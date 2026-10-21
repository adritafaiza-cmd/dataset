```verilog
`timescale 1ns / 1ps

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

    // State encoding
    // 0: IDLE
    // 1: GRANTING (holding grant until release event)
    parameter IDLE = 2'b00;
    parameter GRANTING = 2'b01;

    reg [1:0] state;
    reg [LOG_PORTS-1:0] next_state;
    reg [LOG_PORTS-1:0] rr_index; // Round-robin index
    reg [LOG_PORTS-1:0] rr_next;  // Next round-robin index
    reg [LOG_PORTS-1:0] last_grant; // Last granted port for RR

    reg [PORTS-1:0] grant_reg;
    reg grant_valid_reg;

    // Priority Logic
    // If ARB_LSB_HIGH_PRIORITY is 1, port 0 is lowest, PORTS-1 is highest.
    // If ARB_LSB_HIGH_PRIORITY is 0, port 0 is highest, PORTS-1 is lowest.
    // We map the request vector to a priority score.
    // To simplify, we can iterate from highest priority to lowest.
    
    // Determine the highest priority port with a request
    reg [PORTS-1:0] highest_req_port;
    reg highest_req_found;

    always @(*) begin
        highest_req_found = 1'b0;
        highest_req_port = MAX_IDX;

        if (ARB_LSB_HIGH_PRIORITY) begin
            // LSB High Priority: Port (PORTS-1) is highest, Port 0 is lowest.
            // Iterate from PORTS-1 down to 0.
            for (integer i = MAX_IDX; i >= 0; i--) begin
                if (request[i]) begin
                    highest_req_port = i;
                    highest_req_found = 1'b1;
                    break;
                end
            end
        end else begin
            // LSB Low Priority (Standard): Port 0 is highest, Port (PORTS-1) is lowest.
            // Iterate from 0 up to PORTS-1.
            for (integer i = 0; i <= MAX_IDX; i++) begin
                if (request[i]) begin
                    highest_req_port = i;
                    highest_req_found = 1'b1;
                    break;
                end
            end
        end
    end

    // State Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            rr_index <= 0;
            rr_next <= 0;
            last_grant <= 0;
            grant_reg <= 0;
            grant_valid_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (highest_req_found) begin
                        // Grant the highest priority request
                        grant_reg <= highest_req_port;
                        grant_valid_reg <= 1'b1;
                        state <= GRANTING;
                        
                        // Update Round Robin index if enabled
                        if (ARB_TYPE_ROUND_ROBIN) begin
                            rr_next <= highest_req_port;
                        end
                    end else begin
                        grant_reg <= 0;
                        grant_valid_reg <= 1'b0;
                    end
                end

                GRANTING: begin
                    // Hold the grant
                    grant_reg <= grant_reg;
                    grant_valid_reg <= 1'b1;

                    // Check release conditions
                    // 1. If ARB_BLOCK is 0, grant is released immediately after this cycle (or next cycle depending on interpretation, 
                    //    but typically "hold until release event" implies checking the event in the current cycle to decide next state).
                    //    However, the prompt says "If a grant is blocked, hold it until the specified release event."
                    //    This implies the state machine stays in GRANTING until the condition is met.
                    //    Condition: acknowledge from the granted port OR (if ARB_BLOCK_ACK=0) just one cycle.
                    
                    // Let's interpret "blocked" as: The requester did not acknowledge.
                    // If ARB_BLOCK_ACK is 1, we wait for acknowledge.
                    // If ARB_BLOCK_ACK is 0, we release after 1 cycle regardless of ack (standard non-blocking).
                    
                    if (ARB_BLOCK) begin
                        if (ARB_BLOCK_ACK) begin
                            // Wait for acknowledge from the granted port
                            if (acknowledge[grant_reg]) begin
                                state <= IDLE;
                            end
                        end else begin
                            // Release after 1 cycle regardless of ack
                            state <= IDLE;
                        end
                    end else begin
                        // ARB_BLOCK = 0: Grant is valid for exactly one cycle.
                        // Always go back to IDLE.
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    // Output Logic
    assign grant = grant_reg;
    assign grant_valid = grant_valid_reg;

    // Round Robin Encoding Logic
    // If Round Robin is enabled, we need to output the encoded index based on the RR sequence.
    // If Round Robin is disabled, we output the priority-based grant.
    // Note: The prompt asks for "grant_encoded". Usually, this reflects the actual grant.
    // If RR is active, the grant should follow the RR sequence among active requests.
    // However, the state machine above implements Priority or RR based on ARB_TYPE_ROUND_ROBIN.
    // If ARB_TYPE_ROUND_ROBIN is 1, the selection logic inside IDLE needs to change to RR.
    
    // Re-evaluating the selection logic for Round Robin:
    // If ARB_TYPE_ROUND_ROBIN == 1:
    //   Start from rr_next. Find the first active request starting from rr_next (wrapping around).
    //   Grant that port.
    //   Update rr_next to the next port after the granted one.
    
    reg [PORTS-1:0] rr_selected_port;
    reg rr_selection_active;

    always @(*) begin
        rr_selection_active = 1'b0;
        rr_selected_port = MAX_IDX;

        if (ARB_TYPE_ROUND_ROBIN) begin
            // Find next active request starting from rr_next
            for (integer i = 0; i < PORTS; i++) begin
                integer idx;
                idx = rr_next + i;
                if (idx >= PORTS) idx = idx - PORTS;
                
                if (request[idx]) begin
                    rr_selected_port = idx;
                    rr_selection_active = 1'b1;
                    break;
                end
            end
        end else begin
            // Priority logic (same as before)
            if (ARB_LSB_HIGH_PRIORITY) begin
                for (integer i = MAX_IDX; i >= 0; i--) begin
                    if (request[i]) begin
                        rr_selected_port = i;
                        rr_selection_active = 1'b1;
                        break;
                    end
                end
            end else begin
                for (integer i = 0; i <= MAX_IDX; i++) begin
                    if (request[i]) begin
                        rr_selected_port = i;
                        rr_selection_active = 1'b1;
                        break;
                    end
                end
            end
        end
    end

    // Update rr_next for next cycle if RR is enabled and a grant was made
    // We need to capture the grant decision in the combinational logic to update rr_next correctly
    // before the state machine updates the state.
    
    reg [LOG_PORTS-1:0] next_rr_index;
    reg [LOG_PORTS-1:0] next_last_grant;

    always @(*) begin
        next_rr_index = rr_index;
        next_last_grant = last_grant;

        if (ARB_TYPE_ROUND_ROBIN && rr_selection_active) begin
            // Update RR index to the next port after the selected one
            next_rr_index = rr_selected_port + 1;
            if (next_rr_index >= PORTS) next_rr_index = 0;
            
            // Update last_grant to the selected port
            next_last_grant = rr_selected_port;
        end
    end

    // Final Output Assignment
    // If RR is enabled, the grant should be the RR selected port.
    // If Priority is enabled, the grant is the priority selected port.
    // The state machine logic currently handles the "hold" behavior.
    // We need to ensure the output `grant` matches the selection logic used in the state machine.
    
    // To make the code clean and strictly follow the prompt's "fixed or round-robin priority" in one flow:
    // We will re-calculate the selection in the output logic block to ensure `grant` and `grant_encoded` 
    // are always consistent with the current configuration, while the state machine handles the timing/holding.
    
    // Actually, the state machine updates `grant_reg` based on the selection at the time of entry to GRANTING.
    // If we change the selection logic dynamically in the output, it might conflict if the state machine holds a value.
    // But the state machine holds `grant_reg` only until the release event.
    // So, if we want `grant` to reflect the RR logic immediately when requests change, 
    // we should drive `grant` directly from the selection logic, not just from `grant_reg` in the state machine.
    // However, the prompt says "If a grant is blocked, hold it". This implies the output must remain stable.
    // Therefore, `grant_reg` in the state machine is the correct source for `grant`.
    // The issue is that `grant_reg` was updated in the IDLE state based on the selection logic at that moment.
    // So we just need to make sure the selection logic inside the IDLE state (and potentially GRANTING if we were to re-evaluate, but we don't) is correct.
    
    // Wait, there is a nuance: If ARB_TYPE_ROUND_ROBIN is 1, the selection logic inside the `always @(*)` block for `highest_req_port` 
    // (which I named `highest_req_port` but is actually the priority selector) needs to be replaced by the RR selector.
    // Let's refactor the combinational logic to be unified.
    
    // Unified Selection Logic
    reg [PORTS-1:0] selected_port;
    reg selection_valid;

    always @(*) begin
        selection_valid = 1'b0;
        selected_port = MAX_IDX;

        if (ARB_TYPE_ROUND_ROBIN) begin
            // Round Robin Selection
            for (integer i = 0; i < PORTS; i++) begin
                integer idx;
                idx = rr_next + i;
                if (idx >= PORTS) idx = idx - PORTS;
                
                if (request[idx]) begin
                    selected_port = idx;
                    selection_valid = 1'b1;
                    break;
                end
            end
        end else begin
            // Priority Selection
            if (ARB_LSB_HIGH_PRIORITY) begin
                for (integer i = MAX_IDX; i >= 0; i--) begin
                    if (request[i]) begin
                        selected_port = i;
                        selection_valid = 1'b1;
                        break;
                    end
                end
            end else begin
                for (integer i = 0; i <= MAX_IDX; i++) begin
                    if (request[i]) begin
                        selected_port = i;
                        selection_valid = 1'b1;
                        break;
                    end
                end
            end
        end
    end

    // Update rr_next for next cycle
    reg [LOG_PORTS-1:0] next_rr_next;
    always @(*) begin
        next_rr_next = rr_next;
        if (ARB_TYPE_ROUND_ROBIN && selection_valid) begin
            next_rr_next = selected_port + 1;
            if (next_rr_next >= PORTS) next_rr_next = 0;
        end
    end

    // Re-implement State Logic using `selected_port`
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            rr_index <= 0;
            rr_next <= 0;
            last_grant <= 0;
            grant_reg <= 0;
            grant_valid_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (selection_valid) begin
                        grant_reg <= selected_port;
                        grant_valid_reg <= 1'b1;
                        state <= GRANTING;
                        
                        if (ARB_TYPE_ROUND_ROBIN) begin
                            rr_next <= next_rr_next; // Use the calculated next index
                        end
                    end else begin
                        grant_reg <= 0;
                        grant_valid_reg <= 1'b0;
                    end
                end

                GRANTING: begin
                    grant_reg <= grant_reg;
                    grant_valid_reg <= 1'b1;

                    if (ARB_BLOCK) begin
                        if (ARB_BLOCK_ACK) begin
                            if (acknowledge[grant_reg]) begin
                                state <= IDLE;
                            end
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    // Final Outputs
    assign grant = grant_reg;
    assign grant_valid = grant_valid_reg;
    
    // Encode the grant port
    assign grant_encoded = grant;

endmodule
```<|im_end|>
