# AK — Public CDC benchmark release gap and open-source first-pass plan

**Status: RELEASE BLOCKER**

**Date:** 2026-09-29

## Decision

The current checkout is not yet sufficient for the intended public CDC
benchmark. It can compile generated RTL and detect many functional symptoms,
but it does not consistently identify which common CDC rule failed across all
44 circuits. The benchmark must not be described as a self-contained CDC
screen until the typed enhanced tests, structural checks, rule coverage, and
mutation validation described below are present and passing.

This blocks publication of the current `strict_pass` result as a CDC-quality
score. Existing results remain useful as CodeV-R1 generation, compilation, and
canonical-functional-testbench evidence.

## Intended public claim

The release should support this claim:

> The benchmark applies a reproducible, open-source first-pass CDC review to
> generated RTL. It rejects common unsynchronized crossings, reset mistakes,
> incoherent multi-bit transfers, and broken CDC protocols covered by its
> published rules and tests. Passing means no covered rule fired under the
> published structural and dynamic checks; it does not prove metastability
> safety or replace implementation-aware CDC signoff.

It should not claim that a passing design is CDC-safe, silicon-safe, or
equivalent to JasperGold/Vivado/Questa CDC signoff. “Ten rules cover 90% of
first review findings” is presently a design target, not a measured fact. That
coverage statement may be made only after the mutation campaign and, ideally,
an engineer-reviewed sample establish it.

## Evidence for the current gap

- The September progress report describes `enhanced_cdc_tb/`,
  `cdc_tb_checks/lint_cdc.py`, typed rule messages, and 6/6 initial mutation
  detection. Those directories are absent from this checkout.
- All 44 circuits have canonical testbenches and SDCs, but only three actively
  used testbenches (`apbxclk`, `axixclk`, and `wbxclk`) emit generic
  `ASSERT FAIL` protocol messages. No complete 44-circuit suite currently
  emits `CDC/RESET VIOLATION [RULE_ID]` or
  `PROTOCOL VIOLATION [RULE_ID]`.
- The Phase 1 supervisor evaluator added two heuristic source rules,
  `AK_CDC_DIRECT_REG_CROSSING` and `AK_CDC_MULTI_DOMAIN_DRIVER`. They are
  useful triage, but regex-based source inspection cannot robustly reconstruct
  hierarchy, parameters, memories, generated blocks, signal widths, or all
  legal crossing architectures.
- SDC checking currently confirms clock names and a declared asynchronous
  relationship. It does not prove that every crossing has the correct
  topology or appropriate bus-skew/max-delay treatment.
- Of 214 compiled CodeV-R1 attempts, 121 passed simulation and 93 did not. Logs
  provide a concrete mismatch/assertion symptom for 48 nonpasses; 24 provide
  only a testbench timeout and 21 hit the evaluator timeout. Failure details
  are not normalized into per-attempt JSON.
- Twenty-eight testbench-emitted `TIMEOUT` outcomes are currently folded into
  the functional/protocol bucket because only evaluator-process timeout is a
  structured result field.

## Technical basis for an open-source first-pass screen

The proposed scope follows recurring topology classes in AMD's CDC rule set:
unsynchronized single- and multi-bit crossings, asynchronous reset,
combinational logic before synchronization, synchronizer fanout, and
multi-clock fan-in. AMD explicitly describes CDC reporting as structural
analysis for metastability and coherency risks, rather than timing-slack
analysis. Intel likewise recommends destination-domain synchronization chains,
synchronous reset deassertion, coherent handling of multi-bit data, and
one-bit-change Gray transfers with appropriate constraints.

Relevant public references:

- [AMD UG906 CDC rule precedence](https://docs.amd.com/r/2021.1-English/ug906-vivado-design-analysis/CDC-Rules-Precedence)
- [AMD UG906 CDC structural-analysis overview](https://docs.amd.com/r/2021.1-English/ug906-vivado-design-analysis/Report-Clock-Domain-Crossings)
- [AMD UG906 multi-bit synchronizer guidance](https://docs.amd.com/r/2024.1-English/ug906-vivado-design-analysis/Multi-Bit-Synchronizer)
- [Intel metastability and synchronizer-chain guidance](https://www.intel.com/content/www/us/en/docs/programmable/683068/18-1/metastability-analysis.html)
- [Intel reset synchronization rules, AN 919](https://www.intel.com/programmable/technical-pdfs/683369.pdf)
- [Intel Gray-coded FIFO crossing constraints](https://www.intel.com/content/www/us/en/docs/programmable/683241/24-3/user-configurable-timing-constraint.html)
- [OpenTitan assertion conventions](https://github.com/lowRISC/opentitan/blob/master/hw/formal/README.md)
- [OpenTitan hardware/CDC methodology](https://opentitan.org/book/doc/contributing/hw/methodology.html)
- [Yosys JSON netlist output](https://yosyshq.readthedocs.io/projects/yosys/en/v0.55/cmd/write_json.html)
- [SBY multi-clock behavior and limitations](https://yosyshq.readthedocs.io/projects/ap011/en/latest/unexpected.html)

## Proposed ten-rule first-pass CDC contract

Every rule must have a stable public identifier, applicability declaration,
machine-readable evidence, at least one positive mutant, and a golden negative
test. Structural and dynamic evidence must be retained separately.

| ID | Common issue | Required structural check | Required dynamic check |
|---|---|---|---|
| `AK_CDC_01_RAW_CONTROL` | A single-bit control crosses directly into another domain or has fewer than two visible destination stages. | Build a clock-domain graph from an elaborated netlist; flag source-domain flop-to-destination-domain flop paths that do not match an approved scalar synchronizer. Record source/destination clocks, cells, net, width, and source locations. | Sweep unrelated clock ratios/phases and assert no destination event occurs before the specified synchronization latency, no X reaches functional logic, and no spurious transition occurs. Simulation tests behavior; it does not model analog metastability. |
| `AK_CDC_02_SYNC_CHAIN_INTEGRITY` | A nominal synchronizer has combinational logic between stages, first-stage fanout, stage bypass, multiple destination clocks, or multi-clock fan-in. | Recognize the complete chain in the elaborated graph. Require direct stage-to-stage connectivity, one destination clock, no functional fanout from intermediate stages, and no bypass to downstream logic. | Check expected minimum/maximum latency and one destination transition per stable source transition. Emit the exact topology subreason. |
| `AK_CDC_03_MULTI_BIT_COHERENCY` | A binary counter, state, address, or payload bus is synchronized bit-by-bit or sampled without a coherence protocol. | Flag multi-bit cross-domain cones unless classified as Gray, handshake-held bundled data, mux/CE-held transfer, or async FIFO storage. Require explicit manifest architecture and reject an unclassified bus. | Scoreboard complete words for known value, atomicity, order, loss, and duplication under phase/ratio stress. For declared Gray buses, assert `$onehot0(previous ^ current)` in the source domain. |
| `AK_CDC_04_RECONVERGENCE` | Independently synchronized signals reconverge and create an illegal combined state or glitch. | Detect two or more independently synchronized paths from a common or related source cone that reconverge in destination combinational logic or state decisions. | Drive near-simultaneous source transitions and assert legal destination encodings, mutual exclusion/one-hot properties, and absence of transient commands. |
| `AK_CDC_05_PULSE_EVENT` | A pulse or edge is too narrow, lost, duplicated, stretched incorrectly, or reissued before acknowledgment. | Require a recognized pulse stretcher, toggle synchronizer, or closed-loop event handshake for declared event crossings. Flag raw pulse-to-2FF structures where the source pulse can be shorter than a destination period. | Count source and destination events; require exactly-once delivery within a documented bound, legal pulse width, no duplicate, and correct behavior for back-to-back events and extreme clock ratios. |
| `AK_CDC_06_REQ_ACK_HANDSHAKE` | Request/acknowledge ordering is broken: request drops early, acknowledgment is spurious, transactions overlap illegally, or progress is unbounded. | Confirm each request and acknowledgment crosses through an approved synchronizer and that no first-stage signal drives protocol state. | Assert request persistence until acknowledgment, no ack without an outstanding request, at most one completion per request, no illegal overlap, and bounded progress under a receptive destination. Test independent reset during every handshake phase. |
| `AK_CDC_07_ASYNC_FIFO` | FIFO pointers cross in binary, Gray transitions are invalid, full/empty logic is wrong, or overflow/underflow/data ordering is broken. | Identify write/read domains, pointer encodings, synchronization chains, memory ownership, and full/empty compare cones. Flag binary-pointer crossing, missing stages, unsafe pointer reconvergence, and multi-domain writes to state. | Scoreboard accepted data for order/loss/duplication; check overflow/underflow suppression, full/empty correctness, Gray one-bit transitions, pointer monotonicity, wraparound, reset flushing, and independent reset recovery. Sweep depth and clock ratios. |
| `AK_CDC_08_BUNDLED_DATA_HOLD` | Data or sideband changes while its synchronized valid/request is in flight or while the destination is stalled. | For a declared bundled-data crossing, identify the control synchronizer and verify that the data path is not independently synchronized or captured before the control-qualified point. | Snapshot payload and sidebands when the transfer begins; require stability through acknowledgment/acceptance and backpressure. Check coherent capture, exact data association, and no stale post-reset payload. |
| `AK_CDC_09_RESET_DOMAIN` | Asynchronous reset deasserts unsafely, a foreign-domain reset controls local state, domains restart inconsistently, or stale requests escape after partial reset. | Associate every sequential element with clock and reset domains. Require asynchronous-assert/synchronous-deassert chains where that policy applies; flag foreign reset use, insufficient reset stages, combinational reset gating, and reset used as ordinary CDC control. | Check immediate safe assertion, domain-clocked deassertion after the required stages, no early valid/request/full indication, quiescence while either side is reset, no stale transaction after one-sided reset, and clean protocol recovery. |
| `AK_CDC_10_CLOCK_CONSTRAINT` | A clock is undeclared, asynchronous relationships are missing, generated/gated/muxed clocks are misclassified, or a crossing lacks architecture/constraint coverage. | Cross-check manifest clocks/resets, elaborated clock pins, and SDC objects. Require every clock pair and crossing to have an explicit relationship and every exception to map to a recognized CDC architecture. Flag multi-clock-driven state and unsafe combinational clock gating. | Exercise declared clock-stop/start and ratio/phase scenarios where applicable; check no protocol event depends on a stopped destination clock without a documented hold/recovery mechanism. |

## Required benchmark architecture

### 1. Extend each manifest into an executable CDC contract

Add fields such as:

```yaml
cdc_contract:
  domains:
    - {name: write, clock: wclk, reset: wrst_n}
    - {name: read,  clock: rclk, reset: rrst_n}
  crossings:
    - id: write_pointer
      from: write
      to: read
      kind: gray_counter
      signals: [wptr_gray]
      rules: [AK_CDC_02_SYNC_CHAIN_INTEGRITY, AK_CDC_07_ASYNC_FIFO]
  applicable_rules:
    - AK_CDC_01_RAW_CONTROL
    - AK_CDC_07_ASYNC_FIFO
    - AK_CDC_09_RESET_DOMAIN
  not_applicable:
    AK_CDC_06_REQ_ACK_HANDSHAKE: "No request/acknowledge interface"
```

This prevents a checker from guessing whether an unusual topology is intended
and makes `not applicable` an auditable decision rather than an untested gap.

### 2. Replace regex-only structural inspection with elaborated-netlist checks

Use Yosys to elaborate supported RTL and emit a JSON netlist. Analyze clocked
cells, reset pins, widths, hierarchy, and connectivity from that netlist. Keep
the current source locations where possible, but base rule decisions on the
elaborated graph. Unsupported language constructs must be explicit tool
exclusions rather than clean results.

The structural engine should emit one JSON record per finding:

```json
{
  "rule_id": "AK_CDC_02_SYNC_CHAIN_INTEGRITY",
  "severity": "error",
  "from_clock": "src_clk_i",
  "to_clock": "dst_clk_i",
  "source": "u_src/req_q",
  "endpoint": "u_dst/req_sync1_q",
  "subreason": "first_stage_fanout",
  "evidence": ["u_dst/req_sync1_q -> state_d"]
}
```

### 3. Add portable typed dynamic monitors

Prefer simulator-portable procedural monitors for the required public path so
Icarus and Verilator users get the same rule IDs. SVA bindings may be supplied
as an additional implementation, but the required checks must not depend on a
commercial simulator or unsupported SVA feature.

Every failure must use one of:

```text
CDC/RESET VIOLATION [AK_CDC_09_RESET_DOMAIN]: reset released before two dst clocks
PROTOCOL VIOLATION [AK_CDC_06_REQ_ACK_HANDSHAKE]: ack without outstanding request
FUNCTIONAL VIOLATION [AK_FUNC_FIFO_ORDER]: item=7 expected=0x31 actual=0x13
```

The evaluator must parse all occurrences, not just the first, and store the
rule ID, message, timestamp/cycle, signals, and evidence class.

### 4. Use deterministic CDC stress schedules

Each applicable dynamic test should cover multiple co-prime clock ratios,
relative phases, randomized-but-recorded jitter, reset assertion near both
clock edges, independent reset of each domain, backpressure, wraparound, and
clock stop/restart where relevant. The exact seed and schedule belong in the
result record. A single friendly clock ratio is not adequate CDC stress.

### 5. Normalize result data and scoring

Each attempt should report independent stages:

```json
{
  "generation": "pass",
  "compile": "pass",
  "functional": "fail",
  "dynamic_cdc": "fail",
  "structural_cdc": "fail",
  "constraint_check": "pass",
  "process_timeout": false,
  "testbench_timeout": true,
  "evidence": [
    {"rule_id": "AK_CDC_06_REQ_ACK_HANDSHAKE", "class": "dynamic_cdc"}
  ]
}
```

Use `first_pass_screen_pass` only when compilation, functional checks, all
applicable dynamic CDC rules, structural rules, and constraint checks pass.
Never derive “CDC failures” by subtracting strict passes from attempts.

Recommended reported metrics:

- Generation yield over all planned attempts.
- Compile and functional rates over both planned and generated attempts.
- Per-rule finding counts and per-rule affected-attempt counts.
- Dynamic CDC, structural CDC, and constraint results separately.
- First-pass-screen pass@1/pass@k over all planned attempts.
- Tool exclusions and unsupported circuits separately.

### 6. Validate rule sensitivity with mutants

Create at least two independently implemented positive mutants for each rule
family and safe negative controls for every accepted crossing architecture.
Examples include deleting a synchronizer stage, changing a Gray pointer to
binary, adding first-stage fanout, dropping request early, shortening a pulse,
changing payload under backpressure, releasing one reset early, and removing
an SDC clock relationship.

Release acceptance requires:

- 100% of required mutants detected with the expected rule ID.
- 44/44 golden circuits pass every applicable rule, or have a reviewed,
  published exclusion with rationale.
- No generic failure without a typed rule or functional check ID.
- Every rule is exercised by at least one real circuit and one mutant.
- Repeated runs are deterministic from the stored seed and tool versions.

Mutation sensitivity measures coverage of known injected mistakes. It does not
measure all possible CDC defects. A “90% of first-review issues” statement
requires an additional labeled set of historical or engineer-created defects
and a reported confidence interval.

### 7. Package one public command

Provide a pinned open-source environment and one command that performs:

1. manifest/schema validation;
2. compile/elaboration;
3. canonical functional simulation;
4. typed dynamic CDC stress;
5. elaborated-netlist structural checks;
6. SDC/clock/reset contract validation;
7. JSON and Markdown report generation.

Icarus or Verilator should be the required simulator. Yosys JSON provides the
required structural graph. SBY may be an optional bounded property layer for
supported circuits, but it must not be the sole implementation of multi-clock
checks because public SBY documentation notes limitations around properties
spanning multiple clock domains.

## Implementation order before Phase 2 interpretation

1. Search branches, archives, and the other verification machine for the
   documented `enhanced_cdc_tb/`, `cdc_tb_checks/`, and mutation artifacts.
2. Freeze the ten rule IDs and manifest contract schema.
3. Restore or implement the structural engine on Yosys JSON, retaining the
   present heuristics only as temporary comparison checks.
4. Restore or implement typed procedural monitors for all 44 circuits.
5. Normalize failure evidence and distinguish testbench from process timeout.
6. Build the ten-family mutation suite and run it against golden RTL.
7. Resolve every golden warning or publish a narrow tool/benchmark exclusion.
8. Only then rescore the preserved CodeV-R1 candidates and begin model failure
   interpretation using the new rule IDs.

This order avoids analyzing model failures against a checker that is known to
be incomplete and prevents the public benchmark from presenting heuristic
absence of evidence as CDC cleanliness.
