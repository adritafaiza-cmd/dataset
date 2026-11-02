# Frozen CDC LoRA v1 audit

Frozen 2026-11-01. Scope: all 65 previously filter-kept directories; 47 actually trained in job 21601335, 18 skipped at 4096 tokens. Final: 37 keep, 28 drop; no additions. Dev remains excluded.

Job 21601335 completed (Slurm COMPLETED, exit 0:0), 15:23:31–15:30:56 in scheduler time, 7m25s elapsed. Two epochs, 12 optimizer steps; final minibatch loss 0.1944 is training loss, not evaluation accuracy. Original artifacts are retained; run-21601335 preserves the original input and logs. The original adapter is superseded by this manifest and requires exactly one fresh retrain from the base model. Audited retrain outputs go to retrain-audited/.

Method: inspect source.sv and spec.md, trace named crossing instances into local dependencies where needed, compare exact interface declarations and prose clock/reset/port lists. Compare every source module body against original and fixed RTL in all 44 exam directories (211 bodies, including their helper modules), stripping comments/whitespace, normalizing the module name, and separately canonicalizing every identifier; review nearest lexical matches and provenance. No renamed exam source copy was detected. Common short synchronizer idioms alone are not evidence of copying; this is a source audit, not a formal equivalence or CDC correctness proof. The 18 oversized candidates remain excluded; their rows record crossing/interface findings and length exclusion.

For keep rows: spec interface/clocks/resets match, no exam copy was detected, and reset-only entries are small reset primitives/wrappers. Any qualifications are recorded explicitly. Source/spec hashes and comparison results are in audit-evidence.json. The keep rows below are the sole training allowlist; changing it requires a new audit and retrain.

| Module | Decision | Reason |
| --- | --- | --- |
| `amba_clock_gate_ctrl` | drop | Only u_reset_sync crosses; surrounding wakeup/clock-gating controller is not a reset synchronizer primitive. |
| `andesite_training_plane` | drop | Excluded from latest 47 and frozen v1: 8332 tokens exceeds unchanged 4096 limit. Memory-training controller with level and pulse CDC; interface matches, not reset-only. |
| `apb4_slave_cdc` | drop | Excluded from latest 47 and frozen v1: 4465 tokens exceeds unchanged 4096 limit. Command/response async FIFOs exist; spec reset list omits presetn. |
| `apb4_slave_cdc_cg` | drop | Excluded from latest 47 and frozen v1: 5473 tokens exceeds unchanged 4096 limit. Gated command/response async FIFOs exist; spec omits presetn and calls gating/idle status ports clocks. |
| `apb5_slave_cdc` | drop | Excluded from latest 47 and frozen v1: 6803 tokens exceeds unchanged 4096 limit. Command/response async FIFOs exist; spec reset list omits presetn. |
| `asyncfifo` | drop | Excluded from latest 47 and frozen v1: 4614 tokens exceeds unchanged 4096 limit. Gray-pointer FIFO exists; generated interface incorrectly includes function-local input gray as a module port. |
| `axi4_cdc_rd` | keep | u_ar and u_r carry payloads in opposite directions through gaxi_fifo_async between s_aclk and m_aclk; dedicated CDC wrapper. |
| `axi4_cdc_wr` | drop | Excluded from latest 47 and frozen v1: 4948 tokens exceeds unchanged 4096 limit. Dedicated AW/W/B async FIFOs between s_aclk/m_aclk; interface matches. |
| `bridge_cdc_slave_arb` | drop | Excluded from latest 47 and frozen v1: 8081 tokens exceeds unchanged 4096 limit. Per-lane async FIFOs and slave arbitration exist; interface matches; large bus arbiter. |
| `bridge_mon_cdc` | keep | Packet FIFO crosses s_aclk to aclk; registered Gray timestamp and quasi-static cfg cross back through staged synchronizers. |
| `ca_rx_align_fifo` | keep | SYNC_FIFO=0 instantiates lane_clk/com_clk async payload and soft-reset FIFOs; default SYNC_FIFO=1 is explicitly synchronous, so CDC is configuration-dependent. |
| `cdc_bit` | keep | i_async_in shifts through SYNC_STAGES registers on i_clk; final-stage output, configured reset value. |
| `cdc_counter` | keep | Source count and Gray code register together; cdc_gray_sync transfers Gray bits into i_dst_clk before binary reconstruction. |
| `cdc_counter_domain` | drop | Excluded from latest 47 and frozen v1: 9418 tokens exceeds unchanged 4096 limit. Pulse/FIFO/handshake CDC paths exist; spec clock list incorrectly includes o_clk_ticks counter. |
| `cdc_fifo` | keep | Independent i_wr_clk/i_rd_clk pointers are registered in Gray code, synchronized in opposite directions, and used for local full/empty decisions. |
| `cdc_gray_sync` | keep | One cdc_bit chain per registered Gray input bit on i_clk; spec requires single-bit Gray transitions. |
| `cdc_handshake` | drop | Req/ack CDC exists, but spec calls it four-phase while RTL uses a two-phase toggle handshake; freeze excludes contradictory mechanism contract. |
| `cdc_open_loop` | keep | Source holds data and stretched valid; destination synchronizes valid then captures data; spec states required hold duration and no acknowledgement. |
| `cdc_pulse` | keep | Named cdc_pulse top selects toggle transfer via cdc_bit or counter transfer via cdc_counter; both helper modules are present in source.sv. |
| `cdc_pulse_sync` | keep | Source pulse toggles toggle_src; two destination stages plus XOR with delayed sample regenerate events; spec requires pulse spacing. |
| `cdc_qualifier` | keep | i_valid crosses cdc_bit; o_valid enables destination bus capture; spec states held-data requirement and extra capture cycle. |
| `cdc_reset` | keep | Small 33-line asynchronous-assert, SYNC_STAGES-clock release chain; only clock/reset interface. |
| `cdc_reset_sync` | drop | Small reset chain exists, but spec says flops are asynchronously preset to 1 while RTL clears them to 0; contradictory reset behavior. |
| `cdc_sync2` | keep | Two destination flops synchronize data_src on clk_dst with rst_dst_n and RESET_VAL. |
| `cdc_sync3` | keep | Three destination flops synchronize data_src on clk_dst with rst_dst_n and RESET_VAL. |
| `cdc_synchronizer` | keep | Dedicated level synchronizer wrapper binds async_in to glitch_free_n_dff_arn on clk/rst_n; not an atomic bus handshake. |
| `cdc_toggle_sync` | keep | Two destination synchronizer stages plus XOR delayed sample detect both toggle transitions. |
| `chi_link_rx` | keep | i_req crosses u_req_sync before link ACK/grant logic; synchronization enabled by default, documented bypass for known synchronous configuration. |
| `cxs_slave_cg` | drop | Excluded from latest 47 and frozen v1: 5285 tokens exceeds unchanged 4096 limit. ACTIVEREQ level synchronizer exists before gated CXS receiver; interface matches. |
| `double_flop_synchronizer` | keep | Enabled two-register level synchronizer on clk; parameter selects asynchronous or synchronous rst. |
| `example_handshake` | keep | Local dependency cdc_handshake has clk_src/clk_dst ports and two-flop REQ/ACK paths; differs from same-named standalone cdc_lib module. |
| `example_pulse_sync` | keep | Dedicated wrapper transfers irq_pulse from clk_cpu to clk_periph through local cdc_pulse_sync dependency. |
| `example_reset_sync` | keep | Small 46-line reset-only wrapper instantiates independent 2/3/2-stage release chains for clk_100m/clk_200m/clk_50m. |
| `example_sync2` | keep | flag_src crosses two destination stages on clk_200m; source clock/reset ports are declared context ports and unused in this wrapper. |
| `example_sync3` | keep | status_src crosses three destination stages on clk_500m; source clock/reset ports are declared context ports and unused in this wrapper. |
| `example_toggle_sync` | keep | rx_event_toggle crosses to clk_cpu and yields synchronized level plus both-edge event; MAC clock/reset ports are context ports. |
| `fb_endpoints` | drop | Excluded from latest 47 and frozen v1: 6698 tokens exceeds unchanged 4096 limit. Endpoint/fabric pulse and snapshot handshake crossings exist; interface matches; benchmark endpoint subsystem. |
| `fifo_async` | drop | Excluded from latest 47 and frozen v1: 20083 tokens exceeds unchanged 4096 limit. Gray/Johnson pointer crossings exist; exact module interface matches (earlier fenced blocks in the spec are examples, not the header). |
| `gaxi_fifo_async` | drop | Excluded from latest 47 and frozen v1: 5005 tokens exceeds unchanged 4096 limit. Gray/Johnson pointer crossings between axi_wr_aclk/axi_rd_aclk exist; interface matches. |
| `gaxi_skid_buffer_async` | keep | Write-domain skid buffer feeds dual-clock gaxi_fifo_async, binding separate write/read clocks and resets. |
| `glitch_free_n_dff_arn` | drop | Excluded from latest 47 and frozen v1: 8165 tokens exceeds unchanged 4096 limit. N-stage destination level synchronizer exists on clk/rst_n; interface matches. |
| `high_speed_in_bus` | keep | Small handshake receiver synchronizes request through two flops before data_available/acknowledge logic. |
| `high_speed_out_bus` | keep | Small handshake sender synchronizes returning acknowledge, holds output data while request is outstanding, and counts accepted sends. |
| `levelsync` | keep | Two serial clk_dest flops sample src_data with rst_dest_n; optional simulation delay does not replace the synchronizer. |
| `levelsync_sr` | keep | Two serial clk_dest flops with asynchronous rst_dest_n and set_dest_n; both controls appear in exact interface and reset-over-set priority is documented. |
| `mc_dfi_3p1_plane` | drop | Excluded from latest 47 and frozen v1: 10650 tokens exceeds unchanged 4096 limit. DFI plane contains pulse/level crossings and mc_dfi_cdc FIFO wrapper; interface matches; serializer/aligner subsystem. |
| `mc_dfi_cdc` | drop | Excluded from latest 47 and frozen v1: 6849 tokens exceeds unchanged 4096 limit. Command/data/init token FIFOs cross ctl_clk/dfi_clk; interface matches. |
| `mc_training_shell` | keep | Compact shell has real mc_clk/dfi_clk sync_pulse paths for cal_expect/cal_valid and staged calibration data return; not reset-only. |
| `mspi_intf` | drop | Real spi_bitsync paths exist, but spec mislabels rst_n_sclk as a clock; full SPI command/shift engine also exceeds focused primitive/wrapper scope. |
| `ptp_clock_cdc` | drop | Excluded from latest 47 and frozen v1: 9245 tokens exceeds unchanged 4096 limit. Timestamp held-bus/toggle CDC spans input/output/sample clocks; interface matches. |
| `rst_regen_low` | keep | Small 44-line reset-only wrapper drives levelsync data high, asynchronously clears on async_rst_n and releases rst_n after two clk edges. |
| `rtc_core` | drop | Excluded from latest 47 and frozen v1: 29100 tokens exceeds unchanged 4096 limit. Reset, commit handshake and snapshot pulse crossings exist; large RTC/calendar/alarm core; prose uses pclk/presetn aliases while header uses clk/rst_n. |
| `spi_bitsync` | keep | Dedicated two-stage clk/rst_n level synchronizer, with DWIDTH and reset value preserved. |
| `spi_client` | drop | Spec clock list omits SCK although RTL clocks serialization on both SCK edges; prose also refers to absent in_idle; full SPI client core. |
| `spi_clock_barrier_crossing` | drop | Spec promises payload transfer and returned acknowledgement absent from ports/RTL; write_new uses rising-edge detector, not both-edge toggle transfer. |
| `spi_master` | drop | Reset-only classification admitted a complete SPI/AVMM controller with CSR/buffer/interface children; not a small reset synchronizer. |
| `spi_rstnsync` | keep | Small 40-line reset primitive: async clear then first stage plus spi_bitsync release; scan_mode explicitly bypasses the chain. |
| `sspi_avmm_intf` | drop | Contains csr0_reg bit synchronizer but is a three-channel AVMM transaction/burst controller, not a focused CDC primitive or crossing wrapper. |
| `sync_pulse` | keep | Source toggle crosses SYNC_STAGES destination flops and XOR edge detector; spec explicitly states one-way operation and minimum spacing despite loose introductory handshake wording. |
| `sync_signal` | drop | RTL has a real N-stage pipeline, but spec Input ports invents signals; actual inputs are only clk and in. |
| `traffic_counter` | keep | Tap controls cross explicit two-stage cdc_synchronizer instances before local edge detection/counting; occupancy uses bitwise level sync, not atomic snapshot. |
| `triple_flop_synchronizer` | keep | Two-flop dependency plus third enabled destination register implements three serial stages with matching reset mode. |
| `triple_flop_toggle_synchronizer` | drop | Claimed toggle change detector is actually in_sync AND NOT in_delete; falling toggle transitions generate no event. |
| `wb4_slave_cdc` | drop | Excluded from latest 47 and frozen v1: 4342 tokens exceeds unchanged 4096 limit. Wishbone command/response async FIFOs cross wb_clk/aclk; interface matches. |
| `wide_double_flop_synchronizer` | keep | One enabled two-flop chain per input bit; spec explicitly requires quasi-static data and disclaims atomic bus handshake. |
