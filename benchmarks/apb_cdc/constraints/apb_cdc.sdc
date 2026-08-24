#############################################################################
# CDC constraints for apb_cdc (pulp-platform)
# TWO asynchronous clock domains (src/dst PCLK). Crossing: req/resp FIFOs.
#############################################################################

create_clock -name src_pclk_i -period 10.000 [get_ports src_pclk_i]
create_clock -name dst_pclk_i -period 14.000 [get_ports dst_pclk_i]

set_clock_groups -asynchronous \
    -group {src_pclk_i} \
    -group {dst_pclk_i}
