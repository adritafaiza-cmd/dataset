Please act as a professional Verilog designer.

Implement a two-domain isolate-then-clear reset controller.

Module name:
    cdc_reset_ctrlr

Language:
    Verilog-2001

Clocks:
    a_clk_i: Independent asynchronous clock (async to b_clk_i).
    b_clk_i: Independent asynchronous clock (async to a_clk_i).

Resets:
    a_rst_ni: active-low.
    b_rst_ni: active-low.

Input ports:
    a_clk_i: Clock.
    a_rst_ni: Active-low reset.
    a_clear_i: See Behavior.
    a_clear_ack_i: See Behavior.
    a_isolate_ack_i: See Behavior.
    b_clk_i: Clock.
    b_rst_ni: Active-low reset.
    b_clear_i: See Behavior.
    b_clear_ack_i: See Behavior.
    b_isolate_ack_i: See Behavior.

Output ports:
    a_clear_o: See Behavior.
    a_isolate_o: See Behavior.
    b_clear_o: See Behavior.
    b_isolate_o: See Behavior.

Parameters:
    SYNC_STAGES: Implementation depth parameter. Choose a safe crossing yourself.

Behavior:
    - When either side requests clear (*_clear_i), first raise both isolate outputs, wait for both isolate acks, then raise both clear outputs, wait for both clear acks, then release isolate and clear.
    - Do not leave one domain cleared while the other is still live.
    - After reset, isolate and clear outputs are inactive.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

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
