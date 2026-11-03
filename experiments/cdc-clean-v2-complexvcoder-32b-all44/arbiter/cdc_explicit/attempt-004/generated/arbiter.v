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

    wire [PORTS-1:0] next_grant;
    wire [$clog2(PORTS)-1:0] next_grant_encoded;
    wire request_valid;
    reg [PORTS-1:0] grant_latched;
    reg grant_valid_latched;
    reg [$clog2(PORTS)-1:0] grant_encoded_latched;
    reg [$clog2(PORTS)-1:0] round_robin_counter;

    // Detect if there is any valid request
    assign request_valid = |request;

    // Determine the next grant
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin : round_robin_arb
            always @(*) begin
                next_grant = 0;
                next_grant_encoded = 0;
                for (int i = 0; i < PORTS; i = i + 1) begin
                    int idx = (round_robin_counter + i) % PORTS;
                    if (request[idx]) begin
                        next_grant_encoded = idx;
                        next_grant = 1 << idx;
                        break;
                    end
                end
            end
        end else begin : fixed_priority_arb
            always @(*) begin
                next_grant = 0;
                next_grant_encoded = 0;
                if (ARB_LSB_HIGH_PRIORITY) begin
                    for (int i = 0; i < PORTS; i = i + 1) begin
                        if (request[i]) begin
                            next_grant_encoded = i;
                            next_grant = 1 << i;
                            break;
                        end
                    end
                end else begin
                    for (int i = PORTS - 1; i >= 0; i = i - 1) begin
                        if (request[i]) begin
                            next_grant_encoded = i;
                            next_grant = 1 << i;
                            break;
                        end
                    end
                end
            end
        end
    endgenerate

    // Determine if the grant should be updated
    wire update_grant;
    assign update_grant = (!ARB_BLOCK) || (!grant_valid_latched) || (!ARB_BLOCK_ACK && !acknowledge[next_grant_encoded]) || (!request[next_grant_encoded]);

    // Latch the grant, grant_valid, and grant_encoded
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_latched <= 0;
            grant_valid_latched <= 0;
            grant_encoded_latched <= 0;
            round_robin_counter <= 0;
        end else begin
            if (request_valid && update_grant) begin
                grant_latched <= next_grant;
                grant_valid_latched <= 1;
                grant_encoded_latched <= next_grant_encoded;
            end else if (!request_valid) begin
                grant_latched <= 0;
                grant_valid_latched <= 0;
                grant_encoded_latched <= 0;
            end
            if (ARB_TYPE_ROUND_ROBIN && request_valid && update_grant) begin
                round_robin_counter <= round_robin_counter + 1;
            end
        end
    end

    // Assign outputs
    assign grant = grant_latched;
    assign grant_valid = grant_valid_latched;
    assign grant_encoded = grant_encoded_latched;

endmodule
