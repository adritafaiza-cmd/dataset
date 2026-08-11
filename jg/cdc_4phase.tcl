# JasperGold CDC run: cdc_4phase (pulp_platform)
# Run:  DS=/home/afsara/CDC/dataset jaspergold jg/cdc_4phase.tcl
set TOP       cdc_4phase
set RTL_FILES [list $env(DS)/pulp_platform/rtl/cdc_4phase.v]
set SDC_FILE  $env(DS)/pulp_platform/sdc/cdc_4phase.sdc
set HDL_STD   -v2k
source $env(DS)/jg/lib/cdc_run.tcl
cdc_run $TOP $RTL_FILES $SDC_FILE $HDL_STD
