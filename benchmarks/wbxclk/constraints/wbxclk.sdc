#############################################################################
# CDC constraints for wbxclk
# TWO asynchronous clock domains -> real clock-domain crossing present.
#   Wishbone domain clock : i_wb_clk    (reset i_reset, active-HIGH, sync)
#   Crossed  domain clock : i_xclk_clk  (crossed reset generated in-core)
# Crossing is implemented via afifo (gray-coded async FIFOs) + reset sync.
# Periods are illustrative and unrelated; -asynchronous defines the crossing.
#############################################################################

create_clock -name i_wb_clk   -period 10.000 [get_ports i_wb_clk]
create_clock -name i_xclk_clk -period 14.000 [get_ports i_xclk_clk]

set_clock_groups -asynchronous \
    -group {i_wb_clk} \
    -group {i_xclk_clk}
