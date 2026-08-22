# JasperGold CDC run: axixclk (ZipCPU)
# Run (tcsh):
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/jg/axixclk.tcl

set TOP      axixclk
set RTL_DIR  $env(DS)/ZipCPU/rtl
set SDC_FILE $env(DS)/ZipCPU/sdc/axixclk.sdc
set RPT_DIR  cdc_reports/axixclk

set RTL_FILES [list \
    $RTL_DIR/axixclk.v \
    $RTL_DIR/afifo.v \
]

file mkdir $RPT_DIR

clear -all
analyze -v2k {*}$RTL_FILES
elaborate -bbox_a 50000 -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock S_AXI_ACLK
clock M_AXI_ACLK

# The slave reset is an active-low asynchronous source. M_AXI_ARESETN is
# generated from it by the three-stage synchronizer in axixclk.
config_rtlds -reset -async S_AXI_ARESETN -polarity low

# Slave AXI interface.
config_rtlds -port \
    {S_AXI_AWID S_AXI_AWADDR S_AXI_AWLEN S_AXI_AWSIZE S_AXI_AWBURST \
     S_AXI_AWLOCK S_AXI_AWCACHE S_AXI_AWPROT S_AXI_AWQOS \
     S_AXI_AWVALID S_AXI_AWREADY \
     S_AXI_WDATA S_AXI_WSTRB S_AXI_WLAST S_AXI_WVALID S_AXI_WREADY \
     S_AXI_BID S_AXI_BRESP S_AXI_BVALID S_AXI_BREADY \
     S_AXI_ARID S_AXI_ARADDR S_AXI_ARLEN S_AXI_ARSIZE S_AXI_ARBURST \
     S_AXI_ARLOCK S_AXI_ARCACHE S_AXI_ARPROT S_AXI_ARQOS \
     S_AXI_ARVALID S_AXI_ARREADY \
     S_AXI_RID S_AXI_RDATA S_AXI_RRESP S_AXI_RLAST S_AXI_RVALID S_AXI_RREADY} \
    -clock S_AXI_ACLK

# Master AXI interface, including its generated reset output.
config_rtlds -port \
    {M_AXI_ARESETN \
     M_AXI_AWID M_AXI_AWADDR M_AXI_AWLEN M_AXI_AWSIZE M_AXI_AWBURST \
     M_AXI_AWLOCK M_AXI_AWCACHE M_AXI_AWPROT M_AXI_AWQOS \
     M_AXI_AWVALID M_AXI_AWREADY \
     M_AXI_WDATA M_AXI_WSTRB M_AXI_WLAST M_AXI_WVALID M_AXI_WREADY \
     M_AXI_BID M_AXI_BRESP M_AXI_BVALID M_AXI_BREADY \
     M_AXI_ARID M_AXI_ARADDR M_AXI_ARLEN M_AXI_ARSIZE M_AXI_ARBURST \
     M_AXI_ARLOCK M_AXI_ARCACHE M_AXI_ARPROT M_AXI_ARQOS \
     M_AXI_ARVALID M_AXI_ARREADY \
     M_AXI_RID M_AXI_RDATA M_AXI_RRESP M_AXI_RLAST M_AXI_RVALID M_AXI_RREADY} \
    -clock M_AXI_ACLK

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
