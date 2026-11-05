#############################################################################
# CDC constraints for sync_reset (verilog-axis)
# SINGLE clock domain. rst is an asynchronous reset input, not a clock.
#############################################################################

create_clock -name clk -period 10.000 [get_ports clk]
