# JasperGold CDC run: axi_dma
#   setenv DS /home/ft2335/dataset
#   jg -batch $DS/benchmarks/axi_dma/jasper/run.tcl

set TOP      axi_dma
set BENCH_DIR $env(DS)/benchmarks/axi_dma
set SDC_FILE $BENCH_DIR/constraints/axi_dma.sdc
set RPT_DIR  $env(DS)/build/jasper/axi_dma

set RTL_FILES [list \
    $BENCH_DIR/fixed/rtl/axi_dma.v \
    $BENCH_DIR/fixed/rtl/axi_dma_rd.v \
    $BENCH_DIR/fixed/rtl/axi_dma_wr.v
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
    {rst \
     s_axis_read_desc_addr s_axis_read_desc_len s_axis_read_desc_tag \
     s_axis_read_desc_id s_axis_read_desc_dest s_axis_read_desc_user \
     s_axis_read_desc_valid s_axis_read_desc_ready \
     m_axis_read_desc_status_tag m_axis_read_desc_status_error \
     m_axis_read_desc_status_valid \
     m_axis_read_data_tdata m_axis_read_data_tkeep m_axis_read_data_tvalid \
     m_axis_read_data_tready m_axis_read_data_tlast m_axis_read_data_tid \
     m_axis_read_data_tdest m_axis_read_data_tuser \
     s_axis_write_desc_addr s_axis_write_desc_len s_axis_write_desc_tag \
     s_axis_write_desc_valid s_axis_write_desc_ready \
     m_axis_write_desc_status_len m_axis_write_desc_status_tag \
     m_axis_write_desc_status_id m_axis_write_desc_status_dest \
     m_axis_write_desc_status_user m_axis_write_desc_status_error \
     m_axis_write_desc_status_valid \
     s_axis_write_data_tdata s_axis_write_data_tkeep s_axis_write_data_tvalid \
     s_axis_write_data_tready s_axis_write_data_tlast s_axis_write_data_tid \
     s_axis_write_data_tdest s_axis_write_data_tuser \
     m_axi_awid m_axi_awaddr m_axi_awlen m_axi_awsize m_axi_awburst \
     m_axi_awlock m_axi_awcache m_axi_awprot m_axi_awvalid m_axi_awready \
     m_axi_wdata m_axi_wstrb m_axi_wlast m_axi_wvalid m_axi_wready \
     m_axi_bid m_axi_bresp m_axi_bvalid m_axi_bready \
     m_axi_arid m_axi_araddr m_axi_arlen m_axi_arsize m_axi_arburst \
     m_axi_arlock m_axi_arcache m_axi_arprot m_axi_arvalid m_axi_arready \
     m_axi_rid m_axi_rdata m_axi_rresp m_axi_rlast m_axi_rvalid m_axi_rready \
     read_enable write_enable write_abort} \
    -clock clk

check_cdc -extract
check_cdc -list clock_signals -file $RPT_DIR/inferred_clocks.rpt -force
check_cdc -list design_resets -file $RPT_DIR/inferred_resets.rpt -force
check_cdc -list declared_resets -file $RPT_DIR/declared_resets.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report.rpt -force
puts "\[cdc_run\] $TOP: reports written to $RPT_DIR"
