# JasperGold CDC run: edge_propagator
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/edge_propagator/jasper/run.tcl

set TOP      edge_propagator
set BENCH_DIR $env(DS)/benchmarks/edge_propagator
set SDC_FILE $BENCH_DIR/constraints/edge_propagator.sdc
set RPT_DIR  $env(DS)/build/jasper/edge_propagator

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/edge_propagator.sv \
    $BENCH_DIR/fixed/rtl/edge_propagator_ack.sv \
    $BENCH_DIR/fixed/rtl/pulp_sync_wedge.sv \
    $BENCH_DIR/fixed/rtl/pulp_sync.sv \
    $BENCH_DIR/tb/pulp_clock_gating.sv
]

file mkdir $RPT_DIR
clear -all
analyze -sv12 {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock clk_tx_i
clock clk_rx_i
config_rtlds -reset -async rstn_tx_i -polarity low
config_rtlds -reset -async rstn_rx_i -polarity low
config_rtlds -port \
    {rstn_tx_i edge_i} \
    -clock clk_tx_i
config_rtlds -port \
    {rstn_rx_i edge_o} \
    -clock clk_rx_i

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
