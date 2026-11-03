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

    wire [$clog2(PORTS)-1:0] next_grant_encoded;
    wire [PORTS-1:0] next_grant;
    wire valid_grant;
    reg [PORTS-1:0] current_grant;
    reg [$clog2(PORTS)-1:0] current_grant_encoded;
    reg [PORTS-1:0] pending_request;
    reg [PORTS-1:0] priority;
    reg [$clog2(PORTS)-1:0] round_robin_index;

    // Priority encoder
    genvar i;
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    round_robin_index <= 0;
                end else begin
                    if (valid_grant && (ARB_BLOCK ? ~acknowledge[current_grant_encoded] : 1)) begin
                        for (i = 0; i < PORTS; i = i + 1) begin
                            if (pending_request[round_robin_index])
                                round_robin_index <= round_robin_index;
                            else
                                round_robin_index <= round_robin_index + 1;
                        end
                    end
                end
            end
        end
    endgenerate

    // Priority assignment
    always @(*) begin
        priority = 0;
        if (ARB_TYPE_ROUND_ROBIN) begin
            for (i = 0; i < PORTS; i = i + 1) begin
                priority[i] = request[(round_robin_index + i) % PORTS];
            end
        end else begin
            if (ARB_LSB_HIGH_PRIORITY) begin
                for (i = 0; i < PORTS; i = i + 1) begin
                    priority[i] = request[i];
                end
            end else begin
                for (i = PORTS - 1; i >= 0; i = i - 1) begin
                    priority[i] = request[i];
                end
            end
        end
    end

    // Grant logic
    always @(*) begin
        next_grant = 0;
        next_grant_encoded = 0;
        valid_grant = 0;
        for (i = 0; i < PORTS; i = i + 1) begin
            if (priority[i]) begin
                next_grant[i] = 1;
                next_grant_encoded = i;
                valid_grant = 1;
                break;
            end
        end
    end

    // Update current grant and valid signal
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            current_grant_encoded <= 0;
        end else begin
            if (valid_grant && (ARB_BLOCK ? acknowledge[current_grant_encoded] : 1)) begin
                current_grant <= next_grant;
                current_grant_encoded <= next_grant_encoded;
            end
        end
    end

    // Output assignment
    assign grant = current_grant;
    assign grant_valid = valid_grant;
    assign grant_encoded = current_grant_encoded;

endmodule
