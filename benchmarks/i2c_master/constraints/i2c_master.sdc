#############################################################################
# Timing/CDC constraints for i2c_master (verilog-i2c)
# Port clock: clk (reset rst, active-high, sync).
# SCL is an open-drain I/O generated from clk (prescale divider), not a second
# unconstrained clock domain. Declare only the host clock.
# Periods are illustrative.
#############################################################################

create_clock -name clk -period 10.000 [get_ports clk]
