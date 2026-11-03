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

    reg [PORTS-1:0] current_grant;
    reg [PORTS-1:0] next_grant;
    reg [PORTS-1:0] current_request;
    reg [PORTS-1:0] current_acknowledge;
    reg             valid_request;
    reg [$clog2(PORTS)-1:0] grant_index;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= {PORTS{1'b0}};
            grant_valid <= 1'b0;
        end else begin
            current_request <= request;
            current_acknowledge <= acknowledge;

            // Determine if there is any valid request
            valid_request <= |current_request;

            // Determine next grant based on priority mechanism
            if (ARB_TYPE_ROUND_ROBIN) begin
                // Rotate priority
                if (valid_request) begin
                    integer i;
                    for (i = 0; i < PORTS; i = i + 1) begin
                        if (current_request[(grant_index + i) % PORTS]) begin
                            next_grant <= (1 << ((grant_index + i) % PORTS));
                            break;
                        end
                    end
                end else begin
                    next_grant <= {PORTS{1'b0}};
                end
            end else begin
                // Fixed priority
                integer i;
                for (i = PORTS-1; i >= 0; i = i - 1) begin
                    if (current_request[i]) begin
                        next_grant <= (1 << i);
                        break;
                    end
                end
                if (!valid_request) begin
                    next_grant <= {PORTS{1'b0}};
                end
            end

            // Handle ties using LSB priority if needed
            if (ARB_LSB_HIGH_PRIORITY && valid_request) begin
                integer i;
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (current_request[i]) begin
                        next_grant <= (1 << i);
                        break;
                    end
                end
            end

            // Determine if the current grant is blocked
            reg is_blocked;
            if (ARB_BLOCK) begin
                if (ARB_BLOCK_ACK) begin
                    is_blocked <= (current_grant & ~acknowledge) != {PORTS{1'b0}};
                end else begin
                    is_blocked <= (current_grant & ~request) != {PORTS{1'b0}};
                end
            end else begin
                is_blocked <= 1'b0;
            end

            // Update current grant if not blocked
            if (!is_blocked) begin
                current_grant <= next_grant;
            end

            // Update grant valid
            grant_valid <= valid_request & !is_blocked;

            // Update grant index for round robin
            if (valid_request && !is_blocked && next_grant != current_grant) begin
                integer i;
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (next_grant[i]) begin
                        grant_index <= i;
                    end
                end
            end
        end
    end

    // Assign outputs
    assign grant = current_grant;
    assign grant_encoded = grant_index;

endmodule
