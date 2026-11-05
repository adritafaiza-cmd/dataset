# apbxclk generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
APB clock-domain bridge that transfers requests and responses between asynchronous APB clocks.

## Required interface and behavior
- Implement a synthesizable `apbxclk` module compatible with the supplied testbench.
- Request fields are captured once on the master clock when the synchronized request is first seen, and held through the master setup and access phases. Read data and slave error are captured once on the slave clock when the synchronized acknowledge is first seen. `OPT_REGISTERED` no longer selects a combinational bypass. `S_APB_PREADY` is still asserted only after the master transfer completes. A passing testbench does not prove every APB timing.
- Preserve transactions and data ordering across the asynchronous clock domains.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled, simulated with the supplied testbench, checked with protocol assertions where present, analyzed for CDC/RDC violations in JasperGold, and synthesized.


## CDC-clean benchmark v2 revision

Hold each transaction payload stable under the request/acknowledge protocol. Synchronize the held payload through at least two destination-clock stages and delay its control indication sufficiently for the payload to settle before capture or acceptance. Preserve ordered, exactly-once transfers and stable outputs under backpressure. Additional crossing latency is permitted; do not require an exact cycle count.

This revision retains distinct clocks and actual crossing extraction. Validation requires compile, functional TB, structural lint, enhanced TB, bounded formal assertions plus cover reachability, and Jasper zero raw CDC/RDC errors with zero waivers. Do not interpret bounded assertions as an unbounded proof or structural analysis as MTBF signoff.
