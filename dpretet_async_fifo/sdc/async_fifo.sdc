#############################################################################
# CDC constraints for async_fifo (dpretet_async_fifo)
# TWO asynchronous clock domains -> real clock-domain crossing.
#   Write domain clock : wclk  (reset wrst_n, active-low, async)
#   Read  domain clock : rclk  (reset rrst_n, active-low, async)
# Crossing: gray-coded read/write pointers synchronized across domains
#           (sync_r2w, sync_w2r) + dual-clock RAM (fifomem).
# Periods illustrative and unrelated; -asynchronous defines the crossing.
#############################################################################

create_clock -name wclk -period 10.000 [get_ports wclk]
create_clock -name rclk -period 14.000 [get_ports rclk]

set_clock_groups -asynchronous \
    -group {wclk} \
    -group {rclk}
