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

    reg [PORTS-1:0]         grant_reg;
    reg                     grant_valid_reg;
    reg [$clog2(PORTS)-1:0] grant_encoded_reg;
    reg [PORTS-1:0]         priority;
    reg [PORTS-1:0]         req_mask;
    reg [PORTS-1:0]         ack_mask;
    reg [PORTS-1:0]         next_grant;

    // Priority calculation
    always @(*) begin
        if (ARB_TYPE_ROUND_ROBIN) begin
            // Rotate priority
            priority = {grant_reg[0], grant_reg[PORTS-1:1]};
        end else begin
            // Fixed priority
            priority = {PORTS{1'b1}};
        end
    end

    // req_mask calculation
    always @(*) begin
        req_mask = request & priority;
        if (ARB_BLOCK) begin
            req_mask = req_mask & ~acknowledge;
        end
    end

    // next_grant calculation
    always @(*) begin
        next_grant = 0;
        if (ARB_LSB_HIGH_PRIORITY) begin
            for (integer i = 0; i < PORTS; i = i + 1) begin
                if (req_mask[i]) begin
                    next_grant = (1 << i);
                end
            end
        end else begin
            for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                if (req_mask[i]) begin
                    next_grant = (1 << i);
                end
            end
        end
    end

    // grant_reg, grant_valid_reg, grant_encoded_reg update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= 0;
            grant_valid_reg <= 0;
            grant_encoded_reg <= 0;
        end else begin
            if (next_grant != 0) begin
                grant_reg <= next_grant;
                grant_valid_reg <= 1;
                grant_encoded_reg <= $clog2(PORTS)'(next_grant);
            end else if (grant_valid_reg && (!ARB_BLOCK || !ARB_BLOCK_ACK || acknowledge[grant_encoded_reg])) begin
                grant_valid_reg <= 0;
            end
        end
    end

    // Outputs
    assign grant = grant_reg;
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = grant_encoded_reg;

endmodule
