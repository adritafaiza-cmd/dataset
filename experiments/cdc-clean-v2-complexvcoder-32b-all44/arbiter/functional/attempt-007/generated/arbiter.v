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

    wire [PORTS-1:0] next_request;
    reg  [PORTS-1:0] current_request;
    reg  [PORTS-1:0] current_grant;
    wire [PORTS-1:0] next_grant;
    wire [PORTS-1:0] priority;
    wire             request_valid;
    wire             acknowledge_valid;
    wire             next_grant_valid;
    reg  [$clog2(PORTS)-1:0] grant_counter;
    wire [$clog2(PORTS)-1:0] next_grant_counter;

    // Determine request_valid and acknowledge_valid
    assign request_valid = |request;
    assign acknowledge_valid = |acknowledge;

    // Determine next_request
    assign next_request = request;

    // Generate priority vector
    generate
        if (ARB_LSB_HIGH_PRIORITY) begin
            genvar i;
            generate
                for (i = 0; i < PORTS; i = i + 1) begin : gen_priority
                    assign priority[i] = (current_request[i] & ~(current_request & {i{1'b0, current_request[i]}}));
                end
            endgenerate
        end else begin
            assign priority = current_request;
        end
    endgenerate

    // Determine next_grant
    assign next_grant = priority;

    // Determine next_grant_counter
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin
            always @(*) begin
                if (request_valid) begin
                    next_grant_counter = grant_counter + 1;
                    while (next_grant_counter < PORTS && !request[next_grant_counter])
                        next_grant_counter = next_grant_counter + 1;
                end else begin
                    next_grant_counter = grant_counter;
                end
            end
        end else begin
            assign next_grant_counter = 0;
        end
    endgenerate

    // Determine next_grant_valid
    assign next_grant_valid = request_valid & (!ARB_BLOCK || (ARB_BLOCK_ACK ? acknowledge_valid : !request_valid));

    // Update current_request and current_grant
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_request <= 0;
            current_grant <= 0;
            grant_counter <= 0;
        end else begin
            current_request <= next_request;
            if (!ARB_BLOCK || (ARB_BLOCK_ACK ? acknowledge_valid : !request_valid))
                current_grant <= next_grant;
            if (ARB_TYPE_ROUND_ROBIN && request_valid)
                grant_counter <= next_grant_counter;
        end
    end

    // Assign grant, grant_valid, and grant_encoded
    assign grant = current_grant;
    assign grant_valid = next_grant_valid;
    assign grant_encoded = current_grant ? $clog2(current_grant) : 0;

endmodule
