# JasperGold CDC run: uart16550
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/uart16550/jasper/run.tcl

set TOP      uart_top
set BENCH_DIR $env(DS)/benchmarks/uart16550
set SDC_FILE $BENCH_DIR/constraints/uart16550.sdc
set RPT_DIR  $env(DS)/build/jasper/uart16550

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/raminfr.v \
    $BENCH_DIR/fixed/rtl/uart_debug_if.v \
    $BENCH_DIR/fixed/rtl/uart_receiver.v \
    $BENCH_DIR/fixed/rtl/uart_regs.v \
    $BENCH_DIR/fixed/rtl/uart_rfifo.v \
    $BENCH_DIR/fixed/rtl/uart_sync_flops.v \
    $BENCH_DIR/fixed/rtl/uart_tfifo.v \
    $BENCH_DIR/fixed/rtl/uart_top.v \
    $BENCH_DIR/fixed/rtl/uart_transmitter.v \
    $BENCH_DIR/fixed/rtl/uart_wb.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k +define+DATA_BUS_WIDTH_8 +incdir+$BENCH_DIR/fixed/rtl {*}$RTL_FILES
elaborate -bbox_a 50000 -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock wb_clk_i
config_rtlds -reset -sync wb_rst_i -clock wb_clk_i -polarity high
config_rtlds -port \
    {wb_rst_i wb_adr_i wb_dat_i wb_dat_o wb_we_i wb_stb_i \
     wb_cyc_i wb_ack_o wb_sel_i int_o stx_pad_o srx_pad_i \
     rts_pad_o cts_pad_i dtr_pad_o dsr_pad_i ri_pad_i dcd_pad_i} \
    -clock wb_clk_i

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
