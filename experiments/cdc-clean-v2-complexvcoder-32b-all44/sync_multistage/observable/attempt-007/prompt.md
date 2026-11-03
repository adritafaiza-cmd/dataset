Please act as a professional Verilog designer.

Implement a single-bit destination-clock synchronizer.

Please take care as serial_i enters the clk_i domain. The reset is active-low.

Bring the asynchronous input into the local clock domain, respecting the configured depth and reset value.

Give me the complete SystemVerilog code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module sync #(
    parameter int unsigned STAGES = 2,
    parameter bit ResetValue = 1'b0
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
);
