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
    reg [$clog2(PORTS)-1:0] next_grant;
    reg [$clog2(PORTS)-1:0] grant_reg;
    reg                         grant_valid_reg;
    reg [PORTS-1:0]             acknowledge_reg;
    reg [PORTS-1:0]             request_reg;
    reg [$clog2(PORTS)-1:0]     round_robin_counter;
    reg [PORTS-1:0]             round_robin_mask;
    reg [$clog2(PORTS)-1:0]     priority_encoded;

    // Register request and acknowledge signals
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            request_reg <= {PORTS{1'b0}};
            acknowledge_reg <= {PORTS{1'b0}};
        end else begin
            request_reg <= request;
            acknowledge_reg <= acknowledge;
        end
    end

    // Generate round_robin_mask based on round_robin_counter
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    round_robin_counter <= {$clog2(PORTS){1'b0}};
                end else begin
                    if (grant_valid_reg && (grant_valid_reg == ARB_BLOCK_ACK || !request_reg[next_grant])) begin
                        round_robin_counter <= round_robin_counter + 1;
                    end
                end
            end

            assign round_robin_mask = (PORTS)'(1) << round_robin_counter;
        end else begin
            assign round_robin_mask = {PORTS{1'b1}};
        end
    endgenerate

    // Encode the request signal to priority_encoded based on priority selection
    always @(*) begin
        priority_encoded = {$clog2(PORTS){1'b0}};
        for (integer i = 0; i < PORTS; i = i + 1) begin
            if (request_reg[i] && round_robin_mask[i]) begin
                priority_encoded = i;
            end
        end

        // Handle LSB high priority in case of ties
        if (ARB_LSB_HIGH_PRIORITY) begin
            for (integer i = 0; i < PORTS; i = i + 1) begin
                if (request_reg[i] && round_robin_mask[i]) begin
                    priority_encoded = i;
                end
            end
        end else begin
            for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                if (request_reg[i] && round_robin_mask[i]) begin
                    priority_encoded = i;
                end
            end
        end
    end

    // Update grant_reg and grant_valid_reg based on priority_encoded and request_reg
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= {$clog2(PORTS){1'b0}};
            grant_valid_reg <= 1'b0;
        end else begin
            if (!ARB_BLOCK || (grant_valid_reg && acknowledge_reg[next_grant])) begin
                if (|request_reg) begin
                    grant_reg <= priority_encoded;
                    grant_valid_reg <= 1'b1;
                end else begin
                    grant_valid_reg <= 1'b0;
                end
            end
        end
    end

    // Drive grant, grant_valid, and grant_encoded outputs
    assign grant = (1 << grant_reg);
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = grant_reg;

endmodule
