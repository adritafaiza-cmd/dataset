Please act as a professional Verilog designer.

Implement Report a filtered chip-select deassertion event in the system clock domain.

Module name:
    spid_csb_sync

Language:
    SystemVerilog

Clocks:
    clk_i: Clock input for the associated clock domain.
    sck_i: Clock input for the associated clock domain.
    csb_i: Clock input for the associated clock domain.

Resets:
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.

Input ports:
    clk_i: Clock input for the associated clock domain.
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    sck_i: Clock input for the associated clock domain.
    sck_pulse_en_i: Input control, event, payload, or encoded crossing signal.
    csb_i: Clock input for the associated clock domain.

Output ports:
    csb_deasserted_pulse_o: Output delivered in the receiving or local domain.

Parameters:
    None.

Behavior:
    - Preserve the toggle_sync, pulse_sync crossing mechanism and its clock-domain ownership; every transferred control or payload must remain synchronized before it is consumed.
    - Keep the source and destination handshake, pulse, toggle, Gray-code, or reset sequencing faithful to the interface contract and do not invent a second crossing path.
    - Apply the source-defined reset behavior, including asynchronous assertion and any stated restrictions on independent domain resets.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module spid_csb_sync (
  input clk_i,
  input rst_ni,
  input sck_i,
  input sck_pulse_en_i,
  input csb_i,
  output csb_deasserted_pulse_o
);
