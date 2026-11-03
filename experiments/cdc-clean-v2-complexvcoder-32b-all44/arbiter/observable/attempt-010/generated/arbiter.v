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

    reg [$clog2(PORTS)-1:0] current_grant;
    reg [$clog2(PORTS)-1:0] next_grant;
    reg [PORTS-1:0] grant_onehot;
    reg request_valid;
    reg acknowledge_received;
    reg block_release;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            grant_onehot <= 0;
            request_valid <= 0;
            grant_valid <= 0;
        end else begin
            // Determine if there is any active request
            request_valid <= |request;

            // Determine if the acknowledge for the current grant is received
            acknowledge_received <= acknowledge[current_grant];

            // Determine if the current grant should be blocked
            block_release <= ARB_BLOCK && !acknowledge_received;

            // Calculate next grant based on the arbitration type
            if (ARB_TYPE_ROUND_ROBIN) begin
                integer i;
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (request[ (current_grant + i) % PORTS ]) begin
                        next_grant <= (current_grant + i) % PORTS;
                        break;
                    end
                end
            end else begin
                if (ARB_LSB_HIGH_PRIORITY) begin
                    integer i;
                    for (i = 0; i < PORTS; i = i + 1) begin
                        if (request[i]) begin
                            next_grant <= i;
                            break;
                        end
                    end
                end else begin
                    integer i;
                    for (i = PORTS - 1; i >= 0; i = i - 1) begin
                        if (request[i]) begin
                            next_grant <= i;
                            break;
                        end
                    end
                end
            end

            // Update current grant if not blocked and acknowledge is received
            if (!block_release && acknowledge_received) begin
                current_grant <= next_grant;
            end

            // Update grant_onehot and grant_valid
            grant_onehot <= (1 << current_grant);
            grant_valid <= request_valid && (!ARB_BLOCK || acknowledge_received);
        end
    end

    assign grant = grant_onehot;
    assign grant_encoded = current_grant;

endmodule
