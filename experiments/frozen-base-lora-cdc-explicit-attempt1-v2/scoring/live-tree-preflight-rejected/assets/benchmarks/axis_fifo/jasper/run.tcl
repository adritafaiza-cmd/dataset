# JasperGold CDC run: axis_fifo
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/axis_fifo/jasper/run.tcl

set TOP      axis_fifo
set BENCH_DIR $env(DS)/benchmarks/axis_fifo
set SDC_FILE $BENCH_DIR/constraints/axis_fifo.sdc
set RPT_DIR  $env(DS)/build/jasper/axis_fifo

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/axis_fifo.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -bbox_a 50000 -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock clk
config_rtlds -reset -sync rst -clock clk -polarity high
config_rtlds -port \
    {rst s_axis_tdata s_axis_tkeep s_axis_tvalid s_axis_tready \
     s_axis_tlast s_axis_tid s_axis_tdest s_axis_tuser \
     m_axis_tdata m_axis_tkeep m_axis_tvalid m_axis_tready \
     m_axis_tlast m_axis_tid m_axis_tdest m_axis_tuser \
     pause_req pause_ack status_depth status_depth_commit \
     status_overflow status_bad_frame status_good_frame} \
    -clock clk

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
