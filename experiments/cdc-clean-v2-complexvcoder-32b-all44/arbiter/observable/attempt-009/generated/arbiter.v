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
    reg  [$clog2(PORTS)-1:0] current_grant;
    reg  [$clog2(PORTS)-1:0] round_robin_counter;
    wire [PORTS-1:0] grant_one_hot;
    wire request_valid;

    assign request_valid = |request;

    // Determine next_grant based on the selected arbitration type
    always @(*) begin
        if (ARB_TYPE_ROUND_ROBIN) begin
            integer i;
            integer start_idx;
            if (ARB_LSB_HIGH_PRIORITY)
                start_idx = round_robin_counter;
            else
                start_idx = PORTS - round_robin_counter - 1;

            next_grant = 0;
            for (i = 0; i < PORTS; i = i + 1) begin
                integer idx;
                if (ARB_LSB_HIGH_PRIORITY)
                    idx = (start_idx + i) % PORTS;
                else
                    idx = (start_idx - i + PORTS) % PORTS;

                if (request[idx]) begin
                    next_grant = idx;
                    break;
                end
            end
        end else begin
            integer i;
            if (ARB_LSB_HIGH_PRIORITY) begin
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (request[i]) begin
                        next_grant = i;
                        break;
                    end
                end
            end else begin
                for (i = PORTS - 1; i >= 0; i = i - 1) begin
                    if (request[i]) begin
                        next_grant = i;
                        break;
                    end
                end
            end
        end
    end

    // Update current_grant
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            round_robin_counter <= 0;
        end else begin
            if (ARB_TYPE_ROUND_ROBIN && request_valid && !grant_valid) begin
                round_robin_counter <= round_robin_counter + 1;
            end

            if (!ARB_BLOCK || (ARB_BLOCK && acknowledge[next_grant])) begin
                current_grant <= next_grant;
            end
        end
    end

    // Set grant_valid
    assign grant_valid = request_valid && (!ARB_BLOCK || acknowledge[current_grant]);

    // Set grant_encoded
    assign grant_encoded = current_grant;

    // Convert current_grant to one-hot encoding for grant output
    always @(*) begin
        grant_one_hot = 0;
        grant_one_hot[current_grant] = 1;
    end

    assign grant = grant_one_hot;

endmodule
