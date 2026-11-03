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
    reg [STAGES-1:0] pulseA_synced;
    reg pulseA_edge;
    reg pulseB;
    reg busy;

    // Instantiate the first ff_sync module to cross pulseA_i to clk_b domain
    ff_sync #(
        .STAGES(STAGES)
    ) ff_sync_inst_a (
        .clk(clk_b),
        .rstn(rstn_b),
        .data_i(pulseA_i),
        .data_o(pulseA_synced[0])
    );

    // Instantiate the second ff_sync module to cross pulseA_synced[0] to clk_b domain
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : gen_sync_stages
            ff_sync ff_sync_inst_b (
                .clk(clk_b),
                .rstn(rstn_b),
                .data_i(pulseA_synced[i-1]),
                .data_o(pulseA_synced[i])
            );
        end
    endgenerate

    // Detect rising edge of pulseA_synced[STAGES-1]
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseA_edge <= 1'b0;
        end else begin
            pulseA_edge <= pulseA_synced[STAGES-1] & ~pulseA_synced[STAGES-2];
        end
    end

    // Generate pulseB on rising edge of pulseA_synced[STAGES-1]
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB <= 1'b0;
        end else if (pulseA_edge) begin
            pulseB <= 1'b1;
        end else begin
            pulseB <= 1'b0;
        end
    end

    // Output pulseB_o on rising edge of pulseB
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o <= 1'b0;
        end else if (pulseB) begin
            pulseB_o <= 1'b1;
        end else begin
            pulseB_o <= 1'b0;
        end
    end

    // Set busy high when pulseA_i is detected and hold until pulseB is generated
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy <= 1'b0;
        end else if (pulseA_i) begin
            busy <= 1'b1;
        end else if (pulseB) begin
            busy <= 1'b0;
        end
    end

    // Output busy_o as busy
    assign busy_o = busy;

endmodule

module ff_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  data_i,
    output data_o
);

    reg [STAGES-1:0] sync_chain;

    // Synchronize data_i to clk domain using a shift register chain
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain <= {sync_chain[STAGES-2:0], data_i};
        end
    end

    // Output the last stage of the sync chain
    assign data_o = sync_chain[STAGES-1];

endmodule
