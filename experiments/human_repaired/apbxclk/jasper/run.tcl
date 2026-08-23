set TOP      apbxclk
set RTL_FILE $env(DS)/experiments/human_repaired/apbxclk/generated/apbxclk.v
set SDC_FILE $env(DS)/benchmarks/apbxclk/constraints/apbxclk.sdc
set RPT_DIR  $env(DS)/build/jasper/eval/human_repaired/apbxclk

file mkdir $RPT_DIR
clear -all
analyze -v2k $RTL_FILE
elaborate -top $TOP
read_sdc $SDC_FILE
check_cdc -init
clock S_APB_PCLK
clock M_APB_PCLK
config_rtlds -reset -async S_PRESETn -polarity low
config_rtlds -port \
    {S_APB_PSEL S_APB_PENABLE S_APB_PREADY S_APB_PADDR S_APB_PWRITE \
     S_APB_PWDATA S_APB_PWSTRB S_APB_PPROT S_APB_PRDATA S_APB_PSLVERR} \
    -clock S_APB_PCLK
config_rtlds -port \
    {M_PRESETn M_APB_PSEL M_APB_PENABLE M_APB_PREADY M_APB_PADDR \
     M_APB_PWRITE M_APB_PWDATA M_APB_PWSTRB M_APB_PPROT \
     M_APB_PRDATA M_APB_PSLVERR} \
    -clock M_APB_PCLK
check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP human_repaired: $RPT_DIR"
