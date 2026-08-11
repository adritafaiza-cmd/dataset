# JasperGold CDC run: apbxclk (ZipCPU)
# Run:  DS=/home/afsara/CDC/dataset jaspergold jg/apbxclk.tcl
set TOP       apbxclk
set RTL_FILES [list $env(DS)/ZipCPU/rtl/apbxclk.v]
set SDC_FILE  $env(DS)/ZipCPU/sdc/apbxclk.sdc
set HDL_STD   -v2k
source $env(DS)/jg/lib/cdc_run.tcl
cdc_run $TOP $RTL_FILES $SDC_FILE $HDL_STD
