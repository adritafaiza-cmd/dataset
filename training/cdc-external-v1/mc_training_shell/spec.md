Implement the SystemVerilog module `mc_training_shell`.

Generic, dependency-inverted training-control shell for the

Functional contract and interface notes:

Module: mc_training_shell
Purpose: Generic, dependency-inverted training-control shell for the
mem-ctrl-ip family. Provides a fixed-priority maintenance-slot bus,
a single generic `trn_cmd` output, and the `mc_clk`/`dfi_clk`
calibration-data CDC.  The actual training children (ZQ controllers,
DQ calibrators, write/read leveling, future CA-train sequencers) are
instantiated rock-side and wired into the slot ports.
Slot 0 has highest priority, slot NUM_SLOTS-1 lowest.  Only the
highest-priority requesting slot drives the output stream.
projects/components/mem-ctrl-ip/common-ip/docs/phy_cal_csr_contract.md

Required clock and reset behavior:

- Clock ports: mc_clk, dfi_clk.
- Reset ports: mc_rst_n, dfi_rstn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- sync_pulse: sync_pulse #(.SYNC_STAGES(3)) u_expect_sync ( .i_src_clk (mc_clk), .i_src_rst_n (mc_rst_n), .i_pulse (cal_expect_i), .i_dst_clk (dfi_clk), .i_dst_rst_n (dfi_rstn), .o_pulse (cal_expect_o) );
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(CAL_DATA_WIDTH), .FLOP_COUNT(3)) u_data_sync ( .clk (mc_clk), .rst_n (mc_rst_n), .async_in (cal_data_i), .sync_out (cal_data_o) );
- sync_pulse: sync_pulse #(.SYNC_STAGES(3)) u_valid_sync ( .i_src_clk (dfi_clk), .i_src_rst_n (dfi_rstn), .i_pulse (cal_valid_i), .i_dst_clk (mc_clk), .i_dst_rst_n (mc_rst_n), .o_pulse (cal_valid_o) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module mc_training_shell
    import mc_common_pkg::*;
#(
    parameter int NUM_SLOTS     = 2,
    parameter int BKW           = 3,
    parameter int ROW_WIDTH     = 14,
    parameter int EXTRA_WIDTH   = 1,
    parameter int CAL_DATA_WIDTH = 1
) (
    input  logic                      mc_clk,
    input  logic                      mc_rst_n,
    // ----- generic maintenance slots ----------------------------------------
    input  logic [NUM_SLOTS-1:0]      slot_req_i,
    output logic [NUM_SLOTS-1:0]      slot_grant_o,
    input  dram_op_e [NUM_SLOTS-1:0]  slot_op_i,
    input  logic [NUM_SLOTS-1:0][BKW-1:0]       slot_bank_i,
    input  logic [NUM_SLOTS-1:0][ROW_WIDTH-1:0] slot_row_i,
    input  logic [NUM_SLOTS-1:0][EXTRA_WIDTH-1:0] slot_extra_i,
    // ----- generic maintenance command output to the scheduler ----------------
    output logic                      trn_cmd_req_o,
    input  logic                      trn_cmd_grant_i,
    output dram_op_e                  trn_cmd_op_o,
    output logic [BKW-1:0]            trn_cmd_bank_o,
    output logic [ROW_WIDTH-1:0]      trn_cmd_row_o,
    output logic [EXTRA_WIDTH-1:0]    trn_cmd_extra_o,
    // ----- DFI-plane calibration sideband (dfi_clk domain) --------------------
    input  logic                      dfi_clk,
    input  logic                      dfi_rstn,
    input  logic                      cal_expect_i,
    output logic                      cal_expect_o,
    input  logic [CAL_DATA_WIDTH-1:0] cal_data_i,
    input  logic                      cal_valid_i,
    output logic [CAL_DATA_WIDTH-1:0] cal_data_o,
    output logic                      cal_valid_o
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
