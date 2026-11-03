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

  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_clear_sync;
  logic src_clear_pending_sync;
  logic src_ready_sync;
  logic dst_clear_sync;
  logic dst_clear_pending_sync;
  logic dst_valid_sync;
  logic dst_ready_sync;

  // Source domain
  logic src_valid_reg;
  logic src_ready_reg;
  logic src_clear_pending_reg;
  logic [WIDTH-1:0] src_data_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
      src_data_reg <= '0;
    end else if (src_clear_i) begin
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_clear_pending_reg <= 1'b1;
      src_data_reg <= '0;
    end else if (src_valid_i && src_ready_reg) begin
      src_valid_reg <= 1'b1;
      src_data_reg <= src_data_i;
    end else if (src_valid_reg && ~src_ready_reg) begin
      src_valid_reg <= 1'b0;
    end
  end

  assign src_ready_o = src_ready_reg;
  assign src_clear_pending_o = src_clear_pending_reg;

  // Synchronization
  logic [SYNC_STAGES-1:0] src_valid_sync_chain;
  logic [SYNC_STAGES-1:0] src_clear_sync_chain;
  logic [WIDTH-1:0] src_data_sync_chain [SYNC_STAGES-1:0];

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      src_valid_sync_chain <= '0;
      src_clear_sync_chain <= '0;
      src_data_sync_chain <= '{default: '0};
    end else begin
      src_valid_sync_chain[0] <= src_valid_reg;
      src_clear_sync_chain[0] <= src_clear_pending_reg;
      src_data_sync_chain[0] <= src_data_reg;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_valid_sync_chain[i] <= src_valid_sync_chain[i-1];
        src_clear_sync_chain[i] <= src_clear_sync_chain[i-1];
        src_data_sync_chain[i] <= src_data_sync_chain[i-1];
      end
    end
  end

  assign src_valid_sync = src_valid_sync_chain[SYNC_STAGES-1];
  assign src_clear_sync = src_clear_sync_chain[SYNC_STAGES-1];
  assign src_data_sync = src_data_sync_chain[SYNC_STAGES-1];

  // Destination domain
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic dst_clear_pending_reg;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
    end else if (dst_clear_i) begin
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b1;
    end else if (src_valid_sync && ~dst_valid_reg) begin
      dst_valid_reg <= 1'b1;
      dst_data_o <= src_data_sync;
    end else if (dst_valid_reg && dst_ready_i) begin
      dst_valid_reg <= 1'b0;
    end
  end

  assign dst_valid_o = dst_valid_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

  // Clear handshake
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else if (src_clear_i) begin
      src_ready_reg <= 1'b0;
    end else if (src_clear_pending_reg && ~src_valid_reg) begin
      src_clear_pending_reg <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else if (dst_clear_i) begin
      dst_ready_reg <= 1'b0;
    end else if (dst_clear_pending_reg && ~dst_valid_reg) begin
      dst_clear_pending_reg <= 1'b0;
    end
  end

  // Async reset
  if (CLEAR_ON_ASYNC_RESET) begin
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
      if (~src_rst_ni) begin
        src_clear_pending_reg <= 1'b1;
      end
    end

    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
      if (~dst_rst_ni) begin
        dst_clear_pending_reg <= 1'b1;
      end
    end
  end

endmodule
