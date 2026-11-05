# JasperGold CDC run: apbslave
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/apbslave/jasper/run.tcl

set TOP      apbslave
set BENCH_DIR $env(DS)/benchmarks/apbslave
set SDC_FILE $BENCH_DIR/constraints/apbslave.sdc
set RPT_DIR  $env(DS)/build/jasper/apbslave

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/apbslave.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -bbox_a 50000 -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock PCLK
config_rtlds -reset -sync PRESETn -clock PCLK -polarity low
config_rtlds -port \
    {PRESETn PSEL PENABLE PREADY PADDR PWRITE PWDATA PWSTRB \
     PPROT PRDATA PSLVERR} \
    -clock PCLK

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
