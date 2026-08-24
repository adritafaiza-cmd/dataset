# JasperGold CDC run: spi_master_slave
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/spi_master_slave/jasper/run.tcl

set TOP      spi_master
set BENCH_DIR $env(DS)/benchmarks/spi_master_slave
set SDC_FILE $BENCH_DIR/constraints/spi_master_slave.sdc
set RPT_DIR  $env(DS)/build/jasper/spi_master_slave

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/spi_master.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock sclk_i
clock pclk_i
config_rtlds -reset -async rst_i -polarity high
config_rtlds -port \
    {spi_ssel_o spi_sck_o spi_mosi_o spi_miso_i} \
    -clock sclk_i
config_rtlds -port \
    {di_req_o di_i wren_i wr_ack_o do_valid_o do_o} \
    -clock pclk_i

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
