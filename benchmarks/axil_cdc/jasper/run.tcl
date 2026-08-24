# JasperGold CDC run: axil_cdc
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/axil_cdc/jasper/run.tcl

set TOP      axil_cdc
set BENCH_DIR $env(DS)/benchmarks/axil_cdc
set SDC_FILE $BENCH_DIR/constraints/axil_cdc.sdc
set RPT_DIR  $env(DS)/build/jasper/axil_cdc

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/axil_cdc.v \
    $BENCH_DIR/fixed/rtl/axil_cdc_wr.v \
    $BENCH_DIR/fixed/rtl/axil_cdc_rd.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -bbox_a 50000 -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock s_clk
clock m_clk
config_rtlds -reset -sync s_rst -clock s_clk -polarity high
config_rtlds -reset -sync m_rst -clock m_clk -polarity high
config_rtlds -port \
    {s_rst s_axil_awaddr s_axil_awprot s_axil_awvalid s_axil_awready \
     s_axil_wdata s_axil_wstrb s_axil_wvalid s_axil_wready \
     s_axil_bresp s_axil_bvalid s_axil_bready \
     s_axil_araddr s_axil_arprot s_axil_arvalid s_axil_arready \
     s_axil_rdata s_axil_rresp s_axil_rvalid s_axil_rready} \
    -clock s_clk
config_rtlds -port \
    {m_rst m_axil_awaddr m_axil_awprot m_axil_awvalid m_axil_awready \
     m_axil_wdata m_axil_wstrb m_axil_wvalid m_axil_wready \
     m_axil_bresp m_axil_bvalid m_axil_bready \
     m_axil_araddr m_axil_arprot m_axil_arvalid m_axil_arready \
     m_axil_rdata m_axil_rresp m_axil_rvalid m_axil_rready} \
    -clock m_clk

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
