# JasperGold CDC run: async_fifo
# Run: setenv DS /path/to/dataset; jg -batch $DS/benchmarks/async_fifo/jasper/run.tcl
set TOP async_fifo
set BENCH_DIR $env(DS)/benchmarks/async_fifo
set RTL_DIR $BENCH_DIR/fixed/rtl
set SDC_FILE $BENCH_DIR/constraints/async_fifo.sdc
set RPT_DIR $env(DS)/build/jasper/async_fifo
set RTL_FILES [list $RTL_DIR/async_fifo.v $RTL_DIR/sync_r2w.v $RTL_DIR/sync_w2r.v $RTL_DIR/wptr_full.v $RTL_DIR/rptr_empty.v $RTL_DIR/fifomem.v]
file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -bbox_a 50000 -top $TOP
read_sdc $SDC_FILE
check_cdc -init
clock wclk
clock rclk
config_rtlds -reset -async {wrst_n rrst_n} -polarity low
config_rtlds -port {winc wdata wfull awfull} -clock wclk
config_rtlds -port {rinc rdata rempty arempty} -clock rclk
check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
