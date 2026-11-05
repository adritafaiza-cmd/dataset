# axil_cdc generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
AXI4-Lite clock-domain crossing for write and read channels.

## Required interface and behavior
- Implement a synthesizable `axil_cdc` module compatible with the supplied testbench.
- Preserve the catalog reference behavior from `https://github.com/alexforencich/verilog-axi`.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled and simulated with the supplied testbench.
JasperGold CDC/RDC analysis is not yet frozen for this imported circuit.


## CDC-clean benchmark v2 revision

Hold each transaction payload stable under the request/acknowledge protocol. Synchronize the held payload through at least two destination-clock stages and delay its control indication sufficiently for the payload to settle before capture or acceptance. Preserve ordered, exactly-once transfers and stable outputs under backpressure. Additional crossing latency is permitted; do not require an exact cycle count.

This revision retains distinct clocks and actual crossing extraction. Validation requires compile, functional TB, structural lint, enhanced TB, bounded formal assertions plus cover reachability, and Jasper zero raw CDC/RDC errors with zero waivers. Do not interpret bounded assertions as an unbounded proof or structural analysis as MTBF signoff.
