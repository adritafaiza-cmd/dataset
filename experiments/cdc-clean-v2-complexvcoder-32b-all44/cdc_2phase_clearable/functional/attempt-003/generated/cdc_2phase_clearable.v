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
  reg [WIDTH-1:0] data_storage;
  reg sync_valid, sync_ready;
  reg clear_request, clear_ack;
  reg clear_pending_src, clear_pending_dst;

  // Instantiate the synchronization module
  cdc_2phase_clearable_sync #(
    .SYNC_STAGES(SYNC_STAGES)
  ) sync_stage (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .valid_i(src_valid_i),
    .valid_o(sync_valid),
    .ready_o(sync_ready)
  );

  // Source-side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 0;
      src_clear_pending_o <= 0;
      data_storage <= 0;
      clear_request <= 0;
      clear_pending_src <= 0;
    end else begin
      // Handle clear request
      if (src_clear_i || (CLEAR_ON_ASYNC_RESET && !src_rst_ni)) begin
        clear_request <= 1;
        clear_pending_src <= 1;
      end else if (clear_ack) begin
        clear_request <= 0;
        clear_pending_src <= 0;
      end

      // Handle data transfer
      if (src_valid_i && sync_ready && !clear_request) begin
        data_storage <= src_data_i;
        src_ready_o <= 1;
      end else begin
        src_ready_o <= 0;
      end
    end
  end

  // Destination-side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_o <= 0;
      dst_data_o <= 0;
      dst_valid_o <= 0;
      clear_ack <= 0;
      clear_pending_dst <= 0;
    end else begin
      // Handle clear request
      if (dst_clear_i || (CLEAR_ON_ASYNC_RESET && !dst_rst_ni)) begin
        dst_clear_pending_o <= 1;
        clear_pending_dst <= 1;
      end else if (clear_request) begin
        dst_clear_pending_o <= 0;
        clear_pending_dst <= 0;
        clear_ack <= 1;
      end else begin
        clear_ack <= 0;
      end

      // Handle data transfer
      if (sync_valid && dst_ready_i && !clear_request) begin
        dst_data_o <= data_storage;
        dst_valid_o <= 1;
      end else begin
        dst_valid_o <= 0;
      end
    end
  end

endmodule

module cdc_2phase_clearable_sync #(
  parameter SYNC_STAGES = 3
)(
  input  rst_ni,
  input  clk_i,
  input  valid_i,
  output reg valid_o,
  output reg ready_o
);

  reg [SYNC_STAGES-1:0] sync_chain;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_chain <= 0;
      valid_o <= 0;
      ready_o <= 0;
    end else begin
      sync_chain <= {sync_chain[SYNC_STAGES-2:0], valid_i};
      valid_o <= sync_chain[SYNC_STAGES-1];
      ready_o <= ~sync_chain[SYNC_STAGES-1];
    end
  end

endmodule
