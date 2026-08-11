# JasperGold CDC run: cdc_2phase_clearable (pulp_platform)
# Run:  DS=/home/afsara/CDC/dataset jaspergold jg/cdc_2phase_clearable.tcl
#
# !!! DEPENDENCY: this module `include`s pulp-platform common_cells headers
#     (common_cells/registers.svh, common_cells/assertions.svh) and instantiates
#     cdc_reset_ctrlr. It will NOT elaborate until common_cells is provided.
#     Set COMMON_CELLS to the common_cells checkout, then add its rtl + incdir.
set TOP       cdc_2phase_clearable
set HDL_STD   -sv12

# set COMMON_CELLS /path/to/common_cells
set RTL_FILES [list $env(DS)/pulp_platform/rtl/cdc_2phase_clearable.v]
# When common_cells is available, also add e.g.:
#   lappend RTL_FILES {*}[glob $COMMON_CELLS/src/*.sv]
#   (and pass +incdir+$COMMON_CELLS/include to analyze)

set SDC_FILE  $env(DS)/pulp_platform/sdc/cdc_2phase_clearable.sdc
source $env(DS)/jg/lib/cdc_run.tcl
cdc_run $TOP $RTL_FILES $SDC_FILE $HDL_STD
