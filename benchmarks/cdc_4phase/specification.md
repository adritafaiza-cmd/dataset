# cdc_4phase generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
Four-phase request/acknowledge handshake for robust multi-bit CDC transfers.

## Required interface and behavior
- Implement a synthesizable `cdc_4phase` module compatible with the supplied testbench.
- Preserve transactions and data ordering across the asynchronous clock domains.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled, simulated with the supplied testbench, checked with protocol assertions where present, analyzed for CDC/RDC violations in JasperGold, and synthesized.
