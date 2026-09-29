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
    reg [PORTS-1:0] last_grant;
    reg [PORTS-1:0] next_grant;
    reg [$clog2(PORTS)-1:0] grant_encoded_reg;

    // Convert current_grant to encoded form
    function [$clog2(PORTS)-1:0] onehot_to_bin;
        input [PORTS-1:0] onehot;
        integer i;
        begin
            onehot_to_bin = 0;
            for (i = 0; i < PORTS; i = i + 1) begin
                if (onehot[i]) begin
                    onehot_to_bin = i;
                end
            end
        end
    endfunction

    assign grant = current_grant;
    assign grant_valid = |current_grant;
    assign grant_encoded = grant_encoded_reg;

    // Update current_grant and last_grant on clock edge
    always @(posedge clk) begin
        if (rst) begin
            current_grant <= 0;
            last_grant <= 0;
        end else begin
            current_grant <= next_grant;
            if (ARB_TYPE_ROUND_ROBIN && (next_grant != 0)) begin
                last_grant <= next_grant;
            end
        end
    end

    // Combinational next_grant logic
    always @* begin
        integer i, idx;
        reg [PORTS-1:0] req;
        reg [PORTS-1:0] current_grant_reg;

        current_grant_reg = current_grant;
        req = request;

        if (ARB_BLOCK && (current_grant != 0)) begin
            // Handle blocking mode
            idx = onehot_to_bin(current_grant);
            if (ARB_BLOCK_ACK) begin
                // Wait for acknowledge
                if (acknowledge[idx]) begin
                    next_grant = 0;
                end else begin
                    next_grant = current_grant;
                end
            end else begin
                // Wait until request drops
                if (req[idx]) begin
                    next_grant = current_grant;
                end else begin
                    next_grant = 0;
                end
            end
        end else begin
            // Non-blocking mode or no current grant
            if (ARB_TYPE_ROUND_ROBIN) begin
                // Round-robin arbitration
                integer start_idx;
                start_idx = (last_grant == 0) ? 0 : onehot_to_bin(last_grant) + 1;
                start_idx = start_idx % PORTS;
                req = request & ~current_grant_reg;

                next_grant = 0;
                for (i = start_idx; ; i = (i + 1) % PORTS) begin
                    if (req[i]) begin
                        next_grant = (1 << i);
                        break;
                    end
                    if (i == start_idx) break;
                end
            end else begin
                // Fixed priority
                if (ARB_LSB_HIGH_PRIORITY) begin
                    // Priority from LSB to MSB
                    for (i = 0; i < PORTS; i = i + 1) begin
                        if (req[i]) begin
                            next_grant = (1 << i);
                            break;
                        end
                    end
                end else begin
                    // Priority from MSB to LSB
                    for (i = PORTS - 1; i >= 0; i = i - 1) begin
                        if (req[i]) begin
                            next_grant = (1 << i);
                            break;
                        end
                    end
                end
            end
        end
    end

    // Update grant_encoded_reg
    always @* begin
        grant_encoded_reg = onehot_to_bin(current_grant);
    end

endmodule
