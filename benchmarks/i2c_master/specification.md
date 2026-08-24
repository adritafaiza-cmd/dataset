# i2c_master generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
I2C controller with host stream command interface.

## Required interface and behavior
- Implement a synthesizable `i2c_master` module compatible with the supplied testbench.
- Preserve the catalog reference behavior from `https://github.com/alexforencich/verilog-i2c`.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled and simulated with the supplied testbench.
JasperGold CDC/RDC analysis is not yet frozen for this imported circuit.
