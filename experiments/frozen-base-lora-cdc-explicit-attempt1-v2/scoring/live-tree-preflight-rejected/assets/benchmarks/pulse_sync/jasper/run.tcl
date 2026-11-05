# JasperGold CDC run: pulse_sync
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/pulse_sync/jasper/run.tcl

set TOP      pulse_sync
set BENCH_DIR $env(DS)/benchmarks/pulse_sync
set SDC_FILE $BENCH_DIR/constraints/pulse_sync.sdc
set RPT_DIR  $env(DS)/build/jasper/pulse_sync

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/pulse_sync.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock clk_a
clock clk_b
config_rtlds -reset -sync rstn_a -clock clk_a -polarity low
config_rtlds -reset -sync rstn_b -clock clk_b -polarity low
config_rtlds -port \
    {rstn_a pulseA_i busy_o} \
    -clock clk_a
config_rtlds -port \
    {rstn_b pulseB_o} \
    -clock clk_b

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
