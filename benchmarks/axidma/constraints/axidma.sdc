#############################################################################
# Timing/CDC constraints for axidma (ZipCPU wb2axip)
# SINGLE clock domain: no asynchronous clock-port pair.
#   Clock : S_AXI_ACLK  (reset S_AXI_ARESETN, active-low, async)
# Memory-to-memory AXI DMA plus AXI-lite control. Single-clock; no CDC ports.
# Periods are illustrative. Jasper uses the declared clock, not the period.
#############################################################################

create_clock -name S_AXI_ACLK -period 10.000 [get_ports S_AXI_ACLK]
