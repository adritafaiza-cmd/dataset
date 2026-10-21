Please act as a professional Verilog designer.

Implement a 16550-compatible UART with a Wishbone slave.

Module name:
    uart_top

Language:
    Verilog-2001

Clocks:
    wb_clk_i: Single clock.

Resets:
    wb_rst_i: active-high.

Input ports:
    wb_clk_i: Clock.
    wb_rst_i: Active-high reset.
    wb_adr_i: See Behavior.
    wb_dat_i: See Behavior.
    wb_we_i: See Behavior.
    wb_stb_i: See Behavior.
    wb_cyc_i: See Behavior.
    wb_sel_i: See Behavior.
    srx_pad_i: See Behavior.
    cts_pad_i: See Behavior.
    dsr_pad_i: See Behavior.
    ri_pad_i: See Behavior.
    dcd_pad_i: See Behavior.

Output ports:
    wb_dat_o: See Behavior.
    wb_ack_o: See Behavior.
    int_o: See Behavior.
    stx_pad_o: See Behavior.
    rts_pad_o: See Behavior.
    dtr_pad_o: See Behavior.

Parameters:
    None.

Behavior:
    - The top module name is uart_top.
    - Implement Wishbone slave registers, serial stx_pad_o / srx_pad_i, modem pins, and int_o.
    - Register, baud, and FIFO behavior must match a conventional 16550 so the testbench can program and loop back data.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module uart_top	(
	wb_clk_i,
	wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i,
	int_o,
	stx_pad_o, srx_pad_i,
	rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
	);
