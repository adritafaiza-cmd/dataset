# JasperGold CDC run: axis_async_fifo (verilog_axis)
# Run:  DS=/home/afsara/CDC/dataset jaspergold jg/axis_async_fifo.tcl
set TOP       axis_async_fifo
set RTL_FILES [list $env(DS)/verilog_axis/rtl/axis_async_fifo.v]
set SDC_FILE  $env(DS)/verilog_axis/sdc/axis_async_fifo.sdc
set HDL_STD   -v2k
source $env(DS)/jg/lib/cdc_run.tcl
cdc_run $TOP $RTL_FILES $SDC_FILE $HDL_STD
