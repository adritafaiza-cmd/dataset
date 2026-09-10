Please act as a professional Verilog designer.

Implement a destination-clock reset synchronizer.

Module name:
    sync_reset

Language:
    Verilog-2001

Clocks:
    clk: Single clock.

Resets:
    rst: active-high.

Input ports:
    clk: Clock.
    rst: Active-high reset.

Output ports:
    out: See Behavior.

Parameters:
    N: Implementation depth or word width, as used by the module.

Behavior:
    - out asserts with rst and deasserts only after a safe number of clk edges.
    - N is the pipeline depth.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);
