#############################################################################
# CDC constraints for pulse_sync (tweak_circuits)
# TWO asynchronous clock domains -> real clock-domain crossing.
#   Domain A clock : clk_a  (reset rstn_a, active-low, sync in RTL)
#   Domain B clock : clk_b  (reset rstn_b, active-low, sync in RTL)
# Crossing: handshake/toggle pulse synchronizer (fast-to-slow event)
# Periods illustrative and unrelated; -asynchronous defines the crossing.
#############################################################################

create_clock -name clk_a -period 10.000 [get_ports clk_a]
create_clock -name clk_b -period 14.000 [get_ports clk_b]

set_clock_groups -asynchronous \
    -group {clk_a} \
    -group {clk_b}
