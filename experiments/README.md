# Model experiment outputs

Store generated RTL by model, benchmark, and attempt:

```text
experiments/
└── <model-id>/
    └── <benchmark-id>/
        └── attempt-001/
            ├── prompt.md
            ├── response.txt
            ├── generated/
            │   └── <top>.v
            ├── metadata.json
            └── results.json
```

Do not overwrite failed generations. Every attempt is part of the measured
pass rate.

`metadata.json` should record:

- model provider, model ID, and revision
- prompt-template revision
- temperature, top-p, maximum tokens, and seed
- generation timestamp, runtime, and token counts

`results.json` should record independent outcomes for compilation, functional
simulation, assertions, CDC, RDC, and synthesis. Keep raw tool output under
`build/`; promote only compact, reviewed result summaries into Git.
