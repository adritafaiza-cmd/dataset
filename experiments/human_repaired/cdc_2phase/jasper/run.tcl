set TOP      cdc_2phase
set RTL_FILE $env(DS)/experiments/human_repaired/cdc_2phase/generated/cdc_2phase.v
set SDC_FILE $env(DS)/benchmarks/cdc_2phase/constraints/cdc_2phase.sdc
set RPT_DIR  $env(DS)/build/jasper/eval/human_repaired/cdc_2phase

file mkdir $RPT_DIR
clear -all
analyze -v2k $RTL_FILE
elaborate -top $TOP
read_sdc $SDC_FILE
check_cdc -init
clock src_clk_i
clock dst_clk_i
config_rtlds -reset -async {src_rst_ni dst_rst_ni} -polarity low
config_rtlds -port {src_rst_ni src_data_i src_valid_i src_ready_o} -clock src_clk_i
config_rtlds -port {dst_rst_ni dst_data_o dst_valid_o dst_ready_i} -clock dst_clk_i
check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP human_repaired: $RPT_DIR"
