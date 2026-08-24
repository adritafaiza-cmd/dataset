#############################################################################
# CDC constraints for data_sync (tweak_circuits)
# SINGLE clock domain. din/dready_i are asynchronous data inputs.
#############################################################################

create_clock -name clk -period 10.000 [get_ports clk]
