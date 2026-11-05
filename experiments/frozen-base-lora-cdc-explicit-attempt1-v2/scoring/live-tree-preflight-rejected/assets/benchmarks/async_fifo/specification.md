# async_fifo generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
Dual-clock asynchronous FIFO using Gray-coded pointers and synchronized pointer crossings.

## Required interface and behavior
- Implement a synthesizable `async_fifo` module compatible with the supplied testbench.
- Each pointer stays binary and advances only on an accepted write or on an accepted held read. The other clock receives a snapshot of that pointer on a one-bit request, not a synchronized Gray bus. A snapshot can skip intermediate values; full and empty stay pessimistic. `rdata` is one read-clock sample of the word being offered. `rempty` may be high for one read clock after an accepted read even when another word is stored. `FALLTHROUGH` does not select a combinational memory read. A passing testbench does not prove the pointer protocol.
- Preserve transactions and data ordering across the asynchronous clock domains.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled, simulated with the supplied testbench, checked with protocol assertions where present, analyzed for CDC/RDC violations in JasperGold, and synthesized.


## CDC-clean benchmark v2 revision

Payloads pass through two destination-clock stages before they are advertised as valid. Preserve source ownership of each queued word until its accepted destination transfer; synchronization stages alone do not establish multi-bit coherence. Availability may lag and bubbles may span multiple destination clocks. There is no one-beat-per-clock guarantee.

This revision retains distinct clocks and actual crossing extraction. Validation requires compile, functional TB, structural lint, enhanced TB, bounded formal assertions plus cover reachability, and Jasper zero raw CDC/RDC errors with zero waivers. Do not interpret bounded assertions as an unbounded proof or structural analysis as MTBF signoff.
