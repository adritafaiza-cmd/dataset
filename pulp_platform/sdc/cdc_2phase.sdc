#############################################################################
# CDC constraints for cdc_2phase (pulp_platform)
# TWO asynchronous clock domains -> real clock-domain crossing.
#   Source domain clock : src_clk_i  (reset src_rst_ni, active-low, async)
#   Dest   domain clock : dst_clk_i  (reset dst_rst_ni, active-low, async)
# Crossing: 2-phase (req/ack toggle) handshake over async_req/async_ack/async_data.
# Periods illustrative and unrelated; -asynchronous defines the crossing.
#############################################################################

create_clock -name src_clk -period 10.000 [get_ports src_clk_i]
create_clock -name dst_clk -period 14.000 [get_ports dst_clk_i]

set_clock_groups -asynchronous \
    -group {src_clk} \
    -group {dst_clk}
