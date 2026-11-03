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

    reg  pulseA_d;
    reg  busy;
    reg  pulseB_d;
    reg  pulseB;
    wire cross_pulse;

    // Instance of the async_cross module
    async_cross #(
        .STAGES(STAGES)
    ) cross_inst (
        .clk_a   (clk_a),
        .rstn_a  (rstn_a),
        .clk_b   (clk_b),
        .rstn_b  (rstn_b),
        .data_in (pulseA_i),
        .data_out(cross_pulse)
    );

    // Synchronize pulseA_i in clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseA_d <= 1'b0;
            busy     <= 1'b0;
        end else begin
            pulseA_d <= pulseA_i;
            if (pulseA_i && !pulseA_d) begin
                busy <= 1'b1;
            end
        end
    end

    // Process cross_pulse in clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_d <= 1'b0;
            pulseB   <= 1'b0;
        end else begin
            pulseB_d <= cross_pulse;
            if (cross_pulse && !pulseB_d) begin
                pulseB <= 1'b1;
            end else begin
                pulseB <= 1'b0;
            end
        end
    end

    // Busy signal generation
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy <= 1'b0;
        end else begin
            if (pulseB) begin
                busy <= 1'b0;
            end
        end
    end

    // Output assignments
    assign pulseB_o = pulseB;
    assign busy_o   = busy;

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

    // Synchronize data_in from clk_a domain to clk_b domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain[0] <= data_in;
        end
    end

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            sync_chain[STAGES-1:1] <= {STAGES-1{1'b0}};
        end else begin
            sync_chain[STAGES-1:1] <= sync_chain[STAGES-2:0];
        end
    end

    assign data_out = sync_chain[STAGES-1];

endmodule
