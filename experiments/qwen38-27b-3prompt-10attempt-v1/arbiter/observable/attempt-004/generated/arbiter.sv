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
    reg [ENC_WIDTH-1:0] last_grant_reg;

    // For blocking: track if we are currently blocked
    reg                 blocked_reg;

    // Function to find the highest priority request based on priority scheme
    // Returns the index of the selected port, or -1 (all ones) if no request
    function [ENC_WIDTH-1:0] find_priority;
        input [NUM_PORTS-1:0] req;
        input [ENC_WIDTH-1:0] start;
        integer i;
        integer idx;
        reg found;
        begin
            found = 0;
            idx = 0;
            if (ARB_TYPE_ROUND_ROBIN == 1) begin
                // Round-robin: start from (start + 1) mod NUM_PORTS
                for (i = 0; i < NUM_PORTS; i = i + 1) begin
                    idx = (start + i) % NUM_PORTS;
                    if (req[idx] && !found) begin
                        found = 1;
                    end
                end
            end else begin
                // Fixed priority
                if (ARB_LSB_HIGH_PRIORITY == 1) begin
                    // LSB has highest priority: find lowest index with request
                    for (i = 0; i < NUM_PORTS; i = i + 1) begin
                        if (req[i] && !found) begin
                            found = 1;
                            idx = i;
                        end
                    end
                end else begin
                    // MSB has highest priority: find highest index with request
                    for (i = NUM_PORTS-1; i >= 0; i = i - 1) begin
                        if (req[i] && !found) begin
                            found = 1;
                            idx = i;
                        end
                    end
                end
            end
            if (!found) begin
                find_priority = {ENC_WIDTH{1'b1}};
            end else begin
                find_priority = idx[ENC_WIDTH-1:0];
            end
        end
    endfunction

    // Function to convert one-hot to encoded
    function [ENC_WIDTH-1:0] onehot_to_encoded;
        input [NUM_PORTS-1:0] onehot;
        integer i;
        begin
            onehot_to_encoded = {ENC_WIDTH{1'b0}};
            for (i = 0; i < NUM_PORTS; i = i + 1) begin
                if (onehot[i]) begin
                    onehot_to_encoded = i[ENC_WIDTH-1:0];
                end
            end
        end
    endfunction

    wire [ENC_WIDTH-1:0] next_grant_encoded;
    wire [NUM_PORTS-1:0] next_grant_onehot;
    wire                 next_grant_valid;

    // Determine next grant
    wire [ENC_WIDTH-1:0] selected_port;
    wire                 has_request;

    assign has_request = |request;
    assign selected_port = find_priority(request, last_grant_reg);

    // Check if selected port is valid (not all ones)
    wire selected_valid = (selected_port != {ENC_WIDTH{1'b1}});

    // Generate one-hot from encoded
    reg [NUM_PORTS-1:0] onehot_from_encoded;
    integer j;
    always @* begin
        onehot_from_encoded = {NUM_PORTS{1'b0}};
        for (j = 0; j < NUM_PORTS; j = j + 1) begin
            if (j[ENC_WIDTH-1:0] == selected_port) begin
                onehot_from_encoded[j] = 1'b1;
            end
        end
    end

    assign next_grant_onehot = selected_valid ? onehot_from_encoded : {NUM_PORTS{1'b0}};
    assign next_grant_encoded = selected_port;
    assign next_grant_valid = selected_valid;

    // Blocking logic
    // If ARB_BLOCK is enabled, hold grant until acknowledge
    wire block_active = (ARB_BLOCK == 1);
    wire block_release = (ARB_BLOCK_ACK == 1) ? acknowledge[grant_encoded_reg] : 1'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= {NUM_PORTS{1'b0}};
            grant_valid_reg <= 1'b0;
            grant_encoded_reg <= {ENC_WIDTH{1'b0}};
            last_grant_reg <= {ENC_WIDTH{1'b0}};
            blocked_reg <= 1'b0;
        end else begin
            if (block_active && blocked_reg) begin
                // Hold current grant
                // Check for release
                if (block_release) begin
                    blocked_reg <= 1'b0;
                    // Update last grant for round-robin
                    if (ARB_TYPE_ROUND_ROBIN == 1) begin
                        last_grant_reg <= grant_encoded_reg;
                    end
                end
            end else begin
                // Not blocked or not in block mode
                if (next_grant_valid) begin
                    grant_reg <= next_grant_onehot;
                    grant_valid_reg <= 1'b1;
                    grant_encoded_reg <= next_grant_encoded;
                    if (ARB_TYPE_ROUND_ROBIN == 1) begin
                        last_grant_reg <= next_grant_encoded;
                    end
                    // Check if we should enter blocked state
                    if (block_active) begin
                        blocked_reg <= 1'b1;
                    end
                end else begin
                    grant_reg <= {NUM_PORTS{1'b0}};
                    grant_valid_reg <= 1'b0;
                    grant_encoded_reg <= {ENC_WIDTH{1'b0}};
                    if (block_active) begin
                        blocked_reg <= 1'b0;
                    end
                end
            end
        end
    end

    assign grant = grant_reg;
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = grant_encoded_reg;

endmodule
