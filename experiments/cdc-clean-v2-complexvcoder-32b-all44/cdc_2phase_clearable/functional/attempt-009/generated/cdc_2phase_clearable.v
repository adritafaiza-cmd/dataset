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

  // Synchronizers for valid, ready, and clear signals
  sync_ff #(SYNC_STAGES) src_valid_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(src_valid_i),
    .data_o(src_valid_sync)
  );

  sync_ff #(SYNC_STAGES) dst_ready_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(dst_ready_i),
    .data_o(dst_ready_sync)
  );

  sync_ff #(SYNC_STAGES) src_clear_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(src_clear_i),
    .data_o(src_clear_sync)
  );

  sync_ff #(SYNC_STAGES) dst_clear_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(dst_clear_i),
    .data_o(dst_clear_sync)
  );

  // Internal registers
  reg src_valid_reg;
  reg dst_valid_reg;
  reg src_clear_reg;
  reg dst_clear_reg;
  reg src_clear_pending_reg;
  reg dst_clear_pending_reg;
  reg src_ready_reg;
  reg [WIDTH-1:0] dst_data_reg;

  // Source-side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      src_clear_reg <= 0;
      src_clear_pending_reg <= 0;
      src_ready_reg <= 0;
    end else begin
      // Handle clear request
      if (src_clear_i || (CLEAR_ON_ASYNC_RESET && !src_rst_ni)) begin
        src_clear_reg <= 1;
        src_clear_pending_reg <= 1;
      end else if (src_clear_pending_reg && !src_clear_sync) begin
        src_clear_reg <= 0;
        src_clear_pending_reg <= 0;
      end

      // Handle data transfer
      if (src_valid_i && dst_ready_sync && !src_clear_reg) begin
        src_valid_reg <= 1;
        src_ready_reg <= 0;
      end else if (dst_valid_reg && dst_ready_sync) begin
        src_valid_reg <= 0;
        src_ready_reg <= 1;
      end else if (!src_valid_reg) begin
        src_ready_reg <= 1;
      end
    end
  end

  // Destination-side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
      dst_clear_reg <= 0;
      dst_clear_pending_reg <= 0;
      dst_data_reg <= 0;
    end else begin
      // Handle clear request
      if (dst_clear_i || (CLEAR_ON_ASYNC_RESET && !dst_rst_ni)) begin
        dst_clear_reg <= 1;
        dst_clear_pending_reg <= 1;
      end else if (dst_clear_pending_reg && !dst_clear_sync) begin
        dst_clear_reg <= 0;
        dst_clear_pending_reg <= 0;
      end

      // Handle data transfer
      if (src_valid_sync && !dst_valid_reg && !dst_clear_reg) begin
        dst_data_reg <= src_data_i;
        dst_valid_reg <= 1;
      end else if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 0;
      end
    end
  end

  // Output assignments
  assign src_clear_pending_o = src_clear_pending_reg;
  assign src_ready_o = src_ready_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule

// Synchronizer flip-flop module
module sync_ff #(
  parameter STAGES = 3
)(
  input  clk_i,
  input  rst_ni,
  input  data_i,
  output reg data_o
);

  reg [STAGES-1:0] sync_chain;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_chain <= 0;
    end else begin
      sync_chain[0] <= data_i;
      for (int i = 1; i < STAGES; i = i + 1) begin
        sync_chain[i] <= sync_chain[i-1];
      end
    end
  end

  assign data_o = sync_chain[STAGES-1];

endmodule
