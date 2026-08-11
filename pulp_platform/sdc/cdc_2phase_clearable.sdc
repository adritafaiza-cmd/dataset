#############################################################################
# CDC constraints for cdc_2phase_clearable (pulp_platform)
# TWO asynchronous clock domains -> real clock-domain crossing.
#   Source domain clock : src_clk_i  (reset src_rst_ni, active-low, async)
#   Dest   domain clock : dst_clk_i  (reset dst_rst_ni, active-low, async)
# Also has synchronous clear inputs (src_clear_i/dst_clear_i) sequenced by an
# internal cdc_reset_ctrlr; treat both clocks as mutually asynchronous.
# NOTE: this module `include`s common_cells/*.svh - provide that incdir at elaborate.
#############################################################################

create_clock -name src_clk -period 10.000 [get_ports src_clk_i]
create_clock -name dst_clk -period 14.000 [get_ports dst_clk_i]

set_clock_groups -asynchronous \
    -group {src_clk} \
    -group {dst_clk}
