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

  wire synced_src_rst_ni;
  wire synced_dst_rst_ni;
  wire valid_crossed;
  wire ready_crossed;

  // Synchronize source reset to destination clock domain
  async_reset_sync #(
    .SYNC_STAGES(SYNC_STAGES)
  ) src_reset_sync_inst (
    .clk(dst_clk_i),
    .async_rst_ni(src_rst_ni),
    .sync_rst_ni(synced_src_rst_ni)
  );

  // Synchronize destination reset to source clock domain
  async_reset_sync #(
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_reset_sync_inst (
    .clk(src_clk_i),
    .async_rst_ni(dst_rst_ni),
    .sync_rst_ni(synced_dst_rst_ni)
  );

  // Handle two-phase handshake between source and destination
  cdc_handshake cdc_handshake_inst (
    .src_clk_i(src_clk_i),
    .src_rst_ni(src_rst_ni),
    .src_valid_i(src_valid_i),
    .src_ready_o(src_ready_o),
    .dst_clk_i(dst_clk_i),
    .synced_src_rst_ni(synced_src_rst_ni),
    .valid_crossed(valid_crossed),
    .ready_crossed(ready_crossed)
  );

  // Synchronize source data to destination clock domain
  data_synchronizer #(
    .WIDTH(WIDTH)
  ) data_sync_inst (
    .clk(dst_clk_i),
    .rst_ni(synced_dst_rst_ni),
    .data_i(src_data_i),
    .data_o(dst_data_o)
  );

  // Outputs
  assign src_clear_pending_o = src_clear_i;
  assign dst_clear_pending_o = dst_clear_i;
  assign dst_valid_o = valid_crossed;
  assign dst_ready_i = ready_crossed;

endmodule

// Synchronizes an asynchronous reset signal to a target clock domain
module async_reset_sync #(
  parameter SYNC_STAGES = 3
)(
  input  clk,
  input  async_rst_ni,
  output sync_rst_ni
);

  reg [SYNC_STAGES-1:0] rst_sync;

  always @(posedge clk) begin
    rst_sync <= {rst_sync[SYNC_STAGES-2:0], ~async_rst_ni};
  end

  assign sync_rst_ni = rst_sync[SYNC_STAGES-1];

endmodule

// Handles the two-phase handshake between source and destination
module cdc_handshake (
  input  src_clk_i,
  input  src_rst_ni,
  input  src_valid_i,
  output src_ready_o,
  input  dst_clk_i,
  input  synced_src_rst_ni,
  output valid_crossed,
  output ready_crossed
);

  reg valid_ff;
  reg ready_ff;
  wire valid_synced;

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      valid_ff <= 0;
      src_ready_o <= 0;
    end else begin
      if (src_valid_i && !valid_ff) begin
        valid_ff <= 1;
        src_ready_o <= 1;
      end else if (ready_crossed) begin
        valid_ff <= 0;
        src_ready_o <= 0;
      end
    end
  end

  // Synchronize valid signal from source to destination
  async_reset_sync #(
    .SYNC_STAGES(SYNC_STAGES)
  ) valid_sync_inst (
    .clk(dst_clk_i),
    .async_rst_ni(synced_src_rst_ni),
    .sync_rst_ni(valid_synced)
  );

  // Destination side logic
  always @(posedge dst_clk_i or negedge synced_src_rst_ni) begin
    if (!synced_src_rst_ni) begin
      ready_ff <= 0;
      valid_crossed <= 0;
    end else begin
      if (valid_synced && !ready_ff) begin
        ready_ff <= 1;
        valid_crossed <= 1;
      end else if (dst_ready_i) begin
        ready_ff <= 0;
        valid_crossed <= 0;
      end
    end
  end

endmodule

// Synchronizes the source data to the destination clock domain
module data_synchronizer #(
  parameter WIDTH = 1
)(
  input  clk,
  input  rst_ni,
  input  [WIDTH-1:0] data_i,
  output [WIDTH-1:0] data_o
);

  reg [WIDTH-1:0] data_sync_0;
  reg [WIDTH-1:0] data_sync_1;

  always @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      data_sync_0 <= 0;
      data_sync_1 <= 0;
    end else begin
      data_sync_0 <= data_i;
      data_sync_1 <= data_sync_0;
    end
  end

  assign data_o = data_sync_1;

endmodule
