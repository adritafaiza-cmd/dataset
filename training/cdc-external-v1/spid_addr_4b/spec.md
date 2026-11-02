Please act as a professional Verilog designer.

Implement Exchange a four-byte address-mode update between system and SPI clock domains.

Module name:
    spid_addr_4b

Language:
    SystemVerilog

Clocks:
    spi_clk_i: Clock input for the associated clock domain.

Resets:
    sys_rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.

Input ports:
    sys_clk_i: Clock input for the associated clock domain.
    sys_rst_ni: Reset or reset-control signal; polarity follows the _ni/_no naming and source declaration.
    spi_clk_i: Clock input for the associated clock domain.
    cmd_sync_pulse_i: Input control, event, payload, or encoded crossing signal.
    reg2hw_addr_mode_addr_4b_en_q_i: Input control, event, payload, or encoded crossing signal.
    reg2hw_addr_mode_addr_4b_en_qe_i: Input control, event, payload, or encoded crossing signal.
    spi_addr_4b_set_i: Input control, event, payload, or encoded crossing signal.
    spi_addr_4b_clr_i: Input control, event, payload, or encoded crossing signal.

Output ports:
    hw2reg_addr_mode_pending_d_o: Output delivered in the receiving or local domain.
    hw2reg_addr_mode_addr_4b_en_d_o: Output delivered in the receiving or local domain.
    spi_cfg_addr_4b_en_o: Output delivered in the receiving or local domain.
    cmd_sync_cfg_addr_4b_en_o: Output delivered in the receiving or local domain.

Parameters:
    None.

Behavior:
    - Preserve the req_ack, level_sync, bundled_data crossing mechanism and its clock-domain ownership; every transferred control or payload must remain synchronized before it is consumed.
    - Keep the source and destination handshake, pulse, toggle, Gray-code, or reset sequencing faithful to the interface contract and do not invent a second crossing path.
    - Apply the source-defined reset behavior, including asynchronous assertion and any stated restrictions on independent domain resets.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module spid_addr_4b (
  input sys_clk_i,
  input sys_rst_ni,

  input spi_clk_i,

  input cmd_sync_pulse_i,

  input        reg2hw_addr_mode_addr_4b_en_q_i,  // registered input
  input        reg2hw_addr_mode_addr_4b_en_qe_i, // SYS has originated a change
  output logic hw2reg_addr_mode_pending_d_o,
  output logic hw2reg_addr_mode_addr_4b_en_d_o,

  output logic spi_cfg_addr_4b_en_o, // broadcast
  output logic cmd_sync_cfg_addr_4b_en_o, // early output for cmdfifo

  input spi_addr_4b_set_i, // EN4B command
  input spi_addr_4b_clr_i  // EX4B command
);
