module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Internal signals
  logic src_valid_synced;
  logic [WIDTH-1:0] src_data_synced;
  logic dst_ready_synced;
  logic src_ready;
  logic dst_valid;
  logic [WIDTH-1:0] dst_data;
  logic reset_msg_sent;

  // Sync src_valid_i and src_data_i to dst_clk_i
  sync_reg sync_src_valid (
    .clk_i (dst_clk_i),
    .rst_ni(dst_rst_ni),
    .d_i   (src_valid_i),
    .q_o   (src_valid_synced)
  );

  sync_reg #(.WIDTH(WIDTH)) sync_src_data (
    .clk_i (dst_clk_i),
    .rst_ni(dst_rst_ni),
    .d_i   (src_data_i),
    .q_o   (src_data_synced)
  );

  // Sync dst_ready_i to src_clk_i
  sync_reg sync_dst_ready (
    .clk_i (src_clk_i),
    .rst_ni(src_rst_ni),
    .d_i   (dst_ready_i),
    .q_o   (dst_ready_synced)
  );

  // Source-side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 1'b0;
    end else begin
      if (DECOUPLED) begin
        src_ready <= ~src_valid_i | dst_ready_synced;
      end else begin
        src_ready <= dst_ready_synced;
      end
    end
  end

  // Destination-side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid <= 1'b0;
      dst_data <= RESET_MSG;
      reset_msg_sent <= 1'b0;
    end else begin
      if (SEND_RESET_MSG && !reset_msg_sent) begin
        dst_valid <= 1'b1;
        dst_data <= RESET_MSG;
        reset_msg_sent <= 1'b1;
      end else if (src_valid_synced && !dst_valid) begin
        dst_valid <= 1'b1;
        dst_data <= src_data_synced;
        reset_msg_sent <= 1'b0;
      end else if (dst_ready_i) begin
        dst_valid <= 1'b0;
      end
    end
  end

  // Output assignments
  assign src_ready_o = src_ready;
  assign dst_valid_o = dst_valid;
  assign dst_data_o = dst_data;

endmodule

module sync_reg #(
  parameter WIDTH = 1
)(
  input  clk_i,
  input  rst_ni,
  input  [WIDTH-1:0] d_i,
  output [WIDTH-1:0] q_o
);

  logic [WIDTH-1:0] reg1;
  logic [WIDTH-1:0] reg2;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      reg1 <= '0;
      reg2 <= '0;
    end else begin
      reg1 <= d_i;
      reg2 <= reg1;
    end
  end

  assign q_o = reg2;

endmodule
