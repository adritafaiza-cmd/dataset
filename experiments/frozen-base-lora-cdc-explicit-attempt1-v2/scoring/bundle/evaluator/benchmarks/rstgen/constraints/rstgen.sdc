#############################################################################
# Timing/CDC constraints for rstgen (pulp common_cells)
# SINGLE clock domain: no asynchronous clock-port pair.
#   Clock : clk_i  (reset rst_ni, active-low, async)
# rst_ni is the asynchronous reset being synchronized onto clk_i (reset-release).
# Periods are illustrative. Jasper uses the declared clock, not the period.
#############################################################################

create_clock -name clk_i -period 10.000 [get_ports clk_i]
