#############################################################################
# CDC constraints for isochronous_spill_register (pulp-platform)
# Isochronous clocks: dst is a generated divide-by-2 of src. No async group.
#############################################################################

create_clock -name src_clk_i -period 10.000 [get_ports src_clk_i]
create_generated_clock -name dst_clk_i -source [get_ports src_clk_i] -divide_by 2 [get_ports dst_clk_i]
