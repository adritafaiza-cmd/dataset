Please act as a professional Verilog designer.

Implement a reset generator that releases a synchronized reset in clk_i.

Module name:
    rstgen

Language:
    SystemVerilog

Clocks:
    clk_i: Single clock.

Resets:
    rst_ni: active-low.

Input ports:
    clk_i: Clock.
    rst_ni: Active-low reset.
    test_mode_i: See Behavior.

Output ports:
    rst_no: Active-low reset.
    init_no: See Behavior.

Parameters:
    None.

Behavior:
    - rst_no is the synchronized active-low reset output.
    - init_no is a short initialization qualifier after reset release.
    - test_mode_i bypasses synchronization for scan/test when high.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);
