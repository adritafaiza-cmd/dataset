# OpenRouter Llama 3.3 70B sweep

This directory preserves the raw generation, compilation, and simulation
artifacts from the 41-circuit, two-prompt, three-attempt sweep.

## Jasper status

The stored `cdc_clean: false` values are **not valid CDC/RDC failures**.
All 53 functionally passing candidates reached the Jasper launcher, but Jasper
exited before `check_cdc` with:

```text
ERROR: Cannot obtain ownership of project directory: jgproject
```

No `cdc_report.rpt` was produced for these attempts. Their CDC/RDC status is
therefore unknown until Jasper is rerun with a private project directory for
each attempt.

Compile and functional-simulation fields remain valid.
