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

    reg  [$clog2(PORTS)-1:0] next_grant;
    reg  [$clog2(PORTS)-1:0] current_grant;
    reg  [PORTS-1:0]         grant_mask;
    reg                      valid_request;
    reg  [$clog2(PORTS)-1:0] round_robin_ptr;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            round_robin_ptr <= 0;
        end else begin
            // Generate grant_mask
            if (ARB_BLOCK && !ARB_BLOCK_ACK) begin
                grant_mask <= (1 << current_grant);
            end else if (ARB_BLOCK && ARB_BLOCK_ACK) begin
                grant_mask <= (acknowledge[current_grant]) ? (1 << current_grant) : 0;
            end else begin
                grant_mask <= {PORTS{1'b1}};
            end

            // Determine valid_request
            valid_request <= |(request & grant_mask);

            // Determine next_grant
            if (!ARB_TYPE_ROUND_ROBIN) begin
                if (ARB_LSB_HIGH_PRIORITY) begin
                    for (integer i = 0; i < PORTS; i = i + 1) begin
                        if (request[i] & grant_mask[i]) begin
                            next_grant <= i;
                            break;
                        end
                    end
                end else begin
                    for (integer i = PORTS-1; i >= 0; i = i - 1) begin
                        if (request[i] & grant_mask[i]) begin
                            next_grant <= i;
                            break;
                        end
                    end
                end
            end else begin
                if (valid_request && (!ARB_BLOCK || (ARB_BLOCK_ACK && acknowledge[current_grant]))) begin
                    round_robin_ptr <= round_robin_ptr + 1;
                end
                next_grant <= round_robin_ptr;
            end

            // Update current_grant
            if (valid_request) begin
                current_grant <= next_grant;
            end
        end
    end

    // Output assignments
    assign grant_encoded = current_grant;
    assign grant_valid = valid_request;
    assign grant = (1 << current_grant);

endmodule
