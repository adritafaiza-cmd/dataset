# JasperGold CDC run: areset_sync
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/areset_sync/jasper/run.tcl

set TOP      areset_sync
set BENCH_DIR $env(DS)/benchmarks/areset_sync
set SDC_FILE $BENCH_DIR/constraints/areset_sync.sdc
set RPT_DIR  $env(DS)/build/jasper/areset_sync

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/areset_sync.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock clk
config_rtlds -reset -async async_rst_i -polarity high
config_rtlds -port \
    {async_rst_i sync_rst_o} \
    -clock clk

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
