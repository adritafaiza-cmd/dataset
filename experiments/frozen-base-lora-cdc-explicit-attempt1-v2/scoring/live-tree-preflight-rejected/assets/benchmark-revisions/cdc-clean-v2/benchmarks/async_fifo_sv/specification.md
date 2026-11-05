# async_fifo_sv generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
SystemVerilog Gray-coded asynchronous FIFO.

## Required interface and behavior
- Implement a synthesizable `async_fifo` module compatible with the supplied testbench.
- `rdata` is a read-clock sample of the word being offered, not a combinational memory read. `rempty` may be high for one read clock after an accepted read even when another word is already stored. Order and the write-full rule are unchanged.
- Preserve the catalog reference behavior from `https://github.com/dianluniuniu/async-fifo`.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled and simulated with the supplied testbench.
JasperGold CDC/RDC analysis is not yet frozen for this imported circuit.


## CDC-clean benchmark v2 revision

Payloads pass through two destination-clock stages before they are advertised as valid. Preserve source ownership of each queued word until its accepted destination transfer; synchronization stages alone do not establish multi-bit coherence. Availability may lag and bubbles may span multiple destination clocks. There is no one-beat-per-clock guarantee.

This revision retains distinct clocks and actual crossing extraction. Validation requires compile, functional TB, structural lint, enhanced TB, bounded formal assertions plus cover reachability, and Jasper zero raw CDC/RDC errors with zero waivers. Do not interpret bounded assertions as an unbounded proof or structural analysis as MTBF signoff.
