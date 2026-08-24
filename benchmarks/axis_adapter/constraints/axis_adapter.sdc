#############################################################################
# Timing/CDC constraints for axis_adapter (verilog-axis)
# SINGLE clock domain: no asynchronous clock-port pair.
#   Clock : clk  (reset rst, active-high, sync)
# Width adapter. Single-clock AXI-Stream; no CDC ports.
# Periods are illustrative. Jasper uses the declared clock, not the period.
#############################################################################

create_clock -name clk -period 10.000 [get_ports clk]
