Please act as a professional Verilog designer.

Implement a single-bit destination-clock synchronizer.

Please take care as async_sig_i enters the clk domain. The reset is active-low.

Bring the asynchronous bit into the local clock domain with the configured depth. Reset should leave its output low.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module synchronizer #(
    parameter STAGES = 2
)(
    input  clk,
    input  rstn,
    input  async_sig_i,
    output sync_sig_o
);
