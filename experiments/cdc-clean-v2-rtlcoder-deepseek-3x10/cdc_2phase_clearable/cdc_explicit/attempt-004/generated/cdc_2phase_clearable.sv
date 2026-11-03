Sure, here is the complete implementation of the `cdc_2phase_clearable` module in SystemVerilog:

```systemverilog
module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Internal signals
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  wire src_ready_wire;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  wire dst_ready_wire;
  reg [SYNC_STAGES-1:0] src_clear_sync;
  reg [SYNC_STAGES-1:0] dst_clear_sync;
  reg [SYNC_STAGES-1:0] src_clear_sync_d;
  reg [SYNC_STAGES-1:0] dst_clear_sync_d;
  reg [SYNC_STAGES-1:0] src_clear_sync_dd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] dst_clear_sync_ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;
  reg [SYNC_STAGES-1:0] src_clear_sync_dddddddddddddddddddddddd