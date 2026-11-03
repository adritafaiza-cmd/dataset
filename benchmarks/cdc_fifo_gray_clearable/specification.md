# cdc_fifo_gray_clearable generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
Gray-pointer async FIFO with lock-step isolate/clear on either side.

## Required interface and behavior
- Implement a synthesizable `cdc_fifo_gray_clearable` module compatible with the supplied testbench.
- The Gray code that enters each pointer synchronizer is a register updated on the same edge as its binary pointer. A clear writes both the pointer and that Gray register back to zero on the existing hold-countdown edge. The hold length is unchanged. Returning a Gray pointer to zero can change more than one bit. Registering the encode removes combinational logic before the synchronizer. Safety of that multi-bit change during clear still depends on the hold and reset protocol, and the structural CDC result does not prove that protocol.
- The destination word is one registered sample. `dst_valid_o` may fall for one destination clock after an accepted beat even when another word is stored. Clear and reset still suppress a destination beat and discard stored data.
- Preserve the catalog reference behavior from `https://github.com/pulp-platform/common_cells`.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The generated RTL is compiled and simulated with the supplied testbench.
JasperGold CDC/RDC analysis is not yet frozen for this imported circuit.


## CDC-clean benchmark v2 revision

Payloads pass through two destination-clock stages before they are advertised as valid. Preserve source ownership of each queued word until its accepted destination transfer; synchronization stages alone do not establish multi-bit coherence. Availability may lag and bubbles may span multiple destination clocks. There is no one-beat-per-clock guarantee.

This revision retains distinct clocks and actual crossing extraction. Validation requires compile, functional TB, structural lint, enhanced TB, bounded formal assertions plus cover reachability, and Jasper zero raw CDC/RDC errors with zero waivers. Do not interpret bounded assertions as an unbounded proof or structural analysis as MTBF signoff.
