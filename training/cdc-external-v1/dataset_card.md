# External CDC training set

This dataset is external to the sealed 44-circuit exam. It contains permissively licensed upstream CDC and reset-crossing RTL paired with newly written specifications. No exam RTL, prompt, generated artifact, repair log, simulator output, Jasper report, formal result, benchmark source, or testbench log is included.

The exam remains a separate 1,320-generation flow: generation, compilation, functional testbench, structural CDC lint (`cdc_tb_checks/lint_cdc.py`), enhanced behavioral tests, formal proof where a contract exists, and optional JasperGold as an independent oracle. This collection does not rebuild that flow, write Jasper TCL, or train a model.

Sources are pinned per module in `PROVENANCE.json`. Repository-level splits are recorded in `manifest.jsonl`; development modules are excluded from `train.jsonl`.
