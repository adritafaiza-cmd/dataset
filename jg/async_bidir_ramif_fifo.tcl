# JasperGold CDC run: async_bidir_ramif_fifo (dpretet_async_fifo)
# Run:  DS=/home/afsara/CDC/dataset jaspergold jg/async_bidir_ramif_fifo.tcl
# NOTE: dual-port RAM is external (exposed as ports); elaborates standalone.
set TOP       async_bidir_ramif_fifo
set RTL_FILES [glob $env(DS)/dpretet_async_fifo/rtl/*.v]
set SDC_FILE  $env(DS)/dpretet_async_fifo/sdc/async_bidir_ramif_fifo.sdc
set HDL_STD   -v2k
source $env(DS)/jg/lib/cdc_run.tcl
cdc_run $TOP $RTL_FILES $SDC_FILE $HDL_STD
