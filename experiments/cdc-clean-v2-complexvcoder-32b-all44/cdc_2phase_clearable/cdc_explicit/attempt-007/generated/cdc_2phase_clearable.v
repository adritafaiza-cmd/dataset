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
  logic sync_clear_src_to_dst;
  logic sync_clear_dst_to_src;
  logic sync_valid;
  logic sync_ready;
  logic [WIDTH-1:0] sync_data;

  // Sync signals across domains
  cdc_sync #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) sync_src_valid (
    .data_i(src_valid_i),
    .clk_i(src_clk_i),
    .clk_o(dst_clk_i),
    .rst_ni(src_rst_ni),
    .rst_no(dst_rst_ni),
    .sync_valid(sync_valid),
    .sync_ready()
  );

  cdc_sync #(
    .WIDTH(1),
    .SYNC_STAGES(SYNC_STAGES)
  ) sync_src_clear (
    .data_i(src_clear_i),
    .clk_i(src_clk_i),
    .clk_o(dst_clk_i),
    .rst_ni(src_rst_ni),
    .rst_no(dst_rst_ni),
    .sync_valid(sync_clear_src_to_dst),
    .sync_ready()
  );

  cdc_sync #(
    .WIDTH(1),
    .SYNC_STAGES(SYNC_STAGES)
  ) sync_dst_clear (
    .data_i(dst_clear_i),
    .clk_i(dst_clk_i),
    .clk_o(src_clk_i),
    .rst_ni(dst_rst_ni),
    .rst_no(src_rst_ni),
    .sync_valid(sync_clear_dst_to_src),
    .sync_ready()
  );

  cdc_sync #(
    .WIDTH(1),
    .SYNC_STAGES(SYNC_STAGES)
  ) sync_src_ready (
    .data_i(dst_ready_i),
    .clk_i(dst_clk_i),
    .clk_o(src_clk_i),
    .rst_ni(dst_rst_ni),
    .rst_no(src_rst_ni),
    .sync_valid(),
    .sync_ready(sync_ready)
  );

  cdc_sync #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) sync_dst_data (
    .data_i(src_data_i),
    .clk_i(src_clk_i),
    .clk_o(dst_clk_i),
    .rst_ni(src_rst_ni),
    .rst_no(dst_rst_ni),
    .sync_valid(sync_data),
    .sync_ready()
  );

  // Clear pending signals
  logic src_clear_pending;
  logic dst_clear_pending;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 1'b0;
    end else begin
      if (src_clear_i) begin
        src_clear_pending <= 1'b1;
      end else if (sync_clear_dst_to_src) begin
        src_clear_pending <= 1'b0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        dst_clear_pending <= 1'b1;
      end else if (sync_clear_src_to_dst) begin
        dst_clear_pending <= 1'b0;
      end
    end
  end

  // Output assignments
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

  // Control logic for ready/valid handshake
  logic src_valid_d;
  logic src_ready_d;
  logic dst_valid_d;
  logic dst_ready_d;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_d <= 1'b0;
      src_ready_d <= 1'b0;
    end else begin
      if (src_clear_i) begin
        src_valid_d <= 1'b0;
        src_ready_d <= 1'b0;
      end else begin
        src_valid_d <= src_valid_i & ~sync_clear_src_to_dst;
        src_ready_d <= sync_ready & ~sync_clear_src_to_dst;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_d <= 1'b0;
      dst_ready_d <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        dst_valid_d <= 1'b0;
        dst_ready_d <= 1'b0;
      end else begin
        dst_valid_d <= sync_valid & ~sync_clear_dst_to_src;
        dst_ready_d <= dst_ready_i & ~sync_clear_dst_to_src;
      end
    end
  end

  assign src_ready_o = src_ready_d;
  assign dst_valid_o = dst_valid_d;
  assign dst_data_o = sync_data;

endmodule

module cdc_sync #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  [WIDTH-1:0] data_i,
  input  clk_i,
  input  clk_o,
  input  rst_ni,
  input  rst_no,
  output [WIDTH-1:0] sync_valid,
  output [WIDTH-1:0] sync_ready
);

  logic [WIDTH-1:0] sync_chain [SYNC_STAGES-1:0];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_chain[0] <= '0;
    end else begin
      sync_chain[0] <= data_i;
    end
  end

  genvar i;
  generate
    for (i = 1; i < SYNC_STAGES; i = i + 1) begin : gen_sync_chain
      always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          sync_chain[i] <= '0;
        end else begin
          sync_chain[i] <= sync_chain[i-1];
        end
      end
    end
  endgenerate

  always_ff @(posedge clk_o or negedge rst_no) begin
    if (!rst_no) begin
      sync_valid <= '0;
    end else begin
      sync_valid <= sync_chain[SYNC_STAGES-1];
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_ready <= '0;
    end else begin
      sync_ready <= sync_chain[SYNC_STAGES-1];
    end
  end

endmodule
