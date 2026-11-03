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

    wire [PORTS-1:0] next_request;
    reg [PORTS-1:0] current_grant;
    reg [PORTS-1:0] next_grant;
    reg grant_valid_reg;
    reg [$clog2(PORTS)-1:0] grant_encoded_reg;
    wire request_any;
    wire acknowledge_any;
    reg [$clog2(PORTS)-1:0] priority_index;
    reg [$clog2(PORTS)-1:0] next_priority_index;

    // Determine if there is any request
    assign request_any = |request;

    // Determine if there is any acknowledge
    assign acknowledge_any = |acknowledge;

    // Determine the next request based on the request signals and the current priority index
    always @(*) begin
        next_request = 0;
        if (ARB_LSB_HIGH_PRIORITY) begin
            for (int i = 0; i < PORTS; i = i + 1) begin
                if (request[(priority_index + i) % PORTS]) begin
                    next_request = 1 << ((priority_index + i) % PORTS);
                    break;
                end
            end
        end else begin
            for (int i = PORTS - 1; i >= 0; i = i - 1) begin
                if (request[(priority_index + i) % PORTS]) begin
                    next_request = 1 << ((priority_index + i) % PORTS);
                    break;
                end
            end
        end
    end

    // Update the next priority index for round-robin arbitration
    always @(*) begin
        next_priority_index = priority_index;
        if (ARB_TYPE_ROUND_ROBIN && request_any) begin
            for (int i = 1; i < PORTS; i = i + 1) begin
                if (request[(priority_index + i) % PORTS]) begin
                    next_priority_index = (priority_index + i) % PORTS;
                    break;
                end
            end
        end
    end

    // Determine the next grant
    always @(*) begin
        if (ARB_BLOCK && (current_grant & ~acknowledge)) begin
            next_grant = current_grant;
        end else begin
            next_grant = next_request;
        end
    end

    // Update the current grant on the next clock cycle if the grant is not blocked
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            priority_index <= 0;
            grant_valid_reg <= 0;
            grant_encoded_reg <= 0;
        end else begin
            if (!ARB_BLOCK || (current_grant & acknowledge)) begin
                current_grant <= next_grant;
                priority_index <= next_priority_index;
            end
            grant_valid_reg <= request_any && (next_grant != 0);
            grant_encoded_reg <= grant_encoded_func(next_grant);
        end
    end

    // Function to encode the current grant signal
    function [$clog2(PORTS)-1:0] grant_encoded_func;
        input [PORTS-1:0] grant;
        integer i;
        begin
            grant_encoded_func = 0;
            for (i = 0; i < PORTS; i = i + 1) begin
                if (grant[i]) begin
                    grant_encoded_func = i;
                    break;
                end
            end
        end
    endfunction

    // Output the grant, grant_valid, and grant_encoded based on the internal signals
    assign grant = current_grant;
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = grant_encoded_reg;

endmodule
