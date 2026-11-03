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
  logic dst_clear;
  logic src_clear;
  logic [WIDTH-1:0] dst_data;
  logic dst_valid;
  logic src_clear_pending;
  logic dst_clear_pending;
  logic src_valid_sync;
  logic dst_valid_sync;
  logic [WIDTH-1:0] dst_data_sync;

  // Synchronize clear signals
  sync_ff src_clear_sync (
    .async_clear(src_clear_i),
    .synced_clear(dst_clear),
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni)
  );

  sync_ff dst_clear_sync (
    .async_clear(dst_clear_i),
    .synced_clear(src_clear),
    .clk(src_clk_i),
    .rst_n(src_rst_ni)
  );

  // Synchronize data and valid signals
  sync_ff_array #(.WIDTH(WIDTH)) data_sync (
    .async_data(src_data_i),
    .synced_data(dst_data_sync),
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni)
  );

  sync_ff valid_sync (
    .async_valid(src_valid_i),
    .synced_valid(src_valid_sync),
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni)
  );

  // Source-side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
      src_clear_pending <= 1'b0;
    end else begin
      if (src_clear_i) begin
        src_clear_pending <= 1'b1;
        src_ready_o <= 1'b0;
      end else if (src_clear_pending && !dst_clear_pending) begin
        src_clear_pending <= 1'b0;
      end else begin
        src_ready_o <= (dst_ready_i && dst_valid) ? 1'b1 : 1'b0;
      end
    end
  end

  // Destination-side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= '0;
      dst_valid_o <= 1'b0;
      dst_clear_pending <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        dst_clear_pending <= 1'b1;
        dst_valid_o <= 1'b0;
      end else if (dst_clear_pending && !src_clear_pending) begin
        dst_clear_pending <= 1'b0;
      end else if (src_valid_sync && !dst_valid) begin
        dst_data_o <= dst_data_sync;
        dst_valid_o <= 1'b1;
      end else if (dst_ready_i && dst_valid) begin
        dst_valid_o <= 1'b0;
      end
    end
  end

  // Assign pending clear outputs
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule

// Synchronize a 1-bit signal across clock domains using two flip-flops.
module sync_ff (
  input  async_clear,
  output synced_clear,
  input  clk,
  input  rst_n
);
  logic ff1, ff2;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ff1 <= 1'b0;
      ff2 <= 1'b0;
    end else begin
      ff1 <= async_clear;
      ff2 <= ff1;
    end
  end

  assign synced_clear = ff2;
endmodule

// Synchronize a multi-bit signal across clock domains using two flip-flops per bit.
module sync_ff_array #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] async_data,
  output [WIDTH-1:0] synced_data,
  input  clk,
  input  rst_n
);
  logic [WIDTH-1:0] ff1, ff2;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ff1 <= '0;
      ff2 <= '0;
    end else begin
      ff1 <= async_data;
      ff2 <= ff1;
    end
  end

  assign synced_data = ff2;
endmodule
