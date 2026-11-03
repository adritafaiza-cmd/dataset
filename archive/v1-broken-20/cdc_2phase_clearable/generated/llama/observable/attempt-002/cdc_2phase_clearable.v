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

logic src_valid_sync;
logic src_clear_sync;
logic [WIDTH-1:0] src_data_sync;
logic dst_valid;
logic dst_clear;
logic [WIDTH-1:0] dst_data;
logic src_ready;
logic dst_ready_sync;
logic src_clear_pending;
logic dst_clear_pending;

// Synchronize src_valid and src_clear to dst_clk_i
sync_bit #(.STAGES(SYNC_STAGES)) src_valid_sync_u (
 .clk_i(dst_clk_i),
 .rst_ni(dst_rst_ni),
 .async_i(src_valid_i),
 .sync_o(src_valid_sync)
);

sync_bit #(.STAGES(SYNC_STAGES)) src_clear_sync_u (
 .clk_i(dst_clk_i),
 .rst_ni(dst_rst_ni),
 .async_i(src_clear_i),
 .sync_o(src_clear_sync)
);

// Synchronize src_data to dst_clk_i
sync_data #(
 .WIDTH(WIDTH),
 .STAGES(SYNC_STAGES)
) src_data_sync_u (
 .clk_i(dst_clk_i),
 .rst_ni(dst_rst_ni),
 .async_i(src_data_i),
 .sync_o(src_data_sync)
);

// Synchronize dst_ready_i to src_clk_i
sync_bit #(.STAGES(SYNC_STAGES)) dst_ready_sync_u (
 .clk_i(src_clk_i),
 .rst_ni(src_rst_ni),
 .async_i(dst_ready_i),
 .sync_o(dst_ready_sync)
);

// Synchronize dst_clear_i to src_clk_i
sync_bit #(.STAGES(SYNC_STAGES)) dst_clear_sync_u (
 .clk_i(src_clk_i),
 .rst_ni(src_rst_ni),
 .async_i(dst_clear_i),
 .sync_o(dst_clear)
);

// Generate src_clear_pending
always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
  if (!src_rst_ni) begin
    src_clear_pending <= 1'b0;
  end else if (src_clear_i) begin
    src_clear_pending <= 1'b1;
  end else if (dst_clear) begin
    src_clear_pending <= 1'b0;
  end
end

// Generate dst_clear_pending
always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
  if (!dst_rst_ni) begin
    dst_clear_pending <= 1'b0;
  end else if (dst_clear_i) begin
    dst_clear_pending <= 1'b1;
  end else if (src_clear_sync) begin
    dst_clear_pending <= 1'b0;
  end
end

// Generate src_ready
always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
  if (!src_rst_ni) begin
    src_ready <= 1'b0;
  end else if (src_clear_i) begin
    src_ready <= 1'b0;
  end else if (dst_ready_sync &&!dst_clear) begin
    src_ready <= 1'b1;
  end else begin
    src_ready <= 1'b0;
  end
end

// Generate dst_valid and dst_data
always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
  if (!dst_rst_ni) begin
    dst_valid <= 1'b0;
    dst_data <= '0;
  end else if (dst_clear_i) begin
    dst_valid <= 1'b0;
    dst_data <= '0;
  end else if (src_valid_sync &&!src_clear_sync) begin
    dst_valid <= 1'b1;
    dst_data <= src_data_sync;
  end else if (dst_ready_i) begin
    dst_valid <= 1'b0;
    dst_data <= '0;
  end
end

assign src_clear_pending_o = src_clear_pending;
assign dst_clear_pending_o = dst_clear_pending;
assign src_ready_o = src_ready;
assign dst_valid_o = dst_valid;
assign dst_data_o = dst_data;

endmodule

module sync_bit #(
  parameter STAGES = 3
)(
  input  clk_i,
  input  rst_ni,
  input  async_i,
  output sync_o
);

logic [STAGES-1:0] sync;

always_ff @(posedge clk_i or negedge rst_ni) begin
  if (!rst_ni) begin
    sync <= '0;
  end else begin
    sync[0] <= async_i;
    for (int i = 1; i < STAGES; i++) begin
      sync[i] <= sync[i-1];
    end
  end
end

assign sync_o = sync[STAGES-1];

endmodule

module sync_data #(
  parameter WIDTH = 1,
  parameter STAGES = 3
)(
  input  clk_i,
  input  rst_ni,
  input  [WIDTH-1:0] async_i,
  output [WIDTH-1:0] sync_o
);

logic [WIDTH-1:0] sync [STAGES-1:0];

always_ff @(posedge clk_i or negedge rst_ni) begin
  if (!rst_ni) begin
    for (int i = 0; i < STAGES; i++) begin
      sync[i] <= '0;
    end
  end else begin
    sync[0] <= async_i;
    for (int i = 1; i < STAGES; i++) begin
      sync[i] <= sync[i-1];
    end
  end
end

assign sync_o = sync[STAGES-1];

endmodule
