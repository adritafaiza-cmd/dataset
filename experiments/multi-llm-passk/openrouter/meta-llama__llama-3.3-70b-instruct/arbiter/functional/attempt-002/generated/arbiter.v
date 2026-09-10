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

reg [PORTS-1:0] grant_reg;
reg [$clog2(PORTS)-1:0] grant_encoded_reg;
reg grant_valid_reg;
reg [PORTS-1:0] priority_reg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        grant_reg <= {PORTS{1'b0}};
        grant_encoded_reg <= 0;
        grant_valid_reg <= 1'b0;
        priority_reg <= {PORTS{1'b0}};
    end else begin
        reg [PORTS-1:0] request_mask;
        reg [PORTS-1:0] grant_mask;
        reg [PORTS-1:0] acknowledge_mask;

        if (ARB_LSB_HIGH_PRIORITY) begin
            request_mask <= request;
            grant_mask <= grant_reg;
            acknowledge_mask <= acknowledge;
        end else begin
            request_mask <= {request[PORTS-1], request[PORTS-2:1], request[0]};
            grant_mask <= {grant_reg[PORTS-1], grant_reg[PORTS-2:1], grant_reg[0]};
            acknowledge_mask <= {acknowledge[PORTS-1], acknowledge[PORTS-2:1], acknowledge[0]};
        end

        if (ARB_BLOCK && grant_valid_reg) begin
            if (ARB_BLOCK_ACK) begin
                if (acknowledge_mask[grant_encoded_reg]) begin
                    grant_reg <= {PORTS{1'b0}};
                    grant_encoded_reg <= 0;
                    grant_valid_reg <= 1'b0;
                end
            end else if (!request_mask[grant_encoded_reg]) begin
                grant_reg <= {PORTS{1'b0}};
                grant_encoded_reg <= 0;
                grant_valid_reg <= 1'b0;
            end
        end else begin
            reg [PORTS-1:0] priority;
            if (ARB_TYPE_ROUND_ROBIN) begin
                priority <= {priority_reg[PORTS-2:0], priority_reg[PORTS-1]};
            end else begin
                priority <= priority_reg;
            end

            reg [PORTS-1:0] grant_temp;
            reg [$clog2(PORTS)-1:0] grant_encoded_temp;
            reg grant_valid_temp;

            grant_temp <= {PORTS{1'b0}};
            grant_encoded_temp <= 0;
            grant_valid_temp <= 1'b0;

            for (int i = 0; i < PORTS; i = i + 1) begin
                if (priority[i] && request_mask[i] &&!grant_valid_temp) begin
                    grant_temp <= (1 << i);
                    grant_encoded_temp <= i;
                    grant_valid_temp <= 1'b1;
                end
            end

            grant_reg <= grant_temp;
            grant_encoded_reg <= grant_encoded_temp;
            grant_valid_reg <= grant_valid_temp;

            if (grant_valid_temp) begin
                priority_reg <= priority;
            end
        end
    end
end

assign grant = grant_reg;
assign grant_valid = grant_valid_reg;
assign grant_encoded = grant_encoded_reg;

endmodule
