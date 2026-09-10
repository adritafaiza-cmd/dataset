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
reg block_reg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        grant_reg <= {PORTS{1'b0}};
        grant_encoded_reg <= {$clog2(PORTS){1'b0}};
        grant_valid_reg <= 1'b0;
        priority_reg <= {PORTS{1'b0}};
        block_reg <= 1'b0;
    end else begin
        if (ARB_BLOCK && block_reg) begin
            if (ARB_BLOCK_ACK) begin
                if (acknowledge[grant_encoded_reg]) begin
                    block_reg <= 1'b0;
                end
            end else if (!request[grant_encoded_reg]) begin
                block_reg <= 1'b0;
            end
        end else begin
            reg [PORTS-1:0] req_copy;
            reg [PORTS-1:0] grant_copy;
            reg [$clog2(PORTS)-1:0] grant_encoded_copy;
            reg grant_valid_copy;
            reg [PORTS-1:0] priority_copy;

            req_copy = request;
            grant_copy = grant_reg;
            grant_encoded_copy = grant_encoded_reg;
            grant_valid_copy = grant_valid_reg;
            priority_copy = priority_reg;

            if (ARB_TYPE_ROUND_ROBIN) begin
                priority_copy = {priority_copy[PORTS-2:0], priority_copy[PORTS-1]};
            end

            if (ARB_LSB_HIGH_PRIORITY) begin
                for (int i = 0; i < PORTS; i++) begin
                    if (req_copy[i] && !grant_copy[i]) begin
                        grant_copy = {PORTS{1'b0}};
                        grant_copy[i] = 1'b1;
                        grant_encoded_copy = i;
                        grant_valid_copy = 1'b1;
                        block_reg <= 1'b1;
                    end
                end
            end else begin
                for (int i = PORTS-1; i >= 0; i--) begin
                    if (req_copy[i] && !grant_copy[i]) begin
                        grant_copy = {PORTS{1'b0}};
                        grant_copy[i] = 1'b1;
                        grant_encoded_copy = i;
                        grant_valid_copy = 1'b1;
                        block_reg <= 1'b1;
                    end
                end
            end

            grant_reg <= grant_copy;
            grant_encoded_reg <= grant_encoded_copy;
            grant_valid_reg <= grant_valid_copy;
            priority_reg <= priority_copy;
        end
    end
end

assign grant = grant_reg;
assign grant_valid = grant_valid_reg;
assign grant_encoded = grant_encoded_reg;

endmodule
