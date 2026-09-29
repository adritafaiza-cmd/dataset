module pulse_sync #(
    parameter STAGES = 2
) (
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output pulseB_o,
    output busy_o
);

    // Signals in clk_a domain
    reg req_a;
    reg ack_b_sync1, ack_b_sync2;

    // Signals in clk_b domain
    reg req_sync1, req_sync2;
    reg ack_b;

    // Edge detection in clk_b
    reg req_sync2_prev;

    // Synchronize ack from clk_b to clk_a
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            ack_b_sync1 <= 1'b0;
            ack_b_sync2 <= 1'b0;
        end else begin
            ack_b_sync1 <= ack_b;
            ack_b_sync2 <= ack_b_sync1;
        end
    end

    // State for req in clk_a
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            req_a <= 1'b0;
        end else begin
            if (pulseA_i && !req_a) begin
                req_a <= 1'b1;
            end else if (ack_b_sync2) begin
                req_a <= 1'b0;
            end
        end
    end

    assign busy_o = req_a;

    // Synchronize req to clk_b
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_sync1 <= 1'b0;
            req_sync2 <= 1'b0;
        end else begin
            req_sync1 <= req_a;
            req_sync2 <= req_sync1;
        end
    end

    // Edge detection for clk_b
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_sync2_prev <= 1'b0;
        end else begin
            req_sync2_prev <= req_sync2;
        end
    end

    wire pulseB;
    assign pulseB = req_sync2 && !req_sync2_prev;

    // Generate pulseB and ack
    reg pulseB_reg;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o <= 1'b0;
            ack_b <= 1'b0;
        end else begin
            pulseB_o <= pulseB;
            ack_b <= pulseB;
        end
    end

endmodule
