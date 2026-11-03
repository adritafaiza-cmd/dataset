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
  logic [WIDTH-1:0] src_sync_data;
  logic src_sync_valid;
  logic src_sync_ready;
  logic dst_sync_valid;
  logic dst_sync_ready;
  logic clear_pending;

  // Synchronizer for source domain
  src_sync #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) src_sync_inst (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .clear_i(src_clear_i),
    .ready_o(src_sync_ready)
  );

  // Synchronizer for destination domain
  dst_sync #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_sync_inst (
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_o(dst_data_o),
    .valid_o(dst_valid_o),
    .ready_i(dst_ready_i)
  );

  // Clear logic
  clear_logic #(
    .WIDTH(WIDTH)
  ) clear_logic_inst (
    .src_clear_i(src_clear_i),
    .src_clear_pending_o(src_clear_pending_o),
    .dst_clear_i(dst_clear_i),
    .dst_clear_pending_o(dst_clear_pending_o),
    .clear_pending(clear_pending)
  );

  // Handshake logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_sync_valid <= 1'b0;
    end else if (src_valid_i && src_sync_ready && !clear_pending) begin
      src_sync_valid <= 1'b1;
    end else if (dst_sync_valid) begin
      src_sync_valid <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_sync_valid <= 1'b0;
    end else if (src_sync_valid && dst_ready_i && !clear_pending) begin
      dst_sync_valid <= 1'b1;
    end else if (dst_valid_o) begin
      dst_sync_valid <= 1'b0;
    end
  end

  // Output logic
  assign src_ready_o = src_sync_ready;
  assign dst_sync_data = src_sync_data;
  assign dst_sync_valid = src_sync_valid;

endmodule

module src_sync #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  clk,
  input  rst_ni,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  input  clear_i,
  output ready_o
);

  logic [WIDTH-1:0] sync_data [0:SYNC_STAGES-1];
  logic sync_valid [0:SYNC_STAGES-1];
  logic sync_ready [0:SYNC_STAGES-1];
  logic clear_pending;

  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_valid <= '{default: 1'b0};
      sync_ready <= '{default: 1'b0};
      clear_pending <= 1'b0;
    end else begin
      if (clear_i) begin
        sync_valid <= '{default: 1'b0};
        sync_ready <= '{default: 1'b0};
        clear_pending <= 1'b1;
      end else if (valid_i && sync_ready[SYNC_STAGES-2]) begin
        sync_data[SYNC_STAGES-1] <= data_i;
        sync_valid[SYNC_STAGES-1] <= 1'b1;
        sync_ready[SYNC_STAGES-1] <= 1'b0;
      end else if (sync_valid[SYNC_STAGES-1]) begin
        sync_valid[SYNC_STAGES-1] <= 1'b0;
      end

      for (int i = 0; i < SYNC_STAGES-1; i++) begin
        sync_data[i] <= sync_data[i+1];
        sync_valid[i] <= sync_valid[i+1];
        sync_ready[i] <= sync_ready[i+1];
      end

      ready_o <= sync_ready[0];
    end
  end

endmodule

module dst_sync #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  clk,
  input  rst_ni,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  ready_i
);

  logic [WIDTH-1:0] sync_data [0:SYNC_STAGES-1];
  logic sync_valid [0:SYNC_STAGES-1];
  logic sync_ready [0:SYNC_STAGES-1];

  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_valid <= '{default: 1'b0};
      sync_ready <= '{default: 1'b0};
    end else begin
      if (ready_i) begin
        sync_ready <= '{default: 1'b1};
      end else if (sync_valid[0]) begin
        data_o <= sync_data[0];
        valid_o <= sync_valid[0];
        sync_valid[0] <= 1'b0;
      end

      for (int i = 0; i < SYNC_STAGES-1; i++) begin
        sync_data[i] <= sync_data[i+1];
        sync_valid[i] <= sync_valid[i+1];
        sync_ready[i] <= sync_ready[i+1];
      end
    end
  end

endmodule

module clear_logic #(
  parameter WIDTH = 1
)(
  input  src_clear_i,
  output src_clear_pending_o,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output logic clear_pending
);

  always_ff @(posedge src_clear_i or posedge dst_clear_i) begin
    if (src_clear_i || dst_clear_i) begin
      clear_pending <= 1'b1;
      src_clear_pending_o <= 1'b1;
      dst_clear_pending_o <= 1'b1;
    end else begin
      clear_pending <= 1'b0;
      src_clear_pending_o <= 1'b0;
      dst_clear_pending_o <= 1'b0;
    end
  end

endmodule
