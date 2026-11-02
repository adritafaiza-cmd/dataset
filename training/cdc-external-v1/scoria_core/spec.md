Implement the SystemVerilog module `scoria_core`.

The rearchitected pumice DDR3/LPDDR3 controller core. Wires the

Functional contract and interface notes:

Module: scoria_core
Purpose: The rearchitected pumice DDR3/LPDDR3 controller core. Wires the
three planes built bottom-up this cycle:
1. mc_axi4_plane          (host AXI + wr/rd CAMs)
2. scoria_scheduler_plane (bank timers + arbiter + refresh/init)
3. mc_dfi_3p1_plane         (single async CDC + DFI 3.1 datapath)
Host AXI + scheduler + CAMs run on aclk; the DFI phase-packer + PHY
run on dfi_clk; the ONE clock crossing lives in mc_dfi_3p1_plane's
CDC (async gaxi FIFOs only). Internal data unit = the DFI word
(DFI_DATA_WIDTH); the host AXI data width is the DFI word too (an
external 64<->128 dwidth shim is a separate edge concern).
Config (timings / phases / policy) is delivered on ports here; a
by-name CSR register block is a clean-rebuild follow-up.

Required clock and reset behavior:

- Clock ports: aclk, dfi_clk.
- Reset ports: aresetn, dfi_rstn, dfi_reset_n_o.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync_aclk ( .clk (aclk), .rst_n (aresetn), .sync_rst_n (w_aresetn) );
- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync_dfi_clk ( .clk (dfi_clk), .rst_n (dfi_rstn), .sync_rst_n (w_aresetn_dfi) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module scoria_core
    import scoria_pkg::*;
    import mc_common_pkg::*;   // Vivado: pkg export of the family symbols is not honored; import explicitly
#(
    parameter int AXI_ID_WIDTH   = 8,
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int NUM_RANKS      = 1,
    // One CS_n per rank. Its own parameter because the DFI v3.1 leveling
    // handshake is per-CS rather than per-rank; see scoria_scheduler_plane.
    parameter int NUM_CS         = NUM_RANKS,
    parameter int NUM_BANKS      = 8,
    parameter int ROW_WIDTH      = 14,
    parameter int COL_WIDTH      = 10,
    parameter int DFI_RATE       = 2,
    parameter int DRAM_BEAT_WIDTH = 64,
    // Physical DRAM device word width. When < DRAM_BEAT_WIDTH (e.g. an x16
    // device behind a 32b pumice beat) one pumice beat packs
    // DRAM_BEAT_WIDTH/DRAM_DEVICE_WIDTH physical beats. Default == beat => the
    // legacy 1:1 behaviour (no column/burst scaling).
    parameter int DRAM_DEVICE_WIDTH = DRAM_BEAT_WIDTH,
    parameter int DRAM_BL             = 8,        // burst length, JEDEC device beats (MR0)
    parameter int NUM_ENTRIES    = 8,
    parameter int N_SRAM_SLOTS   = NUM_ENTRIES,
    parameter int RD_RET_DEPTH   = 32,   // reads in flight (return ring), power of 2
    parameter int CMD_DELAY      = 0,    // command release delay (aclk); 0 = auto: 5 + 2*BURST_WORDS (WR data must lead)
    parameter int AGE_WIDTH      = 16,
    // DV knob: arm the scheduler's command-history scoreboard (JEDEC same-bank
    // sequencing audit, $fatal on violation). 0 = generate-off, zero cost.
    parameter int CMD_HISTORY_EN = 0,
    // Windows for the DFI-WIRE checker (scoria_dfi_cmd_path). Separate from the
    // scheduler's HIST_T_*: same numbers, but a TB may want the wire checker
    // armed while the scheduler one is not, or vice versa.
    parameter int HIST_T_RFC_CORE = 0,
    parameter int HIST_T_RTW_CORE = 0,
    parameter int HIST_T_WTR_CORE = 0,
    // Narrow-device derivations: scoria_addr_mapper column stride is the physical
    // device word (BYTE_OFFSET_WIDTH), and the JEDEC burst length scales down
    // to pumice DRAM beats (BL_PUMICE). Ratio 1 => BYTE_OFFSET_WIDTH=log2(beat
    // bytes) and BL_PUMICE=DRAM_BL, i.e. exactly the legacy values.
    parameter int BYTE_OFFSET_WIDTH = $clog2(DRAM_DEVICE_WIDTH / 8),
    parameter int BL_SHIFT   = (DRAM_BEAT_WIDTH > DRAM_DEVICE_WIDTH)
                             ? $clog2(DRAM_BEAT_WIDTH / DRAM_DEVICE_WIDTH) : 0,
    parameter int BL_PUMICE  = DRAM_BL >> BL_SHIFT,
    // ---- sub-DFI-word burst framing (task #146) --------------------------
    // A JEDEC burst is BL_PUMICE DRAM beats. In DFI words that is
    // BL_PUMICE/DFI_RATE. Two regimes, exactly one active for a given build:
    //   * burst >= one DFI word (legacy, incl. x64 BL8 and rate2 x16):
    //       BURST_WORDS = BL_PUMICE/DFI_RATE DFI words per burst, N_SUBCMD = 1.
    //       One AXI beat == one DFI word feeds BURST_WORDS beats/burst as today.
    //   * burst <  one DFI word (the board: gear 1:4 + x16 BL4):
    //       one DFI word holds N_SUBCMD = DFI_RATE/BL_PUMICE JEDEC bursts, so
    //       BURST_WORDS clamps to 1 (the DFI word IS the transfer unit) and the
    //       DFI plane issues N_SUBCMD consecutive-column DRAM commands per word.
    // Both quantities are derived from the compile params (build-for-max sizes
    // every bus); N_SUBCMD>1 is a normal config, not a special case. Legacy
    // (N_SUBCMD==1) is bit-identical: BURST_WORDS==BL_PUMICE/DFI_RATE as before.
    parameter int BURST_WORDS = (BL_PUMICE >= DFI_RATE) ? (BL_PUMICE / DFI_RATE) : 1,
    parameter int N_SUBCMD    = (DFI_RATE > BL_PUMICE) ? (DFI_RATE / BL_PUMICE) : 1,
    // Column stride (device-word units, scoria_addr_mapper granularity) between the
    // N_SUBCMD sub-bursts of one DFI word = one JEDEC burst = DRAM_BL device beats.
    parameter int SUB_COL_STRIDE = DRAM_BL,
    // DFI-phase stride between the packed sub-bursts (= BL_PUMICE = the phases
    // one JEDEC burst occupies). The N_SUBCMD sub anchors {0, BL_PUMICE, ...}
    // tile the DFI cycle: N_SUBCMD*BL_PUMICE == DFI_RATE in the sub-word regime.
    parameter int SUB_PHASE_STRIDE = (N_SUBCMD > 1) ? (DFI_RATE / N_SUBCMD) : 1,
    // Read-enable window width in DFI cycles = TRUE DQ occupancy, which is
    // ceil(DRAM_BL / DFI_RATE) -- DRAM_BL counts DEVICE beats and the devices
    // sit in PARALLEL, so a narrower device does not shorten the burst in
    // time, it only narrows each beat. scoria TASK-004.
    //
    // This is NOT BURST_WORDS. BURST_WORDS counts DRAM_BEAT_WIDTH-wide beats
    // (BL_PUMICE/DFI_RATE), so it HALVES when a narrow device sits behind a
    // wider beat -- and the DFI plane's RD_EN_CYC defaulted to it, which told
    // the PHY to sample DQ for one DFI cycle of a two-cycle burst and lost the
    // second half of every read. The two agree only when
    // DRAM_BEAT_WIDTH == DRAM_DEVICE_WIDTH, which is the Genesys 2 point and
    // is why nothing was wrong on the board.
    //
    // Deliberately the SAME expression as scoria_top's RD_EN_CYC_TOP, which
    // floors tRTW on it. If these two ever disagree the controller programs a
    // tRTW floor for a read window it is not actually opening; they are both
    // derived from DRAM_BL and DFI_RATE so they cannot.
    parameter int RD_EN_CYC_CORE = (DRAM_BL + DFI_RATE - 1) / DFI_RATE,
    // internal data unit = DFI word
    parameter int DFI_DATA_WIDTH = DRAM_BEAT_WIDTH * DFI_RATE,
    parameter int DW  = DFI_DATA_WIDTH,      // host AXI data width == DFI word
    parameter int SW  = DW / 8,
    parameter int IW  = AXI_ID_WIDTH,
    parameter int AW  = AXI_ADDR_WIDTH,
    parameter int UW  = 1,
    parameter int RKW = (NUM_RANKS > 1) ? $clog2(NUM_RANKS) : 1,
    parameter int BKW = $clog2(NUM_BANKS),
    parameter int PHW = (DFI_RATE > 1) ? $clog2(DFI_RATE) : 1,
    parameter int N_LU = NUM_BANKS,
    // DFI geometry
    parameter int DFI_STRB_WIDTH = DW / 8,
    parameter int DFI_EN_WIDTH   = DFI_RATE,
    parameter int DFI_VALID_WIDTH = DFI_RATE,
    parameter int DFI_ADDR_BUS_W = ROW_WIDTH * DFI_RATE,
    parameter int DFI_BANK_BUS_W = BKW * DFI_RATE,
    parameter int DFI_CTRL_BUS_W = 1 * DFI_RATE,
    parameter int DFI_CS_BUS_W   = NUM_RANKS * DFI_RATE
) (
    // ---- controller clock (host AXI + scheduler + CAMs) ----
    input  logic                       aclk,
    input  logic                       aresetn,
    // ---- DFI/PHY clock ----
    input  logic                       dfi_clk,
    input  logic                       dfi_rstn,
    // ---- config (ports; CSR rebuild is a follow-up) ----
    input  memtype_e                   memtype_i,
    input  page_policy_e               page_policy_i,
    // ---- runtime page-policy (TASK-001 Axis 2); all-zero = legacy ----
    input  logic [2:0]                 page_mode_i,
    input  logic [7:0]                 page_tr_init_i,
    input  logic [1:0]                 sched_order_mode_i,
    input  logic [1:0]                 sched_row_sel_i,
    input  logic [1:0]                 sched_col_sel_i,
    input  logic [1:0]                 sched_access_pref_i,
    input  logic [7:0]                 sched_wr_high_wm_i,
    input  logic [7:0]                 sched_wr_batch_max_i,
    input  logic [7:0]                 sched_wr_low_wm_i,
    input  logic [1:0]                 sched_prio_sub_i,
    input  logic                       sched_qos_en_i,
    input  logic [7:0]                 sched_age_thresh_i,
    // stall-cause attribution (TASK-006)
    output logic [31:0]                stall_bp_o,
    output logic [31:0]                stall_refresh_o,
    output logic [31:0]                stall_turnaround_o,
    output logic [31:0]                stall_tccd_o,
    output logic [31:0]                stall_actlimit_o,
    output logic [31:0]                stall_banktimer_o,
    output logic [31:0]                stall_noreq_o,
    output logic [31:0]                stall_zq_o,
    output logic [31:0]                stat_page_hit_o,
    output logic [31:0]                stat_row_hit_o [NUM_BANKS],  // per-bank row hits (BUG-020)
    output logic [31:0]                stat_page_miss_o,
    output logic [31:0]                stat_page_empty_o,
    output logic [31:0]                stat_act_o,
    output logic [31:0]                stat_pre_o,
    output logic [31:0]                stat_ref_o,
    output logic [31:0]                stat_ref_busy_o,   // TASK-012
    input  logic [4:0]                 bank_lsb_i,
    input  logic                       hash_en_i,
    input  logic [7:0]                 hash_seed_i,
    input  logic [7:0]                 t_rcd_i, t_rp_i, t_ras_i, t_rc_i, t_wr_i, t_rtp_i,
    input  logic [7:0]                 t_faw_i, t_rrd_i, t_wtr_i, t_rtw_i, t_ccd_i,
    input  logic [15:0]                t_refi_i,
    // DV/bring-up knob: pulse to reload the tREFI countdown immediately
    // with the current t_refi_i (it otherwise reloads only on expiry).
    // Tie to 0 in production -- no effect unless pulsed.
    input  logic                       refi_reload_i,
    input  logic [15:0]                t_rfc_i,
    input  logic [3:0]                 refresh_burst_i,
    input  logic [3:0]                 ref_postpone_i,
    input  logic [3:0]                 ref_pullin_i,
    input  logic [1:0]                 ref_mode_i,
    input  logic [15:0]                ref_trefi_pb_i,
    input  logic [7:0]                 ref_trfc_pb_i,
    input  logic [15:0]                t_init_wait_i, t_dll_wait_i,
    input  logic [7:0]                 t_mrd_wait_i, t_rp_wait_i, t_rfc_wait_i,
    // DDR3 additions
    input  logic [15:0]                t_xpr_wait_i,     // tXPR, init step 5
    input  logic [15:0]                t_zqinit_wait_i,  // tZQinit, init step 11
    // DDR3 RESET#, carried on the DFI COMMAND interface. Named for the
    // interface it LEAVES this module on, not for the device pin it ends at --
    // a PHY integrator wiring to DFI looks for dfi_reset_n.
    //
    // DFI has defined this since v2.1, gated on MEMORY TYPE not version: it
    // exists for DDR3 and was extended to DDR4/LPDDR4 at v4.0 and DDR5/LPDDR5
    // at v5.x (and renamed dfi_reset in v6.0). So this is not a v3.1 addition
    // -- scoria simply never presented the DFI name. Renamed from
    // dram_reset_n_o 2026-10-01, scoria TASK-005.
    output logic                       dfi_reset_n_o,
    output logic [4:0]                 mr_wr_o,          // write recovery MR0[11:9]
    output logic                       wrlvl_en_o,       // MR1[7]
    // ----- ZQ calibration (DDR3) -----
    input  logic                       zq_enable_i,
    input  logic [31:0]                zq_interval_i,
    input  logic [15:0]                t_zqcs_i,
    output logic                       zq_busy_o,
    output logic [15:0]                zq_total_o,
    output logic [31:0]                zq_interval_cnt_o,
    output logic                       zq_overdue_o,
    // ----- Mode A/B/C CSR fields (TASK-001) ----
    input  logic                       ref_elastic_en_i,
    input  logic [7:0]                 ref_pullin_idle_streak_i,
    input  logic [6:0]                 ref_postpone_demand_streak_i,
    input  logic                       ref_tcr_en_i,
    input  logic [1:0]                 ref_trefi_derate_i,
    input  logic [1:0]                 zq_placement_i,
    input  logic [12:0]                zq_overdue_max_i,
    output logic [15:0]                obs_ref_postpone_events_o,
    output logic [15:0]                obs_ref_pullin_events_o,
    // ----- write leveling (DDR3). The DFI v3.1 leveling handshake is per-CS
    //       and leaves the controller unaltered -- it does not go through
    //       mc_dfi_3p1_plane, because there is no gearing to do on it: the
    //       request/ack pair is a slow control handshake, not phase data. -----
    input  logic                       wrlvl_strobe_i,
    input  logic [3:0]                 wrlvl_cs_sel_i,
    input  logic [15:0]                t_wldqsen_i,
    input  logic [15:0]                t_wlmrd_i,
    input  logic [15:0]                t_wlmrd_max_i,
    input  logic [15:0]                t_wlo_i,
    input  logic [15:0]                t_wloe_i,
    output logic [NUM_CS-1:0]          dfi_phylvl_req_cs_n_o,
    input  logic [NUM_CS-1:0]          dfi_phylvl_ack_cs_n_i,
    output logic [NUM_CS-1:0]          dfi_phy_wrlvl_cs_n_o,
    output logic                       dfi_wrlvl_strobe_o,
    input  logic                       dfi_prime_dq_i,     // dfi_clk domain
    output logic                       wrlvl_result_valid_o,
    output logic                       wrlvl_result_o,
    output logic [15:0]                wrlvl_attempts_o,
    output logic [15:0]                wrlvl_flips_o,
    output logic                       wrlvl_timeout_o,
    output logic                       wrlvl_ever_done_o,
    output logic [2:0]                 wrlvl_state_o,
    input  logic [15:0]                mr0_i, mr1_i, mr2_i, mr3_i,  // CSR MR0..MR3.VAL
    input  logic                       init_restart_i,              // CTRL.init_force_restart
    input  logic [PHW-1:0]             rd_phase_i, wr_phase_i,
    input  logic [7:0]                 t_phy_wrlat_i, t_rddata_en_i,
    // Active DFI gear = log2(active DFI rate). DFI_RATE is the compile-time MAX
    // that sizes all buses; gear_i selects the active phase count at runtime.
    // gear_i = log2(DFI_RATE) (board/default) => active_rate == DFI_RATE => the
    // DFI en masks are all-ones => behaviour is bit-identical to today.
    input  logic [1:0]                 gear_i,
    // JEDEC burst length (device beats: 4/8/16) — the single source of truth for
    // the burst geometry (task #146, DFI_PHASE.bl CSR). Combined with gear_i it
    // derives the ACTIVE sub-DFI-word framing (n_subcmd / col stride) below. The
    // datapath is BUILT for MAX (compile params); this is the runtime selector,
    // so a wrong value is bad config, never a synth mismatch. Board/default value
    // (== compile DRAM_BL) reproduces the compile-time framing bit-for-bit.
    input  logic [3:0]                 bl_i,
    output logic [3:0]                 cl_o, cwl_o, bl_o,
    output logic                       init_done_o,
    // ---- host AXI4 (data width = DFI word; external dwidth shim separate) ----
    input  logic [IW-1:0]  s_axi_awid,   input logic [AW-1:0] s_axi_awaddr,
    input  logic [7:0]     s_axi_awlen,  input logic [2:0]    s_axi_awsize,
    input  logic [1:0]     s_axi_awburst,input logic          s_axi_awlock,
    input  logic [3:0]     s_axi_awcache,input logic [2:0]    s_axi_awprot,
    input  logic [3:0]     s_axi_awqos,  input logic [3:0]    s_axi_awregion,
    input  logic [UW-1:0]  s_axi_awuser, input logic          s_axi_awvalid,
    output logic           s_axi_awready,
    input  logic [DW-1:0]  s_axi_wdata,  input logic [SW-1:0] s_axi_wstrb,
    input  logic           s_axi_wlast,  input logic [UW-1:0] s_axi_wuser,
    input  logic           s_axi_wvalid, output logic         s_axi_wready,
    output logic [IW-1:0]  s_axi_bid,    output logic [1:0]   s_axi_bresp,
    output logic [UW-1:0]  s_axi_buser,  output logic         s_axi_bvalid,
    input  logic           s_axi_bready,
    input  logic [IW-1:0]  s_axi_arid,   input logic [AW-1:0] s_axi_araddr,
    input  logic [7:0]     s_axi_arlen,  input logic [2:0]    s_axi_arsize,
    input  logic [1:0]     s_axi_arburst,input logic          s_axi_arlock,
    input  logic [3:0]     s_axi_arcache,input logic [2:0]    s_axi_arprot,
    input  logic [3:0]     s_axi_arqos,  input logic [3:0]    s_axi_arregion,
    input  logic [UW-1:0]  s_axi_aruser, input logic          s_axi_arvalid,
    output logic           s_axi_arready,
    output logic [IW-1:0]  s_axi_rid,    output logic [DW-1:0] s_axi_rdata,
    output logic [1:0]     s_axi_rresp,  output logic          s_axi_rlast,
    output logic [UW-1:0]  s_axi_ruser,  output logic          s_axi_rvalid,
    input  logic           s_axi_rready,
    // ---- DFI 2.1 pin bus (to PHY) ----
    output logic [DFI_ADDR_BUS_W-1:0]  dfi_address_o,
    output logic [DFI_BANK_BUS_W-1:0]  dfi_bank_o,
    output logic [DFI_CTRL_BUS_W-1:0]  dfi_cas_n_o,
    output logic [DFI_CTRL_BUS_W-1:0]  dfi_ras_n_o,
    output logic [DFI_CTRL_BUS_W-1:0]  dfi_we_n_o,
    output logic [DFI_CS_BUS_W-1:0]    dfi_cs_n_o,
    output logic [DFI_CS_BUS_W-1:0]    dfi_odt_o,
    output logic [DFI_DATA_WIDTH-1:0]  dfi_wrdata_o,
    output logic [DFI_EN_WIDTH-1:0]    dfi_wrdata_en_o,
    output logic [DFI_STRB_WIDTH-1:0]  dfi_wrdata_mask_o,
    output logic [DFI_EN_WIDTH-1:0]    dfi_rddata_en_o,
    // ----- DFI v3.1 per-data-phase chip selects (scoria TASK-005) ----------
    // These exist at EXACTLY v3.1 (min 3.1, max 3.1 -- renamed dfi_wrdata_cs /
    // dfi_rddata_cs in v4.0), so unlike dfi_reset_n above they really are a
    // v3.1-only pair, which is why a v3.1 claim obliges scoria to present them.
    //
    // TWO ROLES, and only the first is satisfied by a constant:
    //   1. which rank owns the DQ bus during the DATA window -- the command
    //      phases carry dfi_cs_n, the data phases carry these. scoria has ONE
    //      rank, so 0 (rank 0 selected) is the only legal value.
    //   2. the CS-UNDER-TRAINING indicator during write leveling / read
    //      training. scoria HAS a write-leveling interface
    //      (scoria_wrlvl_ifc, dfi_phy_wrlvl_cs_n_o), so this role is live --
    //      it is just degenerate at one rank, where the CS under training is
    //      always CS0. A multi-rank scoria must drive these from the granted
    //      command's rank AND from the rank being levelled.
    //
    // Driven by the controller rather than tied off by the integrator, because
    // presenting them is the controller's side of the contract.
    output logic [DFI_CS_BUS_W-1:0]    dfi_wrdata_cs_n_o,
    output logic [DFI_CS_BUS_W-1:0]    dfi_rddata_cs_n_o,
    input  logic [DFI_DATA_WIDTH-1:0]  dfi_rddata_i,
    input  logic [DFI_VALID_WIDTH-1:0] dfi_rddata_valid_i,
    output logic                       dfi_init_start_o,
    input  logic                       dfi_init_complete_i
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
