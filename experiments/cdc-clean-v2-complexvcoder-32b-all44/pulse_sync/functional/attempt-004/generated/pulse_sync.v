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

    reg busy;
    reg pulseA_d;
    reg pulseA_r;
    reg pulseB_d;

    // Instantiate the asynchronous crosser
    async_cross #(
        .STAGES(STAGES)
    ) cross_inst (
        .clk_a  (clk_a),
        .rstn_a (rstn_a),
        .clk_b  (clk_b),
        .rstn_b (rstn_b),
        .data_in(pulseA_r),
        .data_out(pulseB_d)
    );

    // Synchronize and detect pulseA_i
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseA_d <= 0;
            pulseA_r <= 0;
            busy <= 0;
        end else begin
            pulseA_d <= pulseA_i;
            pulseA_r <= pulseA_d;
            if (pulseA_r && !busy) begin
                busy <= 1;
            end
        end
    end

    // Generate pulseB_o and clear busy signal
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o <= 0;
        end else begin
            pulseB_o <= pulseB_d;
            if (pulseB_o) begin
                busy <= 0;
            end
        end
    end

    // Assign busy output
    assign busy_o = busy;

endmodule

module async_cross #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  data_in,
    output data_out
);

    reg [STAGES-1:0] sync_chain;

    // Cross the signal from clk_a domain to clk_b domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_chain <= 0;
        end else begin
            sync_chain[0] <= data_in;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_chain[i] <= sync_chain[i-1];
            end
        end
    end

    // Output the synchronized signal
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            data_out <= 0;
        end else begin
            data_out <= sync_chain[STAGES-1];
        end
    end

endmodule
