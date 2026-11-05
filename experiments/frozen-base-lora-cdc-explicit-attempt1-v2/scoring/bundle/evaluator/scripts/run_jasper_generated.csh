#!/bin/tcsh
# Run the benchmark JasperGold CDC script against generated RTL.
# Usage:
#   setenv DS /home/ft2335/dataset
#   ./scripts/run_jasper_generated.csh apbxclk cdc_explicit attempt-002

if (! $?DS) then
  echo "ERROR: setenv DS to the repository root first."
  exit 1
endif

if ($#argv != 3) then
  echo "Usage: $0 <circuit> <prompt_type> <attempt>"
  exit 1
endif

set circuit = $1
set prompt  = $2
set attempt = $3
set rtl     = $DS/experiments/llama-3.3-70b-instruct/$circuit/$prompt/$attempt/generated/${circuit}.v
set rpt     = $DS/build/jasper/eval/llama-3.3-70b-instruct/$circuit/$prompt/$attempt
set src_tcl = $DS/benchmarks/$circuit/jasper/run.tcl
set tcl     = $rpt/run.tcl

if (! -f "$rtl") then
  echo "ERROR: missing $rtl"
  exit 1
endif

mkdir -p $rpt
sed -e "s|set RTL_FILE .*|set RTL_FILE $rtl|" \
    -e "s|set RPT_DIR  .*|set RPT_DIR  $rpt|" \
    $src_tcl > $tcl

echo "===== JASPER $circuit/$prompt/$attempt ====="
jg -batch $tcl
exit $status
