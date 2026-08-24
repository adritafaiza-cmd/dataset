#############################################################################
# Timing/CDC constraints for sync_multistage (pulp common_cells)
# SINGLE clock domain: no asynchronous clock-port pair.
#   Clock : clk_i  (reset rst_ni, active-low, async)
# Same sync cell with STAGES=4. serial_i is an asynchronous data input, not a clock.
# Periods are illustrative. Jasper uses the declared clock, not the period.
#############################################################################

create_clock -name clk_i -period 10.000 [get_ports clk_i]
