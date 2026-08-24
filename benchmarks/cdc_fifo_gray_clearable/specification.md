# cdc_fifo_gray_clearable generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
Gray-pointer async FIFO with lock-step isolate/clear on either side.

## Required interface and behavior
- Implement a synthesizable `cdc_fifo_gray_clearable` module compatible with the supplied testbench.
- Preserve the catalog reference behavior from `https://github.com/pulp-platform/common_cells`.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled and simulated with the supplied testbench.
JasperGold CDC/RDC analysis is not yet frozen for this imported circuit.
