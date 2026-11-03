# afifo generation specification

> Status: revised 2026-10-16. This replaces the gray-pointer contract.
> The previous contract is in `archive/v1-gray-pointer/`.

## Objective
Asynchronous FIFO with `2**LGFIFO` words of storage and full/empty backpressure.
Words cross one at a time. This is not a gray-pointer FIFO.

## Why this architecture
Jasper 2026.03p001 reports gray-pointer full/empty comparison as `CNV_ST_CONV`.
Proving the Gray encoding did not clear those raw errors, and a waiver would
not meet the benchmark rule of zero raw errors and zero waivers. Single-bit
request and acknowledge synchronizers keep the crossings visible without that
reconvergence. The cost is throughput: after a burst fills storage, further
reads and writes proceed at one word per request/acknowledge round trip, not
one word per clock.

## Observable behavior
All prompt variants require this same behavior.

- Storage accepts `2**LGFIFO` writes before any read. `o_wr_full` is high only when that storage is occupied.
- A write is accepted when `i_wr` is high and `o_wr_full` is low, on the edge selected by `WRITE_ON_POSEDGE`.
- A read is accepted when `i_rd` is high and `o_rd_empty` is low.
- A write while full does not change stored data. A read while empty does not change `o_rd_data` and does not drop a later word.
- Accepted data returns exactly once, in write order.
- While write reset is asserted, `o_wr_full` is low. While read reset is asserted, `o_rd_empty` is high.
- `o_rd_empty` can be high while words remain stored. The read side presents one stored word at a time. After a read, empty may return high until the next stored word becomes visible.
- `OPT_REGISTER_READS` selects whether the read data and empty flag are registered.
- `NFF` is the synchronizer depth. Values below 2 are implemented as 2.
- No FORMAL-only ports.

## Evaluation
The supplied testbench checks reset, an 8-word fill with no read, rejection of a write while full, in-order readout, and the absence of an extra word. It instantiates registered reads and posedge writes.
Jasper must show zero raw CDC/RDC errors, zero waivers, and at least one extracted crossing while the clocks stay asynchronous.


## CDC-clean benchmark v2 revision

Payloads pass through two destination-clock stages before they are advertised as valid. Preserve source ownership of each queued word until its accepted destination transfer; synchronization stages alone do not establish multi-bit coherence. Availability may lag and bubbles may span multiple destination clocks. There is no one-beat-per-clock guarantee. Register the offered word in the write domain before launching its request. NFF sets the minimum control synchronization depth; additional request-settling stages are permitted. OPT_REGISTER_READS selects an additional destination holding register or the synchronized destination payload, never an asynchronous memory bypass.

This revision retains distinct clocks and actual crossing extraction. Validation requires compile, functional TB, structural lint, enhanced TB, bounded formal assertions plus cover reachability, and Jasper zero raw CDC/RDC errors with zero waivers. Do not interpret bounded assertions as an unbounded proof or structural analysis as MTBF signoff.
