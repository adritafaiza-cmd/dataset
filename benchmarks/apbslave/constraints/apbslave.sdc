#############################################################################
# Timing/CDC constraints for apbslave (ZipCPU wb2axip)
# SINGLE clock domain: no asynchronous clock-port pair.
#   Clock : PCLK  (reset PRESETn, active-low, async)
# Demonstration APB slave memory. Single-clock; no CDC ports.
# Periods are illustrative. Jasper uses the declared clock, not the period.
#############################################################################

create_clock -name PCLK -period 10.000 [get_ports PCLK]
