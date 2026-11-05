#############################################################################
# CDC constraints for edge_propagator (pulp common_cells)
# TWO asynchronous clock domains -> real clock-domain crossing.
#   Domain A clock : clk_tx_i  (reset rstn_tx_i, active-low, async)
#   Domain B clock : clk_rx_i  (reset rstn_rx_i, active-low, async)
# Crossing: pulse/edge propagator (toggle + 2-FF + wedge detect)
# Periods illustrative and unrelated; -asynchronous defines the crossing.
#############################################################################

create_clock -name clk_tx -period 10.000 [get_ports clk_tx_i]
create_clock -name clk_rx -period 14.000 [get_ports clk_rx_i]

set_clock_groups -asynchronous \
    -group {clk_tx} \
    -group {clk_rx}
