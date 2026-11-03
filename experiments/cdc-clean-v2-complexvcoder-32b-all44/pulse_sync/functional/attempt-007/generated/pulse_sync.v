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

    reg [STAGES-1:0] sync_ffs;
    reg              pulseA_ff;
    reg              pulseB_ff;
    reg              busy_a;

    // Synchronize pulseA_i from clk_a to clk_b using STAGES flip-flops
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_ffs <= {STAGES{1'b0}};
        end else begin
            sync_ffs <= {sync_ffs[STAGES-2:0], pulseA_i};
        end
    end

    // Detect the edge of the synchronized pulseA_i in clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseA_ff <= 1'b0;
            pulseB_ff <= 1'b0;
        end else begin
            pulseA_ff <= sync_ffs[STAGES-1];
            pulseB_ff <= pulseA_ff & ~sync_ffs[STAGES-1];
        end
    end

    // Assign the output pulseB_o in clk_b domain
    assign pulseB_o = pulseB_ff;

    // Detect the start and end of the pulse in flight in clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy_a <= 1'b0;
        end else if (pulseA_i & ~busy_a) begin
            busy_a <= 1'b1;
        end else if (pulseB_ff) begin
            busy_a <= 1'b0;
        end
    end

    // Assign the busy_o output in clk_a domain
    assign busy_o = busy_a;

endmodule
