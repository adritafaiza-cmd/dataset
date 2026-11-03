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
    reg  [PORTS-1:0]                next_grant;
    reg  [PORTS-1:0]                current_grant;
    wire [PORTS-1:0]                priority;
    wire [PORTS-1:0]                grant_one_hot;
    reg  [PORTS-1:0]                grant_one_hot_next;
    reg                               grant_valid_next;
    reg  [$clog2(PORTS)-1:0]        grant_encoded_next;
    wire                            request_valid;
    wire                            acknowledge_valid;
    reg  [$clog2(PORTS)-1:0]        round_robin_counter;

    // Priority generation
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin : round_robin
            always @(*) begin
                priority = 0;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    priority[(round_robin_counter + i) % PORTS] = request[(round_robin_counter + i) % PORTS];
                end
            end
        end else begin : fixed_priority
            assign priority = request;
        end
    endgenerate

    // Tie-breaking
    generate
        if (ARB_LSB_HIGH_PRIORITY) begin : lsb_high_priority
            always @(*) begin
                grant_one_hot_next = 0;
                for (integer i = 0; i < PORTS; i = i + 1) begin
                    if (priority[i]) begin
                        grant_one_hot_next = (1 << i);
                        break;
                    end
                end
            end
        end else begin : msb_high_priority
            always @(*) begin
                grant_one_hot_next = 0;
                for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                    if (priority[i]) begin
                        grant_one_hot_next = (1 << i);
                        break;
                    end
                end
            end
        end
    endgenerate

    // Grant logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            grant_valid <= 0;
            grant_encoded <= 0;
            round_robin_counter <= 0;
        end else begin
            if (ARB_BLOCK) begin
                if (grant_valid && ((ARB_BLOCK_ACK && acknowledge_valid) || !request_valid)) begin
                    grant_one_hot_next = current_grant;
                    grant_valid_next = 1;
                    grant_encoded_next = grant_encoded;
                end else if (!grant_valid && request_valid) begin
                    grant_one_hot_next = grant_one_hot;
                    grant_valid_next = 1;
                    grant_encoded_next = grant_encoded;
                end else begin
                    grant_one_hot_next = 0;
                    grant_valid_next = 0;
                    grant_encoded_next = 0;
                end
            end else begin
                if (request_valid) begin
                    grant_one_hot_next = grant_one_hot;
                    grant_valid_next = 1;
                    grant_encoded_next = grant_encoded;
                end else begin
                    grant_one_hot_next = 0;
                    grant_valid_next = 0;
                    grant_encoded_next = 0;
                end
            end

            current_grant <= grant_one_hot_next;
            grant_valid <= grant_valid_next;
            grant_encoded <= grant_encoded_next;

            if (grant_valid_next && grant_one_hot_next != 0 && !ARB_BLOCK) begin
                round_robin_counter <= round_robin_counter + 1;
            end
        end
    end

    // Output assignments
    assign grant = current_grant;
    assign grant_one_hot = grant_one_hot_next;
    assign request_valid = |request;
    assign acknowledge_valid = |acknowledge;

endmodule
