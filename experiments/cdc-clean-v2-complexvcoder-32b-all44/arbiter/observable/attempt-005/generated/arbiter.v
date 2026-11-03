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
    wire [PORTS-1:0] next_grant;
    wire request_valid;
    reg [$clog2(PORTS)-1:0] grant_count;
    reg blocked;
    reg [$clog2(PORTS)-1:0] selected_port;

    // Register to hold the current grant
    reg [PORTS-1:0] current_grant;
    reg current_grant_valid;

    // Priority encoder for fixed priority
    function integer priority_encode;
        input [PORTS-1:0] req;
        integer i;
        begin
            for (i = 0; i < PORTS; i = i + 1) begin
                if (req[i]) begin
                    priority_encode = i;
                    return;
                end
            end
            priority_encode = 0; // Default case, should not happen
        end
    endfunction

    // Round-robin selection logic
    always @(*) begin
        if (ARB_TYPE_ROUND_ROBIN) begin
            integer i;
            for (i = 0; i < PORTS; i = i + 1) begin
                integer index;
                if (ARB_LSB_HIGH_PRIORITY) begin
                    index = (grant_count + i) % PORTS;
                end else begin
                    index = (grant_count - i) % PORTS;
                end
                if (request[index]) begin
                    selected_port = index;
                    next_grant = 1 << index;
                    next_request = request & ~(1 << index);
                    request_valid = 1;
                    break;
                end
            end
            if (i == PORTS) begin
                selected_port = 0;
                next_grant = 0;
                next_request = request;
                request_valid = 0;
            end
        end else begin
            if (ARB_LSB_HIGH_PRIORITY) begin
                selected_port = PORTS - 1 - priority_encode(request);
            end else begin
                selected_port = priority_encode(request);
            end
            next_grant = 1 << selected_port;
            next_request = request & ~(1 << selected_port);
            request_valid = (request[selected_port] != 0);
        end
    end

    // Grant logic with blocking and release handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            current_grant_valid <= 0;
            grant_count <= 0;
            blocked <= 0;
        end else begin
            if (request_valid && (!blocked || (blocked && acknowledge[selected_port]))) begin
                current_grant <= next_grant;
                current_grant_valid <= request_valid;
                if (ARB_TYPE_ROUND_ROBIN && request_valid) begin
                    grant_count <= grant_count + 1;
                end
            end else if (blocked && acknowledge[selected_port]) begin
                blocked <= 0;
            end else if (ARB_BLOCK && request_valid) begin
                blocked <= 1;
            end
        end
    end

    assign grant = current_grant;
    assign grant_valid = current_grant_valid;
    assign grant_encoded = selected_port;

endmodule
