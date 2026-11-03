#############################################################################
# CDC constraints for axis_async_fifo_adapter (verilog_axis)
# TWO asynchronous clock domains -> real clock-domain crossing.
#   Slave (input)  domain clock : s_clk  (reset s_rst, active-HIGH, sync)
#   Master (output) domain clock: m_clk  (reset m_rst, active-HIGH, sync)
# axis_async_fifo + width adapters; crossing is inside the async FIFO.
# Periods illustrative and unrelated; -asynchronous defines the crossing.
#############################################################################

create_clock -name s_clk -period 10.000 [get_ports s_clk]
create_clock -name m_clk -period 14.000 [get_ports m_clk]

set_clock_groups -asynchronous \
    -group {s_clk} \
    -group {m_clk}
