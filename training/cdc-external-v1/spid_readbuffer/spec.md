Please act as a professional Verilog designer.

Implement Move SPI read-buffer requests and responses between the SPI and system clock domains.

Module name:
    spid_readbuffer

Language:
    SystemVerilog

Clocks:
    clk_i: Clock input for the associated clock domain.

Resets:
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    sys_rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.

Input ports:
    clk_i: Clock input for the associated clock domain.
    rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    sys_clk_i: Clock input for the associated clock domain.
    sys_rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    sys_clr_i: Input control, event, payload, or encoded crossing signal.
    spi_mode_i: Input control, event, payload, or encoded crossing signal.
    current_address_i: Input control, event, payload, or encoded crossing signal.
    threshold_i: Input control, event, payload, or encoded crossing signal.
    sfdp_hit_i: Input control, event, payload, or encoded crossing signal.
    mailbox_hit_i: Input control, event, payload, or encoded crossing signal.
    mailbox_en_i: Input control, event, payload, or encoded crossing signal.
    start_i: Input control, event, payload, or encoded crossing signal.
    address_update_i: Input control, event, payload, or encoded crossing signal.

Output ports:
    event_watermark_o: Output delivered in the receiving or local domain.
    event_flip_o: Output delivered in the receiving or local domain.

Parameters:
    None.

Behavior:
    - Preserve the req_ack, pulse_sync, bundled_data crossing mechanism and its clock-domain ownership; every transferred control or payload must remain synchronized before it is consumed.
    - Keep the source and destination handshake, pulse, toggle, Gray-code, or reset sequencing faithful to the interface contract and do not invent a second crossing path.
    - Apply the source-defined reset behavior, including asynchronous assertion and any stated restrictions on independent domain resets.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module spid_readbuffer
  import spi_device_pkg::SramBufferAw, spi_device_pkg::FlashMode;
(
  input clk_i,
  input rst_ni,

  input sys_clk_i,
  input sys_rst_ni, // to keep the addr, bufidx, flip signals
  // Reset read buffer address tracker.
  input sys_clr_i,

  input spi_device_pkg::spi_mode_e spi_mode_i,

  input [31:0]             current_address_i,
  input [SramBufferAw-1:0] threshold_i,

  input sfdp_hit_i,
  input mailbox_hit_i,
  input mailbox_en_i,

  // start: data Output phase indicator. Either pulse or level are fine.
  input start_i,

  // The Buffer logic updates its status only at the last beat of the byte.
  // The time is when the address is updated.
  // It is expected that the address is updated at the end of beat of a byte.
  input address_update_i,

  output logic event_watermark_o,
  output logic event_flip_o
);
