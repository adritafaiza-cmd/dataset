#############################################################################
# Timing/CDC constraints for uart16550 (OpenCores)
# Port clock: wb_clk_i (reset wb_rst_i, active-high, async).
# The 16x baud tick is generated inside uart_regs from wb_clk_i. It is not a
# top-level clock port unless UART_HAS_BAUDRATE_OUTPUT is defined.
# TX/RX FIFOs and the bit sampler therefore share one declared clock; treat
# any inferred baud divider as a generated clock of wb_clk_i if Jasper asks.
# Periods are illustrative.
#############################################################################

create_clock -name wb_clk_i -period 10.000 [get_ports wb_clk_i]
