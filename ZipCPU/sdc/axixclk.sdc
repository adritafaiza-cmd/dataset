#############################################################################
# CDC constraints for axixclk
# TWO asynchronous clock domains -> real clock-domain crossing present.
#   Slave  domain clock : S_AXI_ACLK   (reset S_AXI_ARESETN, active-low, async)
#   Master domain clock : M_AXI_ACLK   (reset M_AXI_ARESETN is generated in-core)
# Crossing is implemented via afifo (gray-coded async FIFOs) + reset sync.
# Periods are illustrative and unrelated; -asynchronous defines the crossing.
#############################################################################

create_clock -name s_axi_aclk -period 10.000 [get_ports S_AXI_ACLK]
create_clock -name m_axi_aclk -period 14.000 [get_ports M_AXI_ACLK]

set_clock_groups -asynchronous \
    -group {s_axi_aclk} \
    -group {m_axi_aclk}
