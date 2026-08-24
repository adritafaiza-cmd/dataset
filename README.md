# CDC-Aware RTL Generation Benchmark

This repository is a research benchmark for evaluating whether language models
can generate RTL that is both functionally correct and safe across clock and
reset domain crossings.

## Pilot dataset

The Jasper-verified pilot contains 11 circuits:

- Asynchronous FIFOs: `async_fifo`, `async_bidir_fifo`,
  `async_bidir_ramif_fifo`
- Bus clock bridges: `apbxclk`, `axixclk`, `wbxclk`
- AXI-Stream FIFOs: `axis_async_fifo`, `axis_async_fifo_adapter`
- Handshake CDCs: `cdc_2phase`, `cdc_4phase`,
  `cdc_2phase_clearable`

An additional 33 catalog circuits are imported under `benchmarks/` with
Verilog RTL, testbenches, SDC constraints, and JasperGold scripts. Their
manifests remain `imported_unverified` and specifications remain draft.
They are not part of the frozen 3-circuit generation pilot.

Each directory under `benchmarks/` contains:

```text
original/rtl/       RTL before benchmark-specific CDC/RDC fixes
fixed/rtl/          verified reference RTL
constraints/        SDC clock constraints
tb/                 functional testbench
jasper/run.tcl      JasperGold CDC/RDC analysis
sim/run.sh          Xcelium functional simulation
manifest.yaml       machine-readable provenance and file list
specification.md    draft model-generation specification
```

The original RTL is retained as an experimental baseline. The corrected RTL is
the reference implementation and must not be included in model prompts.

## Clone

The clearable PULP benchmark uses a pinned `common_cells` dependency:

```bash
git clone --recurse-submodules https://github.com/adritafaiza-cmd/dataset.git
```

For an existing clone:

```bash
git submodule update --init --recursive
```

## Functional simulation

Run one benchmark:

```bash
./benchmarks/async_fifo/sim/run.sh
```

Run all pilot simulations:

```bash
./scripts/run_all_sim.sh
```

Compile/elaborate all tests without consuming a simulation runtime license:

```bash
COMPILE_ONLY=1 ./scripts/run_all_sim.sh
```

Xcelium must be available as `xrun`. Generated files are written under
`build/sim/`.

## JasperGold CDC/RDC analysis

In `tcsh`:

```tcsh
setenv DS /path/to/dataset
jg -batch $DS/benchmarks/async_fifo/jasper/run.tcl
```

Run all pilot designs:

```tcsh
setenv DS /path/to/dataset
$DS/scripts/run_all_jasper.csh
```

Reports are written under `build/jasper/<benchmark>/`.

## Intended model evaluation

For each model and generation attempt, preserve the prompt, raw response,
extracted RTL, model/version, decoding parameters, seed, runtime, and token
usage. Evaluate every output using the same stages:

1. HDL compilation
2. Functional simulation
3. Protocol assertions
4. JasperGold CDC/RDC analysis
5. Synthesis

Specifications are currently marked `draft`; they require review to ensure
that they describe behavior without leaking reference implementation details.

## Provenance

- Baseline repository snapshot: commit `0d63dfb`
- CDC/RDC-corrected pilot snapshot: commit `a609317`
- PULP `common_cells`: pinned Git submodule under `vendor/common_cells`

Upstream project URLs and file lists are recorded in each
`manifest.yaml`. Preserve applicable upstream copyright and license notices
when redistributing benchmark sources.
