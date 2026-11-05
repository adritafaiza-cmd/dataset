# JasperGold CDC run: rstgen
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/rstgen/jasper/run.tcl

set TOP      rstgen
set BENCH_DIR $env(DS)/benchmarks/rstgen
set SDC_FILE $BENCH_DIR/constraints/rstgen.sdc
set RPT_DIR  $env(DS)/build/jasper/rstgen

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/rstgen.sv \
    $BENCH_DIR/fixed/rtl/rstgen_bypass.sv
]

file mkdir $RPT_DIR
clear -all
analyze -sv12 {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock clk_i
config_rtlds -reset -async rst_ni -polarity low
config_rtlds -port \
    {rst_ni test_mode_i rst_no init_no} \
    -clock clk_i

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
