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

    reg [PORTS-1:0]                 next_grant;
    reg [PORTS-1:0]                 current_grant;
    reg [$clog2(PORTS)-1:0]         current_grant_encoded;
    reg                             request_valid;
    reg [$clog2(PORTS)-1:0]         round_robin_counter;
    reg [$clog2(PORTS)-1:0]         next_round_robin_counter;

    always @(*) begin
        next_grant = 0;
        next_round_robin_counter = round_robin_counter;
        request_valid = |request;

        if (ARB_TYPE_ROUND_ROBIN) begin
            // Find the next request starting from round_robin_counter
            for (integer i = 0; i < PORTS; i = i + 1) begin
                integer index = (round_robin_counter + i) % PORTS;
                if (request[index]) begin
                    next_grant[index] = 1;
                    next_round_robin_counter = index + 1;
                    break;
                end
            end
        end else begin
            // Fixed priority with LSB high priority if ARB_LSB_HIGH_PRIORITY
            if (ARB_LSB_HIGH_PRIORITY) begin
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        next_grant[i] = 1;
                        break;
                    end
                end
            end else begin
                for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                    if (request[i]) begin
                        next_grant[i] = 1;
                        break;
                    end
                end
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            current_grant_encoded <= 0;
            round_robin_counter <= 0;
            grant_valid <= 0;
        end else begin
            if (!grant_valid || (!ARB_BLOCK_ACK && acknowledge[current_grant_encoded]) || !request[current_grant_encoded]) begin
                current_grant <= next_grant;
                current_grant_encoded <= 0;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (next_grant[i]) begin
                        current_grant_encoded <= i;
                    end
                end
                round_robin_counter <= next_round_robin_counter;
                grant_valid <= request_valid;
            end
        end
    end

    assign grant = current_grant;
    assign grant_encoded = current_grant_encoded;

endmodule
