Please act as a professional Verilog designer.

Implement Convert edges of a slow clock into a controlled pulse in a faster manager clock domain.

Module name:
    pwrmgr_cdc_pulse

Language:
    SystemVerilog

Clocks:
    clk_slow_i: Clock input for the associated clock domain.
    clk_i: Clock input for the associated clock domain.

Resets:
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    rst_slow_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.

Input ports:
    clk_slow_i: Clock input for the associated clock domain.
    clk_i: Clock input for the associated clock domain.
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    rst_slow_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    start_i: Input control, event, payload, or encoded crossing signal.
    stop_i: Input control, event, payload, or encoded crossing signal.

Output ports:
    pulse_o: Output delivered in the receiving or local domain.

Parameters:
    None.

Behavior:
    - Preserve the toggle_sync, pulse_sync crossing mechanism and its clock-domain ownership; every transferred control or payload must remain synchronized before it is consumed.
    - Keep the source and destination handshake, pulse, toggle, Gray-code, or reset sequencing faithful to the interface contract and do not invent a second crossing path.
    - Apply the source-defined reset behavior, including asynchronous assertion and any stated restrictions on independent domain resets.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module pwrmgr_cdc_pulse (
  input clk_slow_i,
  input clk_i,
  input rst_ni,
  input rst_slow_ni,
  input start_i,
  input stop_i,
  output logic pulse_o
);
