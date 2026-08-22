#############################################################################
# CDC constraints for async_bidir_fifo (dpretet_async_fifo)
# TWO asynchronous clock domains -> real clock-domain crossing.
#   A-side domain clock : a_clk  (reset a_rst_n, active-low, async)
#   B-side domain clock : b_clk  (reset b_rst_n, active-low, async)
# Bidirectional gray-coded pointer synchronization between the two domains.
# Periods illustrative and unrelated; -asynchronous defines the crossing.
#############################################################################

create_clock -name a_clk -period 10.000 [get_ports a_clk]
create_clock -name b_clk -period 14.000 [get_ports b_clk]

set_clock_groups -asynchronous \
    -group {a_clk} \
    -group {b_clk}
