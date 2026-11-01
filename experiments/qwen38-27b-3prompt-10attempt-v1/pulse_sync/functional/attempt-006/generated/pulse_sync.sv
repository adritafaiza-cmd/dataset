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

    // Domain A: latch the pulse and generate a level signal
    reg a_latch;
    wire a_level;

    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a)
            a_latch <= 1'b0;
        else if (pulseA_i && !a_latch)
            a_latch <= 1'b1;
        else if (a_latch && !pulseA_i)
            a_latch <= 1'b0;
    end

    assign a_level = a_latch;

    // Synchronize a_level into domain B
    reg [STAGES-1:0] b_sync;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            b_sync <= {STAGES{1'b0}};
        else
            b_sync <= {b_sync[STAGES-2:0], a_level};
    end

    // Detect rising edge of synchronized signal in domain B
    reg b_prev;
    wire b_pulse;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            b_prev <= 1'b0;
        else
            b_prev <= b_sync[STAGES-1];
    end

    assign b_pulse = b_sync[STAGES-1] & ~b_prev;

    // Generate pulseB_o and busy_o
    reg b_busy;

    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b)
            b_busy <= 1'b0;
        else if (b_pulse)
            b_busy <= 1'b1;
        else if (b_busy && !b_sync[STAGES-1])
            b_busy <= 1'b0;
    end

    assign pulseB_o = b_pulse;
    assign busy_o   = b_busy;

endmodule
