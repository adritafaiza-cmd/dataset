# JasperGold CDC run: axixclk (ZipCPU)  -- needs afifo.v
# Run:  DS=/home/afsara/CDC/dataset jaspergold jg/axixclk.tcl
set TOP       axixclk
set RTL_FILES [list $env(DS)/ZipCPU/rtl/axixclk.v $env(DS)/ZipCPU/rtl/afifo.v]
set SDC_FILE  $env(DS)/ZipCPU/sdc/axixclk.sdc
set HDL_STD   -v2k
source $env(DS)/jg/lib/cdc_run.tcl
cdc_run $TOP $RTL_FILES $SDC_FILE $HDL_STD
