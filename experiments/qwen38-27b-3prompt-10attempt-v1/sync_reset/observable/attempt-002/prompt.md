Please act as a professional Verilog designer.

Implement a destination-clock reset synchronizer.

Please take care when rst is released into the clk domain. The reset is active-high.

Assert reset promptly and release the output cleanly after the configured number of local clock edges.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);
