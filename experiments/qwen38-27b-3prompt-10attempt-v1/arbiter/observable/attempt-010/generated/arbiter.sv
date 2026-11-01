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
    reg                 grant_valid_reg;
    reg [ENC_WIDTH-1:0] grant_encoded_reg;

    // For round-robin: track the last granted port
    reg [ENC_WIDTH-1:0] last_grant;

    // For blocking: track if a grant is currently held
    reg                 block_hold;

    // Function to find the first set bit (lowest index) in a vector
    // Returns the index of the lowest set bit, or NUM_PORTS if none
    function [ENC_WIDTH-1:0] find_first_set;
        input [NUM_PORTS-1:0] vec;
        integer i;
        begin
            find_first_set = NUM_PORTS;
            for (i = 0; i < NUM_PORTS; i = i + 1) begin
                if (vec[i] && find_first_set == NUM_PORTS) begin
                    find_first_set = i;
                end
            end
        end
    endfunction

    // Function to find the first set bit starting from a given index (wrapping around)
    function [ENC_WIDTH-1:0] find_first_set_wrapped;
        input [NUM_PORTS-1:0] vec;
        input [ENC_WIDTH-1:0] start;
        integer i;
        integer idx;
        begin
            find_first_set_wrapped = NUM_PORTS;
            for (i = 0; i < NUM_PORTS; i = i + 1) begin
                idx = (start + i) % NUM_PORTS;
                if (vec[idx] && find_first_set_wrapped == NUM_PORTS) begin
                    find_first_set_wrapped = idx;
                end
            end
        end
    endfunction

    // Determine the next grant based on arbitration type
    reg [NUM_PORTS-1:0] next_grant;
    reg                 next_grant_valid;
    reg [ENC_WIDTH-1:0] next_grant_encoded;

    always @(*) begin
        next_grant = {NUM_PORTS{1'b0}};
        next_grant_valid = 1'b0;
        next_grant_encoded = {ENC_WIDTH{1'b0}};

        if (request != {NUM_PORTS{1'b0}}) begin
            if (ARB_TYPE_ROUND_ROBIN) begin
                // Round-robin: start from last_grant + 1
                next_grant_encoded = find_first_set_wrapped(request, last_grant + 1'b1);
                if (next_grant_encoded < NUM_PORTS) begin
                    next_grant_valid = 1'b1;
                    next_grant = {NUM_PORTS{1'b0}};
                    next_grant[next_grant_encoded] = 1'b1;
                end
            end else begin
                // Fixed priority
                if (ARB_LSB_HIGH_PRIORITY) begin
                    // LSB has highest priority: find lowest set bit
                    next_grant_encoded = find_first_set(request);
                    if (next_grant_encoded < NUM_PORTS) begin
                        next_grant_valid = 1'b1;
                        next_grant = {NUM_PORTS{1'b0}};
                        next_grant[next_grant_encoded] = 1'b1;
                    end
                end else begin
                    // MSB has highest priority: find highest set bit
                    next_grant_encoded = NUM_PORTS - 1;
                    for (next_grant_encoded = NUM_PORTS - 1; next_grant_encoded >= 0; next_grant_encoded = next_grant_encoded - 1) begin
                        if (request[next_grant_encoded]) begin
                            next_grant_valid = 1'b1;
                            next_grant = {NUM_PORTS{1'b0}};
                            next_grant[next_grant_encoded] = 1'b1;
                            break;
                        end
                    end
                end
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= {NUM_PORTS{1'b0}};
            grant_valid_reg <= 1'b0;
            grant_encoded_reg <= {ENC_WIDTH{1'b0}};
            last_grant <= {ENC_WIDTH{1'b0}};
            block_hold <= 1'b0;
        end else begin
            if (ARB_BLOCK) begin
                // Blocking mode
                if (block_hold) begin
                    // Check if release event occurred
                    if (ARB_BLOCK_ACK) begin
                        // Release when acknowledge matches current grant
                        if (acknowledge == grant_reg) begin
                            block_hold <= 1'b0;
                        end
                    end else begin
                        // No specific release event defined, hold indefinitely
                        // This case is ambiguous; we'll assume no release
                    end
                end else begin
                    // Not holding, check for new grant
                    if (next_grant_valid) begin
                        grant_reg <= next_grant;
                        grant_valid_reg <= 1'b1;
                        grant_encoded_reg <= next_grant_encoded;
                        last_grant <= next_grant_encoded;
                        block_hold <= 1'b1;
                    end
                end
            end else begin
                // Non-blocking mode
                if (next_grant_valid) begin
                    grant_reg <= next_grant;
                    grant_valid_reg <= 1'b1;
                    grant_encoded_reg <= next_grant_encoded;
                    last_grant <= next_grant_encoded;
                end else begin
                    grant_reg <= {NUM_PORTS{1'b0}};
                    grant_valid_reg <= 1'b0;
                    grant_encoded_reg <= {ENC_WIDTH{1'b0}};
                end
            end
        end
    end

    assign grant = grant_reg;
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = grant_encoded_reg;

endmodule
