# JasperGold CDC run: i2c_master
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/i2c_master/jasper/run.tcl

set TOP      i2c_master
set BENCH_DIR $env(DS)/benchmarks/i2c_master
set SDC_FILE $BENCH_DIR/constraints/i2c_master.sdc
set RPT_DIR  $env(DS)/build/jasper/i2c_master

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/i2c_master.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock clk
config_rtlds -reset -sync rst -clock clk -polarity high
config_rtlds -port \
    {rst s_axis_cmd_address s_axis_cmd_start s_axis_cmd_read \
     s_axis_cmd_write s_axis_cmd_write_multiple s_axis_cmd_stop \
     s_axis_cmd_valid s_axis_cmd_ready s_axis_data_tdata \
     s_axis_data_tvalid s_axis_data_tready s_axis_data_tlast \
     m_axis_data_tdata m_axis_data_tvalid m_axis_data_tready \
     m_axis_data_tlast scl_i scl_o scl_t sda_i sda_o sda_t \
     busy bus_control bus_active missed_ack prescale stop_on_idle} \
    -clock clk

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
