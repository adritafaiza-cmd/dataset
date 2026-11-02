Please act as a professional Verilog designer.

Implement Synchronize an asynchronous clock-enable request before producing a gated clock.

Module name:
    prim_clock_gating_sync

Language:
    SystemVerilog

Clocks:
    clk_i: Clock input for the associated clock domain.
    clk_o: Clock or clock-derived domain signal.

Resets:
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.

Input ports:
    clk_i: Clock input for the associated clock domain.
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    test_en_i: Input control, event, payload, or encoded crossing signal.
    async_en_i: Input control, event, payload, or encoded crossing signal.

Output ports:
    en_o: Output delivered in the receiving or local domain.
    clk_o: Clock or clock-derived domain signal.

Parameters:
    None.

Behavior:
    - Preserve the level_sync crossing mechanism and its clock-domain ownership; every transferred control or payload must remain synchronized before it is consumed.
    - Keep the source and destination handshake, pulse, toggle, Gray-code, or reset sequencing faithful to the interface contract and do not invent a second crossing path.
    - Apply the source-defined reset behavior, including asynchronous assertion and any stated restrictions on independent domain resets.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_clock_gating_sync (
  input        clk_i,
  input        rst_ni,
  input        test_en_i,
  input        async_en_i,
  output logic en_o,
  output logic clk_o
);
