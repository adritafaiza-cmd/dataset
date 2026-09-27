Please act as a professional Verilog designer.

Implement a reset generator that releases a synchronized reset in clk_i.

Please take care when rst_ni is released into the clk_i domain. The reset is active-low.

Generate the active-low reset and initialization indication for the local clock. Honor the test-mode bypass when enabled.

Give me the complete SystemVerilog code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);
