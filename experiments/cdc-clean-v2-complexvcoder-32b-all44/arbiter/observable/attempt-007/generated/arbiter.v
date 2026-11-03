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
    reg [$clog2(PORTS)-1:0] next_grant;
    reg [$clog2(PORTS)-1:0] current_grant;
    reg [$clog2(PORTS)-1:0] round_robin_counter;
    reg [$clog2(PORTS)-1:0] fixed_priority;
    reg                       blocked;
    reg                       block_acknowledge;

    // Grant vector
    wire [PORTS-1:0] grant_vector;

    // Assign grant vector
    assign grant_vector = (1 << current_grant);

    // Assign grant and grant_encoded
    assign grant = grant_vector;
    assign grant_encoded = current_grant;

    // Grant valid signal
    assign grant_valid = (|grant_vector) & ~blocked;

    // Determine fixed priority based on LSB_HIGH_PRIORITY
    generate
        if (ARB_LSB_HIGH_PRIORITY) begin
            assign fixed_priority = $clog2(PORTS) - 1 - current_grant;
        end else begin
            assign fixed_priority = current_grant;
        end
    endgenerate

    // Determine next grant
    always @(*) begin
        if (ARB_TYPE_ROUND_ROBIN) begin
            next_grant = round_robin_counter;
        end else begin
            next_grant = fixed_priority;
        end

        // Find the next available request
        for (integer i = 0; i < PORTS; i = i + 1) begin
            if (request[(next_grant + i) % PORTS]) begin
                next_grant = (next_grant + i) % PORTS;
                break;
            end
        end
    end

    // Sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            round_robin_counter <= 0;
            blocked <= 0;
            block_acknowledge <= 0;
        end else begin
            if (grant_valid && acknowledge[current_grant]) begin
                blocked <= 0;
            end else if (grant_valid && ARB_BLOCK) begin
                blocked <= 1;
            end

            if (grant_valid && acknowledge[current_grant] && ARB_BLOCK_ACK) begin
                block_acknowledge <= 1;
            end else if (grant_valid && acknowledge[current_grant] && !ARB_BLOCK_ACK) begin
                block_acknowledge <= 0;
            end

            if (!blocked) begin
                current_grant <= next_grant;
                if (ARB_TYPE_ROUND_ROBIN) begin
                    round_robin_counter <= round_robin_counter + 1;
                end
            end
        end
    end

endmodule
