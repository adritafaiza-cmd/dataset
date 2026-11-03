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

    reg [PORTS-1:0]         next_grant;
    reg [PORTS-1:0]         current_grant;
    reg [$clog2(PORTS)-1:0] round_robin_counter;
    wire [PORTS-1:0]        request_mask;
    reg [$clog2(PORTS)-1:0] grant_encoded_internal;

    // Generate request_mask based on ARB_BLOCK
    assign request_mask = (ARB_BLOCK == 0) ? request : (request & ~acknowledge);

    // Determine next_grant based on request_mask and priority
    always @(*) begin
        next_grant = '0;
        if (ARB_LSB_HIGH_PRIORITY == 0) begin
            for (integer i = PORTS-1; i >= 0; i = i - 1) begin
                if (request_mask[i] == 1'b1) begin
                    next_grant[i] = 1'b1;
                    break;
                end
            end
        end else begin
            for (integer i = 0; i < PORTS; i = i + 1) begin
                if (request_mask[i] == 1'b1) begin
                    next_grant[i] = 1'b1;
                    break;
                end
            end
        end
    end

    // Update current_grant and round_robin_counter on rising edge of clk
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= '0;
            round_robin_counter <= '0;
        end else begin
            if (grant_valid) begin
                if (ARB_TYPE_ROUND_ROBIN == 1) begin
                    round_robin_counter <= round_robin_counter + 1;
                end
                current_grant <= next_grant;
            end
            if (ARB_BLOCK == 1) begin
                if ((ARB_BLOCK_ACK == 1 && acknowledge & current_grant) || (request & current_grant) == '0) begin
                    current_grant <= '0;
                end
            end
        end
    end

    // Assign grant and grant_valid
    assign grant = current_grant;
    assign grant_valid = (|request_mask) ? 1'b1 : 1'b0;

    // Encode the granted port index into grant_encoded_internal
    always @(*) begin
        grant_encoded_internal = '0;
        for (integer i = 0; i < PORTS; i = i + 1) begin
            if (grant[i] == 1'b1) begin
                grant_encoded_internal = i;
            end
        end
    end

    // Assign grant_encoded
    assign grant_encoded = grant_encoded_internal;

endmodule
