#############################################################################
# Timing/CDC constraints for axixbar
# SINGLE clock domain -> no clock-domain crossing in this design.
#   Clock : S_AXI_ACLK    Reset : S_AXI_ARESETN (active-low, sync)
# Provided for completeness; a CDC run should report no crossings here.
#############################################################################

create_clock -name s_axi_aclk -period 10.000 [get_ports S_AXI_ACLK]
