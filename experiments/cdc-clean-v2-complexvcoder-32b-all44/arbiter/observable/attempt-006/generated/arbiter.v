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

    wire [$clog2(PORTS)-1:0] next_grant;
    reg [$clog2(PORTS)-1:0] current_grant;
    reg grant_block;
    reg [$clog2(PORTS)-1:0] round_robin_counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            grant_block <= 0;
            round_robin_counter <= 0;
        end else begin
            if (ARB_TYPE_ROUND_ROBIN == 1) begin
                if (|request) begin
                    round_robin_counter <= round_robin_counter + 1;
                end
            end

            if (ARB_BLOCK == 1 && acknowledge[current_grant] != ARB_BLOCK_ACK) begin
                grant_block <= 1;
            end else begin
                grant_block <= 0;
            end

            if (grant_block == 0) begin
                current_grant <= next_grant;
            end
        end
    end

    always @(*) begin
        if (ARB_LSB_HIGH_PRIORITY == 1) begin
            next_grant = PORTS - 1;
            for (integer i = PORTS - 1; i >= 0; i = i - 1) begin
                if (request[i]) begin
                    next_grant = i;
                    break;
                end
            end
        end else begin
            next_grant = 0;
            for (integer i = 0; i < PORTS; i = i + 1) begin
                if (request[i]) begin
                    next_grant = i;
                    break;
                end
            end
        end
    end

    assign grant_valid = (grant_block == 0) && (|request);
    assign grant_encoded = current_grant;

    assign grant = (1 << current_grant);

endmodule
