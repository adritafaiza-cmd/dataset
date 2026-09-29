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

    // clk_a domain signals
    reg toggle_a;
    reg [STAGES-1:0] toggle_b_sync;

    // clk_b domain signals
    reg [STAGES-1:0] toggle_a_sync;
    reg toggle_prev;
    reg toggle_b;

    // Synchronize toggle_b (ack) to clk_a
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            toggle_b_sync <= 0;
        end else begin
            toggle_b_sync <= {toggle_b_sync[STAGES-2:0], toggle_b};
        end
    end

    // Busy is high when toggle_a differs from synchronized ack
    assign busy_o = (toggle_a != toggle_b_sync[STAGES-1]);

    // Toggle_a logic
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            toggle_a <= 0;
        end else begin
            if (pulseA_i && !busy_o) begin
                toggle_a <= ~toggle_a;
            end
        end
    end

    // Synchronize toggle_a to clk_b
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            toggle_a_sync <= 0;
        end else begin
            toggle_a_sync <= {toggle_a_sync[STAGES-2:0], toggle_a};
        end
    end

    // Edge detection in clk_b
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            toggle_prev <= 0;
        end else begin
            toggle_prev <= toggle_a_sync[STAGES-1];
        end
    end

    assign pulseB_o = (toggle_a_sync[STAGES-1] != toggle_prev);

    // Toggle_b (ack) generation
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            toggle_b <= 0;
        end else begin
            if (pulseB_o) begin
                toggle_b <= ~toggle_b;
            end
        end
    end

endmodule
