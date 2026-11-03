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

    reg [PORTS-1:0]                 current_grant;
    reg [$clog2(PORTS)-1:0]         round_robin_counter;
    reg                             valid_request;
    reg [$clog2(PORTS)-1:0]         priority_encoded;
    reg [$clog2(PORTS)-1:0]         grant_encoded_internal;
    wire [PORTS-1:0]                next_grant;
    wire [$clog2(PORTS)-1:0]        next_round_robin_counter;

    // Detect valid request
    assign valid_request = |request;

    // Priority encoding logic
    always @(*) begin
        if (ARB_LSB_HIGH_PRIORITY) begin
            // LSB priority
            priority_encoded = 0;
            for (integer i = 0; i < PORTS; i = i + 1) begin
                if (request[i]) begin
                    priority_encoded = i;
                end
            end
        end else begin
            // MSB priority
            priority_encoded = PORTS - 1;
            for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                if (request[i]) begin
                    priority_encoded = i;
                end
            end
        end
    end

    // Next grant logic
    always @(*) begin
        if (ARB_TYPE_ROUND_ROBIN) begin
            // Round-robin priority
            next_grant = 0;
            for (integer i = 0; i < PORTS; i = i + 1) begin
                if (request[(round_robin_counter + i) % PORTS]) begin
                    next_grant[(round_robin_counter + i) % PORTS] = 1;
                    break;
                end
            end
        end else begin
            // Fixed priority
            next_grant = 0;
            next_grant[priority_encoded] = 1;
        end
    end

    // Next round-robin counter logic
    always @(*) begin
        next_round_robin_counter = round_robin_counter;
        if (valid_request) begin
            for (integer i = 0; i < PORTS; i = i + 1) begin
                if (request[(round_robin_counter + i) % PORTS]) begin
                    next_round_robin_counter = (round_robin_counter + i) % PORTS;
                    break;
                end
            end
        end
    end

    // Current grant logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            round_robin_counter <= 0;
        end else begin
            if (ARB_BLOCK) begin
                if ((ARB_BLOCK_ACK && |(acknowledge & current_grant)) || !(request & current_grant)) begin
                    current_grant <= next_grant;
                end
            end else begin
                current_grant <= next_grant;
            end
            if (ARB_TYPE_ROUND_ROBIN && valid_request) begin
                round_robin_counter <= next_round_robin_counter;
            end
        end
    end

    // Grant output
    assign grant = current_grant;

    // Grant valid output
    assign grant_valid = valid_request && (current_grant != 0);

    // Grant encoded output
    always @(*) begin
        grant_encoded_internal = 0;
        for (integer i = 0; i < PORTS; i = i + 1) begin
            if (current_grant[i]) begin
                grant_encoded_internal = i;
            end
        end
    end

    assign grant_encoded = grant_encoded_internal;

endmodule
