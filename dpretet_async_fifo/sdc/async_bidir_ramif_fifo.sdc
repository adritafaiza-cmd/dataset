#############################################################################
# CDC constraints for async_bidir_ramif_fifo (dpretet_async_fifo)
# TWO asynchronous clock domains -> real clock-domain crossing.
#   A-side domain clock : a_clk  (reset a_rst_n, active-low, async)
#   B-side domain clock : b_clk  (reset b_rst_n, active-low, async)
# Same as async_bidir_fifo but with an external dual-port RAM interface.
# NOTE: o_ram_a_clk / o_ram_b_clk are OUTPUT clocks (driven from a_clk/b_clk)
#       to the external RAM; the two primary domain clocks are a_clk and b_clk.
# Periods illustrative and unrelated; -asynchronous defines the crossing.
#############################################################################

create_clock -name a_clk -period 10.000 [get_ports a_clk]
create_clock -name b_clk -period 14.000 [get_ports b_clk]

create_generated_clock -name o_ram_a_clk \
    -source [get_ports a_clk] \
    -divide_by 1 \
    [get_ports o_ram_a_clk]

create_generated_clock -name o_ram_b_clk \
    -source [get_ports b_clk] \
    -divide_by 1 \
    [get_ports o_ram_b_clk]

set_clock_groups -asynchronous \
    -group {a_clk o_ram_a_clk} \
    -group {b_clk o_ram_b_clk}
