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

    // Internal signals
    reg  [PORTS-1:0]                next_grant;
    reg  [PORTS-1:0]                current_grant;
    wire                            active_request;
    wire [$clog2(PORTS)-1:0]        grant_index;
    reg  [$clog2(PORTS)-1:0]        next_grant_index;
    reg  [$clog2(PORTS)-1:0]        current_grant_index;

    // Detect active request
    assign active_request = |request;

    // Calculate next_grant_index
    always @(*) begin
        if (ARB_TYPE_ROUND_ROBIN) begin
            // Find next request in round-robin fashion
            next_grant_index = current_grant_index + 1;
            while (next_grant_index < PORTS && !request[next_grant_index])
                next_grant_index = next_grant_index + 1;
            if (next_grant_index == PORTS)
                next_grant_index = 0;
            while (next_grant_index < PORTS && !request[next_grant_index])
                next_grant_index = next_grant_index + 1;
        end else begin
            // Find highest priority request
            if (ARB_LSB_HIGH_PRIORITY) begin
                for (next_grant_index = 0; next_grant_index < PORTS; next_grant_index = next_grant_index + 1) begin
                    if (request[next_grant_index])
                        break;
                end
            end else begin
                for (next_grant_index = PORTS-1; next_grant_index >= 0; next_grant_index = next_grant_index - 1) begin
                    if (request[next_grant_index])
                        break;
                end
            end
        end
    end

    // Calculate next_grant
    always @(*) begin
        next_grant = 0;
        next_grant[next_grant_index] = 1;
    end

    // Update current_grant
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            current_grant_index <= 0;
        end else if (active_request) begin
            if (!ARB_BLOCK || (ARB_BLOCK && (!acknowledge[current_grant_index] || !request[current_grant_index]))) begin
                current_grant <= next_grant;
                current_grant_index <= next_grant_index;
            end
        end
    end

    // Calculate grant_index
    always @(*) begin
        grant_index = 0;
        for (grant_index = 0; grant_index < PORTS; grant_index = grant_index + 1) begin
            if (current_grant[grant_index])
                break;
        end
    end

    // Assign outputs
    assign grant = current_grant;
    assign grant_valid = active_request;
    assign grant_encoded = grant_index;

endmodule
