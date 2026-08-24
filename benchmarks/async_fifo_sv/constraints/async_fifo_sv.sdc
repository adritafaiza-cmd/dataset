#############################################################################
# CDC constraints for async_fifo_sv (dianluniuniu async-fifo)
# TWO asynchronous clock domains -> real clock-domain crossing.
#   Domain A clock : wclk  (reset wrst_n, active-low, async)
#   Domain B clock : rclk  (reset rrst_n, active-low, async)
# Crossing: Gray-coded write/read pointers through 2-FF synchronizers + dual-clock RAM
# Periods illustrative and unrelated; -asynchronous defines the crossing.
#############################################################################

create_clock -name wclk -period 10.000 [get_ports wclk]
create_clock -name rclk -period 14.000 [get_ports rclk]

set_clock_groups -asynchronous \
    -group {wclk} \
    -group {rclk}
