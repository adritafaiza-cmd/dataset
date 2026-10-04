# Formal verification policy

SymbiYosys results in this directory are **contract-specific digital proofs**.
They are not simulations of analog metastability and are not interchangeable
with JasperGold CDC/RDC reports.

## Eligibility gate

A generated candidate is eligible for formal scoring only when:

1. the circuit has a documented formal contract;
2. the contract's prove task passes on `benchmarks/<circuit>/fixed/rtl/`;
3. the candidate top module, parameters, and ports match that contract; and
4. Yosys elaborates the candidate with the declared dependency policy.

The golden result must be regenerated whenever its harness, assumptions,
properties, engine, or proof depth changes.

## Primary result categories

- `FORMAL_UNSUPPORTED`: no golden-validated contract for this circuit.
- `FORMAL_SKIPPED_COMPILE`: the candidate failed the prerequisite RTL compile.
- `FORMAL_SKIPPED_INTERFACE`: the candidate does not match the contract.
- `FORMAL_ELAB_ERROR`: Yosys could not elaborate the formal design.
- `FORMAL_PROVED`: the prove task passed under the recorded assumptions.
- `FORMAL_COUNTEREXAMPLE`: an assertion failed and a trace was produced.
- `FORMAL_TIMEOUT`: the configured wall-clock limit expired.
- `FORMAL_INCONCLUSIVE`: unknown, engine error, or incomplete proof.

Report `n_eligible`, `n_run`, `n_proved`, `n_counterexample`,
`n_timeout`, and `n_unsupported` separately. Do not use all generated files as
the denominator for a formal pass rate when some circuits lack validated
contracts.

## Evidence boundaries

- Enhanced testbench records are simulation evidence of observable digital
  behavior.
- JasperGold reports are structural CDC/RDC evidence.
- SymbiYosys results prove only the assertions encoded by a circuit's formal
  contract.
- A formal pass must not be labeled generically as "CDC clean."

All 44 benchmark specifications are currently marked `draft`; 33 circuits are
also `imported_unverified`. Results must remain stratified by benchmark status.

## Current validated coverage

A generated candidate is scored only if `formal/<circuit>/golden_prove/PASS`
exists. Run those ComplexVCoder files with:

```text
python3 scripts/evaluate_symbiyosys_eligible.py
```

Results: `formal/eligible_generated_summary.json`.

Circuits without a golden PASS remain `FORMAL_UNSUPPORTED` and are not counted
as model failures.
