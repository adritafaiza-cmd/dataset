# cdc_2phase_clearable generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
Clearable two-phase CDC channel with coordinated isolation and reset sequencing.

## Required interface and behavior
- Implement a synthesizable `cdc_2phase_clearable` module compatible with the supplied testbench.
- Preserve transactions and data ordering across the asynchronous clock domains.
- The channel still holds one outstanding beat. Isolate gates both ends first. Clear then forces the two-phase request and acknowledge back to zero, so that outstanding beat is dropped rather than delivered. The destination still captures the payload on the request edge; there is no extra valid bubble between beats.
- The clear sequence uses the ordered idle, active, done code transfer. Each step is visible to the peer one handshake later. A passing testbench does not prove that an outstanding beat is dropped for every timing.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled, simulated with the supplied testbench, checked with protocol assertions where present, analyzed for CDC/RDC violations in JasperGold, and synthesized.


## CDC-clean benchmark v2 revision

Hold each transaction payload stable under the request/acknowledge protocol. Synchronize the held payload through at least two destination-clock stages and delay its control indication sufficiently for the payload to settle before capture or acceptance. Preserve ordered, exactly-once transfers and stable outputs under backpressure. Additional crossing latency is permitted; do not require an exact cycle count.

This revision retains distinct clocks and actual crossing extraction. Validation requires compile, functional TB, structural lint, enhanced TB, bounded formal assertions plus cover reachability, and Jasper zero raw CDC/RDC errors with zero waivers. Do not interpret bounded assertions as an unbounded proof or structural analysis as MTBF signoff.
