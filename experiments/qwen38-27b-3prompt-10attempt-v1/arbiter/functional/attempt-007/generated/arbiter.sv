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

    localparam NUM_PORTS = PORTS;
    localparam ENC_WIDTH = $clog2(PORTS);

    reg [NUM_PORTS-1:0] grant_reg;
    reg [ENC_WIDTH-1:0] grant_encoded_reg;
    reg                 grant_valid_reg;

    // For round-robin, we need to track the last granted port
    reg [ENC_WIDTH-1:0] last_grant_reg;

    // Internal signals for arbitration
    wire [NUM_PORTS-1:0] arb_request;
    wire [NUM_PORTS-1:0] arb_grant;
    wire                 arb_valid;
    wire [ENC_WIDTH-1:0] arb_encoded;

    // Determine if we should hold the grant (blocking mode)
    wire hold_grant;
    
    generate
        if (ARB_BLOCK) begin
            if (ARB_BLOCK_ACK) begin
                // Hold until acknowledge
                assign hold_grant = grant_valid_reg && !(&acknowledge | ~grant_reg);
            end else begin
                // Hold until request drops
                assign hold_grant = grant_valid_reg && request[grant_encoded_reg];
            end
        end else begin
            assign hold_grant = 1'b0;
        end
    endgenerate

    // When holding, use the stored grant; otherwise, perform new arbitration
    wire [NUM_PORTS-1:0] effective_request;
    wire [NUM_PORTS-1:0] effective_grant;
    wire                 effective_valid;
    wire [ENC_WIDTH-1:0] effective_encoded;

    assign effective_request = hold_grant ? grant_reg : request;
    
    // Perform arbitration on effective_request
    // We need a function to find the highest priority requestor

    // For fixed priority:
    // If ARB_LSB_HIGH_PRIORITY, LSB has highest priority
    // Otherwise, MSB has highest priority

    // For round-robin:
    // Rotate the request vector so that the port after last_grant has highest priority

    // Let's implement the arbitration logic

    // First, handle the case where we're holding
    // If holding, the grant is the stored one
    // If not holding, we do fresh arbitration

    // Let's create a combinational arbiter that takes request and returns grant

    // For simplicity, let's implement both fixed and round-robin

    // Fixed priority arbiter:
    // If ARB_LSB_HIGH_PRIORITY: find lowest set bit
    // Else: find highest set bit

    // Round-robin:
    // Rotate request so that position after last_grant is at LSB (if LSB high priority)
    // or at MSB (if MSB high priority)

    // Let's implement a helper to find the index of the first set bit (LSB) or last set bit (MSB)

    // Function to find lowest set bit index
    function [ENC_WIDTH-1:0] find_lsb;
        input [NUM_PORTS-1:0] vec;
        integer i;
        begin
            find_lsb = 0;
            for (i = 0; i < NUM_PORTS; i = i + 1) begin
                if (vec[i]) begin
                    find_lsb = i;
                    disable find_lsb;
                end
            end
        end
    endfunction

    // Function to find highest set bit index
    function [ENC_WIDTH-1:0] find_msb;
        input [NUM_PORTS-1:0] vec;
        integer i;
        begin
            find_msb = 0;
            for (i = NUM_PORTS - 1; i >= 0; i = i - 1) begin
                if (vec[i]) begin
                    find_msb = i;
                    disable find_msb;
                end
            end
        end
    endfunction

    // For round-robin, we need to rotate the request vector
    // The port after last_grant should have highest priority
    // If ARB_LSB_HIGH_PRIORITY, we want the port after last_grant to be at LSB position
    // If not, we want it at MSB position

    // Let's compute the rotated request
    wire [NUM_PORTS-1:0] rotated_request;
    wire [ENC_WIDTH-1:0] rotate_amount;

    // The next port after last_grant
    wire [ENC_WIDTH-1:0] next_port;
    assign next_port = (last_grant_reg == NUM_PORTS - 1) ? 0 : last_grant_reg + 1;

    // For LSB high priority round-robin:
    // We want to rotate so that next_port is at position 0
    // rotated_request[i] = request[(i + next_port) % NUM_PORTS]
    // Then find LSB of rotated_request, and the actual port is (lsb_index + next_port) % NUM_PORTS

    // For MSB high priority round-robin:
    // We want to rotate so that next_port is at position NUM_PORTS-1
    // rotated_request[i] = request[(i + next_port) % NUM_PORTS]
    // Then find MSB of rotated_request, and the actual port is (msb_index + next_port) % NUM_PORTS

    // Let's implement the rotation
    genvar gi;
    generate
        for (gi = 0; gi < NUM_PORTS; gi = gi + 1) begin : rotate_gen
            assign rotated_request[gi] = request[(gi + next_port) % NUM_PORTS];
        end
    endgenerate

    // Now perform arbitration based on type
    wire [NUM_PORTS-1:0] comb_grant;
    wire                 comb_valid;
    wire [ENC_WIDTH-1:0] comb_encoded;

    generate
        if (ARB_TYPE_ROUND_ROBIN) begin
            if (ARB_LSB_HIGH_PRIORITY) begin
                // Find LSB of rotated_request
                wire [ENC_WIDTH-1:0] lsb_idx;
                assign lsb_idx = find_lsb(rotated_request);
                assign comb_valid = |rotated_request;
                assign comb_encoded = (lsb_idx + next_port) % NUM_PORTS;
                assign comb_grant = (1 << comb_encoded);
            end else begin
                // Find MSB of rotated_request
                wire [ENC_WIDTH-1:0] msb_idx;
                assign msb_idx = find_msb(rotated_request);
                assign comb_valid = |rotated_request;
                assign comb_encoded = (msb_idx + next_port) % NUM_PORTS;
                assign comb_grant = (1 << comb_encoded);
            end
        end else begin
            if (ARB_LSB_HIGH_PRIORITY) begin
                assign comb_valid = |request;
                assign comb_encoded = find_lsb(request);
                assign comb_grant = (1 << comb_encoded);
            end else begin
                assign comb_valid = |request;
                assign comb_encoded = find_msb(request);
                assign comb_grant = (1 << comb_encoded);
            end
        end
    endgenerate

    // Now decide between holding and new grant
    assign effective_grant = hold_grant ? grant_reg : comb_grant;
    assign effective_valid = hold_grant ? grant_valid_reg : comb_valid;
    assign effective_encoded = hold_grant ? grant_encoded_reg : comb_encoded;

    // Register the output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= {NUM_PORTS{1'b0}};
            grant_encoded_reg <= {ENC_WIDTH{1'b0}};
            grant_valid_reg <= 1'b0;
            last_grant_reg <= {ENC_WIDTH{1'b0}};
        end else begin
            grant_reg <= effective_grant;
            grant_encoded_reg <= effective_encoded;
            grant_valid_reg <= effective_valid;
            
            // Update last_grant for round-robin when a new grant is issued
            if (ARB_TYPE_ROUND_ROBIN && !hold_grant && comb_valid) begin
                last_grant_reg <= comb_encoded;
            end
        end
    end

    assign grant = grant_reg;
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = grant_encoded_reg;

endmodule
