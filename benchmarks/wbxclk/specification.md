# wbxclk generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
Wishbone clock-domain bridge carrying requests and acknowledgements across asynchronous clocks.

## Required interface and behavior
- Implement a synthesizable `wbxclk` module compatible with the supplied testbench.
- Preserve transactions and data ordering across the asynchronous clock domains. Each FIFO keeps its own order. A beat is one registered sample, and that FIFO's empty flag falls on a later read clock. Empty can then rise for one read clock before the next beat. `o_wb_stall` is still the outstanding-request count, not the FIFO full flag. A passing testbench does not prove the abort or outstanding-request protocol.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled, simulated with the supplied testbench, checked with protocol assertions where present, analyzed for CDC/RDC violations in JasperGold, and synthesized.


## CDC-clean benchmark v2 revision

Payloads pass through two destination-clock stages before they are advertised as valid. Preserve source ownership of each queued word until its accepted destination transfer; synchronization stages alone do not establish multi-bit coherence. Availability may lag and bubbles may span multiple destination clocks. There is no one-beat-per-clock guarantee.

This revision retains distinct clocks and actual crossing extraction. Validation requires compile, functional TB, structural lint, enhanced TB, bounded formal assertions plus cover reachability, and Jasper zero raw CDC/RDC errors with zero waivers. Do not interpret bounded assertions as an unbounded proof or structural analysis as MTBF signoff.
