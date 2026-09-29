module arbiter #(
    parameter PORTS = 4,
    parameter ARB_TYPE_ROUND_ROBIN = 0,
    parameter ARB_BLOCK = 0,
    parameter ARB_BLOCK_ACK = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 0
) (
    input wire clk,
    input wire rst,
    input wire [PORTS-1:0] request,
    input wire [PORTS-1:0] acknowledge,
    output wire [PORTS-1:0] grant,
    output wire grant_valid,
    output wire [$clog2(PORTS)-1:0] grant_encoded
);

    reg [PORTS-1:0] current_grant;
    reg [PORTS-1:0] next_grant;

    function [PORTS-1:0] fixed_priority;
        input [PORTS-1:0] req;
        input lsb_high;
        integer i;
        reg [PORTS-1:0] prio;
        begin
            prio = 0;
            if (lsb_high) begin
                for (i = PORTS-1; i >= 0; i = i - 1) begin
                    if (req[i] && prio == 0) begin
                        prio = (1 << i);
                    end
                end
            end else begin
                for (i = 0; i < PORTS; i = i + 1) begin
                    if (req[i] && prio == 0) begin
                        prio = (1 << i);
                    end
                end
            end
            fixed_priority = prio;
        end
    endfunction

    function integer find_highest_bit;
        input [PORTS-1:0] vec;
        integer i;
        begin
            find_highest_bit = -1;
            for (i = PORTS-1; i >= 0; i = i - 1) begin
                if (vec[i]) begin
                    find_highest_bit = i;
                    i = -1;
                end
            end
        end
    endfunction

    reg [PORTS-1:0] rr_grant;
    integer start;
    integer highest_bit;
    integer i;
    integer idx;

    always @* begin
        rr_grant = 0;
        if (current_grant == 0) begin
            start = 0;
        end else begin
            highest_bit = find_highest_bit(current_grant);
            start = (highest_bit + 1) % PORTS;
        end

        for (i = 0; i < PORTS; i = i + 1) begin
            idx = (start + i) % PORTS;
            if (request[idx]) begin
                rr_grant = (1 << idx);
                i = PORTS;
            end
        end
    end

    always @* begin
        if (ARB_BLOCK) begin
            if (current_grant != 0) begin
                if (ARB_BLOCK_ACK) begin
                    if (|(acknowledge & current_grant)) begin
                        next_grant = 0;
                    end else begin
                        next_grant = current_grant;
                    end
                end else begin
                    if (|(request & current_grant)) begin
                        next_grant = current_grant;
                    end else begin
                        next_grant = 0;
                    end
                end
            end else begin
                if (ARB_TYPE_ROUND_ROBIN) begin
                    next_grant = rr_grant;
                end else begin
                    next_grant = fixed_priority(request, ARB_LSB_HIGH_PRIORITY);
                end
            end
        end else begin
            if (ARB_TYPE_ROUND_ROBIN) begin
                next_grant = rr_grant;
            end else begin
                next_grant = fixed_priority(request, ARB_LSB_HIGH_PRIORITY);
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            current_grant <= 0;
        end else begin
            current_grant <= next_grant;
        end
    end

    assign grant = current_grant;
    assign grant_valid = |current_grant;

    function [$clog2(PORTS)-1:0] encode;
        input [PORTS-1:0] vec;
        integer i;
        begin
            encode = 0;
            for (i = 0; i < PORTS; i = i + 1) begin
                if (vec[i]) begin
                    encode = i;
                end
            end
        end
    endfunction

    assign grant_encoded = encode(current_grant);

endmodule
