module pulse_sync #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output pulseB_o,
    output busy_o
);

    // A to B direction: clk_a to clk_b
    reg req_toggle;
    reg ack_toggle_sync1, ack_toggle_sync2;
    reg busy;

    // Synchronize ack_toggle from clk_b
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            ack_toggle_sync1 <= 0;
            ack_toggle_sync2 <= 0;
        end else begin
            ack_toggle_sync1 <= ack_toggle;
            ack_toggle_sync2 <= ack_toggle_sync1;
        end
    end

    // Main logic for busy and req_toggle
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy <= 0;
            req_toggle <= 0;
        end else begin
            if (pulseA_i && !busy) begin
                req_toggle <= ~req_toggle;
                busy <= 1;
            end else if (ack_toggle_sync2 == req_toggle) begin
                busy <= 0;
            end
        end
    end

    assign busy_o = busy;

    // Signals in clk_b domain
    reg req_toggle_sync1, req_toggle_sync2;
    reg req_toggle_prev;
    reg ack_toggle;
    reg pulseB_reg;

    // Synchronize req_toggle to clk_b
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_toggle_sync1 <= 0;
            req_toggle_sync2 <= 0;
        end else begin
            req_toggle_sync1 <= req_toggle;
            req_toggle_sync2 <= req_toggle_sync1;
        end
    end

    // Previous state to detect edge
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            req_toggle_prev <= 0;
        end else begin
            req_toggle_prev <= req_toggle_sync2;
        end
    end

    // Generate pulseB and toggle ack_toggle
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_reg <= 0;
            ack_toggle <= 0;
        end else begin
            pulseB_reg <= 0;
            if (req_toggle_sync2 != req_toggle_prev) begin
                pulseB_reg <= 1;
                ack_toggle <= ~ack_toggle;
            end
        end
    end

    assign pulseB_o = pulseB_reg;

endmodule
