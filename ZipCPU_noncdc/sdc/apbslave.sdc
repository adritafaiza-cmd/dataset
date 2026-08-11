#############################################################################
# Timing/CDC constraints for apbslave
# SINGLE clock domain -> no clock-domain crossing in this design.
#   Clock : PCLK    Reset : PRESETn (active-low, sync)
# Provided for completeness; a CDC run should report no crossings here.
#############################################################################

create_clock -name pclk -period 10.000 [get_ports PCLK]
