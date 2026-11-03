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
  logic [WIDTH-1:0] src_data_synced;
  logic src_valid_synced;
  logic valid_src;
  logic [WIDTH-1:0] data_src;
  logic clear_src;
  logic clear_dst;
  logic src_clear_req;
  logic dst_clear_req;
  logic src_clear_done;
  logic dst_clear_done;

  // Sync stage to cross data and valid signals
  sync_stage #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) sync_stage_inst (
    .data_i(src_data_i),
    .data_o(src_data_synced),
    .valid_i(src_valid_i),
    .valid_o(src_valid_synced)
  );

  // Clear logic for source domain
  clear_logic clear_logic_src (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .clear_i(src_clear_i),
    .clear_pending_o(src_clear_pending_o),
    .clear_src(clear_src),
    .clear_dst(clear_dst)
  );

  // Clear logic for destination domain
  clear_logic clear_logic_dst (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .clear_i(dst_clear_i),
    .clear_pending_o(dst_clear_pending_o),
    .clear_src(clear_src),
    .clear_dst(clear_dst)
  );

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
      src_clear_req <= 1'b0;
    end else begin
      if (src_clear_i) begin
        src_clear_req <= 1'b1;
      end else if (src_clear_done) begin
        src_clear_req <= 1'b0;
      end

      if (src_clear_i || src_clear_req) begin
        src_ready_o <= 1'b0;
      end else if (src_valid_i && !valid_src) begin
        src_ready_o <= 1'b1;
      end else begin
        src_ready_o <= 1'b0;
      end
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= '0;
      dst_valid_o <= 1'b0;
      dst_clear_req <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        dst_clear_req <= 1'b1;
      end else if (dst_clear_done) begin
        dst_clear_req <= 1'b0;
      end

      if (clear_dst) begin
        dst_valid_o <= 1'b0;
      end else if (src_valid_synced && !dst_valid_o) begin
        dst_data_o <= src_data_synced;
        dst_valid_o <= 1'b1;
      end else if (dst_ready_i && dst_valid_o) begin
        dst_valid_o <= 1'b0;
      end
    end
  end

  // Cross-domain clear signal handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      clear_src <= 1'b0;
    end else begin
      clear_src <= clear_dst;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      clear_dst <= 1'b0;
    end else begin
      clear_dst <= clear_src;
    end
  end

  // Clear completion detection
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_done <= 1'b0;
    end else begin
      if (src_clear_req && !clear_src) begin
        src_clear_done <= 1'b1;
      end else if (src_clear_i) begin
        src_clear_done <= 1'b0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_done <= 1'b0;
    end else begin
      if (dst_clear_req && !clear_dst) begin
        dst_clear_done <= 1'b1;
      end else if (dst_clear_i) begin
        dst_clear_done <= 1'b0;
      end
    end
  end

endmodule

module sync_stage #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  [WIDTH-1:0] data_i,
  output [WIDTH-1:0] data_o,
  input  valid_i,
  output valid_o
);

  logic [SYNC_STAGES-1:0] data_sync;
  logic [SYNC_STAGES-1:0] valid_sync;

  always_ff @(posedge dst_clk_i) begin
    data_sync[0] <= data_i;
    valid_sync[0] <= valid_i;
    for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
      data_sync[i] <= data_sync[i-1];
      valid_sync[i] <= valid_sync[i-1];
    end
  end

  assign data_o = data_sync[SYNC_STAGES-1];
  assign valid_o = valid_sync[SYNC_STAGES-1];

endmodule

module clear_logic (
  input  rst_ni,
  input  clk_i,
  input  clear_i,
  output clear_pending_o,
  inout  clear_src,
  inout  clear_dst
);

  logic clear_req;
  logic clear_done;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      clear_req <= 1'b0;
      clear_done <= 1'b0;
    end else begin
      if (clear_i) begin
        clear_req <= 1'b1;
      end else if (clear_done) begin
        clear_req <= 1'b0;
      end

      if (clear_req && !clear_src) begin
        clear_done <= 1'b1;
      end else if (clear_i) begin
        clear_done <= 1'b0;
      end
    end
  end

  assign clear_pending_o = clear_req;

endmodule
