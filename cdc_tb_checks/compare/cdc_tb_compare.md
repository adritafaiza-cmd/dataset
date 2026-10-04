# CDC TB comparison (edited testbench)

Each cell is lint_ok/n and sim_ok/n for circuits with embedded Verilog monitors. Golden must stay lint-clean. Generated: fraction the CDC lint did **not** flag.

| Circuit | golden | complexvcoder | qwen-32b | llama-70b-openrouter | gpt-5.6-sol |
|---|---|---|---|---|---|
| afifo | 1/1 lint (clean) · 1/1 sim | 5/6 lint (C) · 0/6 sim | — | 3/6 lint (C) · 0/6 sim | — |
| apb_cdc | 1/1 lint (clean) · 1/1 sim | 6/6 lint (clean) · 0/6 sim | — | 6/6 lint (clean) · 0/6 sim | — |
| apb_regs | 1/1 lint (clean) · 1/1 sim | 6/6 lint (clean) · 0/6 sim | — | 6/6 lint (clean) · 0/6 sim | — |
| apbslave | 1/1 lint (clean) · 1/1 sim | 6/6 lint (clean) · 0/6 sim | — | 6/6 lint (clean) · 3/6 sim | — |
| apbxclk | 1/1 lint (clean) · 1/1 sim | 1/3 lint (B) · 0/3 sim | 0/6 lint (I) · 0/6 sim | — | 0/9 lint (B) · 9/9 sim |
| arbiter | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 2/6 sim | — |
| areset_deassert_sync | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 3/6 sim | — |
| areset_sync | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 6/6 sim | — |
| async_bidir_fifo | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| async_bidir_ramif_fifo | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| async_fifo | 1/1 lint (clean) · 0/1 sim | — | 0/6 lint (I) · 0/6 sim | — | 17/20 lint (C) · 0/20 sim |
| async_fifo_sv | 1/1 lint (clean) · 1/1 sim | — | — | 2/6 lint (C) · 0/6 sim | — |
| axi_dma | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 1/6 sim | — |
| axidma | 1/1 lint (clean) · 1/1 sim | — | — | 5/5 lint (clean) · 0/5 sim | — |
| axil_cdc | 1/1 lint (clean) · 1/1 sim | — | — | 5/6 lint (I) · 0/6 sim | — |
| axis_adapter | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| axis_async_fifo | 1/1 lint (clean) · 1/1 sim | — | — | 4/6 lint (C) · 0/6 sim | — |
| axis_async_fifo_adapter | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| axis_fifo | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| axis_register | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 4/6 sim | — |
| axis_switch | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 2/6 sim | — |
| axixclk | 1/1 lint (clean) · 1/1 sim | — | — | 5/6 lint (I) · 0/6 sim | — |
| cdc_2phase | 1/1 lint (clean) · 1/1 sim | — | 5/6 lint (I) · 0/6 sim | 4/4 lint (clean) · 0/4 sim | 14/20 lint (G) · 20/20 sim |
| cdc_2phase_clearable | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| cdc_4phase | 1/1 lint (clean) · 1/1 sim | — | — | 5/6 lint (I) · 1/6 sim | — |
| cdc_fifo_2phase | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 1/6 sim | — |
| cdc_fifo_gray | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| cdc_fifo_gray_clearable | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| cdc_reset_ctrlr | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| data_sync | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 2/6 sim | — |
| edge_propagator | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 4/6 sim | — |
| i2c_master | 1/1 lint (clean) · 1/1 sim | — | — | 5/6 lint (I) · 0/6 sim | — |
| isochronous_4phase_handshake | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| isochronous_spill_register | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| pulse_sync | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| rstgen | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| spi_master_slave | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| sync | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 6/6 sim | — |
| sync_multistage | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 6/6 sim | — |
| sync_reset | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 6/6 sim | — |
| sync_wedge | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| synchronizer | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 5/6 sim | — |
| uart16550 | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
| wbxclk | 1/1 lint (clean) · 1/1 sim | — | — | 6/6 lint (clean) · 0/6 sim | — |
