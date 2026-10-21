Please act as a professional Verilog designer.

Implement a 16550-compatible UART with a Wishbone slave.

The reset is active-high.

Provide a UART with its Wishbone registers, serial interface, modem signals, and interrupt behavior. Reset should leave it idle.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module uart_top	(
	wb_clk_i,
	wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i,
	int_o,
	stx_pad_o, srx_pad_i,
	rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
	);
