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

always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        grant_reg <= {PORTS{1'b0}};
        grant_encoded_reg <= {($clog2(PORTS)){1'b0}};
        grant_valid_reg <= 1'b0;
        priority_reg <= {PORTS{1'b0}};
    end
    else
    begin
        reg [PORTS-1:0] request_mask;
        reg [PORTS-1:0] priority_mask;
        reg [PORTS-1:0] grant_mask;

        if (ARB_TYPE_ROUND_ROBIN)
        begin
            priority_mask[PORTS-1:0] = (priority_reg << 1) | {({PORTS-2{1'b0}}), priority_reg[PORTS-1]};
        end
        else
        begin
            priority_mask[PORTS-1:0] = (ARB_LSB_HIGH_PRIORITY) ? {({PORTS-1{1'b0}}), 1'b1} : {1'b1, {PORTS-2{1'b0}}};
        end

        request_mask[PORTS-1:0] = request & ~grant_reg;
        grant_mask[PORTS-1:0] = request_mask & priority_mask;

        if (ARB_BLOCK && grant_valid_reg)
        begin
            if (ARB_BLOCK_ACK)
            begin
                if (acknowledge[grant_encoded_reg])
                begin
                    grant_reg <= {PORTS{1'b0}};
                    grant_encoded_reg <= {($clog2(PORTS)){1'b0}};
                    grant_valid_reg <= 1'b0;
                end
            end
            else if (~request[grant_encoded_reg])
            begin
                grant_reg <= {PORTS{1'b0}};
                grant_encoded_reg <= {($clog2(PORTS)){1'b0}};
                grant_valid_reg <= 1'b0;
            end
        end
        else if (|request_mask)
        begin
            grant_reg <= grant_mask;
            grant_encoded_reg <= get_encoded(grant_mask);
            grant_valid_reg <= 1'b1;
        end
        else
        begin
            grant_reg <= {PORTS{1'b0}};
            grant_encoded_reg <= {($clog2(PORTS)){1'b0}};
            grant_valid_reg <= 1'b0;
        end

        if (ARB_TYPE_ROUND_ROBIN && |request_mask)
        begin
            priority_reg <= grant_mask;
        end
    end
end

function [$clog2(PORTS)-1:0] get_encoded;
input [PORTS-1:0] grant_mask;
integer i;
begin
    get_encoded = {($clog2(PORTS)){1'b0}};
    for (i = 0; i < PORTS; i = i + 1)
    begin
        if (grant_mask[i])
        begin
            get_encoded = i;
        end
    end
end
endfunction

assign grant = grant_reg;
assign grant_valid = grant_valid_reg;
assign grant_encoded = grant_encoded_reg;

endmodule
