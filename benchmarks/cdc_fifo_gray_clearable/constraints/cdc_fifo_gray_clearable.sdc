#############################################################################
# CDC constraints for cdc_fifo_gray_clearable (pulp-platform)
# TWO asynchronous clock domains. Crossing: gray pointers plus clear request.
#############################################################################

create_clock -name src_clk_i -period 10.000 [get_ports src_clk_i]
create_clock -name dst_clk_i -period 14.000 [get_ports dst_clk_i]

set_clock_groups -asynchronous \
    -group {src_clk_i} \
    -group {dst_clk_i}
