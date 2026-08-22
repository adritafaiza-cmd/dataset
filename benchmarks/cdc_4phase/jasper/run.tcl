# JasperGold CDC run: cdc_4phase (pulp_platform)
# Run (tcsh):
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/cdc_4phase/jasper/run.tcl

set TOP      cdc_4phase
set RTL_FILE $env(DS)/benchmarks/cdc_4phase/fixed/rtl/cdc_4phase.v
set SDC_FILE $env(DS)/benchmarks/cdc_4phase/constraints/cdc_4phase.sdc
set RPT_DIR  $env(DS)/build/jasper/cdc_4phase

file mkdir $RPT_DIR

clear -all
analyze -v2k $RTL_FILE
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock src_clk_i
clock dst_clk_i

# Effective common asynchronous reset source. Reset release is synchronized
# independently to src_clk_i and dst_clk_i inside the wrapper.
config_rtlds -reset -async common_rst_ni -polarity low

config_rtlds -port \
    {src_rst_ni src_data_i src_valid_i src_ready_o} \
    -clock src_clk_i
config_rtlds -port \
    {dst_rst_ni dst_data_o dst_valid_o dst_ready_i} \
    -clock dst_clk_i

check_cdc -extract

check_cdc -list clock_signals \
    -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets \
    -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets \
    -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings \
    -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed \
    -file $RPT_DIR/cdc_report.rpt -force

puts "======================================================================"
puts "\[cdc_run\] $TOP: done."
puts "  Declared (SDC)  : $SDC_FILE"
puts "  Inferred clocks : $RPT_DIR/inferred_clocks.rpt"
puts "  Inferred resets : $RPT_DIR/inferred_resets.rpt"
puts "  CDC crossings   : $RPT_DIR/cdc_crossings.rpt"
puts "  CDC violations  : $RPT_DIR/cdc_report.rpt"
puts "======================================================================"
