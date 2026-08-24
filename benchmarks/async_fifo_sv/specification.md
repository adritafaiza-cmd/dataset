# async_fifo_sv generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
SystemVerilog Gray-coded asynchronous FIFO.

## Required interface and behavior
- Implement a synthesizable `async_fifo` module compatible with the supplied testbench.
- Preserve the catalog reference behavior from `https://github.com/dianluniuniu/async-fifo`.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled and simulated with the supplied testbench.
JasperGold CDC/RDC analysis is not yet frozen for this imported circuit.
