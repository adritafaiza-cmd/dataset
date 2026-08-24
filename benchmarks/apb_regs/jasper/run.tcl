# JasperGold CDC run: apb_regs
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/apb_regs/jasper/run.tcl

set TOP      apb_regs_wrap
set BENCH_DIR $env(DS)/benchmarks/apb_regs
set SDC_FILE $BENCH_DIR/constraints/apb_regs.sdc
set RPT_DIR  $env(DS)/build/jasper/apb_regs

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/cf_math_pkg.sv \
    $BENCH_DIR/fixed/rtl/apb_pkg.sv \
    $BENCH_DIR/fixed/rtl/apb_intf.sv \
    $BENCH_DIR/fixed/rtl/addr_decode.sv \
    $BENCH_DIR/fixed/rtl/apb_regs.sv \
    $BENCH_DIR/jasper/apb_regs_wrap.sv
]

file mkdir $RPT_DIR
clear -all
analyze -sv12 +incdir+$BENCH_DIR/fixed/rtl/include +incdir+$env(DS)/vendor/common_cells/include {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock pclk_i
config_rtlds -reset -async preset_ni -polarity low
config_rtlds -port \
    {preset_ni psel penable pwrite paddr pwdata pstrb \
     pready prdata pslverr base_addr_i} \
    -clock pclk_i

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
