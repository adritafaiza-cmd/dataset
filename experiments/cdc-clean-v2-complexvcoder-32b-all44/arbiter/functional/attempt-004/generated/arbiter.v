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

    reg [PORTS-1:0] next_grant;
    reg [PORTS-1:0] current_grant;
    reg [PORTS-1:0] active_request;
    reg [PORTS-1:0] request_priority;
    reg             valid_grant;
    reg [$clog2(PORTS)-1:0] encoded_grant;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            valid_grant <= 0;
        end else begin
            if (valid_grant) begin
                if (ARB_BLOCK) begin
                    if (ARB_BLOCK_ACK ? acknowledge & current_grant : ~request & current_grant) begin
                        current_grant <= next_grant;
                        valid_grant <= |next_grant;
                    end
                end else begin
                    current_grant <= next_grant;
                    valid_grant <= |next_grant;
                end
            end else begin
                current_grant <= next_grant;
                valid_grant <= |next_grant;
            end
        end
    end

    always @(*) begin
        if (ARB_BLOCK && ARB_BLOCK_ACK) begin
            active_request = request & ~acknowledge;
        end else begin
            active_request = request;
        end
    end

    always @(*) begin
        request_priority = active_request;
        if (ARB_TYPE_ROUND_ROBIN) begin
            if (valid_grant) begin
                request_priority = {current_grant[PORTS-2:0], current_grant[PORTS-1]};
            end
        end
        if (ARB_LSB_HIGH_PRIORITY) begin
            next_grant = (1 << (PORTS - 1 - $lsb(request_priority)));
        end else begin
            next_grant = (1 << (PORTS - 1 - $highest(request_priority)));
        end
    end

    always @(*) begin
        if (valid_grant) begin
            encoded_grant = $clog2(current_grant);
        end else begin
            encoded_grant = 0;
        end
    end

    assign grant = current_grant;
    assign grant_valid = valid_grant;
    assign grant_encoded = encoded_grant;

endmodule
