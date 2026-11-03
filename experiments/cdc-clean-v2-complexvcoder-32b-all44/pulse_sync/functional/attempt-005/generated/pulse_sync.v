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

    reg  [STAGES-1:0] sync_reg_a;
    reg  [STAGES-1:0] sync_reg_b;
    reg               pulseA_sync;
    reg               pulseA_edge;
    reg               pulseB_reg;
    reg               busy_reg;

    // Synchronize pulseA_i to clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_reg_a <= {STAGES{1'b0}};
        end else begin
            sync_reg_a <= {sync_reg_a[STAGES-2:0], pulseA_i};
        end
    end

    // Detect rising edge of synchronized pulseA_i
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseA_edge <= 1'b0;
        end else begin
            pulseA_edge <= sync_reg_a[0] & ~sync_reg_a[1];
        end
    end

    // Synchronize pulseA_edge to clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_reg_b <= {STAGES{1'b0}};
        end else begin
            sync_reg_b <= {sync_reg_b[STAGES-2:0], pulseA_edge};
        end
    end

    assign pulseA_sync = sync_reg_b[0];

    // Generate pulseB_o and busy_o
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_reg <= 1'b0;
            busy_reg   <= 1'b0;
        end else if (pulseA_sync) begin
            pulseB_reg <= 1'b1;
            busy_reg   <= 1'b1;
        end else if (pulseB_reg) begin
            pulseB_reg <= 1'b0;
            busy_reg   <= 1'b0;
        end
    end

    assign pulseB_o = pulseB_reg;
    assign busy_o   = busy_reg;

endmodule
