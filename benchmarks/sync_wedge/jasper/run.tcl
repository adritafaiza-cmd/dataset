# JasperGold CDC run: sync_wedge
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/sync_wedge/jasper/run.tcl

set TOP      sync_wedge
set BENCH_DIR $env(DS)/benchmarks/sync_wedge
set SDC_FILE $BENCH_DIR/constraints/sync_wedge.sdc
set RPT_DIR  $env(DS)/build/jasper/sync_wedge

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/sync_wedge.v \
    $BENCH_DIR/fixed/rtl/sync.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock clk_i
config_rtlds -reset -async rst_ni -polarity low
config_rtlds -port \
    {rst_ni en_i serial_i r_edge_o f_edge_o serial_o} \
    -clock clk_i

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
