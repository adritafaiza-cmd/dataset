# Archive

Local working copies of the repository's previous upstream-project-oriented
layout may be kept here during migration:

- `upstream/` contains the imported project snapshots.
- `non_cdc/` contains circuits outside the current 11-design CDC pilot.
- `legacy/` contains the former top-level JasperGold wrappers.

Active benchmark inputs and run scripts live under `benchmarks/`. New
experiments should not depend on paths in this archive. Archive contents are
ignored; the complete previous layout remains available through Git history.
