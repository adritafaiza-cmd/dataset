# axis_async_fifo_adapter generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
Width-adapting AXI-Stream asynchronous FIFO between independently clocked interfaces.

## Required interface and behavior
- Implement a synthesizable `axis_async_fifo_adapter` module compatible with the supplied testbench.
- The embedded FIFO uses the same acknowledged binary pointer snapshots as `axis_async_fifo`, so ready can lag. Width conversion stays in one clock: a wider slave bus is packed before the FIFO, and a wider master bus is unpacked after it. `tdata` and `tlast` are still held while `tready` is low. A passing testbench does not prove the pointer or width-conversion protocol.
- Preserve transactions and data ordering across the asynchronous clock domains.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled, simulated with the supplied testbench, checked with protocol assertions where present, analyzed for CDC/RDC violations in JasperGold, and synthesized.


## CDC-clean benchmark v2 revision

Payloads pass through two destination-clock stages before they are advertised as valid. Preserve source ownership of each queued word until its accepted destination transfer; synchronization stages alone do not establish multi-bit coherence. Availability may lag and bubbles may span multiple destination clocks. There is no one-beat-per-clock guarantee.

This revision retains distinct clocks and actual crossing extraction. Validation requires compile, functional TB, structural lint, enhanced TB, bounded formal assertions plus cover reachability, and Jasper zero raw CDC/RDC errors with zero waivers. Do not interpret bounded assertions as an unbounded proof or structural analysis as MTBF signoff.
