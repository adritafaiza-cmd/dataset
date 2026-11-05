# apb_regs generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
PULP APB register block.

## Required interface and behavior
- Implement a synthesizable `apb_regs` module compatible with the supplied testbench.
- Preserve the catalog reference behavior from `https://github.com/pulp-platform/apb`.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled and simulated with the supplied testbench.
JasperGold CDC/RDC analysis is not yet frozen for this imported circuit.


## CDC-clean benchmark v2 correction

Writes commit only in the APB access phase (psel and penable). Byte strobes update only the selected bytes of a writable register; unstrobed bytes and idle-cycle state are preserved. Writes outside the register width do not change stored data. Each AddrOffset-byte decoded address range maps to its register. Reset cancels pending writes; writable registers reset to zero and read-only registers expose reg_init_i.

The formal contract includes state/sequence assertions and reachable transaction covers. Bounded checks are reported with their exact depths.

Writable register reset values are zero. reg_init_i supplies read-only values; it is not a writable-register reset preload. Partial writes preserve unstrobed bytes.
