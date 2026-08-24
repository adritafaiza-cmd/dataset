# JasperGold CDC run: cdc_reset_ctrlr
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/cdc_reset_ctrlr/jasper/run.tcl

set TOP      cdc_reset_ctrlr
set BENCH_DIR $env(DS)/benchmarks/cdc_reset_ctrlr
set SDC_FILE $BENCH_DIR/constraints/cdc_reset_ctrlr.sdc
set RPT_DIR  $env(DS)/build/jasper/cdc_reset_ctrlr

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/cdc_reset_ctrlr.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock a_clk_i
clock b_clk_i
config_rtlds -reset -async a_rst_ni -polarity low
config_rtlds -reset -async b_rst_ni -polarity low
config_rtlds -port \
    {a_rst_ni a_clear_i a_clear_o a_clear_ack_i \
     a_isolate_o a_isolate_ack_i} \
    -clock a_clk_i
config_rtlds -port \
    {b_rst_ni b_clear_i b_clear_o b_clear_ack_i \
     b_isolate_o b_isolate_ack_i} \
    -clock b_clk_i

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
