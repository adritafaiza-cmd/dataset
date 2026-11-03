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
    reg [PORTS-1:0]                 priority;
    reg [$clog2(PORTS)-1:0]         grant_encoded_reg;
    reg                             grant_valid_reg;
    reg [$clog2(PORTS)-1:0]         round_robin_counter;

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            grant_valid_reg <= 0;
            round_robin_counter <= 0;
        end else begin
            if (ARB_TYPE_ROUND_ROBIN) begin
                // Rotate priority using round_robin_counter
                for (i = 0; i < PORTS; i = i + 1) begin
                    priority[i] <= request[(round_robin_counter + i) % PORTS];
                end
            end else begin
                // Use fixed priority
                priority <= request;
            end

            // Select the highest priority request that is active
            if (ARB_LSB_HIGH_PRIORITY) begin
                // Prioritize lower significant bit in case of ties
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (priority[i]) begin
                        next_grant <= (1 << i);
                        break;
                    end
                end
            end else begin
                // Prioritize higher significant bit in case of ties
                for (i = PORTS - 1; i >= 0; i = i - 1) begin
                    if (priority[i]) begin
                        next_grant <= (1 << i);
                        break;
                    end
                end
            end

            // If ARB_BLOCK is set, hold the grant until acknowledge (ARB_BLOCK_ACK nonzero) or until request drops (ARB_BLOCK_ACK zero)
            if (ARB_BLOCK) begin
                if (grant_valid_reg && acknowledge[grant_encoded_reg] == ARB_BLOCK_ACK) begin
                    current_grant <= current_grant;
                    grant_valid_reg <= grant_valid_reg;
                end else if (|request) begin
                    current_grant <= next_grant;
                    grant_valid_reg <= 1;
                end else begin
                    current_grant <= 0;
                    grant_valid_reg <= 0;
                end
            end else begin
                if (|request) begin
                    current_grant <= next_grant;
                    grant_valid_reg <= 1;
                end else begin
                    current_grant <= 0;
                    grant_valid_reg <= 0;
                end
            end

            // Update round_robin_counter if a grant is made
            if (grant_valid_reg) begin
                round_robin_counter <= grant_encoded_reg + 1;
            end

            // Encode the grant signal into grant_encoded
            for (i = 0; i < PORTS; i = i + 1) begin
                if (current_grant[i]) begin
                    grant_encoded_reg <= i;
                end
            end
        end
    end

    assign grant = current_grant;
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = grant_encoded_reg;

endmodule
