# JasperGold CDC run: axis_async_fifo (verilog_axis)
# Run (tcsh):
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/jg/axis_async_fifo.tcl

set TOP      axis_async_fifo
set RTL_FILE $env(DS)/verilog_axis/rtl/axis_async_fifo.v
set SDC_FILE $env(DS)/verilog_axis/sdc/axis_async_fifo.sdc
set RPT_DIR  cdc_reports/axis_async_fifo

file mkdir $RPT_DIR

clear -all
analyze -v2k $RTL_FILE
elaborate -bbox_a 50000 -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock s_clk
clock m_clk

# Active-high synchronous source resets; RTL synchronizes cross-domain effects.
config_rtlds -reset -sync s_rst -clock s_clk -polarity high
config_rtlds -reset -sync m_rst -clock m_clk -polarity high

# Slave/write-domain interface.
config_rtlds -port \
    {s_axis_tdata s_axis_tkeep s_axis_tvalid s_axis_tready s_axis_tlast \
     s_axis_tid s_axis_tdest s_axis_tuser s_pause_req s_pause_ack \
     s_status_depth s_status_depth_commit s_status_overflow \
     s_status_bad_frame s_status_good_frame} \
    -clock s_clk

# Master/read-domain interface.
config_rtlds -port \
    {m_axis_tdata m_axis_tkeep m_axis_tvalid m_axis_tready m_axis_tlast \
     m_axis_tid m_axis_tdest m_axis_tuser m_pause_req m_pause_ack \
     m_status_depth m_status_depth_commit m_status_overflow \
     m_status_bad_frame m_status_good_frame} \
    -clock m_clk

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
