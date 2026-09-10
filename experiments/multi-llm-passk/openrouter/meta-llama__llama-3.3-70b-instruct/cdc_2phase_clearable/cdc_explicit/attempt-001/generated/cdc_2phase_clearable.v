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

  logic src_clear_synced;
  logic dst_clear_synced;
  logic src_clear_pending;
  logic dst_clear_pending;
  logic src_valid_synced;
  logic src_ready_synced;
  logic dst_valid_synced;
  logic dst_ready_synced;
  logic [WIDTH-1:0] src_data_synced;
  logic [WIDTH-1:0] dst_data_synced;

  // Synchronize src_clear_i to src_clk_i
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_synced <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_synced <= 1'b1;
    end else if (src_clear_pending) begin
      src_clear_synced <= 1'b0;
    end
  end

  // Synchronize dst_clear_i to dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_synced <= 1'b0;
    end else if (dst_clear_i) begin
      dst_clear_synced <= 1'b1;
    end else if (dst_clear_pending) begin
      dst_clear_synced <= 1'b0;
    end
  end

  // Synchronize src_valid_i and src_data_i to dst_clk_i
  logic [SYNC_STAGES-1:0] src_valid_sync;
  logic [SYNC_STAGES-1:0][WIDTH-1:0] src_data_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= '0;
      src_data_sync <= '0;
    end else if (src_clear_synced) begin
      src_valid_sync <= '0;
      src_data_sync <= '0;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_sync[0] <= 1'b1;
      src_data_sync[0] <= src_data_i;
    end else begin
      src_valid_sync[0] <= 1'b0;
      src_data_sync[0] <= '0;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    for (int i = 1; i < SYNC_STAGES; i++) begin
      if (!src_rst_ni) begin
        src_valid_sync[i] <= 1'b0;
        src_data_sync[i] <= '0;
      end else if (src_clear_synced) begin
        src_valid_sync[i] <= 1'b0;
        src_data_sync[i] <= '0;
      end else begin
        src_valid_sync[i] <= src_valid_sync[i-1];
        src_data_sync[i] <= src_data_sync[i-1];
      end
    end
  end

  // Synchronize src_valid_sync and src_data_sync to dst_clk_i
  logic [SYNC_STAGES-1:0] src_valid_synced;
  logic [SYNC_STAGES-1:0][WIDTH-1:0] src_data_synced;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_synced <= '0;
      src_data_synced <= '0;
    end else if (dst_clear_synced) begin
      src_valid_synced <= '0;
      src_data_synced <= '0;
    end else begin
      src_valid_synced[0] <= src_valid_sync[SYNC_STAGES-1];
      src_data_synced[0] <= src_data_sync[SYNC_STAGES-1];
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    for (int i = 1; i < SYNC_STAGES; i++) begin
      if (!dst_rst_ni) begin
        src_valid_synced[i] <= 1'b0;
        src_data_synced[i] <= '0;
      end else if (dst_clear_synced) begin
        src_valid_synced[i] <= 1'b0;
        src_data_synced[i] <= '0;
      end else begin
        src_valid_synced[i] <= src_valid_synced[i-1];
        src_data_synced[i] <= src_data_synced[i-1];
      end
    end
  end

  // Synchronize dst_ready_i to src_clk_i
  logic [SYNC_STAGES-1:0] dst_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_sync <= '0;
    end else if (dst_clear_synced) begin
      dst_ready_sync <= '0;
    end else if (dst_ready_i) begin
      dst_ready_sync[0] <= 1'b1;
    end else begin
      dst_ready_sync[0] <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    for (int i = 1; i < SYNC_STAGES; i++) begin
      if (!dst_rst_ni) begin
        dst_ready_sync[i] <= 1'b0;
      end else if (dst_clear_synced) begin
        dst_ready_sync[i] <= 1'b0;
      end else begin
        dst_ready_sync[i] <= dst_ready_sync[i-1];
      end
    end
  end

  // Synchronize dst_ready_sync to src_clk_i
  logic [SYNC_STAGES-1:0] dst_ready_synced;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_synced <= '0;
    end else if (src_clear_synced) begin
      dst_ready_synced <= '0;
    end else begin
      dst_ready_synced[0] <= dst_ready_sync[SYNC_STAGES-1];
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    for (int i = 1; i < SYNC_STAGES; i++) begin
      if (!src_rst_ni) begin
        dst_ready_synced[i] <= 1'b0;
      end else if (src_clear_synced) begin
        dst_ready_synced[i] <= 1'b0;
      end else begin
        dst_ready_synced[i] <= dst_ready_synced[i-1];
      end
    end
  end

  // Generate src_ready_o
  always_comb begin
    src_ready_o = dst_ready_synced[SYNC_STAGES-1] && !src_clear_synced;
  end

  // Generate dst_valid_o and dst_data_o
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= '0;
    end else if (dst_clear_synced) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= '0;
    end else if (src_valid_synced[SYNC_STAGES-1] && dst_ready_i) begin
      dst_valid_o <= 1'b1;
      dst_data_o <= src_data_synced[SYNC_STAGES-1];
    end else begin
      dst_valid_o <= 1'b0;
      dst_data_o <= '0;
    end
  end

  // Generate src_clear_pending_o
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_pending <= 1'b1;
    end else if (dst_clear_synced) begin
      src_clear_pending <= 1'b0;
    end
  end

  assign src_clear_pending_o = src_clear_pending;

  // Generate dst_clear_pending_o
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 1'b0;
    end else if (dst_clear_i) begin
      dst_clear_pending <= 1'b1;
    end else if (src_clear_synced) begin
      dst_clear_pending <= 1'b0;
    end
  end

  assign dst_clear_pending_o = dst_clear_pending;

endmodule
