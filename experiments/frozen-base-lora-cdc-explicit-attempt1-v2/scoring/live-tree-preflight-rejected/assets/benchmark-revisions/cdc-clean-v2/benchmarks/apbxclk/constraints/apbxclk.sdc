#############################################################################
# CDC constraints for apbxclk
# TWO asynchronous clock domains -> real clock-domain crossing present.
#   Slave  domain clock : S_APB_PCLK   (reset S_PRESETn, active-low, async)
#   Master domain clock : M_APB_PCLK   (reset M_PRESETn is generated in-core)
# Periods are illustrative and unrelated; -asynchronous is what defines the
# crossing for the CDC engine (exact numbers do not matter for CDC).
#############################################################################

create_clock -name s_apb_pclk -period 10.000 [get_ports S_APB_PCLK]
create_clock -name m_apb_pclk -period 14.000 [get_ports M_APB_PCLK]

set_clock_groups -asynchronous \
    -group {s_apb_pclk} \
    -group {m_apb_pclk}
