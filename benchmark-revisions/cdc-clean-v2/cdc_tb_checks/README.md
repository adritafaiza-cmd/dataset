# CDC checks for functional simulation

Open-source supplement to the functional testbenches. All 44 benchmark TBs
now contain plain-Verilog procedural monitors directly in the existing TB
file; there are no separate per-circuit SVA bind files.

The monitors cover simulation-visible behavior such as reset isolation,
unknown outputs, valid/data stability under backpressure, and protocol
responses during reset.

`lint_cdc.py` remains separate because zero-delay Verilog simulation cannot
observe metastability or prove structural CDC properties. It scans generated
RTL for missing synchronizers, foreign-domain asynchronous resets, binary
pointer crossings, truncated RTL, and reset logic anti-patterns.

| File | Role |
|---|---|
| `lint_cdc.py` | Structural checks that simulation cannot reliably detect |
| `MARKS.md` | Violation taxonomy and detection method |
| `compare/` | Golden-versus-generated lint/simulation results |

The benchmark testbench itself is the single source for behavioral checks.
