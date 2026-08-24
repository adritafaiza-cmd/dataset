#############################################################################
# CDC constraints for spi_master_slave (OpenCores spi_master_slave)
# TWO asynchronous clock domains -> real clock-domain crossing.
#   Domain A clock : sclk_i  (reset rst_i, active-high, sync)
#   Domain B clock : pclk_i  (reset rst_i, active-high, sync)
# Crossing: serial SPI domain (sclk_i) <-> parallel register domain (pclk_i)
# Periods illustrative and unrelated; -asynchronous defines the crossing.
#############################################################################

create_clock -name sclk_i -period 10.000 [get_ports sclk_i]
create_clock -name pclk_i -period 14.000 [get_ports pclk_i]

set_clock_groups -asynchronous \
    -group {sclk_i} \
    -group {pclk_i}
