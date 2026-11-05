#############################################################################
# Timing/CDC constraints for areset_sync (tweak_circuits)
# SINGLE clock domain: no asynchronous clock-port pair.
#   Clock : clk  (reset async_rst_i, active-high, async)
# async_rst_i is synchronized onto clk. This is an RDC, not a second clock domain.
# Periods are illustrative. Jasper uses the declared clock, not the period.
#############################################################################

create_clock -name clk -period 10.000 [get_ports clk]
