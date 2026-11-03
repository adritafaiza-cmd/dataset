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

    reg [$clog2(PORTS)-1:0] next_grant;
    reg [$clog2(PORTS)-1:0] current_grant;
    reg [PORTS-1:0]         request_masked;
    reg [PORTS-1:0]         grant_reg;
    reg                     grant_valid_reg;
    reg [$clog2(PORTS)-1:0] grant_encoded_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= 0;
            grant_valid_reg <= 0;
            grant_encoded_reg <= 0;
        end else begin
            // Generate masked request vector
            if (ARB_BLOCK && grant_valid_reg && !acknowledge[grant_encoded_reg])
                request_masked <= request & ~(1 << grant_encoded_reg);
            else
                request_masked <= request;

            // Determine next grant
            if (ARB_TYPE_ROUND_ROBIN) begin
                // Find next request in round-robin order
                integer i;
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (request_masked[(current_grant + i) % PORTS]) begin
                        next_grant <= (current_grant + i) % PORTS;
                        break;
                    end
                end
            end else if (ARB_LSB_HIGH_PRIORITY) begin
                // Find next request with LSB priority
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request_masked[i]) begin
                        next_grant <= i;
                        break;
                    end
                end
            end else begin
                // Fixed priority
                for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                    if (request_masked[i]) begin
                        next_grant <= i;
                        break;
                    end
                end
            end

            // Update grant and grant_valid
            if (ARB_BLOCK && grant_valid_reg && !acknowledge[grant_encoded_reg]) begin
                // Hold current grant
                grant_encoded_reg <= grant_encoded_reg;
                grant_valid_reg <= grant_valid_reg;
            end else begin
                // Update to next grant
                grant_encoded_reg <= next_grant;
                grant_valid_reg <= |request_masked;
            end

            // Register the next grant and grant_valid
            current_grant <= next_grant;
            grant_reg <= 1 << grant_encoded_reg;
        end
    end

    assign grant = grant_reg;
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = grant_encoded_reg;

endmodule
