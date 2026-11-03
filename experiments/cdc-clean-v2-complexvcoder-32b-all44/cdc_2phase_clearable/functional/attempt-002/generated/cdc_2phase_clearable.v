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
  logic src_valid_synced;
  logic dst_ready_synced;
  logic src_clear_pending;
  logic dst_clear_pending;
  logic clear_request;
  logic clear_ack;
  logic clear_request_synced;
  logic clear_ack_synced;
  logic [WIDTH-1:0] data_ff;
  logic valid_ff;

  // Sync signals between domains
  sync_register #(.SYNC_STAGES(SYNC_STAGES)) src_to_dst_sync (
    .sync_in(src_valid_i),
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .sync_clk(dst_clk_i),
    .sync_rst_ni(dst_rst_ni),
    .sync_out(src_valid_synced)
  );

  sync_register #(.SYNC_STAGES(SYNC_STAGES)) dst_to_src_sync (
    .sync_in(dst_ready_i),
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .sync_clk(src_clk_i),
    .sync_rst_ni(src_rst_ni),
    .sync_out(dst_ready_synced)
  );

  sync_register #(.SYNC_STAGES(SYNC_STAGES)) clear_request_sync (
    .sync_in(clear_request),
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .sync_clk(dst_clk_i),
    .sync_rst_ni(dst_rst_ni),
    .sync_out(clear_request_synced)
  );

  sync_register #(.SYNC_STAGES(SYNC_STAGES)) clear_ack_sync (
    .sync_in(clear_ack),
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .sync_clk(src_clk_i),
    .sync_rst_ni(src_rst_ni),
    .sync_out(clear_ack_synced)
  );

  // Source domain logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
      src_clear_pending <= 1'b0;
      clear_request <= 1'b0;
    end else begin
      src_ready_o <= dst_ready_synced && !clear_request_synced;
      if (src_clear_i) begin
        src_clear_pending <= 1'b1;
        clear_request <= 1'b1;
      end else if (clear_ack_synced) begin
        src_clear_pending <= 1'b0;
        clear_request <= 1'b0;
      end
    end
  end

  // Destination domain logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_clear_pending <= 1'b0;
      clear_ack <= 1'b0;
    end else begin
      dst_valid_o <= src_valid_synced && !clear_request;
      if (dst_clear_i) begin
        dst_clear_pending <= 1'b1;
        clear_ack <= 1'b1;
      end else if (clear_request_synced) begin
        dst_clear_pending <= 1'b0;
        clear_ack <= 1'b0;
      end
    end
  end

  // Data transfer logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_ff <= '0;
      valid_ff <= 1'b0;
    end else if (src_valid_i && dst_ready_synced && !clear_request_synced) begin
      data_ff <= src_data_i;
      valid_ff <= 1'b1;
    end else if (clear_request_synced) begin
      valid_ff <= 1'b0;
    end
  end

  assign dst_data_o = data_ff;

  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule

module sync_register #(
  parameter SYNC_STAGES = 3
)(
  input  sync_in,
  input  clk,
  input  rst_ni,
  input  sync_clk,
  input  sync_rst_ni,
  output sync_out
);

  logic [SYNC_STAGES-1:0] sync_reg;

  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_reg <= '0;
    end else begin
      sync_reg[0] <= sync_in;
      sync_reg[1:SYNC_STAGES-1] <= sync_reg[0:SYNC_STAGES-2];
    end
  end

  always_ff @(posedge sync_clk or negedge sync_rst_ni) begin
    if (!sync_rst_ni) begin
      sync_out <= 1'b0;
    end else begin
      sync_out <= sync_reg[SYNC_STAGES-1];
    end
  end

endmodule
