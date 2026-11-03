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

    wire pulseA_r;
    wire pulseA_d;
    wire pulseA_re;
    reg  busy_q;

    // Detect rising edge of pulseA_i in clk_a domain
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            pulseA_d <= 1'b0;
        end else begin
            pulseA_d <= pulseA_i;
        end
    end

    assign pulseA_r = ~pulseA_d & pulseA_i;
    assign pulseA_re = pulseA_r & ~busy_q;

    // Set busy to high when a pulse is detected
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            busy_q <= 1'b0;
        end else if (pulseA_re) begin
            busy_q <= 1'b1;
        end else if (pulseB_o) begin
            busy_q <= 1'b0;
        end
    end

    assign busy_o = busy_q;

    // Cross the detected pulse to clk_b domain using a shift register with STAGES
    reg [STAGES-1:0] pulse_shift;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulse_shift <= {STAGES{1'b0}};
        end else begin
            pulse_shift <= {pulse_shift[STAGES-2:0], pulseA_re};
        end
    end

    // Generate a one-cycle pulse on pulseB_o in clk_b domain upon crossing
    reg pulseB_d;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            pulseB_d <= 1'b0;
        end else begin
            pulseB_d <= pulse_shift[STAGES-1];
        end
    end

    assign pulseB_o = pulse_shift[STAGES-1] & ~pulseB_d;

endmodule
