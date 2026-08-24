#############################################################################
# CDC constraints for areset_deassert_sync (tweak_circuits)
# SINGLE clock domain. async_rst_i is an RDC, not a second clock.
#############################################################################

create_clock -name clk -period 10.000 [get_ports clk]
