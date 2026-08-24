# axil_cdc generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
AXI4-Lite clock-domain crossing for write and read channels.

## Required interface and behavior
- Implement a synthesizable `axil_cdc` module compatible with the supplied testbench.
- Preserve the catalog reference behavior from `https://github.com/alexforencich/verilog-axi`.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled and simulated with the supplied testbench.
JasperGold CDC/RDC analysis is not yet frozen for this imported circuit.
