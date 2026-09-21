# Daily CDC benchmark progress report

**Researcher:** Faiza  
**Work period:** 20–21 September 2026  
**Scope:** CDC/reset-aware RTL benchmark development and no-Sol generated-RTL evaluation

## Executive summary

Today’s work converted the CDC/reset checks into a reproducible, typed
verification flow covering all 44 benchmark circuits. The flow now distinguishes
compilation, functional/protocol, dynamic CDC/reset, structural CDC lint, timeout,
and strict-pass outcomes.

The no-Sol run evaluated 276 reusable generated RTL attempts:

- 22 strict passes (8.0%)
- 143 compilation failures (51.8%)
- 49 primary functional/protocol failures (17.8%)
- 55 primary dynamic CDC/reset failures (19.9%)
- 7 timeouts (2.5%)

The automated classifier found CDC-related evidence in 78 compilable attempts:
74 Llama and 4 ComplexVCoder. These should be described as **automatically
attributed CDC/reset findings**, not as 78 proven CDC root causes. Behavioral
symptoms and heuristic lint findings still require waveform/RTL confirmation.

This run demonstrates a substantial generated-RTL reliability problem. It does
not yet establish a statistically supported model-versus-golden CDC gap because
the matrix is incomplete, Qwen was excluded for incompatible metadata, and
golden RTL was not part of this particular comparison.

## What was implemented today

### 1. Existing testbench integration

Plain procedural monitors were embedded into the existing benchmark TBs. They
use `always` blocks, registers, counters and `$display`; no concurrent SVA is
required. Structural checks remain separate because zero-delay simulation
cannot prove synchronizer topology or model metastability.

### 2. Separate enhanced testbench suite

`enhanced_cdc_tb/` now contains one enhanced TB for every one of the 44
circuits, grouped into FIFO, bus, handshake and synchronizer/reset families.
These TBs apply reset stress, clock-ratio stress, transaction scoreboarding,
bounded-progress checks and protocol-specific monitoring.

### 3. Typed evidence

Every enhanced error path emits one of:

```text
CDC/RESET VIOLATION [RULE_ID]: circuit-specific evidence
PROTOCOL VIOLATION [RULE_ID]: circuit-specific evidence
```

The parser preserves all rule IDs rather than collapsing a run into a generic
`TESTS FAILED` line. Untyped failures remain ambiguous. Timeouts and simulator
license/tool failures are infrastructure outcomes and are not counted as CDC
failures.

### 4. Structural CDC lint

`cdc_tb_checks/lint_cdc.py` reports structured rule IDs, source locations,
excerpts and CDC attribution. It checks structural patterns that ordinary
simulation cannot reliably establish.

### 5. Matched experiment framework

`matched_cdc_experiment/` now provides append-only inventory, verification,
mutation and analysis commands; deterministic simulation seeds; strict-pass
classification; per-attempt logs; review queues; rule summaries; paired
bootstrap support; and a mixed-effects model implementation.

### 6. Validation completed

- Typed-evidence audit passed for 44/44 enhanced TBs.
- Python regression suite passed 23/23 tests.
- Representative FIFO, bus, handshake and synchronizer TBs elaborated with
  zero HDL compilation errors.
- The previously prepared mutation campaign detected 6/6 injected defects.
  This is useful initial sensitivity evidence, but it is not yet comprehensive.

## JG-derived/common issue set carried into the TB and lint

The initial issue taxonomy came from common failures identified during
JasperGold CDC/RDC work:

- **A — Raw reset release:** dynamic monitor checks that destination valid,
  request and FIFO status remain safe while reset is asserted.
- **B — Foreign-domain asynchronous reset:** structural lint detects a clocked
  domain controlled by another domain’s reset.
- **C — Binary pointer crossing:** structural lint detects binary FIFO pointers
  or binary arithmetic used directly across domains.
- **D — Missing or bypassed synchronizer stage:** lint detects direct
  request/acknowledge comparisons and first-stage synchronizer bypass.
- **E — Data without hold:** dynamic monitor saves valid/data/sideband values
  and verifies stability while the destination is stalled.
- **F — Abort used as asynchronous reset:** handled by the foreign-reset lint
  family.
- **G — Reset AND-ed into ready:** lint detects reset-dependent combinational
  ready logic that can glitch a handshake.
- **H — Uncoordinated dual reset:** dynamic monitor requires destination
  request/valid to remain idle when either CDC domain is in reset.

These checks preserve the original JG-derived concerns without claiming that
procedural simulation is equivalent to formal CDC/RDC analysis.

## Additional checks added later

### FIFO and bundled-data crossings

- Data ordering, loss, duplication and conservation
- Overflow and underflow
- Write/read/handshake completion timeouts
- Backpressure payload stability
- Reset flushing and post-reset stale-data detection
- Unknown data and status outputs
- Clear-handshake behavior, width conversion and RAM-port conflict checks

### Handshake crossings

- Lost and duplicated requests/responses
- Transfer ordering and exactly-once behavior
- Payload stability under backpressure
- Bounded forward progress
- Reset during an active transfer
- Spurious completion after independent-domain reset

### Synchronizers, pulses and reset controllers

- Expected synchronizer stage latency
- Unknown output propagation
- Pulse/edge loss, duplication and width
- Exactly-once pulse delivery
- Asynchronous reset assertion
- Synchronous reset deassertion, including early/late release
- Reset-controller isolation, clear and release ordering
- Recovery without stale pulses or transactions

### APB, AXI, AXI-Stream, Wishbone and peripherals

- Request/response conservation and response-without-request checks
- Address, data and sideband stability while stalled
- Cross-domain response latency
- Response/data coherency and known-value checks
- AXI-Stream routing, width adaptation, ordering and `last` behavior
- UART, SPI and I2C completion/data checks

Local protocol failures are deliberately labeled `PROTOCOL VIOLATION`; they do
not become CDC findings merely because the circuit belongs to a CDC benchmark.

## Model-to-result comparison

### Llama 3.3 70B through OpenRouter

249 attempts were evaluated:

- 123 compilation failures
- 45 primary functional/protocol failures
- 52 primary dynamic CDC/reset failures
- 22 strict passes
- 7 timeouts
- 74 attempts contained automatically attributed CDC/reset evidence
- 126 attempts compiled; 98 had a failing dynamic stage and 14 had structural
  lint findings

### ComplexVCoder

27 attempts were evaluated:

- 20 compilation failures
- 4 primary functional/protocol failures
- 3 primary dynamic CDC/reset failures
- 0 strict passes
- 4 attempts contained automatically attributed CDC/reset evidence
- 7 attempts compiled; 8 dynamic failures and 3 lint failures were recorded
  across stages, including failures in attempts whose primary status occurred
  earlier

### Prompt comparison

The functional-prompt subset contained 141 attempts and the CDC-explicit subset
contained 135. Each subset produced 11 strict passes and 39 automatically
attributed CDC findings. Because the model/circuit cells are incomplete and
unbalanced, this is descriptive only; it does not show that the CDC-explicit
prompt had no effect.

### Models not represented

- Sol was intentionally excluded from this run.
- Qwen artifacts were excluded because their stored metadata did not satisfy
  the frozen matched-experiment identity requirements.
- Golden RTL was not included in this run and therefore no generated-minus-
  golden effect estimate can yet be calculated.

## Why these failures cannot all be concluded to be CDC failures

### Compilation failures

An RTL that does not elaborate never executes a CDC transfer. Compilation
failure is a model-generation failure, not evidence of a CDC defect.

### Functional and protocol failures

Wrong arithmetic, incorrect state machines, malformed interfaces, bad routing
and local handshake errors can fail the canonical or enhanced TB without any
clock-domain root cause.

### Behavioral CDC symptoms are not always root causes

FIFO ordering errors, transfer timeouts, stale data and request/response count
mismatches are consistent with CDC defects, but they can also result from
ordinary functional bugs. They require an RTL trace or waveform showing the
crossing mechanism before being called confirmed root-cause CDC defects.

### Unknown values are ambiguous

An `X` can indicate unsafe reset or synchronization, but it can also come from
an uninitialized local register, unsupported generated hierarchy or unrelated
functional logic.

### Simulation cannot model metastability

Digital simulation detects observable consequences, not analog metastability,
MTBF or silicon probability. Passing simulation therefore does not prove CDC
safety.

### Structural lint is heuristic

The repository-owned lint is reproducible and useful, but it is not a complete
formal CDC engine. Every publication-level structural finding should retain its
file, line and excerpt and should be manually confirmed or corroborated.

### Tool/TB incompatibility is infrastructure evidence

If an enhanced TB references a golden internal hierarchy that a generated DUT
does not provide, elaboration of that TB is a tool/configuration incompatibility,
not a CDC violation. The classifier keeps simulator/tool failures separate.

### Primary statuses and evidence counts overlap

The 55 primary dynamic CDC/reset failures and 78 CDC-attributed attempts answer
different questions. Primary status records the earliest failure category.
CDC evidence records attributable findings from all completed stages. They must
not be added together.

## What is still needed for a publication benchmark

1. Freeze the no-Sol design before final evaluation: 44 circuits × 3 models ×
   2 prompts × 10 attempts = 2,640 generated records.
2. Repair or regenerate Qwen metadata and fill missing Llama/ComplexVCoder/Qwen
   cells without adaptive cherry-picking.
3. Run all 44 golden RTLs through the identical four-stage strict-pass flow.
   Resolve or predeclare any golden exclusions before model comparison.
4. Split CDC evidence into:
   - direct structural CDC defect,
   - CDC-specific dynamic violation,
   - cross-domain behavioral symptom requiring review.
5. Review every unique model/circuit/rule combination using RTL locations and,
   when needed, waveforms.
6. Expand mutation testing to cover every major rule family and report
   sensitivity by category, not only aggregate detection.
7. Add an open-source simulator path using Verilator or Icarus where supported.
   Cadence Xcelium and JasperGold are proprietary and must not be described as
   open-source tools.
8. Report circuit-macro rates as primary, micro rates as secondary, and use a
   circuit-clustered paired bootstrap against golden. Treat GLMM as sensitivity
   analysis.
9. Release prompts, manifests, seeds, generated RTL, golden hashes, TBs, lint
   rules, mutants, logs, review decisions, tool versions and exclusion reasons.

## Claim that is currently supported

> In the 276 reusable no-Sol generated RTL attempts evaluated under the recorded
> benchmark conditions, 22 (8.0%) achieved strict pass. Compilation and
> functional failures were common, and 78 compilable attempts produced
> automatically attributed CDC/reset evidence requiring structural or waveform
> confirmation.

## Claim that is not yet supported

> The evaluated models have a statistically significant CDC/reset correctness
> gap relative to golden RTL.

That claim requires the completed balanced matrix, validated golden baseline,
adjudicated CDC evidence and paired statistical analysis.

## Main artifacts

- Enhanced TBs: `enhanced_cdc_tb/`
- Typed rule contract: `enhanced_cdc_tb/RULES.md`
- Evidence audit: `enhanced_cdc_tb/check_typed_evidence.py`
- Structural lint: `cdc_tb_checks/lint_cdc.py`
- Matched experiment: `matched_cdc_experiment/`
- Raw 276-attempt results:
  `matched_cdc_experiment/runs/all-model-rtls-typed-20260920T2344Z/results/attempts.jsonl`
- Analysis report:
  `matched_cdc_experiment/runs/all-model-typed-analysis-20260921T0007Z/report/`

