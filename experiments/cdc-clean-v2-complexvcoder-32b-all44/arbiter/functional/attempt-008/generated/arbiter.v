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

    reg [PORTS-1:0] current_request;
    reg [PORTS-1:0] next_request;
    reg [PORTS-1:0] priority_select;
    reg [PORTS-1:0] grant_temp;
    reg             grant_valid_temp;
    reg [$clog2(PORTS)-1:0] grant_encoded_temp;
    reg [PORTS-1:0] request_mask;

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_request <= {PORTS{1'b0}};
            grant_temp <= {PORTS{1'b0}};
            grant_valid_temp <= 1'b0;
            grant_encoded_temp <= {$clog2(PORTS){1'b0}};
        end else begin
            // Determine next_request based on arbitration type
            if (ARB_TYPE_ROUND_ROBIN) begin
                // Rotate priority
                next_request <= {current_request[PORTS-2:0], current_request[PORTS-1]};
            end else begin
                // Fixed priority
                next_request <= current_request;
            end

            // Generate priority_select based on current_request and request signals
            priority_select <= request & next_request;

            // Determine grant_temp based on priority_select and request signals
            if (ARB_LSB_HIGH_PRIORITY) begin
                // Select the LSB in case of a tie
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (priority_select[i]) begin
                        grant_temp <= {PORTS{1'b0}};
                        grant_temp[i] <= 1'b1;
                        break;
                    end
                end
            end else begin
                // Select the MSB in case of a tie
                for (i = PORTS-1; i >= 0; i = i - 1) begin
                    if (priority_select[i]) begin
                        grant_temp <= {PORTS{1'b0}};
                        grant_temp[i] <= 1'b1;
                        break;
                    end
                end
            end

            // If ARB_BLOCK is set, hold the grant_temp until acknowledge or request drops based on ARB_BLOCK_ACK
            if (ARB_BLOCK) begin
                if (ARB_BLOCK_ACK) begin
                    if (acknowledge & grant_temp) begin
                        grant_temp <= {PORTS{1'b0}};
                        grant_valid_temp <= 1'b0;
                    end
                end else begin
                    if (~(request & grant_temp)) begin
                        grant_temp <= {PORTS{1'b0}};
                        grant_valid_temp <= 1'b0;
                    end
                end
            end

            // Generate grant_valid_temp and grant_encoded_temp based on grant_temp
            grant_valid_temp <= |grant_temp;
            grant_encoded_temp <= 0;
            for (i = 0; i < PORTS; i = i + 1) begin
                if (grant_temp[i]) begin
                    grant_encoded_temp <= i;
                end
            end

            // Update current_request
            current_request <= next_request;

            // Assign outputs
            grant <= grant_temp;
            grant_valid <= grant_valid_temp;
            grant_encoded <= grant_encoded_temp;
        end
    end
endmodule
