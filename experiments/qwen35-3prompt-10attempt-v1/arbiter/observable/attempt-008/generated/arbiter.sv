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
    localparam NUM_PORTS = PORTS;

    // State encoding
    // 0: IDLE
    // 1: GRANTING
    // 2: WAITING_FOR_ACK (if ARB_BLOCK_ACK is enabled)
    localparam [1:0] STATE_IDLE = 2'b00;
    localparam [1:0] STATE_GRANTING = 2'b01;
    localparam [1:0] STATE_WAITING_ACK = 2'b10;

    reg [1:0] state, next_state;
    reg [LOG_PORTS-1:0] rr_index;
    reg [NUM_PORTS-1:0] grant_reg;
    reg [NUM_PORTS-1:0] ack_reg;
    reg [NUM_PORTS-1:0] req_reg;
    reg [NUM_PORTS-1:0] grant_mask;

    // Priority logic
    // If LSB_HIGH_PRIORITY is 1, port 0 is highest. If 0, port PORTS-1 is highest.
    // We map the request vector to a priority vector where 1 means "has request"
    // and the index with the highest weight is selected.
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            rr_index <= 0;
            grant_reg <= 0;
            ack_reg <= 0;
            req_reg <= 0;
            grant_mask <= 0;
        end
        else begin
            state <= next_state;
            req_reg <= request;
            ack_reg <= acknowledge;
            
            if (state == STATE_IDLE) begin
                rr_index <= 0;
                grant_mask <= 0;
            end
        end
    end

    // Priority Selection Logic
    // Determine the winner based on current request and priority scheme
    reg [NUM_PORTS-1:0] priority_vector;
    reg [LOG_PORTS-1:0] winner_index;
    reg winner_found;

    always @(*) begin
        winner_found = 1'b0;
        winner_index = 0;
        priority_vector = 0;

        if (ARB_TYPE_ROUND_ROBIN) begin
            // Round Robin: Select the first active port starting from rr_index
            for (int i = 0; i < NUM_PORTS; i++) begin
                int idx = rr_index + i;
                if (idx >= NUM_PORTS) idx = idx - NUM_PORTS;
                
                if (request[idx]) begin
                    winner_index = idx;
                    winner_found = 1'b1;
                    priority_vector = 1 << idx;
                    break;
                end
            end
        end
        else begin
            // Fixed Priority
            // Determine direction of scan based on ARB_LSB_HIGH_PRIORITY
            // If LSB_HIGH_PRIORITY == 1: Scan from 0 to PORTS-1 (0 is highest)
            // If LSB_HIGH_PRIORITY == 0: Scan from PORTS-1 to 0 (PORTS-1 is highest)
            
            if (ARB_LSB_HIGH_PRIORITY) begin
                for (int i = 0; i < NUM_PORTS; i++) begin
                    if (request[i]) begin
                        winner_index = i;
                        winner_found = 1'b1;
                        priority_vector = 1 << i;
                        break;
                    end
                end
            end
            else begin
                for (int i = NUM_PORTS-1; i >= 0; i--) begin
                    if (request[i]) begin
                        winner_index = i;
                        winner_found = 1'b1;
                        priority_vector = 1 << i;
                        break;
                    end
                end
            end
        end

        // Update Round Robin index if a winner was found
        if (winner_found && ARB_TYPE_ROUND_ROBIN) begin
            rr_index = winner_index + 1;
            if (rr_index >= NUM_PORTS) begin
                rr_index = 0;
            end
        end
    end

    // State Machine Logic
    always @(*) begin
        next_state = state;
        grant_valid = 1'b0;
        grant = 0;
        grant_mask = 0;

        case (state)
            STATE_IDLE: begin
                if (winner_found) begin
                    next_state = STATE_GRANTING;
                    grant_valid = 1'b1;
                    grant = 1 << winner_index;
                    grant_mask = 1 << winner_index;
                end
            end

            STATE_GRANTING: begin
                // Check if the granted port acknowledges
                if (ack_reg[winner_index]) begin
                    if (ARB_BLOCK_ACK) begin
                        // Wait for ACK before releasing grant
                        next_state = STATE_WAITING_ACK;
                    end
                    else begin
                        // Release immediately
                        next_state = STATE_IDLE;
                    end
                end
                else begin
                    // Hold grant
                    next_state = STATE_GRANTING;
                end
            end

            STATE_WAITING_ACK: begin
                if (ack_reg[winner_index]) begin
                    next_state = STATE_IDLE;
                end
                else begin
                    next_state = STATE_WAITING_ACK;
                end
            end
        endcase
    end

    // Output assignments
    grant <= grant_reg;
    grant_valid <= (state == STATE_GRANTING || state == STATE_WAITING_ACK) ? 1'b1 : 1'b0;
    
    // Encode the grant signal
    if (grant_valid) begin
        grant_encoded = winner_index;
    end
    else begin
        grant_encoded = 0;
    end

endmodule
```<|im_end|>
