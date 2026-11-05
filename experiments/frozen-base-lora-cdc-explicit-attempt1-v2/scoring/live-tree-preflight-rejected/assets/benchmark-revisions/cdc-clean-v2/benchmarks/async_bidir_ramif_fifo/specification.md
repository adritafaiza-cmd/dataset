# async_bidir_ramif_fifo generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
Bidirectional asynchronous FIFO controller with an external dual-port RAM interface.

## Required interface and behavior
- Implement a synthesizable `async_bidir_ramif_fifo` module compatible with the supplied testbench.
- Both directions keep binary pointers that advance only on an accepted write or read. Each pointer crosses as an acknowledged snapshot, so full and empty can lag. The external RAM ports are unchanged: each side's address, write data, and read or write enable are still the local signals in that clock, and the read data is still the RAM input. A passing testbench does not prove either direction's pointer protocol.
- Preserve transactions and data ordering across the asynchronous clock domains.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled, simulated with the supplied testbench, checked with protocol assertions where present, analyzed for CDC/RDC violations in JasperGold, and synthesized.
