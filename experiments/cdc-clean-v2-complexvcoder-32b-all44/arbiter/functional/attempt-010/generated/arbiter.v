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
    reg next_grant_valid;
    reg [$clog2(PORTS)-1:0] next_grant_encoded;
    reg request_pending;
    reg [$clog2(PORTS)-1:0] round_robin_counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            round_robin_counter <= 0;
            grant_valid <= 0;
        end else begin
            if (!ARB_BLOCK || !grant_valid || !acknowledge[next_grant_encoded] || !request[next_grant_encoded]) begin
                current_grant <= next_grant;
                grant_valid <= next_grant_valid;
            end
        end
    end

    always @(*) begin
        request_pending = |request;
        next_grant = 0;
        next_grant_valid = 0;
        next_grant_encoded = 0;

        if (request_pending) begin
            if (ARB_TYPE_ROUND_ROBIN) begin
                integer i;
                integer start_index;
                start_index = round_robin_counter;
                for (i = 0; i < PORTS; i = i + 1) begin
                    integer index;
                    index = (start_index + i) % PORTS;
                    if (request[index]) begin
                        next_grant[index] = 1;
                        next_grant_valid = 1;
                        next_grant_encoded = index;
                        break;
                    end
                end
            end else begin
                integer i;
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        next_grant[i] = 1;
                        next_grant_valid = 1;
                        next_grant_encoded = i;
                        break;
                    end
                end
            end

            if (ARB_LSB_HIGH_PRIORITY) begin
                integer i;
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        next_grant = 0;
                        next_grant[i] = 1;
                        next_grant_valid = 1;
                        next_grant_encoded = i;
                        break;
                    end
                end
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round_robin_counter <= 0;
        end else if (next_grant_valid) begin
            round_robin_counter <= next_grant_encoded + 1;
        end
    end

    assign grant = current_grant;
    assign grant_encoded = next_grant_encoded;

endmodule
