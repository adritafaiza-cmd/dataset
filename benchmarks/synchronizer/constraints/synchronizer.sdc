#############################################################################
# CDC constraints for synchronizer (tweak_circuits)
# SINGLE clock domain. async_sig_i is an asynchronous data input.
#############################################################################

create_clock -name clk -period 10.000 [get_ports clk]
