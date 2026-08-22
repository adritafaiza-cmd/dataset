# JasperGold CDC run: cdc_2phase_clearable (pulp_platform)
# Run (tcsh):
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/jg/cdc_2phase_clearable.tcl

set TOP      cdc_2phase_clearable
set PP_DIR   $env(DS)/pulp_platform
set CC_DIR   $PP_DIR/common_cells
set SDC_FILE $PP_DIR/sdc/cdc_2phase_clearable.sdc
set RPT_DIR  cdc_reports/cdc_2phase_clearable

set RTL_FILES [list \
    $CC_DIR/src/cdc_reset_ctrlr_pkg.sv \
    $CC_DIR/src/sync.sv \
    $CC_DIR/src/spill_register.sv \
    $CC_DIR/src/cdc_4phase.sv \
    $CC_DIR/src/cdc_reset_ctrlr.sv \
    $PP_DIR/rtl/cdc_2phase_clearable.v \
]

file mkdir $RPT_DIR

clear -all
analyze -sv12 +incdir+$CC_DIR/include {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock src_clk_i
clock dst_clk_i

# Effective common asynchronous reset source. Both local reset outputs
# deassert synchronously in their respective clock domains.
config_rtlds -reset -async common_rst_ni -polarity low

config_rtlds -port \
    {src_rst_ni src_clear_i src_clear_pending_o src_data_i src_valid_i src_ready_o} \
    -clock src_clk_i
config_rtlds -port \
    {dst_rst_ni dst_clear_i dst_clear_pending_o dst_data_o dst_valid_o dst_ready_i} \
    -clock dst_clk_i

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
