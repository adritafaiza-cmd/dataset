#############################################################################
# Timing/CDC constraints for sfifo
# SINGLE clock domain (synchronous FIFO) -> no clock-domain crossing.
#   Clock : i_clk    Reset : i_reset (active-HIGH, sync)
# Provided for completeness; a CDC run should report no crossings here.
#############################################################################

create_clock -name i_clk -period 10.000 [get_ports i_clk]
