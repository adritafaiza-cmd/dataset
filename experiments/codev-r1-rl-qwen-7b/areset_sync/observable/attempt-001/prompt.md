Please act as a professional Verilog designer.

Implement a destination-clock reset-release synchronizer.

Please take care when async_rst_i is released into the clk domain.

Make reset assert promptly but release cleanly with the destination clock, respecting the configured depth.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module areset_sync #(
    parameter STAGES = 2
)(
    input  clk,
    input  async_rst_i,
    output sync_rst_o
);
