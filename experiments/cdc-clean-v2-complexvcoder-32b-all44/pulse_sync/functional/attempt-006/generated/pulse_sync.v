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

    // Internal signals
    reg [STAGES-1:0] pulseA_sync;
    reg [STAGES-1:0] pulseB_sync;
    reg              pulseA_dff;
    reg              pulseB_dff;
    reg              busy_dff;

    // Synchronize pulseA_i to clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseA_sync <= 0;
        end else begin
            pulseA_sync <= {pulseA_sync[STAGES-2:0], pulseA_dff};
        end
    end

    // Detect edge of synchronized pulseA_i in clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseA_dff <= 0;
        end else begin
            pulseA_dff <= pulseA_i;
        end
    end

    // Generate pulseB_o and busy_o
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o <= 0;
            busy_o   <= 0;
        end else begin
            pulseB_o <= pulseA_sync[STAGES-1] & ~pulseB_sync[STAGES-1];
            busy_o   <= |pulseA_sync | pulseB_o;
        end
    end

    // Synchronize pulseB_o to clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseB_sync <= 0;
        end else begin
            pulseB_sync <= {pulseB_sync[STAGES-2:0], pulseB_o};
        end
    end

endmodule
