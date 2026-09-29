Please act as a professional Verilog designer.

Implement a destination-clock bit synchronizer with edge detect.

Please take care as serial_i enters the clk_i domain. The reset is active-low.

Bring the incoming bit into the local clock domain and give a short indication when it rises or falls, when enabled.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module sync_wedge #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output r_edge_o,
    output f_edge_o,
    output serial_o
);
