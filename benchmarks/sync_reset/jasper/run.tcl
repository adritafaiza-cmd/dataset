# JasperGold CDC run: sync_reset
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/sync_reset/jasper/run.tcl

set TOP      sync_reset
set BENCH_DIR $env(DS)/benchmarks/sync_reset
set SDC_FILE $BENCH_DIR/constraints/sync_reset.sdc
set RPT_DIR  $env(DS)/build/jasper/sync_reset

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/sync_reset.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock clk
config_rtlds -reset -async rst -polarity high
config_rtlds -port \
    {rst out} \
    -clock clk

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
