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
    reg [PORTS-1:0]                 next_grant;
    reg [PORTS-1:0]                 current_grant;
    reg [$clog2(PORTS)-1:0]         grant_index;
    wire [PORTS-1:0]                valid_request;
    wire                            request_valid;
    wire                            acknowledge_received;
    reg                             next_grant_valid;
    reg                             current_grant_valid;

    // Priority logic
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin : round_robin_arbiter
            reg [$clog2(PORTS)-1:0] round_robin_counter;

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    round_robin_counter <= 0;
                    next_grant_valid <= 0;
                    next_grant <= 0;
                end else begin
                    if (current_grant_valid && (ARB_BLOCK && acknowledge_received)) begin
                        next_grant_valid <= 0;
                        next_grant <= 0;
                    end else begin
                        wire [PORTS-1:0] shifted_request = request_valid ? (request << round_robin_counter) | (request >> (PORTS - round_robin_counter)) : 0;
                        integer i;
                        integer highest_priority;
                        highest_priority = ARB_LSB_HIGH_PRIORITY ? 0 : PORTS-1;
                        for (i = 0; i < PORTS; i = i + 1) begin
                            if (ARB_LSB_HIGH_PRIORITY) begin
                                if (shifted_request[i]) begin
                                    highest_priority = i;
                                    break;
                                end
                            end else begin
                                if (shifted_request[i]) begin
                                    highest_priority = i;
                                end
                            end
                        end
                        next_grant_valid <= request_valid;
                        next_grant <= (1 << highest_priority);
                        if (request_valid && !current_grant_valid) begin
                            round_robin_counter <= round_robin_counter + 1;
                        end
                    end
                end
            end
        end else begin : fixed_priority_arbiter
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    next_grant_valid <= 0;
                    next_grant <= 0;
                end else begin
                    if (current_grant_valid && (ARB_BLOCK && acknowledge_received)) begin
                        next_grant_valid <= 0;
                        next_grant <= 0;
                    end else begin
                        integer i;
                        integer highest_priority;
                        highest_priority = ARB_LSB_HIGH_PRIORITY ? 0 : PORTS-1;
                        for (i = 0; i < PORTS; i = i + 1) begin
                            if (ARB_LSB_HIGH_PRIORITY) begin
                                if (request[i]) begin
                                    highest_priority = i;
                                    break;
                                end
                            end else begin
                                if (request[i]) begin
                                    highest_priority = i;
                                end
                            end
                        end
                        next_grant_valid <= request_valid;
                        next_grant <= (1 << highest_priority);
                    end
                end
            end
        end
    endgenerate

    // Valid request logic
    assign valid_request = request;
    assign request_valid = |valid_request;
    assign acknowledge_received = &((~acknowledge) | (~current_grant));

    // Register outputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            current_grant_valid <= 0;
        end else begin
            current_grant <= next_grant;
            current_grant_valid <= next_grant_valid;
        end
    end

    // Assign outputs
    assign grant = current_grant;
    assign grant_valid = current_grant_valid;
    assign grant_encoded = grant_index;

    // Encode the grant index
    always @(*) begin
        integer i;
        grant_index = 0;
        for (i = 0; i < PORTS; i = i + 1) begin
            if (grant[i]) begin
                grant_index = i;
            end
        end
    end

endmodule
