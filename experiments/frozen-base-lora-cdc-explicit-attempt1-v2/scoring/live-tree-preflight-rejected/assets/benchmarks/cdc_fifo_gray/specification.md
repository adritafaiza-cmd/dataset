# cdc_fifo_gray generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
Gray-pointer asynchronous FIFO for valid/ready payload CDC.

## Required interface and behavior
- Implement a synthesizable `cdc_fifo_gray` module compatible with the supplied testbench.
- Each pointer stays binary and advances only on an accepted beat. The other clock receives a snapshot on one request bit. A snapshot can skip intermediate values, so full and empty stay pessimistic. `dst_data_o` is one destination-clock sample. `dst_valid_o` may fall for one destination clock after an accepted beat even when another word is stored. `SYNC_STAGES` below 2 is raised to 2. A passing testbench does not prove the pointer protocol.
- Preserve the catalog reference behavior from `https://github.com/pulp-platform/common_cells`.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled and simulated with the supplied testbench.
JasperGold CDC/RDC analysis is not yet frozen for this imported circuit.


## CDC-clean benchmark v2 revision

Payloads pass through two destination-clock stages before they are advertised as valid. Preserve source ownership of each queued word until its accepted destination transfer; synchronization stages alone do not establish multi-bit coherence. Availability may lag and bubbles may span multiple destination clocks. There is no one-beat-per-clock guarantee.

This revision retains distinct clocks and actual crossing extraction. Validation requires compile, functional TB, structural lint, enhanced TB, bounded formal assertions plus cover reachability, and Jasper zero raw CDC/RDC errors with zero waivers. Do not interpret bounded assertions as an unbounded proof or structural analysis as MTBF signoff.
