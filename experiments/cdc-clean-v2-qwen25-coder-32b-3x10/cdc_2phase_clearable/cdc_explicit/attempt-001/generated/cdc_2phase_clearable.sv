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

  // Source domain signals
  logic src_valid_sync;
  logic src_clear_sync;
  logic src_clear_pending;
  logic src_ready;

  // Destination domain signals
  logic dst_valid_sync;
  logic dst_clear_sync;
  logic dst_clear_pending;
  logic dst_ready;

  // Synchronization registers
  logic [SYNC_STAGES-1:0] src_valid_sync_reg;
  logic [SYNC_STAGES-1:0] src_clear_sync_reg;
  logic [SYNC_STAGES-1:0] dst_valid_sync_reg;
  logic [SYNC_STAGES-1:0] dst_clear_sync_reg;

  // Data storage
  logic [WIDTH-1:0] data_storage;

  // Source domain logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync_reg <= '0;
      src_clear_sync_reg <= '0;
      src_clear_pending <= 1'b0;
      src_ready <= 1'b0;
    end else begin
      // Synchronize src_valid_i and src_clear_i to destination domain
      src_valid_sync_reg <= {src_valid_sync_reg[SYNC_STAGES-2:0], src_valid_i};
      src_clear_sync_reg <= {src_clear_sync_reg[SYNC_STAGES-2:0], src_clear_i};

      // Update clear pending status
      src_clear_pending <= src_clear_i || (src_clear_sync && !dst_clear_sync);

      // Update ready signal
      src_ready <= !src_valid_sync && !src_clear_pending;
    end
  end

  // Destination domain logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync_reg <= '0;
      dst_clear_sync_reg <= '0;
      dst_clear_pending <= 1'b0;
      dst_ready <= 1'b0;
      dst_data_o <= '0;
      dst_valid_o <= 1'b0;
    end else begin
      // Synchronize dst_valid_sync and dst_clear_i to source domain
      dst_valid_sync_reg <= {dst_valid_sync_reg[SYNC_STAGES-2:0], dst_valid_o};
      dst_clear_sync_reg <= {dst_clear_sync_reg[SYNC_STAGES-2:0], dst_clear_i};

      // Update clear pending status
      dst_clear_pending <= dst_clear_i || (dst_clear_sync && !src_clear_sync);

      // Update ready signal
      dst_ready <= !dst_valid_o && !dst_clear_pending;

      // Handle data transfer
      if (src_valid_sync && dst_ready) begin
        data_storage <= src_data_i;
        dst_data_o <= src_data_i;
        dst_valid_o <= 1'b1;
      end else if (dst_ready_i) begin
        dst_valid_o <= 1'b0;
      end

      // Handle clear request
      if (src_clear_sync && dst_clear_sync) begin
        dst_data_o <= '0;
        dst_valid_o <= 1'b0;
      end
    end
  end

  // Assign outputs
  assign src_clear_pending_o = src_clear_pending;
  assign src_ready_o = src_ready;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule
