# v1 record for the 20 circuits whose reference RTL changed

The live benchmark now holds the CDC-clean v2 reference for these circuits.
This directory keeps the previous record that Llama and ComplexVCoder were scored against:

- `golden/` is the reference RTL from git HEAD before this revision
- `prompts/` are the three prompts used to generate the broken designs
- `generated/complexvcoder/` and `generated/llama/` are those models' Verilog files

Do not use these files as the prompts for the new OpenRouter run.
The new prompts are `experiments/prompts/<circuit>.{functional,cdc_explicit,observable}.md`.
The new reference RTL is `benchmarks/<circuit>/fixed/rtl/`.

Circuits (20):
- afifo
- apb_cdc
- apb_regs
- apbxclk
- async_bidir_fifo
- async_fifo
- async_fifo_sv
- axil_cdc
- axis_async_fifo
- axis_async_fifo_adapter
- axixclk
- cdc_2phase
- cdc_2phase_clearable
- cdc_4phase
- cdc_fifo_2phase
- cdc_fifo_gray
- cdc_fifo_gray_clearable
- cdc_reset_ctrlr
- spi_master_slave
- wbxclk

Counts: 50 golden files, 60 prompts, 600 ComplexVCoder files, 600 Llama files.
Missing generated attempts: 0.
