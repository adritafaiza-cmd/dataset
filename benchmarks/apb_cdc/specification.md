# apb_cdc generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
APB4 clock-domain crossing using gray FIFOs for request and response.

## Required interface and behavior
- Implement a synthesizable `apb_cdc` module compatible with the supplied testbench.
- Preserve the catalog reference behavior from `https://github.com/pulp-platform/apb`. The destination still issues setup, then access, and holds the request fields through `dst_pready_i`. Each FIFO beat is one registered sample; valid can fall for one read clock before the next beat. A passing testbench does not prove the wait-state protocol.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled and simulated with the supplied testbench.
JasperGold CDC/RDC analysis is not yet frozen for this imported circuit.


## CDC-clean benchmark v2 revision

Payloads pass through two destination-clock stages before they are advertised as valid. Preserve source ownership of each queued word until its accepted destination transfer; synchronization stages alone do not establish multi-bit coherence. Availability may lag and bubbles may span multiple destination clocks. There is no one-beat-per-clock guarantee.

This revision retains distinct clocks and actual crossing extraction. Validation requires compile, functional TB, structural lint, enhanced TB, bounded formal assertions plus cover reachability, and Jasper zero raw CDC/RDC errors with zero waivers. Do not interpret bounded assertions as an unbounded proof or structural analysis as MTBF signoff.
