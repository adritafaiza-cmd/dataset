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

    // Domain A signals
    reg a_toggle;
    reg [STAGES-1:0] b_toggle_sync;

    // Synchronize b_toggle (ack) to A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            b_toggle_sync <= 0;
        end else begin
            b_toggle_sync <= {b_toggle_sync[STAGES-2:0], b_toggle};
        end
    end

    // Busy is when a_toggle and synchronized ack are different
    assign busy_o = (a_toggle != b_toggle_sync[STAGES-1]);

    // Toggle a when pulseA_i and not busy
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            a_toggle <= 0;
        end else if (pulseA_i && !busy_o) begin
            a_toggle <= ~a_toggle;
        end
    end

    // Synchronize a_toggle to B
    reg [STAGES-1:0] a_toggle_sync;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            a_toggle_sync <= 0;
        end else begin
            a_toggle_sync <= {a_toggle_sync[STAGES-2:0], a_toggle};
        end
    end

    // Detect edge in a_toggle_sync to generate pulseB
    reg a_toggle_prev;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            a_toggle_prev <= 0;
        end else begin
            a_toggle_prev <= a_toggle_sync[STAGES-1];
        end
    end

    assign pulseB_o = (a_toggle_sync[STAGES-1] != a_toggle_prev);

    // Generate b_toggle (ack) when pulseB is generated
    reg b_toggle;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            b_toggle <= 0;
        end else if (pulseB_o) begin
            b_toggle <= ~b_toggle;
        end
    end

endmodule
