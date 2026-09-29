Please act as a professional Verilog designer.

Implement a two-domain isolate-then-clear reset controller.

a_clk_i and b_clk_i are independent clocks. Please take care of any clock-domain crossings between them. The resets are active-low.

When either side requests a clear, isolate both sides before clearing either of them; wait for both acknowledgments at each step before releasing them.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  a_clear_i,
    output a_clear_o,
    input  a_clear_ack_i,
    output a_isolate_o,
    input  a_isolate_ack_i,
    input  b_clk_i,
    input  b_rst_ni,
    input  b_clear_i,
    output b_clear_o,
    input  b_clear_ack_i,
    output b_isolate_o,
    input  b_isolate_ack_i
);
