# spi_master_slave generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
OpenCores SPI master/slave with independent serial and parallel clocks.

## Required interface and behavior
- Implement a synthesizable `spi_master` module compatible with the supplied testbench.
- Preserve the catalog reference behavior from `https://github.com/freecores/spi_master_slave`.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled and simulated with the supplied testbench.
JasperGold CDC/RDC analysis is not yet frozen for this imported circuit.


## CDC-clean benchmark v2 revision

Hold the transmit word until serial acceptance, synchronize both transmit and completed receive payloads, and use only final control synchronizer stages. Complete each request exactly once. Re-arm serial acceptance only after observing the request return low. di_req_o advertises that the complete return-to-zero handshake has finished and another word can be accepted; wr_ack_o acknowledges acceptance and do_valid_o pulses for each completed word.

This revision retains distinct clocks and actual crossing extraction. Validation requires compile, functional TB, structural lint, enhanced TB, bounded formal assertions plus cover reachability, and Jasper zero raw CDC/RDC errors with zero waivers. Do not interpret bounded assertions as an unbounded proof or structural analysis as MTBF signoff.
