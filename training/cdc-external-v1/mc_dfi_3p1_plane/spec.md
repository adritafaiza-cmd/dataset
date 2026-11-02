Implement the SystemVerilog module `mc_dfi_3p1_plane`.

Common DFI 3.1 plane. Holds the single controller<->PHY crossing

Functional contract and interface notes:

Module: mc_dfi_3p1_plane
Purpose: Common DFI 3.1 plane. Holds the single controller<->PHY crossing
(mc_dfi_cdc, async gaxi FIFOs only) and the dfi_clk-domain command
path + write serializer + read aligner. Presents the controller-clock
command/wrdata/rddata streams on one side and the DFI 3.1 pin bus on
the other.
ctl_clk : cmd (from scheduler), wrdata (from wr CAM), rddata (to rd CAM),
init_start/init_complete
dfi_clk : DFI command bus, dfi_wrdata/en/mask, dfi_rddata/en/valid,
dfi_init_start/complete
Internal datapath unit = the DFI word (dfi_wrdata width, all DFI_RATE phases).
One FIFO word = one DFI cycle => bubble-free.
Extracted from scoria_dfi_plane during Phase 2 common-plane reorg
(2026-10-10). Authority: JEDEC DFI 3.1 specification plus the
simplified study notes in
projects/components/mem-ctrl-ip/research-ip/scoria-ddr3-lpddr3/docs/simplified_dfi_3_1/.

Required clock and reset behavior:

- Clock ports: ctl_clk, dfi_clk.
- Reset ports: ctl_rstn, dfi_rstn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_synchronizer: cdc_synchronizer #(.WIDTH(NUM_CS), .FLOP_COUNT(3)) u_wl_req_sync ( .clk (dfi_clk), .rst_n (dfi_rstn), .async_in (w_wl_req_h), .sync_out (w_wl_req_h_sync) );
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(NUM_CS), .FLOP_COUNT(3)) u_wl_mode_sync ( .clk (dfi_clk), .rst_n (dfi_rstn), .async_in (w_wl_mode_h), .sync_out (w_wl_mode_h_sync) );
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(NUM_CS), .FLOP_COUNT(3)) u_wl_ack_sync ( .clk (ctl_clk), .rst_n (ctl_rstn), .async_in (w_wl_ack_h), .sync_out (w_wl_ack_h_sync) );
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(1), .FLOP_COUNT(3)) u_wl_dq_sync ( .clk (ctl_clk), .rst_n (ctl_rstn), .async_in (dfi_prime_dq_i), .sync_out (w_wl_dq_sync) );
- sync_pulse: sync_pulse #(.SYNC_STAGES(3)) u_wl_strobe_sync ( .i_src_clk (ctl_clk), .i_src_rst_n (ctl_rstn), .i_pulse (wl_strobe_i), .i_dst_clk (dfi_clk), .i_dst_rst_n (dfi_rstn), .o_pulse (dfi_wrlvl_strobe_o) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module mc_dfi_3p1_plane
    import mc_common_pkg::*;   // Vivado: pkg export of the family symbols is not honored; import explicitly
#(
    parameter int NUM_RANKS      = 1,
    parameter int NUM_CS         = NUM_RANKS,
    parameter int NUM_BANKS      = 8,
    parameter int ROW_WIDTH      = 14,
    parameter int COL_WIDTH      = 10,
    parameter int DFI_RATE       = 2,
    parameter int DRAM_BEAT_WIDTH = 64,
    parameter int DFI_BEATS_PER_BURST             = 8,     // DRAM beats per burst (BL_PUMICE)
    // Sub-DFI-word burst framing (task #146). N_SUBCMD DRAM column commands are
    // issued per DFI word when a burst is smaller than one DFI word (gear 1:4 +
    // x16 BL4 => N_SUBCMD=2); SUB_COL_STRIDE (device-word col units) separates
    // them. BURST_WORDS = DFI words captured/driven per burst-group (clamps to 1
    // in the sub-word regime). Defaults => N_SUBCMD=1 => legacy (bit-identical).
    parameter int N_SUBCMD       = 1,
    parameter int SUB_COL_STRIDE = 1,
    // Compile MAX DFI-phase stride between packed sub-bursts (= BL_PUMICE).
    parameter int SUB_PHASE_STRIDE = (N_SUBCMD > 1) ? (DFI_RATE / N_SUBCMD) : 1,
    parameter int SUBW_MAX       = $clog2(N_SUBCMD + 1),
    parameter int BURST_WORDS    = (DFI_BEATS_PER_BURST >= DFI_RATE) ? (DFI_BEATS_PER_BURST / DFI_RATE) : 1,
    parameter int CMD_FIFO_DEPTH = 8,
    parameter int WD_FIFO_DEPTH  = 16,
    // Read-return FIFO. dfi_rddata_valid is FIRE-AND-FORGET (no PHY
    // backpressure), so this FIFO must cover the WHOLE read-admission
    // domain or beats are silently lost when it fills: total in-flight
    // read beats anywhere <= rd-CAM depth x BL_WORDS (8 x 4 = 32 at the
    // default build). Depth 16 dropped beats under a paced-but-adjacent
    // burst schedule (found by test_pumice_core_sched_order: the aligner
    // forwarded a beat into a full FIFO and the AR-order drain wedged
    // behind the short burst forever).
    parameter int RD_FIFO_DEPTH  = 32,
    parameter int N_FLOP_CROSS   = 2,
    // Async-FIFO pointer encoding, forwarded to mc_dfi_cdc: 0 = Gray
    // (power-of-2 depths only), 1 = Johnson (any depth, DEPTH-bit pointers).
    // Gray by default -- Johnson is opt-in.
    parameter int USE_JOHNSON    = 0,
    parameter bit DFI_CDC_EN     = 1'b1, // 0 = ctl_clk and dfi_clk are one clock: synchronous FIFOs in mc_dfi_cdc, no crossing
    // ---- derived DFI geometry ----
    parameter int DFI_DATA_WIDTH = DRAM_BEAT_WIDTH * DFI_RATE,
    parameter int DFI_STRB_WIDTH = DFI_DATA_WIDTH / 8,
    parameter int DFI_EN_WIDTH   = DFI_RATE,
    parameter int DFI_VALID_WIDTH = DFI_RATE,
    parameter int DFI_ADDR_WIDTH = ROW_WIDTH,
    parameter int DFI_BANK_WIDTH = $clog2(NUM_BANKS),
    parameter int DFI_CTRL_WIDTH = 1,
    parameter int DFI_CS_WIDTH   = NUM_RANKS,
    parameter int DFI_ADDR_BUS_W = DFI_ADDR_WIDTH * DFI_RATE,
    parameter int DFI_BANK_BUS_W = DFI_BANK_WIDTH * DFI_RATE,
    parameter int DFI_CTRL_BUS_W = DFI_CTRL_WIDTH * DFI_RATE,
    parameter int DFI_CS_BUS_W   = DFI_CS_WIDTH * DFI_RATE,
    parameter int RKW = (NUM_RANKS > 1) ? $clog2(NUM_RANKS) : 1,
    parameter int BKW = $clog2(NUM_BANKS),
    parameter int PHW = (DFI_RATE > 1) ? $clog2(DFI_RATE) : 1,
    // DFI words captured/driven per burst-group. Clamped to >=1 so the
    // sub-DFI-word regime (DFI_BEATS_PER_BURST/DFI_RATE < 1) frames exactly one DFI word.
    // DFI-wire command-history scoreboard (sim only, off by default). Passed
    // straight through to mc_dfi_3p1_cmd_path; see the note there for why a
    // second instance is needed when the scheduler already has one.
    parameter int CMD_HISTORY_EN = 0,
    parameter int HIST_T_RCD     = 0,
    parameter int HIST_T_RP      = 0,
    parameter int HIST_T_RAS     = 0,
    parameter int HIST_T_RFC     = 0,
    parameter int HIST_T_WTR     = 0,
    parameter int HIST_T_RTW     = 0,
    parameter int BL_WORDS = BURST_WORDS,
    // Read aligner outstanding-read tracking depth (exposed). Size >= the read
    // CAM depth so op_ready never deasserts in steady state; the valid/ready
    // handshake to command issue is the just-in-case backpressure.
    parameter int RD_MAX_OUTSTANDING = 16,
    // rddata_en window width = DQ-bus occupancy of one read, in DFI cycles.
    //
    // scoria_core SETS THIS EXPLICITLY (RD_EN_CYC_CORE = ceil(DRAM_BL /
    // DFI_RATE), the true occupancy). The BL_WORDS default is kept only so a
    // bare instantiation of this plane elaborates; it is WRONG whenever
    // DRAM_BEAT_WIDTH > DRAM_DEVICE_WIDTH, because BL_WORDS counts beats of
    // the wider DRAM beat and halves. Do not rely on the default -- that is
    // what TASK-004 was.
    parameter int RD_EN_CYC = BL_WORDS,
    // FIFO payloads
    parameter int CMD_DW = $bits(dram_op_e) + RKW + BKW + ROW_WIDTH + COL_WIDTH + 1,
    parameter int WD_DW  = 1 + DFI_STRB_WIDTH + DFI_DATA_WIDTH,   // {last,strb,data}
    parameter int RD_DW  = 1 + 2 + DFI_DATA_WIDTH                 // {last,resp,data}
) (
    //=========================================================================
    // Controller domain (ctl_clk)
    //=========================================================================
    input  logic                       ctl_clk,
    input  logic                       ctl_rstn,
    // cmd in (from scheduler cmd stream)
    input  logic                       cmd_valid_i,
    output logic                       cmd_ready_o,
    input  logic [CMD_DW-1:0]          cmd_data_i,
    // wrdata in (from wr CAM drain; DFI-word granular {last,strb,data})
    input  logic                       wd_valid_i,
    output logic                       wd_ready_o,
    input  logic [WD_DW-1:0]           wd_data_i,
    // rddata out (to rd CAM dfi_ret; {last,resp,data})
    output logic                       rd_valid_o,
    input  logic                       rd_ready_i,
    output logic [RD_DW-1:0]           rd_data_o,
    // init handshake (controller side)
    input  logic                       init_start_i,
    output logic                       init_complete_o,
    //=========================================================================
    // PHY DFI domain (dfi_clk)
    //=========================================================================
    input  logic                       dfi_clk,
    input  logic                       dfi_rstn,
    input  memtype_e                   memtype_i,
    input  logic [PHW-1:0]             rd_phase_i,
    input  logic [PHW-1:0]             wr_phase_i,
    input  logic [7:0]                 t_phy_wrlat_i,
    input  logic [7:0]                 t_rddata_en_i,
    // Direction turnaround for the DFI-side column pacer (pumice BUG-017 (was PUMICE-042)).
    // Active DFI gear = log2(active DFI rate). DFI_RATE is the compile-time MAX
    // rate that sizes every bus; gear_i selects how many of those phases are
    // active. active_rate = 1 << gear_i. At gear_i = log2(DFI_RATE) (board /
    // default) the mask is all-ones and the DFI en outputs are UNCHANGED.
    input  logic [1:0]                 gear_i,
    // Runtime sub-DFI-word framing (from the bl+gear CSRs; <= compile MAX).
    // n_subcmd_i = active DRAM commands per DFI word; sub_col_stride_i = active
    // device-word column stride; sub_phase_stride_i = active DFI-phase stride
    // (= active bl_pumice) between the packed sub-bursts. Board/default => MAX.
    input  logic [SUBW_MAX-1:0]        n_subcmd_i,
    input  logic [COL_WIDTH-1:0]       sub_col_stride_i,
    input  logic [PHW-1:0]             sub_phase_stride_i,
    // DFI command bus
    output logic [DFI_ADDR_BUS_W-1:0]  dfi_address_o,
    output logic [DFI_BANK_BUS_W-1:0]  dfi_bank_o,
    output logic [DFI_CTRL_BUS_W-1:0]  dfi_cas_n_o,
    output logic [DFI_CTRL_BUS_W-1:0]  dfi_ras_n_o,
    output logic [DFI_CTRL_BUS_W-1:0]  dfi_we_n_o,
    output logic [DFI_CS_BUS_W-1:0]    dfi_cs_n_o,
    output logic [DFI_CS_BUS_W-1:0]    dfi_odt_o,
    // DFI write data
    output logic [DFI_DATA_WIDTH-1:0]  dfi_wrdata_o,
    output logic [DFI_EN_WIDTH-1:0]    dfi_wrdata_en_o,
    output logic [DFI_STRB_WIDTH-1:0]  dfi_wrdata_mask_o,
    // DFI read data
    output logic [DFI_EN_WIDTH-1:0]    dfi_rddata_en_o,
    input  logic [DFI_DATA_WIDTH-1:0]  dfi_rddata_i,
    input  logic [DFI_VALID_WIDTH-1:0] dfi_rddata_valid_i,
    // DFI init handshake (to/from PHY)
    output logic                       dfi_init_start_o,
    input  logic                       dfi_init_complete_i,
    // ---- DDR3 write-leveling handshake (DFI v3.1, per CS) ----
    // It crosses HERE, with the command path, because this module owns the one
    // ctl_clk/dfi_clk boundary in the design. scoria_wrlvl_ifc runs on ctl_clk
    // and the PHY samples these pins on dfi_clk; wiring them from the scheduler
    // straight to the top's pin bus would have been an UNSYNCHRONIZED crossing,
    // and no lint pass reports that -- it reports nothing at all.
    //
    // The two directions need different primitives. The request/mode/ack/result
    // signals are slow levels, so a flop chain is enough. wl_strobe_i is a
    // ONE-CYCLE pulse and a flop chain would either duplicate or swallow it
    // depending on the clock ratio, so it goes through sync_pulse's toggle
    // handshake instead.
    input  logic [NUM_CS-1:0]          wl_req_cs_n_i,    // ctl_clk, level
    input  logic [NUM_CS-1:0]          wl_wrlvl_cs_n_i,  // ctl_clk, level
    input  logic                       wl_strobe_i,      // ctl_clk, 1-cycle pulse
    output logic [NUM_CS-1:0]          wl_ack_cs_n_o,    // ctl_clk, level
    output logic                       wl_prime_dq_o,    // ctl_clk, level
    output logic [NUM_CS-1:0]          dfi_phylvl_req_cs_n_o,
    input  logic [NUM_CS-1:0]          dfi_phylvl_ack_cs_n_i,
    output logic [NUM_CS-1:0]          dfi_phy_wrlvl_cs_n_o,
    output logic                       dfi_wrlvl_strobe_o,
    input  logic                       dfi_prime_dq_i
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
