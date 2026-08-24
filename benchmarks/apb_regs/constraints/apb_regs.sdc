#############################################################################
# Timing/CDC constraints for apb_regs (pulp apb)
# SINGLE clock domain: no asynchronous clock-port pair.
#   Clock : pclk_i  (reset preset_ni, active-low, async)
# APB register file. Single-clock APB4; no CDC ports.
# Periods are illustrative. Jasper uses the declared clock, not the period.
#############################################################################

create_clock -name pclk_i -period 10.000 [get_ports pclk_i]
