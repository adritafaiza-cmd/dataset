Implement the SystemVerilog module `andesite_training_plane`.

Andesite-specific wrapper around the common mc_training_plane shell.

Functional contract and interface notes:

Module: andesite_training_plane
Purpose: Andesite-specific wrapper around the common mc_training_plane shell.
Owns the rock-side training FUBs (wrlvl, rdlvl, ca_train/wdq) and
maps the generic 2-slot maintenance-command stream onto the
scheduler's native {req,ack,op,bank,addr,mpc} port.
Slot 0 = read leveling (MRS-based). Slot 1 = CA/WDQ training
(MPC-based). Write-leveling is a mode, not a command-channel flow,
and owns the DFI training pins directly.
projects/components/mem-ctrl-ip/research-ip/andesite-ddr4-lpddr4/docs/andesite_mas/

Required clock and reset behavior:

- Clock ports: mc_clk, dfi_clk.
- Reset ports: mc_rst_n, dfi_rstn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_synchronizer: cdc_synchronizer #(.WIDTH(NUM_CS), .FLOP_COUNT(3)) u_wl_req_sync ( .clk (dfi_clk), .rst_n (dfi_rstn), .async_in (w_wl_req_h), .sync_out (w_wl_req_h_sync) );
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(NUM_CS), .FLOP_COUNT(3)) u_wl_mode_sync ( .clk (dfi_clk), .rst_n (dfi_rstn), .async_in (w_wl_mode_h), .sync_out (w_wl_mode_h_sync) );
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(NUM_CS), .FLOP_COUNT(3)) u_rl_ack_sync ( .clk (dfi_clk), .rst_n (dfi_rstn), .async_in (w_rl_ack_h), .sync_out (w_rl_ack_h_sync) );
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(NUM_CS), .FLOP_COUNT(3)) u_rl_cs_sync ( .clk (dfi_clk), .rst_n (dfi_rstn), .async_in (w_rl_cs_h), .sync_out (w_rl_cs_h_sync) );
- sync_pulse: sync_pulse #(.SYNC_STAGES(3)) u_wl_strobe_sync ( .i_src_clk (mc_clk), .i_src_rst_n (mc_rst_n), .i_pulse (w_dfi_strobe), .i_dst_clk (dfi_clk), .i_dst_rst_n (dfi_rstn), .o_pulse (dfi_wrlvl_strobe_o) );
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(NUM_CS), .FLOP_COUNT(3)) u_wl_ack_sync ( .clk (mc_clk), .rst_n (mc_rst_n), .async_in (w_wl_ack_h), .sync_out (w_wl_ack_h_sync) );
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(NUM_CS), .FLOP_COUNT(3)) u_rl_req_sync ( .clk (mc_clk), .rst_n (mc_rst_n), .async_in (w_rl_req_h), .sync_out (w_rl_req_h_sync) );
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(1), .FLOP_COUNT(3)) u_wl_dq_sync ( .clk (mc_clk), .rst_n (mc_rst_n), .async_in (wrlvl_prime_dq_i), .sync_out (w_wl_dq_sync) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module andesite_training_plane
    import andesite_pkg::*;
    import mc_common_pkg::*;   // Vivado: pkg export of the family symbols is not honored; import explicitly
#(
    parameter int NUM_CS = 1,
    parameter int CSW    = (NUM_CS > 1) ? $clog2(NUM_CS) : 1
)(
    input  logic             mc_clk,
    input  logic             mc_rst_n,
    // ----- write-leveling policy and CSR controls ---------------------------
    input  logic             wrlvl_en_i,       // MR1[7] mode (from mode_register)
    input  logic             wrlvl_strobe_i,
    input  logic [3:0]       wrlvl_cs_sel_i,
    input  logic [15:0]      t_wldqsen_i,
    input  logic [15:0]      t_wlmrd_i,
    input  logic [15:0]      t_wlmrd_max_i,
    input  logic [15:0]      t_wlo_i,
    input  logic [15:0]      t_wloe_i,
    // ----- read-leveling CSR controls ---------------------------------------
    input  logic             rdlvl_en_i,
    input  logic [3:0]       rdlvl_cs_sel_i,
    input  logic [15:0]      csr_mr3_mpr_enter_i,
    input  logic [15:0]      csr_mr3_mpr_exit_i,
    input  logic [15:0]      t_mpr_enter_i,
    input  logic [15:0]      t_mpr_exit_i,
    input  logic [15:0]      t_mpr_readout_i,
    input  logic [15:0]      tmod_i,
    input  logic [15:0]      t_rdlvl_timeout_i,
    // ----- CA/WDQ training CSR controls -------------------------------------
    input  logic             ca_train_en_i,
    input  logic             wdq_cal_en_i,
    input  logic             chan_sel_i,
    input  logic [15:0]      csr_mpc_ca_enter_i,
    input  logic [15:0]      csr_mpc_ca_exit_i,
    input  logic [15:0]      csr_mpc_wdq_enter_i,
    input  logic [15:0]      csr_mpc_wdq_exit_i,
    input  logic [15:0]      t_ca_train_i,
    input  logic [15:0]      t_wdq_cal_i,
    input  logic [15:0]      t_ca_timeout_i,
    // ----- PHY-side DFI training pins ---------------------------------------
    input  logic             dfi_clk,
    input  logic             dfi_rstn,
    output logic [NUM_CS-1:0] dfi_phylvl_req_cs_n_o,  // wrlvl request to PHY
    input  logic [NUM_CS-1:0] dfi_phylvl_ack_cs_n_i,  // wrlvl ack from PHY
    output logic [NUM_CS-1:0] dfi_phy_wrlvl_cs_n_o,   // wrlvl mode select
    output logic              dfi_wrlvl_strobe_o,     // wrlvl DQS strobe
    output logic [NUM_CS-1:0] dfi_phylvl_ack_cs_n_o,  // rdlvl ack to PHY
    input  logic [NUM_CS-1:0] dfi_phylvl_req_cs_n_i,  // rdlvl request from PHY
    output logic [NUM_CS-1:0] dfi_phy_rdlvl_cs_n_o,   // rdlvl mode select
    input  logic              wrlvl_prime_dq_i,
    input  logic              mpr_pattern_i,
    input  logic              ca_sample_i,
    input  logic              wdq_sample_i,
    // ----- maintenance-class training commands (from andesite_training_plane)
    output logic              trn_cmd_req_o,
    input  logic              trn_cmd_ack_i,
    output dram_op_e          trn_cmd_op_o,
    output logic [2:0]        trn_cmd_bank_o,
    output logic [17:0]       trn_cmd_addr_o,
    output logic [5:0]        trn_cmd_mpc_o,
    // ----- write-leveling telemetry -----------------------------------------
    output logic              wrlvl_result_valid_o,
    output logic              wrlvl_result_o,
    output logic [15:0]       wrlvl_attempts_o,
    output logic [15:0]       wrlvl_flips_o,
    output logic              wrlvl_timeout_o,
    output logic              wrlvl_ever_done_o,
    output logic [2:0]        wrlvl_state_o,
    // ----- read-leveling telemetry ------------------------------------------
    output logic              rdlvl_result_valid_o,
    output logic [NUM_CS-1:0] rdlvl_result_o,
    output logic [1:0]        rdlvl_status_o,
    output logic [15:0]       rdlvl_attempts_o,
    output logic [15:0]       rdlvl_results_o,
    output logic [15:0]       rdlvl_timeouts_o,
    output logic [2:0]        rdlvl_state_o,
    // ----- CA/WDQ training telemetry ----------------------------------------
    output logic              ca_train_result_valid_o,
    output logic [1:0]        ca_train_result_o,
    output logic [1:0]        ca_train_status_o,
    output logic [15:0]       ca_train_attempts_o,
    output logic [15:0]       ca_train_results_o,
    output logic [15:0]       ca_train_timeouts_o,
    output logic [2:0]        ca_train_state_o
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
