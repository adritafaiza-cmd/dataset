# JasperGold CDC run: isochronous_spill_register
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/isochronous_spill_register/jasper/run.tcl

set TOP      isochronous_spill_register
set BENCH_DIR $env(DS)/benchmarks/isochronous_spill_register
set SDC_FILE $BENCH_DIR/constraints/isochronous_spill_register.sdc
set RPT_DIR  $env(DS)/build/jasper/isochronous_spill_register

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/isochronous_spill_register.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock src_clk_i
clock dst_clk_i
config_rtlds -reset -async src_rst_ni -polarity low
config_rtlds -reset -async dst_rst_ni -polarity low
config_rtlds -port \
    {src_rst_ni src_valid_i src_ready_o src_data_i} \
    -clock src_clk_i
config_rtlds -port \
    {dst_rst_ni dst_valid_o dst_ready_i dst_data_o} \
    -clock dst_clk_i

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
