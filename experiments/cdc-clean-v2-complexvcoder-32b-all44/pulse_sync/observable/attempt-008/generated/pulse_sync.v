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

    reg sync_pulseA_sync_out;
    reg sync_busy_sync_out;
    reg busy_reg;
    reg pulseB_d;

    // Synchronizer for pulseA_i from clk_a to clk_b
    synchronizer #(.STAGES(STAGES)) sync_pulseA (
        .clk(clk_b),
        .rstn(rstn_b),
        .async_in(pulseA_i),
        .sync_out(sync_pulseA_sync_out)
    );

    // Synchronizer for busy_o from clk_a to clk_b
    synchronizer #(.STAGES(STAGES)) sync_busy (
        .clk(clk_b),
        .rstn(rstn_b),
        .async_in(busy_o),
        .sync_out(sync_busy_sync_out)
    );

    // Logic for clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy_reg <= 1'b0;
        end else begin
            if (!busy_o && pulseA_i) begin
                busy_reg <= 1'b1;
            end else if (busy_o) begin
                busy_reg <= 1'b1;
            end else begin
                busy_reg <= 1'b0;
            end
        end
    end

    // Logic for clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o <= 1'b0;
        end else begin
            if (sync_pulseA_sync_out && !pulseB_d) begin
                pulseB_o <= 1'b1;
            end else if (sync_busy_sync_out) begin
                pulseB_o <= 1'b1;
            end else begin
                pulseB_o <= 1'b0;
            end
        end
    end

    // Delay pulseB_o by one clock cycle in clk_b domain to generate pulseB_d
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_d <= 1'b0;
        end else begin
            pulseB_d <= pulseB_o;
        end
    end

    // Assign busy_o
    assign busy_o = busy_reg;

endmodule

module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_in,
    output sync_out
);

    reg [STAGES-1:0] sync_stage;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_stage <= {STAGES{1'b0}};
        end else begin
            sync_stage[0] <= async_in;
            for (integer i = 1; i < STAGES; i = i + 1) begin
                sync_stage[i] <= sync_stage[i-1];
            end
        end
    end

    assign sync_out = sync_stage[STAGES-1];

endmodule
