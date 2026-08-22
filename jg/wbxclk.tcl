# JasperGold CDC run: wbxclk (ZipCPU)
# Run (tcsh):
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/jg/wbxclk.tcl

set TOP      wbxclk
set RTL_DIR  $env(DS)/ZipCPU/rtl
set SDC_FILE $env(DS)/ZipCPU/sdc/wbxclk.sdc
set RPT_DIR  cdc_reports/wbxclk

set RTL_FILES [list \
    $RTL_DIR/cdc_reset_sync.v \
    $RTL_DIR/wbxclk.v \
    $RTL_DIR/afifo.v \
]

file mkdir $RPT_DIR

clear -all
analyze -v2k {*}$RTL_FILES
# Keep both asynchronous FIFO memories internal to the CDC model.
elaborate -bbox_a 10000 -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock i_wb_clk
clock i_xclk_clk

# Wishbone reset is synchronous to the upstream clock. bus_abort is the common
# asynchronous assertion source for both local FIFO reset synchronizers.
config_rtlds -reset -sync i_reset -clock i_wb_clk -polarity high
config_rtlds -reset -async bus_abort -polarity high

# cdc_reset_sync has active-high asynchronous assertion and synchronous
# deassertion. Module-based mapping uses real module ports.
check_cdc -scheme -add reset -module cdc_reset_sync -map \
    {{srst i_async_reset} {dclk i_clk} {snrst o_reset}}

# Original Wishbone domain.
config_rtlds -port \
    {i_wb_cyc i_wb_stb i_wb_we i_wb_addr i_wb_data i_wb_sel \
     o_wb_stall o_wb_ack o_wb_data o_wb_err} \
    -clock i_wb_clk

# Crossed/downstream Wishbone domain.
config_rtlds -port \
    {o_xclk_cyc o_xclk_stb o_xclk_we o_xclk_addr o_xclk_data o_xclk_sel \
     i_xclk_stall i_xclk_ack i_xclk_data i_xclk_err} \
    -clock i_xclk_clk

check_cdc -extract

check_cdc -list clock_signals \
    -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets \
    -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets \
    -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings \
    -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed \
    -file $RPT_DIR/cdc_report.rpt -force

puts "======================================================================"
puts "\[cdc_run\] $TOP: done."
puts "  Declared (SDC)  : $SDC_FILE"
puts "  Inferred clocks : $RPT_DIR/inferred_clocks.rpt"
puts "  Inferred resets : $RPT_DIR/inferred_resets.rpt"
puts "  CDC crossings   : $RPT_DIR/cdc_crossings.rpt"
puts "  CDC violations  : $RPT_DIR/cdc_report.rpt"
puts "======================================================================"
