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

    wire [$clog2(PORTS)-1:0] next_grant;
    reg  [$clog2(PORTS)-1:0] current_grant;
    reg  [PORTS-1:0]         grant_reg;
    reg                      grant_valid_reg;
    reg  [$clog2(PORTS)-1:0] grant_encoded_reg;
    wire                     request_valid;
    wire [$clog2(PORTS)-1:0] request_encoded;
    wire                     block_condition;
    wire                     block_release;
    reg  [$clog2(PORTS)-1:0] round_robin_index;

    // Priority encoder to encode the request signal
    priority_encoder #(.WIDTH(PORTS)) u_priority_encoder (
        .request(request),
        .request_encoded(request_encoded),
        .request_valid(request_valid)
    );

    // Generate round_robin_index if ARB_TYPE_ROUND_ROBIN is set
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin : round_robin_gen
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    round_robin_index <= 0;
                end else if (grant_valid_reg) begin
                    round_robin_index <= (round_robin_index == PORTS-1) ? 0 : round_robin_index + 1;
                end
            end
        end else begin : fixed_priority_gen
            assign round_robin_index = 0;
        end
    endgenerate

    // Determine next_grant
    always @(*) begin
        if (ARB_TYPE_ROUND_ROBIN) begin
            next_grant = round_robin_index;
            for (int i = 0; i < PORTS; i = i + 1) begin
                if (request[(round_robin_index + i) % PORTS]) begin
                    next_grant = (round_robin_index + i) % PORTS;
                    break;
                end
            end
        end else begin
            next_grant = request_encoded;
        end
    end

    // Determine block_condition
    assign block_condition = ARB_BLOCK && ARB_BLOCK_ACK && grant_valid_reg && !acknowledge[grant_encoded_reg];

    // Determine block_release
    assign block_release = acknowledge[grant_encoded_reg];

    // Update grant registers on rising edge of clk
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg         <= 0;
            grant_valid_reg   <= 0;
            grant_encoded_reg <= 0;
            current_grant     <= 0;
        end else begin
            if (!block_condition) begin
                if (request_valid) begin
                    grant_reg         <= 1 << next_grant;
                    grant_valid_reg   <= 1;
                    grant_encoded_reg <= next_grant;
                    current_grant     <= next_grant;
                end else begin
                    grant_reg         <= 0;
                    grant_valid_reg   <= 0;
                    grant_encoded_reg <= 0;
                end
            end else if (block_release) begin
                grant_reg         <= 1 << current_grant;
                grant_valid_reg   <= 1;
                grant_encoded_reg <= current_grant;
            end
        end
    end

    // Drive outputs
    assign grant        = grant_reg;
    assign grant_valid  = grant_valid_reg;
    assign grant_encoded = grant_encoded_reg;

endmodule

// Priority encoder module
module priority_encoder #(
    parameter WIDTH = 4
)
(
    input  wire [WIDTH-1:0] request,
    output wire [WIDTH-1:0] request_encoded,
    output wire             request_valid
);

    reg [WIDTH-1:0] encoded;
    reg valid;

    always @(*) begin
        encoded = 0;
        valid = 0;
        for (int i = 0; i < WIDTH; i = i + 1) begin
            if (request[i]) begin
                encoded = i;
                valid = 1;
                break;
            end
        end
    end

    assign request_encoded = encoded;
    assign request_valid   = valid;

endmodule
