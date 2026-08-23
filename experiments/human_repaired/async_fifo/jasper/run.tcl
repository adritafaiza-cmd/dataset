set TOP      async_fifo
set RTL_FILE $env(DS)/experiments/human_repaired/async_fifo/generated/async_fifo.v
set SDC_FILE $env(DS)/benchmarks/async_fifo/constraints/async_fifo.sdc
set RPT_DIR  $env(DS)/build/jasper/eval/human_repaired/async_fifo

file mkdir $RPT_DIR
clear -all
analyze -v2k $RTL_FILE
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
puts "\[cdc_run\] $TOP human_repaired: $RPT_DIR"
