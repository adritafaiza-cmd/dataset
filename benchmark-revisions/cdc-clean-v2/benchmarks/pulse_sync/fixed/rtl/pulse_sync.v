// Handshake pulse synchronizer. Verilog rewrite of tweak_circuits pulse_sync.vhd.
// Designed by Mitu Raj, Chipmunk Logic.

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

    (* ASYNC_REG = "TRUE" *)
    reg [STAGES-1:0] flipflops_a;
    (* ASYNC_REG = "TRUE" *)
    reg [STAGES-1:0] flipflops_b;
    reg pulseA_regA;
    reg busyB_delayed;
    wire busyB = flipflops_b[STAGES-1];
    wire busyB_syncA = flipflops_a[STAGES-1];

    always @(posedge clk_a) begin
        if (!rstn_a)
            flipflops_a <= {STAGES{1'b0}};
        else
            flipflops_a <= {flipflops_a[STAGES-2:0], busyB};
    end

    always @(posedge clk_a) begin
        if (!rstn_a)
            pulseA_regA <= 1'b0;
        else
            pulseA_regA <= pulseA_i | (pulseA_regA & ~busyB_syncA);
    end

    always @(posedge clk_b) begin
        if (!rstn_b) begin
            flipflops_b <= {STAGES{1'b0}};
            busyB_delayed <= 1'b0;
        end else begin
            flipflops_b <= {flipflops_b[STAGES-2:0], pulseA_regA};
            busyB_delayed <= flipflops_b[STAGES-1];
        end
    end

    assign busy_o = busyB_syncA | pulseA_regA;
    assign pulseB_o = busyB & ~busyB_delayed;

endmodule
