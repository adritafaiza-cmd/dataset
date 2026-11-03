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
    reg             grant_valid_reg;
    reg [$clog2(PORTS)-1:0] current_encoded;
    reg [PORTS-1:0] next_grant;
    reg             next_valid;
    reg [$clog2(PORTS)-1:0] next_encoded;
    wire [PORTS-1:0] priority_signal;
    wire [PORTS-1:0] pending_request;
    wire [PORTS-1:0] selected_request;

    // Priority signal generation
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin : round_robin
            wire [$clog2(PORTS)-1:0] round_robin_counter;
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    round_robin_counter <= 0;
                end else if (next_valid) begin
                    round_robin_counter <= round_robin_counter + 1;
                end
            end
            assign priority_signal = (1 << round_robin_counter);
        end else begin : fixed_priority
            assign priority_signal = {PORTS{1'b1}};
        end
    endgenerate

    // Mask priority signal with request to get pending request
    assign pending_request = priority_signal & request;

    // Select the highest priority request from pending_request as selected_request
    genvar i;
    generate
        if (ARB_LSB_HIGH_PRIORITY) begin : lsb_priority
            always @(*) begin
                selected_request = 0;
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (pending_request[i]) begin
                        selected_request = (1 << i);
                    end
                end
            end
        end else begin : msb_priority
            always @(*) begin
                selected_request = 0;
                for (i = PORTS - 1; i >= 0; i = i - 1) begin
                    if (pending_request[i]) begin
                        selected_request = (1 << i);
                    end
                end
            end
        end
    endgenerate

    // Determine next_grant based on selected_request and grant_valid
    always @(*) begin
        next_grant = selected_request;
        if (ARB_BLOCK && grant_valid_reg) begin
            if (ARB_BLOCK_ACK) begin
                if (acknowledge & current_grant) begin
                    next_grant = current_grant;
                end else if (~request & current_grant) begin
                    next_grant = 0;
                end
            end else begin
                if (~request & current_grant) begin
                    next_grant = 0;
                end
            end
        end
    end

    // Determine next_valid based on selected_request and ARB_BLOCK
    always @(*) begin
        next_valid = (selected_request != 0);
        if (ARB_BLOCK && grant_valid_reg) begin
            if (ARB_BLOCK_ACK) begin
                if (acknowledge & current_grant) begin
                    next_valid = 1;
                end else if (~request & current_grant) begin
                    next_valid = 0;
                end
            end else begin
                if (~request & current_grant) begin
                    next_valid = 0;
                end
            end
        end
    end

    // Encode the selected request index into next_encoded
    always @(*) begin
        next_encoded = 0;
        for (i = 0; i < PORTS; i = i + 1) begin
            if (selected_request[i]) begin
                next_encoded = i;
            end
        end
    end

    // Update current_grant and grant_valid on each clock cycle
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            grant_valid_reg <= 0;
            current_encoded <= 0;
        end else begin
            current_grant <= next_grant;
            grant_valid_reg <= next_valid;
            current_encoded <= next_encoded;
        end
    end

    // Drive grant and grant_valid from current_grant and grant_valid_reg respectively
    assign grant = current_grant;
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = current_encoded;

endmodule
