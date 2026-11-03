module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  logic src_rst_ni,
  input  logic src_clk_i,
  input  logic src_clear_i,
  output logic src_clear_pending_o,
  input  logic [WIDTH-1:0] src_data_i,
  input  logic src_valid_i,
  output logic src_ready_o,
  input  logic dst_rst_ni,
  input  logic dst_clk_i,
  input  logic dst_clear_i,
  output logic dst_clear_pending_o,
  output logic [WIDTH-1:0] dst_data_o,
  output logic dst_valid_o,
  input  logic dst_ready_i
);

  logic src_valid_synced;
  logic [WIDTH-1:0] src_data_synced;
  logic src_clear_synced;
  logic dst_clear_synced;
  logic src_valid_dst;
  logic [WIDTH-1:0] src_data_dst;
  logic dst_valid;
  logic src_ready;

  // Synchronize src_valid and src_data to dst_clk_i
  sync_fifo #(
    .WIDTH(WIDTH + 1),
    .DEPTH(1)
  ) src_sync (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .valid_i(src_valid_i),
    .data_i({src_valid_i, src_data_i}),
    .ready_o(src_ready),
    .valid_o(src_valid_synced),
    .data_o({src_valid_dst, src_data_synced})
  );

  // Synchronize src_clear to dst_clk_i
  sync_bit #(
    .SYNC_STAGES(SYNC_STAGES)
  ) src_clear_sync (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .i(src_clear_i),
    .o(src_clear_synced)
  );

  // Synchronize dst_clear to src_clk_i
  sync_bit #(
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_clear_sync (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .i(dst_clear_i),
    .o(dst_clear_synced)
  );

  // Generate src_clear_pending_o
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_o <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_pending_o <= 1'b1;
    end else if (dst_clear_synced) begin
      src_clear_pending_o <= 1'b0;
    end
  end

  // Generate dst_clear_pending_o
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_o <= 1'b0;
    end else if (dst_clear_i) begin
      dst_clear_pending_o <= 1'b1;
    end else if (src_clear_synced) begin
      dst_clear_pending_o <= 1'b0;
    end
  end

  // Generate src_ready_o
  assign src_ready_o = src_ready;

  // Generate dst_valid_o and dst_data_o
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= '0;
    end else if (src_clear_synced) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= '0;
    end else if (src_valid_synced && dst_ready_i) begin
      dst_valid_o <= 1'b1;
      dst_data_o <= src_data_synced;
    end else if (!dst_ready_i) begin
      dst_valid_o <= 1'b0;
    end
  end

  // Generate src_ready
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 1'b0;
    end else if (dst_clear_synced) begin
      src_ready <= 1'b0;
    end else if (src_valid_i && !src_clear_i) begin
      src_ready <= 1'b1;
    end else if (src_clear_i) begin
      src_ready <= 1'b0;
    end
  end

endmodule

module sync_fifo #(
  parameter WIDTH = 1,
  parameter DEPTH = 1
)(
  input  logic rst_ni,
  input  logic clk_i,
  input  logic valid_i,
  input  logic [WIDTH-1:0] data_i,
  output logic ready_o,
  output logic valid_o,
  output logic [WIDTH-1:0] data_o
);

  logic [WIDTH-1:0] fifo [DEPTH-1:0];
  logic [DEPTH-1:0] valid;
  logic [DEPTH-1:0] ready;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid <= '0;
      ready <= '0;
      fifo <= '0;
    end else if (valid_i && ready[0]) begin
      valid[0] <= 1'b1;
      fifo[0] <= data_i;
      ready[0] <= 1'b0;
    end else if (!valid_i && ready[0]) begin
      valid[0] <= 1'b0;
      ready[0] <= 1'b1;
    end
  end

  assign valid_o = valid[0];
  assign data_o = fifo[0];
  assign ready_o = ready[0];

endmodule

module sync_bit #(
  parameter SYNC_STAGES = 3
)(
  input  logic rst_ni,
  input  logic clk_i,
  input  logic i,
  output logic o
);

  logic [SYNC_STAGES-1:0] sync;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync <= '0;
    end else begin
      sync[0] <= i;
      for (int j = 1; j < SYNC_STAGES; j++) begin
        sync[j] <= sync[j-1];
      end
    end
  end

  assign o = sync[SYNC_STAGES-1];

endmodule
