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
  logic src_clear_sync;
  logic dst_clear_sync;
  logic src_valid_sync;
  logic [WIDTH-1:0] src_data_sync;
  logic dst_ready_sync;
  logic clear_src;
  logic clear_dst;
  logic src_clear_handshake;
  logic dst_clear_handshake;
  logic [1:0] src_clear_state;
  logic [1:0] dst_clear_state;

  // Sync clear signal to destination domain
  sync_chain #(.STAGES(SYNC_STAGES)) u_src_clear_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .d_i(src_clear_i),
    .q_o(src_clear_sync)
  );

  // Sync clear signal to source domain
  sync_chain #(.STAGES(SYNC_STAGES)) u_dst_clear_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .d_i(dst_clear_i),
    .q_o(dst_clear_sync)
  );

  // Sync valid signal to destination domain
  sync_chain #(.STAGES(SYNC_STAGES)) u_src_valid_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .d_i(src_valid_i),
    .q_o(src_valid_sync)
  );

  // Sync data signal to destination domain
  sync_chain #(.STAGES(SYNC_STAGES), .WIDTH(WIDTH)) u_src_data_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .d_i(src_data_i),
    .q_o(src_data_sync)
  );

  // Sync ready signal to source domain
  sync_chain #(.STAGES(SYNC_STAGES)) u_dst_ready_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .d_i(dst_ready_i),
    .q_o(dst_ready_sync)
  );

  // Source clear handshake logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_handshake <= 0;
      src_clear_state <= 0;
    end else begin
      if (src_clear_i && !src_clear_sync) begin
        src_clear_handshake <= 1;
        src_clear_state <= 2'b01;
      end else if (src_clear_state == 2'b01 && src_clear_sync) begin
        src_clear_state <= 2'b10;
      end else if (src_clear_state == 2'b10 && !src_clear_sync) begin
        src_clear_state <= 2'b00;
        src_clear_handshake <= 0;
      end
    end
  end

  // Destination clear handshake logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_handshake <= 0;
      dst_clear_state <= 0;
    end else begin
      if (dst_clear_i && !dst_clear_sync) begin
        dst_clear_handshake <= 1;
        dst_clear_state <= 2'b01;
      end else if (dst_clear_state == 2'b01 && dst_clear_sync) begin
        dst_clear_state <= 2'b10;
      end else if (dst_clear_state == 2'b10 && !dst_clear_sync) begin
        dst_clear_state <= 2'b00;
        dst_clear_handshake <= 0;
      end
    end
  end

  // Clear signals
  assign clear_src = src_clear_i || (CLEAR_ON_ASYNC_RESET && !src_rst_ni);
  assign clear_dst = dst_clear_i || (CLEAR_ON_ASYNC_RESET && !dst_rst_ni);

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_o <= 0;
      src_ready_o <= 0;
    end else begin
      if (src_clear_handshake) begin
        src_clear_pending_o <= 1;
      end else if (src_clear_state == 2'b00) begin
        src_clear_pending_o <= 0;
      end

      if (clear_src) begin
        src_ready_o <= 0;
      end else begin
        src_ready_o <= dst_ready_sync && !src_valid_sync;
      end
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_o <= 0;
      dst_valid_o <= 0;
      dst_data_o <= 0;
    end else begin
      if (dst_clear_handshake) begin
        dst_clear_pending_o <= 1;
      end else if (dst_clear_state == 2'b00) begin
        dst_clear_pending_o <= 0;
      end

      if (clear_dst) begin
        dst_valid_o <= 0;
      end else begin
        dst_valid_o <= src_valid_sync;
        dst_data_o <= src_data_sync;
      end
    end
  end

endmodule

// Sync chain module for synchronizing signals between clock domains
module sync_chain #(
  parameter STAGES = 3,
  parameter WIDTH = 1
)(
  input  logic clk_i,
  input  logic rst_ni,
  input  logic [WIDTH-1:0] d_i,
  output logic [WIDTH-1:0] q_o
);

  logic [WIDTH-1:0] sync_stages [STAGES-1:0];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < STAGES; i++) begin
        sync_stages[i] <= 0;
      end
    end else begin
      sync_stages[0] <= d_i;
      for (int i = 1; i < STAGES; i++) begin
        sync_stages[i] <= sync_stages[i-1];
      end
    end
  end

  assign q_o = sync_stages[STAGES-1];

endmodule
