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

    localparam GRANT_WIDTH = $clog2(PORTS);

    reg [PORTS-1:0] grant_reg;
    reg             grant_valid_reg;
    reg [GRANT_WIDTH-1:0] grant_encoded_reg;

    // For round-robin: track the last granted port
    reg [GRANT_WIDTH-1:0] last_grant;

    // For blocking: track if a grant is currently blocked
    reg block_active;

    // Combinational logic to determine the next grant
    wire [PORTS-1:0] next_grant;
    wire             next_grant_valid;
    wire [GRANT_WIDTH-1:0] next_grant_encoded;

    // Priority encoder for fixed priority
    function [PORTS-1:0] fixed_priority_grant;
        input [PORTS-1:0] req;
        integer i;
        begin
            fixed_priority_grant = {PORTS{1'b0}};
            if (ARB_LSB_HIGH_PRIORITY) begin
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (req[i] && fixed_priority_grant == {PORTS{1'b0}}) begin
                        fixed_priority_grant[i] = 1'b1;
                    end
                end
            end else begin
                for (i = PORTS-1; i >= 0; i = i - 1) begin
                    if (req[i] && fixed_priority_grant == {PORTS{1'b0}}) begin
                        fixed_priority_grant[i] = 1'b1;
                    end
                end
            end
        end
    endfunction

    // Priority encoder for round-robin
    function [PORTS-1:0] round_robin_grant;
        input [PORTS-1:0] req;
        input [GRANT_WIDTH-1:0] last;
        integer i;
        integer start;
        begin
            round_robin_grant = {PORTS{1'b0}};
            if (req == {PORTS{1'b0}}) begin
                round_robin_grant = {PORTS{1'b0}};
            end else begin
                start = last + 1;
                if (start >= PORTS) start = 0;
                // Search from start to PORTS-1
                for (i = start; i < PORTS; i = i + 1) begin
                    if (req[i] && round_robin_grant == {PORTS{1'b0}}) begin
                        round_robin_grant[i] = 1'b1;
                    end
                end
                // Search from 0 to start-1
                for (i = 0; i < start; i = i + 1) begin
                    if (req[i] && round_robin_grant == {PORTS{1'b0}}) begin
                        round_robin_grant[i] = 1'b1;
                    end
                end
            end
        end
    endfunction

    // One-hot to binary encoder
    function [GRANT_WIDTH-1:0] onehot_to_binary;
        input [PORTS-1:0] onehot;
        integer i;
        begin
            onehot_to_binary = {GRANT_WIDTH{1'b0}};
            for (i = 0; i < PORTS; i = i + 1) begin
                if (onehot[i]) begin
                    onehot_to_binary = i[GRANT_WIDTH-1:0];
                end
            end
        end
    endfunction

    // Determine the candidate grant based on arbiter type
    wire [PORTS-1:0] candidate_grant;
    wire             candidate_valid;
    wire [GRANT_WIDTH-1:0] candidate_encoded;

    assign candidate_grant = ARB_TYPE_ROUND_ROBIN ? round_robin_grant(request, last_grant) : fixed_priority_grant(request);
    assign candidate_valid = (candidate_grant != {PORTS{1'b0}});
    assign candidate_encoded = onehot_to_binary(candidate_grant);

    // Blocking logic
    // If ARB_BLOCK is enabled, a grant is held until the acknowledge signal for that port is asserted
    wire block_release;
    wire block_hold;

    if (ARB_BLOCK) begin
        // Block is active if we have a valid grant that hasn't been acknowledged yet
        assign block_release = (grant_valid_reg && acknowledge[grant_encoded_reg]);
        assign block_hold = grant_valid_reg && !block_release;
    end else begin
        assign block_release = 1'b1;
        assign block_hold = 1'b0;
    end

    // Next state logic
    always @(*) begin
        if (block_hold) begin
            // Hold the current grant
            next_grant = grant_reg;
            next_grant_valid = grant_valid_reg;
            next_grant_encoded = grant_encoded_reg;
        end else begin
            // Grant the candidate
            next_grant = candidate_grant;
            next_grant_valid = candidate_valid;
            next_grant_encoded = candidate_encoded;
        end
    end

    // Sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= {PORTS{1'b0}};
            grant_valid_reg <= 1'b0;
            grant_encoded_reg <= {GRANT_WIDTH{1'b0}};
            last_grant <= {GRANT_WIDTH{1'b0}};
        end else begin
            grant_reg <= next_grant;
            grant_valid_reg <= next_grant_valid;
            grant_encoded_reg <= next_grant_encoded;

            // Update last_grant for round-robin when a new grant is issued
            if (ARB_TYPE_ROUND_ROBIN && next_grant_valid && !block_hold) begin
                last_grant <= next_grant_encoded;
            end
        end
    end

    assign grant = grant_reg;
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = grant_encoded_reg;

endmodule
