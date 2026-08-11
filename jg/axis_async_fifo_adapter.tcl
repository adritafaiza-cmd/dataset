# JasperGold CDC run: axis_async_fifo_adapter (verilog_axis)
# Run:  DS=/home/afsara/CDC/dataset jaspergold jg/axis_async_fifo_adapter.tcl
# Pulls in axis_async_fifo + axis_adapter etc. -> analyze the whole rtl/ lib.
set TOP       axis_async_fifo_adapter
set RTL_FILES [glob $env(DS)/verilog_axis/rtl/*.v]
set SDC_FILE  $env(DS)/verilog_axis/sdc/axis_async_fifo_adapter.sdc
set HDL_STD   -v2k
source $env(DS)/jg/lib/cdc_run.tcl
cdc_run $TOP $RTL_FILES $SDC_FILE $HDL_STD
