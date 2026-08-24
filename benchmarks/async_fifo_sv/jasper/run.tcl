# JasperGold CDC run: async_fifo_sv
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/async_fifo_sv/jasper/run.tcl

set TOP      async_fifo
set BENCH_DIR $env(DS)/benchmarks/async_fifo_sv
set SDC_FILE $BENCH_DIR/constraints/async_fifo_sv.sdc
set RPT_DIR  $env(DS)/build/jasper/async_fifo_sv

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/async_fifo.sv \
    $BENCH_DIR/fixed/rtl/fifomem.sv \
    $BENCH_DIR/fixed/rtl/rptr_empty.sv \
    $BENCH_DIR/fixed/rtl/wptr_full.sv \
    $BENCH_DIR/fixed/rtl/sync_r2w.sv \
    $BENCH_DIR/fixed/rtl/sync_w2r.sv
]

file mkdir $RPT_DIR
clear -all
analyze -sv12 {*}$RTL_FILES
elaborate -bbox_a 50000 -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock wclk
clock rclk
# Coordinated POR assertion lives on common_rst_n; each domain deasserts locally.
config_rtlds -reset -async common_rst_n -polarity low
config_rtlds -port \
    {wrst_n winc wdata wfull waddr} \
    -clock wclk
config_rtlds -port \
    {rrst_n rinc rdata rempty raddr} \
    -clock rclk

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
