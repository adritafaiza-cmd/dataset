# JasperGold CDC run: axidma
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/axidma/jasper/run.tcl

set TOP      axidma
set BENCH_DIR $env(DS)/benchmarks/axidma
set SDC_FILE $BENCH_DIR/constraints/axidma.sdc
set RPT_DIR  $env(DS)/build/jasper/axidma

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/axidma.v \
    $BENCH_DIR/fixed/rtl/skidbuffer.v \
    $BENCH_DIR/fixed/rtl/sfifo.v
]

file mkdir $RPT_DIR
clear -all
analyze -v2k {*}$RTL_FILES
elaborate -bbox_a 50000 -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock S_AXI_ACLK
config_rtlds -reset -sync S_AXI_ARESETN -clock S_AXI_ACLK -polarity low
config_rtlds -port \
    {S_AXI_ARESETN \
     S_AXIL_AWVALID S_AXIL_AWREADY S_AXIL_AWADDR S_AXIL_AWPROT \
     S_AXIL_WVALID S_AXIL_WREADY S_AXIL_WDATA S_AXIL_WSTRB \
     S_AXIL_BVALID S_AXIL_BREADY S_AXIL_BRESP \
     S_AXIL_ARVALID S_AXIL_ARREADY S_AXIL_ARADDR S_AXIL_ARPROT \
     S_AXIL_RVALID S_AXIL_RREADY S_AXIL_RDATA S_AXIL_RRESP \
     M_AXI_AWVALID M_AXI_AWREADY M_AXI_AWID M_AXI_AWADDR \
     M_AXI_AWLEN M_AXI_AWSIZE M_AXI_AWBURST M_AXI_AWLOCK \
     M_AXI_AWCACHE M_AXI_AWPROT M_AXI_AWQOS \
     M_AXI_WVALID M_AXI_WREADY M_AXI_WDATA M_AXI_WSTRB M_AXI_WLAST \
     M_AXI_BVALID M_AXI_BREADY M_AXI_BID M_AXI_BRESP \
     M_AXI_ARVALID M_AXI_ARREADY M_AXI_ARID M_AXI_ARADDR \
     M_AXI_ARLEN M_AXI_ARSIZE M_AXI_ARBURST M_AXI_ARLOCK \
     M_AXI_ARCACHE M_AXI_ARPROT M_AXI_ARQOS \
     M_AXI_RVALID M_AXI_RREADY M_AXI_RID M_AXI_RDATA M_AXI_RLAST M_AXI_RRESP \
     o_int} \
    -clock S_AXI_ACLK

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
