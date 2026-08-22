# cdc_2phase generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
Two-phase request/acknowledge handshake for transferring stable multi-bit data between clock domains.

## Required interface and behavior
- Implement a synthesizable `cdc_2phase` module compatible with the supplied testbench.
- Preserve transactions and data ordering across the asynchronous clock domains.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled, simulated with the supplied testbench, checked with protocol assertions where present, analyzed for CDC/RDC violations in JasperGold, and synthesized.
