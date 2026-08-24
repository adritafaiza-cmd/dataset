#############################################################################
# CDC constraints for sync_wedge (pulp-platform)
# SINGLE clock domain. serial_i is an asynchronous data input, not a clock.
#############################################################################

create_clock -name clk_i -period 10.000 [get_ports clk_i]
