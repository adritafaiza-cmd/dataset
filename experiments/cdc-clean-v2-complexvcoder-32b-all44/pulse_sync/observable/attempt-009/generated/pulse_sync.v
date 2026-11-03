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

    reg pulseA_to_b;
    reg pulseB_to_a;
    reg busy;

    // Cross pulseA_i from clk_a to clk_b
    async_cross #(
        .STAGES(STAGES)
    ) cross_a_to_b (
        .clk_src(clk_a),
        .rstn_src(rstn_a),
        .clk_dst(clk_b),
        .rstn_dst(rstn_b),
        .data_in(pulseA_i),
        .data_out(pulseA_to_b)
    );

    // Cross pulseB_o from clk_b to clk_a
    async_cross #(
        .STAGES(STAGES)
    ) cross_b_to_a (
        .clk_src(clk_b),
        .rstn_src(rstn_b),
        .clk_dst(clk_a),
        .rstn_dst(rstn_a),
        .data_in(pulseB_o),
        .data_out(pulseB_to_a)
    );

    // Logic in clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy <= 0;
            pulseB_o <= 0;
        end else begin
            if (!busy && pulseA_i) begin
                pulseA_to_b <= 1;
                busy <= 1;
            end
        end
    end

    // Logic in clk_b domain
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_o <= 0;
        end else begin
            if (pulseA_to_b) begin
                pulseB_o <= 1;
            end else if (pulseB_to_a) begin
                pulseB_o <= 0;
                busy <= 0;
            end
        end
    end

    assign busy_o = busy;

endmodule

module async_cross #(
    parameter STAGES = 2
)(
    input  clk_src,
    input  rstn_src,
    input  clk_dst,
    input  rstn_dst,
    input  data_in,
    output data_out
);

    reg [STAGES-1:0] shift_reg;

    // Shift register in source clock domain
    always @(posedge clk_src or negedge rstn_src) begin
        if (!rstn_src) begin
            shift_reg <= {STAGES{1'b0}};
        end else begin
            shift_reg <= {shift_reg[STAGES-2:0], data_in};
        end
    end

    // Output register in destination clock domain
    always @(posedge clk_dst or negedge rstn_dst) begin
        if (!rstn_dst) begin
            data_out <= 1'b0;
        end else begin
            data_out <= shift_reg[STAGES-1];
        end
    end

endmodule
