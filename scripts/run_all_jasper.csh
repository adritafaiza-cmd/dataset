#!/bin/tcsh

if (! $?DS) then
  echo "ERROR: set DS to the repository root first."
  exit 1
endif

foreach run_script ($DS/benchmarks/*/jasper/run.tcl)
  set benchmark = ${run_script:h:h:t}
  echo "=== Checking $benchmark ==="
  jg -batch $run_script
  if ($status != 0) exit $status
end
