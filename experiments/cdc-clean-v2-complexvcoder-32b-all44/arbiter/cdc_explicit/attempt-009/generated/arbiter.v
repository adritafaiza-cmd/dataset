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

    wire [$clog2(PORTS)-1:0] next_grant_encoded;
    reg  [PORTS-1:0]         current_grant;
    wire [PORTS-1:0]         next_grant;
    wire [PORTS-1:0]         active_request;
    reg                      grant_valid_reg;
    reg [$clog2(PORTS)-1:0]  grant_encoded_reg;
    reg  [$clog2(PORTS)-1:0] round_robin_counter;
    wire [$clog2(PORTS)-1:0] round_robin_counter_next;

    // Determine active request
    assign active_request = request;

    // Generate next grant encoded based on request
    genvar i;
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin : round_robin_logic
            always @(*) begin
                round_robin_counter_next = round_robin_counter;
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (active_request[(round_robin_counter + i) % PORTS]) begin
                        round_robin_counter_next = (round_robin_counter + i) % PORTS;
                        break;
                    end
                end
            end
            assign next_grant_encoded = round_robin_counter_next;
        end else begin : fixed_priority_logic
            assign next_grant_encoded = ARB_LSB_HIGH_PRIORITY ? 
                (active_request[0] ? 0 :
                 active_request[1] ? 1 :
                 active_request[2] ? 2 :
                 active_request[3] ? 3 : 0) :
                (active_request[3] ? 3 :
                 active_request[2] ? 2 :
                 active_request[1] ? 1 :
                 active_request[0] ? 0 : 0);
        end
    endgenerate

    // Generate one-hot encoded next grant
    assign next_grant = (1 << next_grant_encoded);

    // Grant logic with blocking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            grant_valid_reg <= 0;
            grant_encoded_reg <= 0;
            round_robin_counter <= 0;
        end else begin
            if (!grant_valid_reg || (!ARB_BLOCK_ACK && acknowledge[grant_encoded_reg]) || !request[grant_encoded_reg]) begin
                current_grant <= next_grant;
                grant_valid_reg <= |next_grant;
                grant_encoded_reg <= next_grant_encoded;
                if (ARB_TYPE_ROUND_ROBIN && grant_valid_reg) begin
                    round_robin_counter <= round_robin_counter_next;
                end
            end else if (ARB_BLOCK && ARB_BLOCK_ACK && acknowledge[grant_encoded_reg]) begin
                current_grant <= 0;
                grant_valid_reg <= 0;
            end
        end
    end

    // Outputs
    assign grant = current_grant;
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = grant_encoded_reg;

endmodule
