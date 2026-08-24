# JasperGold CDC run: afifo
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/afifo/jasper/run.tcl

set TOP      afifo
set BENCH_DIR $env(DS)/benchmarks/afifo
set SDC_FILE $BENCH_DIR/constraints/afifo.sdc
set RPT_DIR  $env(DS)/build/jasper/afifo

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/afifo.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -bbox_a 50000 -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock i_wclk
clock i_rclk
config_rtlds -reset -async i_wr_reset_n -polarity low
config_rtlds -reset -async i_rd_reset_n -polarity low
config_rtlds -port \
    {i_wr_reset_n i_wr i_wr_data o_wr_full} \
    -clock i_wclk
config_rtlds -port \
    {i_rd_reset_n i_rd o_rd_data o_rd_empty} \
    -clock i_rclk

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
