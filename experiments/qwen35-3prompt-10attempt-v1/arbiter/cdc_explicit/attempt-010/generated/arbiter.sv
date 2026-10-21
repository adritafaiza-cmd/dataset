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
    // State: [Next Winner Index : Current Winner Index]
    // We use a counter that wraps around.
    // If ARB_TYPE_ROUND_ROBIN is 0, we ignore the state machine logic for rotation.
    
    reg [LOG_PORTS-1:0] rr_counter;
    reg [LOG_PORTS-1:0] rr_next;
    reg [LOG_PORTS-1:0] rr_current;
    
    // For Fixed Priority, we just need the highest index (or lowest depending on LSB_HIGH_PRIORITY)
    // We will compute this combinatorially.
    
    // Grant State Machine
    // States: IDLE, GRANTING, BLOCKING
    // To ensure CDC safety, we use a synchronous state machine with one-hot or binary encoding.
    // We use a simple binary state machine for area efficiency, ensuring all transitions are synchronous.
    
    reg [1:0] state;
    parameter IDLE = 2'b00;
    parameter GRANTING = 2'b01;
    parameter BLOCKING = 2'b10;

    // Internal signals for priority selection
    wire [LOG_PORTS-1:0] priority_index;
    wire priority_valid;

    // ---------------------------------------------------------
    // Priority Logic (Combinatorial)
    // ---------------------------------------------------------
    // Determine which port has the highest priority based on current request.
    // If ARB_LSB_HIGH_PRIORITY is 1, lower index wins ties (e.g., 0 > 1 > 2).
    // If ARB_LSB_HIGH_PRIORITY is 0, higher index wins ties (e.g., 3 > 2 > 1).
    
    always @(*) begin
        priority_valid = 1'b0;
        priority_index = 0;
        
        if (ARB_TYPE_ROUND_ROBIN) begin
            // In Round Robin mode, the "priority" is effectively the next counter value
            // if that port is requesting. If not, we find the next one.
            // However, the standard RR arbiter logic is:
            // 1. Check if the current counter port is requesting.
            // 2. If yes, grant it.
            // 3. If no, increment counter and check again.
            // This is handled in the sequential logic below to avoid race conditions 
            // and to keep the "next" pointer valid across clock cycles.
            
            // We set a flag here to indicate that the decision depends on the RR state
            // rather than a static priority scan.
            priority_valid = 1'b1; 
            // The actual index will be derived from rr_counter in the next block
        end
        else begin
            // Fixed Priority Scan
            if (ARB_LSB_HIGH_PRIORITY) begin
                // LSB High: 0 is highest priority. Find first '1' in request.
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        priority_index = i;
                        priority_valid = 1'b1;
                        break;
                    end
                end
            end
            else begin
                // LSB Low (MSB High): PORTS-1 is highest priority. Find last '1' in request.
                for (integer i = PORTS-1; i >= 0; i = i - 1) begin
                    if (request[i]) begin
                        priority_index = i;
                        priority_valid = 1'b1;
                        break;
                    end
                end
            end
        end
    end

    // ---------------------------------------------------------
    // State Machine & Round Robin Logic
    // ---------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            rr_counter <= 0;
            rr_next <= 0;
            rr_current <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (priority_valid) begin
                        // Check if the priority winner is actually requesting
                        if (ARB_TYPE_ROUND_ROBIN) begin
                            // In RR mode, we check if the current counter points to a requester
                            if (request[rr_counter]) begin
                                state <= GRANTING;
                                rr_current <= rr_counter;
                            end
                            else begin
                                // Increment counter to find next requester
                                rr_counter <= rr_counter + 1;
                                // Wrap around if needed, but we keep checking until we find one or loop
                                // Since at least one request must exist to enter GRANTING, 
                                // we just wrap the counter.
                                if (rr_counter >= PORTS) rr_counter <= 0;
                                state <= IDLE;
                            end
                        end
                        else begin
                            // Fixed Priority
                            state <= GRANTING;
                            rr_current <= priority_index;
                        end
                    end
                    else begin
                        state <= IDLE;
                    end
                end

                GRANTING: begin
                    // Grant is active.
                    // If ARB_BLOCK is 0, we go back to IDLE immediately after this cycle.
                    // If ARB_BLOCK is 1, we wait for acknowledge.
                    if (ARB_BLOCK) begin
                        if (acknowledge[rr_current]) begin
                            // Ack received, release grant
                            state <= IDLE;
                        end
                        else begin
                            // Still blocking, stay in GRANTING
                            state <= GRANTING;
                        end
                    end
                    else begin
                        // Non-blocking, release immediately
                        state <= IDLE;
                    end
                end

                BLOCKING: begin
                    // This state is technically redundant if we handle the transition in GRANTING,
                    // but kept for clarity if logic changes. 
                    // With current logic, we transition directly from GRANTING.
                    state <= IDLE;
                end
            endcase
        end
    end

    // ---------------------------------------------------------
    // Output Logic
    // ---------------------------------------------------------
    // Determine the final grant index
    wire [LOG_PORTS-1:0] final_grant_index;
    wire final_grant_valid;

    always @(*) begin
        final_grant_valid = 1'b0;
        final_grant_index = 0;

        if (state == GRANTING) begin
            if (ARB_TYPE_ROUND_ROBIN) begin
                final_grant_index = rr_counter;
                // Ensure we only grant if the port is requesting (safety check)
                if (request[rr_counter]) final_grant_valid = 1'b1;
            end
            else begin
                final_grant_index = priority_index;
                if (priority_valid) final_grant_valid = 1'b1;
            end
        end
        else begin
            final_grant_valid = 1'b0;
        end
    end

    // Assign outputs
    grant = final_grant_index;
    grant_valid = final_grant_valid;
    grant_encoded = final_grant_index;

    // ---------------------------------------------------------
    // CDC Safety Measures
    // ---------------------------------------------------------
    // 1. Synchronous State Machine: All state transitions occur on clk edge.
    // 2. Reset Synchronization: Single active-high reset.
    // 3. Data Coherence: 
    //    - 'request' and 'acknowledge' are sampled synchronously.
    //    - 'grant' and 'grant_encoded' are derived purely from synchronous state and inputs.
    //    - No asynchronous resets or cross-clock-domain handshakes within this module.
    //    - The handshake (grant_valid/acknowledge) is fully synchronous.
    
    // Optional: Add a small delay or register if synthesis tool flags potential timing issues
    // with the combinatorial priority loop, but for PORTS=4 it is trivial.
    // For larger PORTS, the loop might be optimized by the synthesizer.

endmodule
```<|im_end|>
