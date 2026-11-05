# axixclk generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
AXI clock-domain bridge using asynchronous FIFOs for independent AXI channels.

## Required interface and behavior
- Implement a synthesizable `axixclk` module compatible with the supplied testbench.
- AW, W, B, AR, and R each keep their own FIFO order. A channel's valid is its not-empty flag and its ready is its not-full flag. Those flags use acknowledged binary pointer snapshots. Each beat is one registered memory sample, and that channel's valid rises on a later read clock so the payload is already stable. Valid can then fall for one read clock before the next beat. Master write data is held one extra M_AXI clock before M_AXI_WVALID, so a write beat is not accepted on the same edge that captures a new write address. A passing testbench does not prove the channel protocols.
- Preserve transactions and data ordering across the asynchronous clock domains.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled, simulated with the supplied testbench, checked with protocol assertions where present, analyzed for CDC/RDC violations in JasperGold, and synthesized.


## CDC-clean benchmark v2 revision

Payloads pass through two destination-clock stages before they are advertised as valid. Preserve source ownership of each queued word until its accepted destination transfer; synchronization stages alone do not establish multi-bit coherence. Availability may lag and bubbles may span multiple destination clocks. There is no one-beat-per-clock guarantee.

This revision retains distinct clocks and actual crossing extraction. Validation requires compile, functional TB, structural lint, enhanced TB, bounded formal assertions plus cover reachability, and Jasper zero raw CDC/RDC errors with zero waivers. Do not interpret bounded assertions as an unbounded proof or structural analysis as MTBF signoff.
