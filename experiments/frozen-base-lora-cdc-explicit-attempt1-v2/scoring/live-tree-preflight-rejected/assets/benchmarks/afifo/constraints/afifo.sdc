#############################################################################
# CDC constraints for afifo (zipcpu-wb2axip)
# TWO asynchronous clock domains (write / read).
#############################################################################

create_clock -name i_wclk -period 10.000 [get_ports i_wclk]
create_clock -name i_rclk -period 14.000 [get_ports i_rclk]

set_clock_groups -asynchronous \
    -group {i_wclk} \
    -group {i_rclk}
