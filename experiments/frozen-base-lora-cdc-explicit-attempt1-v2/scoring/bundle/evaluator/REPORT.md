# CDC-clean benchmark v2 validation

All 44 reference circuits pass the following checks in the isolated v2 tree. No circuit was excluded.

| Check | Pass |
|---|---:|
| compile | 44/44 |
| functional | 44/44 |
| formal | 44/44 |
| lint | 44/44 |
| enhanced | 44/44 |
| jasper | 44/44 |

Jasper reports zero raw CDC/RDC errors and zero waived violations on every reference. All 24 multi-clock references retain both declared clocks. The 22 asynchronous references have positive extracted crossing pairs; the two isochronous references retain their documented generated-clock relationship and do not produce asynchronous pairs. The remaining 20 are single-clock controls. All SDC and per-circuit Jasper setup files are unchanged from v1.

The three handshake primitives also pass Jasper with WIDTH=8. Two deliberate faults are rejected: a control-synchronizer bypass by Jasper, and payload corruption by the functional TB, enhanced TB, and a concrete bounded-formal counterexample.

## What changed

The 18 originally flagged references now synchronize payloads before use while retaining queue ownership or request/acknowledge protection. Additional settling/availability latency is documented. Bidirectional storage uses separate directional banks. APB register byte preservation/access-phase behavior and reset-controller isolate/clear/release sequencing were also corrected. RTL changed in 20 circuits:

afifo, apb_cdc, apb_regs, apbxclk, async_bidir_fifo, async_fifo, async_fifo_sv, axil_cdc, axis_async_fifo, axis_async_fifo_adapter, axixclk, cdc_2phase, cdc_2phase_clearable, cdc_4phase, cdc_fifo_2phase, cdc_fifo_gray, cdc_fifo_gray_clearable, cdc_reset_ctrlr, spi_master_slave, wbxclk.

Specifications and all three prompt profiles were updated for the 20 RTL changes. Functional/observable profiles state behavior; CDC-explicit profiles retain the additional CDC guidance. Existing functional and enhanced assertions were preserved, except that APB strobe expectations now require unstrobed-byte preservation rather than the previous incorrect clearing behavior.

## Formal evidence and limits

Every circuit passes both bounded assertions and cover reachability. Assertion depths extend beyond the latest reached cover for each circuit. VALIDATION.csv lists all bounds. These are bounded model checks under the specified harness clocks, assumptions, and configurations—not unbounded functional proofs or metastability/MTBF signoff.

Formal repairs include preventing startup-counter wrap, separating typed-DUT elaboration from native symbolic harness handling, driving explicit clocks across frontend boundaries, reset-aware APB state assertions, legal APB/Wishbone environment assumptions, and Wishbone error-abort semantics. No assertion was removed merely to make a golden pass. The full byte-state model replaces incorrect reset/address assumptions with explicit state tracking.

## Version boundary

The original 994 benchmark/support files are unchanged and archived in ../cdc-clean-v1-frozen.tar.gz. The earlier base/LoRA candidate comparison belongs to v1 and remains unchanged. Revised v2 prompts/contracts require fresh matched base and LoRA generations for a primary v2 comparison; do not relabel the old scores or regenerate only one arm.

No model generation, retraining, or repair feedback occurred during this revision. Goldens and Jasper reports remain evaluation assets and must stay out of model inputs.

## Reproduce

From the original repository root:

```bash
python3 benchmark-revisions/cdc-clean-v2/scripts/validate_cdc_clean_v2.py
python3 benchmark-revisions/cdc-clean-v2/scripts/validate_cdc_clean_v2.py --circuits cdc_2phase cdc_2phase_clearable cdc_4phase --checks jasper --parameter WIDTH=8
python3 benchmark-revisions/cdc-clean-v2/scripts/validate_cdc_v2_negative_controls.py
python3 benchmark-revisions/cdc-clean-v2/scripts/seal_cdc_clean_v2.py
```

Commercial checks require the working Xcelium/Jasper license environment. The validator uses the installed oss-cad-suite for formal checks. VALIDATION.json records source hashes and individual log paths.
