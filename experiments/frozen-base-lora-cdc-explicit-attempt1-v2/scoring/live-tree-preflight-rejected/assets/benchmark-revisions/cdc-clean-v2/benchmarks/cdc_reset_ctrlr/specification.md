# cdc_reset_ctrlr generation specification

> Status: draft. Review this document before using it as an LLM prompt.

## Objective
Lock-step isolate-then-clear sequencer for both sides of a CDC.

## Required interface and behavior
- Implement a synthesizable `cdc_reset_ctrlr` module compatible with the supplied testbench.
- Each side still isolates, then clears, on its own acknowledgments, and releases only after the peer has reported completion. The peer status is a registered code sent in order (idle, then active, then done, then released, then idle). A code is not launched until the previous transfer is acknowledged, so the peer sees a step one handshake later than the local transition. Completion must still be observed before isolate and clear fall.
- Preserve the catalog reference behavior from `https://github.com/pulp-platform/common_cells`.
- Handle reset assertion and release without creating unsafe CDC or RDC paths.
- Do not use the reference implementations as model input.

## Evaluation
The supplied testbench passed after the ordered-code repair. That is not a formal proof of the sequencing. Jasper structural CDC on the repaired RTL is a separate result: zero raw CDC errors, zero reset-domain errors, zero waivers, with crossings extracted.


## CDC-clean benchmark v2 correction

Both sides must acknowledge isolation before clearing begins. Hold clear while completion is exchanged with the peer. Drop clear before releasing isolation, and exchange an explicit release status so neither side leaves isolation while its peer is still clearing. Complete one sequence before accepting another. Added handshake latency is permitted.

The formal contract includes state/sequence assertions and reachable transaction covers. Bounded checks are reported with their exact depths.
