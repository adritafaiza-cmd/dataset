Please act as a professional Verilog designer.

Implement a one-pulse-in, one-pulse-out crossing between asynchronous clocks.

clk_a and clk_b are independent clocks. Please take care of any clock-domain crossings between them. The resets are active-low.

Carry an input pulse to the other side once. Indicate when one is in flight, ignore further pulses while busy, and clear the outputs on reset.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

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
