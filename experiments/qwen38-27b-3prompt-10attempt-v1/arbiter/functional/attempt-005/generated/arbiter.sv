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

    localparam NUM_BITS = $clog2(PORTS);

    reg [PORTS-1:0] grant_reg;
    reg [NUM_BITS-1:0] grant_encoded_reg;
    reg grant_valid_reg;

    // For round-robin, we need to track the last granted port
    reg [NUM_BITS-1:0] last_grant;

    // Function to find the first set bit (LSB priority)
    function [PORTS-1:0] find_first_set;
        input [PORTS-1:0] mask;
        integer i;
        begin
            find_first_set = {PORTS{1'b0}};
            for (i = 0; i < PORTS; i = i + 1) begin
                if (mask[i] && find_first_set == {PORTS{1'b0}}) begin
                    find_first_set[i] = 1'b1;
                end
            end
        end
    endfunction

    // Function to find the last set bit (MSB priority)
    function [PORTS-1:0] find_last_set;
        input [PORTS-1:0] mask;
        integer i;
        begin
            find_last_set = {PORTS{1'b0}};
            for (i = PORTS - 1; i >= 0; i = i - 1) begin
                if (mask[i] && find_last_set == {PORTS{1'b0}}) begin
                    find_last_set[i] = 1'b1;
                end
            end
        endfunction
    endfunction

    // Function to encode one-hot to binary
    function [NUM_BITS-1:0] encode_one_hot;
        input [PORTS-1:0] one_hot;
        integer i;
        begin
            encode_one_hot = {NUM_BITS{1'b0}};
            for (i = 0; i < PORTS; i = i + 1) begin
                if (one_hot[i]) begin
                    encode_one_hot = i[NUM_BITS-1:0];
                end
            end
        end
    endfunction

    // Combinational logic to determine the grant
    wire [PORTS-1:0] grant_comb;
    wire grant_valid_comb;
    wire [NUM_BITS-1:0] grant_encoded_comb;

    // For round-robin, we rotate the request based on last_grant
    // We need to create a rotated version of the request where the port after last_grant has highest priority
    wire [PORTS-1:0] rotated_request;
    wire [PORTS-1:0] rotated_mask;

    // Generate rotated request for round-robin
    // The idea: shift the request so that the port after last_grant is at position 0
    // Then find the first set bit in the rotated request
    // Then rotate back to get the actual grant

    // For simplicity, let's use a different approach:
    // Create a priority mask where ports after last_grant have higher priority
    // We can do this by creating two masks:
    // 1. Ports with index > last_grant (these should have higher priority)
    // 2. Ports with index <= last_grant (these should have lower priority)

    wire [PORTS-1:0] high_priority_mask;
    wire [PORTS-1:0] low_priority_mask;

    genvar g;
    generate
        for (g = 0; g < PORTS; g = g + 1) begin : gen_mask
            if (ARB_TYPE_ROUND_ROBIN) begin
                // High priority: ports with index > last_grant
                assign high_priority_mask[g] = (g > last_grant);
                // Low priority: ports with index <= last_grant
                assign low_priority_mask[g] = (g <= last_grant);
            end else begin
                // Fixed priority: all ports have same priority level
                assign high_priority_mask[g] = 1'b1;
                assign low_priority_mask[g] = 1'b0;
            end
        end
    endgenerate

    // For fixed priority, we just use the request directly
    // For round-robin, we first check high priority ports, then low priority ports

    wire [PORTS-1:0] high_priority_request;
    wire [PORTS-1:0] low_priority_request;

    assign high_priority_request = request & high_priority_mask;
    assign low_priority_request = request & low_priority_mask;

    // Find the grant based on priority
    wire [PORTS-1:0] grant_high;
    wire [PORTS-1:0] grant_low;

    // For LSB high priority, we want the lowest index to win
    // For MSB high priority, we want the highest index to win

    // Let's use a simpler approach with a priority encoder

    // Priority encoder for LSB high priority (lowest index wins)
    function [PORTS-1:0] priority_encode_lsb;
        input [PORTS-1:0] req;
        integer i;
        begin
            priority_encode_lsb = {PORTS{1'b0}};
            for (i = 0; i < PORTS; i = i + 1) begin
                if (req[i] && priority_encode_lsb == {PORTS{1'b0}}) begin
                    priority_encode_lsb[i] = 1'b1;
                end
            end
        end
    endfunction

    // Priority encoder for MSB high priority (highest index wins)
    function [PORTS-1:0] priority_encode_msb;
        input [PORTS-1:0] req;
        integer i;
        begin
            priority_encode_msb = {PORTS{1'b0}};
            for (i = PORTS - 1; i >= 0; i = i - 1) begin
                if (req[i] && priority_encode_msb == {PORTS{1'b0}}) begin
                    priority_encode_msb[i] = 1'b1;
                end
            end
        endfunction
    endfunction

    // Determine the grant
    wire [PORTS-1:0] grant_high_priority;
    wire [PORTS-1:0] grant_low_priority;

    assign grant_high_priority = ARB_LSB_HIGH_PRIORITY ? priority_encode_lsb(high_priority_request) : priority_encode_msb(high_priority_request);
    assign grant_low_priority = ARB_LSB_HIGH_PRIORITY ? priority_encode_lsb(low_priority_request) : priority_encode_msb(low_priority_request);

    // If there's a high priority grant, use it; otherwise use low priority
    assign grant_comb = (grant_high_priority != {PORTS{1'b0}}) ? grant_high_priority : grant_low_priority;

    assign grant_valid_comb = (grant_comb != {PORTS{1'b0}});
    assign grant_encoded_comb = encode_one_hot(grant_comb);

    // Blocking logic
    reg [PORTS-1:0] blocked_grant;
    reg blocked_valid;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= {PORTS{1'b0}};
            grant_encoded_reg <= {NUM_BITS{1'b0}};
            grant_valid_reg <= 1'b0;
            last_grant <= {NUM_BITS{1'b0}};
            blocked_grant <= {PORTS{1'b0}};
            blocked_valid <= 1'b0;
        end else begin
            if (ARB_BLOCK) begin
                if (blocked_valid) begin
                    // Check if we should release the block
                    if (ARB_BLOCK_ACK) begin
                        // Release when acknowledge is received
                        if (blocked_grant & acknowledge) begin
                            blocked_valid <= 1'b0;
                            blocked_grant <= {PORTS{1'b0}};
                        end
                    end else begin
                        // Release when request drops
                        if (!(blocked_grant & request)) begin
                            blocked_valid <= 1'b0;
                            blocked_grant <= {PORTS{1'b0}};
                        end
                    end
                end else begin
                    // No block, take new grant
                    if (grant_valid_comb) begin
                        blocked_valid <= 1'b1;
                        blocked_grant <= grant_comb;
                    end
                end
            end else begin
                // No blocking, just use combinational grant
                grant_reg <= grant_comb;
                grant_encoded_reg <= grant_encoded_comb;
                grant_valid_reg <= grant_valid_comb;
            end

            // Update last_grant for round-robin
            if (ARB_TYPE_ROUND_ROBIN && grant_valid_comb) begin
                last_grant <= grant_encoded_comb;
            end
        end
    end

    // Output logic
    assign grant = ARB_BLOCK ? (blocked_valid ? blocked_grant : grant_comb) : grant_reg;
    assign grant_valid = ARB_BLOCK ? (blocked_valid ? 1'b1 : grant_valid_comb) : grant_valid_reg;
    assign grant_encoded = ARB_BLOCK ? (blocked_valid ? encode_one_hot(blocked_grant) : grant_encoded_comb) : grant_encoded_reg;

endmodule
