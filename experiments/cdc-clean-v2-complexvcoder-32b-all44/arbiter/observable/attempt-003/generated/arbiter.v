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
    reg [PORTS-1:0]                 req_latched;
    reg [PORTS-1:0]                 req_grant;
    reg [PORTS-1:0]                 grant_reg;
    reg                             grant_valid_reg;
    reg [$clog2(PORTS)-1:0]         grant_encoded_reg;
    reg [$clog2(PORTS)-1:0]         next_grant;
    reg                             next_grant_valid;
    reg [$clog2(PORTS)-1:0]         next_grant_encoded;
    reg                             grant_blocked;
    reg [$clog2(PORTS)-1:0]         round_robin_counter;

    // Latch the request signals into req_latched on the rising edge of the clock
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            req_latched <= 0;
        end else begin
            req_latched <= request;
        end
    end

    // Determine the next grant based on the request signals and the arbitration type
    always @(*) begin
        next_grant_valid = 0;
        next_grant_encoded = 0;

        if (ARB_TYPE_ROUND_ROBIN) begin
            integer i;
            for (i = 0; i < PORTS; i = i + 1) begin
                integer idx = (round_robin_counter + i) % PORTS;
                if (req_latched[idx]) begin
                    next_grant_encoded = idx;
                    next_grant_valid = 1;
                    break;
                end
            end
        end else begin
            integer i;
            if (ARB_LSB_HIGH_PRIORITY) begin
                for (i = PORTS - 1; i >= 0; i = i - 1) begin
                    if (req_latched[i]) begin
                        next_grant_encoded = i;
                        next_grant_valid = 1;
                        break;
                    end
                end
            end else begin
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (req_latched[i]) begin
                        next_grant_encoded = i;
                        next_grant_valid = 1;
                        break;
                    end
                end
            end
        end
    end

    // Determine if the grant is blocked
    always @(*) begin
        grant_blocked = 0;
        if (ARB_BLOCK) begin
            if (ARB_BLOCK_ACK) begin
                if (grant_valid_reg && !acknowledge[grant_encoded_reg]) begin
                    grant_blocked = 1;
                end
            end else begin
                if (grant_valid_reg && request[grant_encoded_reg]) begin
                    grant_blocked = 1;
                end
            end
        end
    end

    // Update grant_reg, grant_valid_reg, and grant_encoded_reg on the rising edge of the clock if grant_blocked is low
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= 0;
            grant_valid_reg <= 0;
            grant_encoded_reg <= 0;
            round_robin_counter <= 0;
        end else begin
            if (!grant_blocked) begin
                grant_reg <= 1 << next_grant_encoded;
                grant_valid_reg <= next_grant_valid;
                grant_encoded_reg <= next_grant_encoded;
                if (ARB_TYPE_ROUND_ROBIN && next_grant_valid) begin
                    round_robin_counter <= next_grant_encoded + 1;
                end
            end
        end
    end

    // Drive the grant, grant_valid, and grant_encoded outputs
    assign grant = grant_reg;
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = grant_encoded_reg;

endmodule
