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
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready_sync;
  logic src_clear_sync;
  logic dst_valid_sync;
  logic dst_ready_sync;
  logic dst_clear_sync;
  logic [WIDTH-1:0] dst_data_sync;

  logic [SYNC_STAGES-1:0] src_valid_reg;
  logic [SYNC_STAGES-1:0] src_data_reg;
  logic [SYNC_STAGES-1:0] src_ready_reg;
  logic [SYNC_STAGES-1:0] src_clear_reg;
  logic [SYNC_STAGES-1:0] dst_valid_reg;
  logic [SYNC_STAGES-1:0] dst_ready_reg;
  logic [SYNC_STAGES-1:0] dst_clear_reg;
  logic [WIDTH-1:0] dst_data_reg;

  logic src_clear_pending;
  logic dst_clear_pending;

  // Source to Destination synchronization
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni || CLEAR_ON_ASYNC_RESET && src_clear_i) begin
      src_valid_reg <= 0;
      src_data_reg <= 0;
      src_ready_reg <= 0;
      src_clear_reg <= 0;
      src_clear_pending <= 0;
    end else begin
      src_valid_reg <= {src_valid_reg[SYNC_STAGES-2:0], src_valid_i};
      src_data_reg <= {src_data_reg[SYNC_STAGES-2:0], src_data_i};
      src_ready_reg <= {src_ready_reg[SYNC_STAGES-2:0], src_ready_o};
      src_clear_reg <= {src_clear_reg[SYNC_STAGES-2:0], src_clear_i};
      src_clear_pending <= src_clear_reg[SYNC_STAGES-1];
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni || CLEAR_ON_ASYNC_RESET && dst_clear_i) begin
      dst_valid_reg <= 0;
      dst_data_reg <= 0;
      dst_ready_reg <= 0;
      dst_clear_reg <= 0;
      dst_clear_pending <= 0;
    end else begin
      dst_valid_reg <= {dst_valid_reg[SYNC_STAGES-2:0], dst_valid_sync};
      dst_data_reg <= {dst_data_reg[SYNC_STAGES-2:0], dst_data_sync};
      dst_ready_reg <= {dst_ready_reg[SYNC_STAGES-2:0], dst_ready_o};
      dst_clear_reg <= {dst_clear_reg[SYNC_STAGES-2:0], dst_clear_sync};
      dst_clear_pending <= dst_clear_reg[SYNC_STAGES-1];
    end
  end

  // Output logic
  assign src_data_sync = src_data_reg[0];
  assign src_valid_sync = src_valid_reg[0];
  assign src_ready_sync = src_ready_reg[0];
  assign src_clear_sync = src_clear_reg[0];
  assign dst_valid_sync = dst_valid_reg[0];
  assign dst_ready_sync = dst_ready_reg[0];
  assign dst_clear_sync = dst_clear_reg[0];
  assign dst_data_sync = dst_data_reg[0];

  assign src_ready_o = src_ready_sync;
  assign dst_valid_o = dst_valid_sync;
  assign dst_data_o = dst_data_sync;

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule
