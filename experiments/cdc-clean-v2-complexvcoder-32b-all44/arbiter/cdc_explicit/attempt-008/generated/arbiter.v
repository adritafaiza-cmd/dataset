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

    wire [PORTS-1:0] req_active;
    wire [PORTS-1:0] next_grant;
    reg  [PORTS-1:0] current_grant;
    reg  [$clog2(PORTS)-1:0] grant_index;
    reg  block_condition;

    // Capture active requests
    assign req_active = request;

    // Determine the next grant
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin : round_robin_arb
            wire [PORTS-1:0] rotated_req;
            assign rotated_req = req_active << (grant_index + 1) | (req_active >> (PORTS - grant_index - 1));

            always @(*) begin
                next_grant = 0;
                if (ARB_LSB_HIGH_PRIORITY) begin
                    for (integer i = 0; i < PORTS; i = i + 1) begin
                        if (rotated_req[i]) begin
                            next_grant[i] = 1;
                            break;
                        end
                    end
                end else begin
                    for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                        if (rotated_req[i]) begin
                            next_grant[i] = 1;
                            break;
                        end
                    end
                end
            end
        end else begin : fixed_priority_arb
            always @(*) begin
                next_grant = 0;
                if (ARB_LSB_HIGH_PRIORITY) begin
                    for (integer i = 0; i < PORTS; i = i + 1) begin
                        if (req_active[i]) begin
                            next_grant[i] = 1;
                            break;
                        end
                    end
                end else begin
                    for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                        if (req_active[i]) begin
                            next_grant[i] = 1;
                            break;
                        end
                    end
                end
            end
        end
    endgenerate

    // Determine block condition
    always @(*) begin
        block_condition = 0;
        if (ARB_BLOCK) begin
            if (ARB_BLOCK_ACK) begin
                block_condition = (current_grant & ~acknowledge) != 0;
            end else begin
                block_condition = (current_grant & request) != 0;
            end
        end
    end

    // Update current grant and grant_valid
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            grant_valid <= 0;
            grant_index <= 0;
        end else begin
            if (!block_condition && !grant_valid) begin
                current_grant <= next_grant;
                grant_valid <= 1;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (next_grant[i]) begin
                        grant_index <= i;
                    end
                end
            end else if (grant_valid && (acknowledge & current_grant) != 0) begin
                grant_valid <= 0;
            end
        end
    end

    // Assign grant and grant_encoded
    assign grant = current_grant;
    assign grant_encoded = grant_index;

endmodule
