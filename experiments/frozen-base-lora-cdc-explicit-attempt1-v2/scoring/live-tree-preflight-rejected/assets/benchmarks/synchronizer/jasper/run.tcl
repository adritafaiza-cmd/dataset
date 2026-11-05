# JasperGold CDC run: synchronizer
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/synchronizer/jasper/run.tcl

set TOP      synchronizer
set BENCH_DIR $env(DS)/benchmarks/synchronizer
set SDC_FILE $BENCH_DIR/constraints/synchronizer.sdc
set RPT_DIR  $env(DS)/build/jasper/synchronizer

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/synchronizer.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock clk
config_rtlds -reset -sync rstn -clock clk -polarity low
config_rtlds -port \
    {rstn async_sig_i sync_sig_o} \
    -clock clk

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
