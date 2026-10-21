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
    localparam NUM_STATES = PORTS;

    // State encoding:
    // 0: IDLE
    // 1..PORTS: Active grant state (state index corresponds to granted port)
    reg [LOG_PORTS:0] state;
    reg [LOG_PORTS:0] next_state;
    reg [PORTS-1:0]   next_grant;
    reg [LOG_PORTS-1:0] round_robin_index;
    reg [LOG_PORTS-1:0] next_round_robin_index;

    // Internal signals for priority logic
    reg [PORTS-1:0] active_ports;
    reg [PORTS-1:0] priority_mask;

    // Priority calculation based on LSB_HIGH_PRIORITY
    genvar i;
    generate
        if (ARB_LSB_HIGH_PRIORITY) begin : gen_high_priority
            // Lower index = Higher priority
            assign priority_mask = {PORTS{1'b1}};
        end
        else begin : gen_low_priority
            // Higher index = Higher priority
            assign priority_mask = {PORTS{1'b0}};
            // Invert to make lower index effectively higher priority in selection logic if needed,
            // but standard RR usually scans 0..N-1. Let's stick to scanning 0..N-1.
            // If LSB_HIGH_PRIORITY is 0, we want port PORTS-1 to win over 0.
            // We will handle this in the selection logic by reversing the scan order or masking.
            // Simpler approach: Use a mask that disables lower priority ports.
            // If LSB_HIGH_PRIORITY is 0, Port 3 > Port 2 > ... > Port 0.
            // We can just scan from PORTS-1 down to 0.
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 1; // IDLE
            round_robin_index <= 0;
            grant <= 0;
            grant_valid <= 1'b0;
            grant_encoded <= 0;
            next_state <= 1;
            next_grant <= 0;
            next_round_robin_index <= 0;
            active_ports <= 0;
        end
        else begin
            state <= next_state;
            round_robin_index <= next_round_robin_index;
            grant <= next_grant;
            grant_valid <= 1'b1;
            grant_encoded <= next_grant;
            active_ports <= request;
        end
    end

    always @(*) begin
        next_state = 1; // Default to IDLE
        next_grant = 0;
        next_round_robin_index = round_robin_index;
        active_ports = request;

        if (ARB_TYPE_ROUND_ROBIN) begin
            if (ARB_BLOCK) begin
                // Round Robin with Blocking
                if (state == 1) begin
                    // IDLE: Find first active port based on priority
                    if (ARB_LSB_HIGH_PRIORITY) begin
                        // Scan from 0 to PORTS-1 (0 is highest priority)
                        for (i = 0; i < PORTS; i = i + 1) begin
                            if (active_ports[i]) begin
                                next_grant = i;
                                next_state = i + 1;
                                next_round_robin_index = i;
                                break;
                            end
                        end
                    end
                    else begin
                        // Scan from PORTS-1 down to 0 (PORTS-1 is highest priority)
                        for (i = PORTS - 1; i >= 0; i = i - 1) begin
                            if (active_ports[i]) begin
                                next_grant = i;
                                next_state = i + 1;
                                next_round_robin_index = i;
                                break;
                            end
                        end
                    end
                end
                else begin
                    // Active state: Check if current grant is still requested
                    if (active_ports[next_grant]) begin
                        // Hold grant
                        next_state = state;
                        next_round_robin_index = round_robin_index;
                    end
                    else begin
                        // Grant released, move to next in round robin
                        next_state = 1; // Go back to IDLE to re-evaluate priority
                        // Update round robin index for next time
                        if (ARB_LSB_HIGH_PRIORITY) begin
                            // If we were at PORTS-1, wrap to 0. Else increment.
                            if (round_robin_index == PORTS - 1)
                                next_round_robin_index = 0;
                            else
                                next_round_robin_index = round_robin_index + 1;
                        end
                        else begin
                            // If we were at 0, wrap to PORTS-1. Else decrement.
                            if (round_robin_index == 0)
                                next_round_robin_index = PORTS - 1;
                            else
                                next_round_robin_index = round_robin_index - 1;
                        end
                    end
                end
            end
            else begin
                // Round Robin without Blocking (Grant released immediately if ack comes)
                if (state == 1) begin
                    if (ARB_LSB_HIGH_PRIORITY) begin
                        for (i = 0; i < PORTS; i = i + 1) begin
                            if (active_ports[i]) begin
                                next_grant = i;
                                next_state = i + 1;
                                next_round_robin_index = i;
                                break;
                            end
                        end
                    end
                    else begin
                        for (i = PORTS - 1; i >= 0; i = i - 1) begin
                            if (active_ports[i]) begin
                                next_grant = i;
                                next_state = i + 1;
                                next_round_robin_index = i;
                                break;
                            end
                        end
                    end
                end
                else begin
                    // Active state
                    if (active_ports[next_grant]) begin
                        // Hold grant
                        next_state = state;
                        next_round_robin_index = round_robin_index;
                    end
                    else begin
                        // Grant released, move to next in round robin
                        next_state = 1;
                        if (ARB_LSB_HIGH_PRIORITY) begin
                            if (round_robin_index == PORTS - 1)
                                next_round_robin_index = 0;
                            else
                                next_round_robin_index = round_robin_index + 1;
                        end
                        else begin
                            if (round_robin_index == 0)
                                next_round_robin_index = PORTS - 1;
                            else
                                next_round_robin_index = round_robin_index - 1;
                        end
                    end
                end
            end
        end
        else begin
            // Fixed Priority
            if (state == 1) begin
                if (ARB_LSB_HIGH_PRIORITY) begin
                    // Scan 0 to PORTS-1
                    for (i = 0; i < PORTS; i = i + 1) begin
                        if (active_ports[i]) begin
                            next_grant = i;
                            next_state = i + 1;
                            break;
                        end
                    end
                end
                else begin
                    // Scan PORTS-1 down to 0
                    for (i = PORTS - 1; i >= 0; i = i - 1) begin
                        if (active_ports[i]) begin
                            next_grant = i;
                            next_state = i + 1;
                            break;
                        end
                    end
                end
            end
            else begin
                // Active state
                if (active_ports[next_grant]) begin
                    // Hold grant
                    next_state = state;
                end
                else begin
                    // Grant released, go back to IDLE to re-evaluate fixed priority
                    next_state = 1;
                end
            end
        end
    end

    // Output logic
    assign grant = next_grant;
    assign grant_valid = (state != 1);
    assign grant_encoded = next_grant;

endmodule
```<|im_end|>
