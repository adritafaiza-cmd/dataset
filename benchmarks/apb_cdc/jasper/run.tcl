# JasperGold CDC run: apb_cdc
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/apb_cdc/jasper/run.tcl

set TOP      apb_cdc
set BENCH_DIR $env(DS)/benchmarks/apb_cdc
set SDC_FILE $BENCH_DIR/constraints/apb_cdc.sdc
set RPT_DIR  $env(DS)/build/jasper/apb_cdc

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/apb_cdc.v \
    $BENCH_DIR/fixed/rtl/cdc_fifo_gray.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock src_pclk_i
clock dst_pclk_i
config_rtlds -reset -async src_preset_ni -polarity low
config_rtlds -reset -async dst_preset_ni -polarity low
config_rtlds -port \
    {src_preset_ni src_psel_i src_penable_i src_pwrite_i \
     src_paddr_i src_pwdata_i src_pstrb_i src_pprot_i \
     src_pready_o src_prdata_o src_pslverr_o} \
    -clock src_pclk_i
config_rtlds -port \
    {dst_preset_ni dst_psel_o dst_penable_o dst_pwrite_o \
     dst_paddr_o dst_pwdata_o dst_pstrb_o dst_pprot_o \
     dst_pready_i dst_prdata_i dst_pslverr_i} \
    -clock dst_pclk_i

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
