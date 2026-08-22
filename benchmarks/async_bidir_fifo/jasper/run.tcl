# JasperGold CDC run: async_bidir_fifo (dpretet_async_fifo)
# Run (tcsh):
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/async_bidir_fifo/jasper/run.tcl

set TOP      async_bidir_fifo
set RTL_DIR  $env(DS)/benchmarks/async_bidir_fifo/fixed/rtl
set SDC_FILE $env(DS)/benchmarks/async_bidir_fifo/constraints/async_bidir_fifo.sdc
set RPT_DIR  $env(DS)/build/jasper/async_bidir_fifo

# Analyze only the top and its RTL dependencies.
set RTL_FILES [list \
    $RTL_DIR/async_bidir_fifo.v \
    $RTL_DIR/sync_ptr.v \
    $RTL_DIR/wptr_full.v \
    $RTL_DIR/rptr_empty.v \
    $RTL_DIR/fifomem_dp.v \
]

file mkdir $RPT_DIR

clear -all
analyze -v2k {*}$RTL_FILES
elaborate -top $TOP

# The SDC declares a_clk and b_clk as asynchronous clock groups.
read_sdc $SDC_FILE
check_cdc -init
clock a_clk
clock b_clk

# Active-low asynchronous resets for their respective domains.
config_rtlds -reset -async {a_rst_n b_rst_n} -polarity low

# Top-level interface clock-domain associations.
config_rtlds -port \
    {a_winc a_wdata a_rinc a_rdata a_full a_afull a_empty a_aempty a_dir} \
    -clock a_clk
config_rtlds -port \
    {b_winc b_wdata b_rinc b_rdata b_full b_afull b_empty b_aempty b_dir} \
    -clock b_clk

check_cdc -extract

check_cdc -list clock_signals \
    -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets \
    -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets \
    -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings \
    -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report \
    -file $RPT_DIR/cdc_report.rpt -force

puts "======================================================================"
puts "\[cdc_run\] $TOP: done."
puts "  Declared (SDC)  : $SDC_FILE"
puts "  Inferred clocks : $RPT_DIR/inferred_clocks.rpt"
puts "  Inferred resets : $RPT_DIR/inferred_resets.rpt"
puts "  CDC crossings   : $RPT_DIR/cdc_crossings.rpt"
puts "  CDC violations  : $RPT_DIR/cdc_report.rpt"
puts "======================================================================"
