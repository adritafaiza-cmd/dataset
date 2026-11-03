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

  // Internal signals for synchronization
  logic src_sync_rst;
  logic dst_sync_rst;
  logic dst_sync_src_clear;
  logic src_sync_dst_clear;
  logic [WIDTH-1:0] fifo_data_o;
  logic fifo_valid_o;

  // Synchronize src_rst_ni to src_clk_i
  async_reset_synchronizer src_async_reset_sync (
    .async_rst_i(src_rst_ni),
    .sync_clk_i(src_clk_i),
    .sync_rst_o(src_sync_rst)
  );

  // Synchronize dst_rst_ni to dst_clk_i
  async_reset_synchronizer dst_async_reset_sync (
    .async_rst_i(dst_rst_ni),
    .sync_clk_i(dst_clk_i),
    .sync_rst_o(dst_sync_rst)
  );

  // Synchronize src_clear_i to dst_clk_i
  async_clear_synchronizer src_async_clear_sync (
    .async_clear_i(src_clear_i),
    .sync_clk_i(dst_clk_i),
    .sync_clear_o(dst_sync_src_clear)
  );

  // Synchronize dst_clear_i to src_clk_i
  async_clear_synchronizer dst_async_clear_sync (
    .async_clear_i(dst_clear_i),
    .sync_clk_i(src_clk_i),
    .sync_clear_o(src_sync_dst_clear)
  );

  // FIFO buffer for data transfer between src_clk_i and dst_clk_i
  fifo_buffer #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES),
    .CLEAR_ON_ASYNC_RESET(CLEAR_ON_ASYNC_RESET)
  ) data_fifo (
    .rst_ni(src_sync_rst),
    .clk_i(src_clk_i),
    .clear_i(src_clear_i),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o),
    .dst_clk_i(dst_clk_i),
    .dst_rst_ni(dst_sync_rst),
    .dst_clear_i(dst_clear_i),
    .data_o(fifo_data_o),
    .valid_o(fifo_valid_o),
    .ready_i(dst_ready_i)
  );

  // Output assignments
  assign src_clear_pending_o = src_clear_i;
  assign dst_clear_pending_o = dst_clear_i;
  assign dst_data_o = fifo_data_o;
  assign dst_valid_o = fifo_valid_o;

endmodule

// Synchronizes an asynchronous reset signal to a target clock domain
module async_reset_synchronizer (
  input  async_rst_i,
  input  sync_clk_i,
  output sync_rst_o
);

  logic sync_rst_1, sync_rst_2;

  always_ff @(posedge sync_clk_i) begin
    sync_rst_1 <= ~async_rst_i;
    sync_rst_2 <= sync_rst_1;
  end

  assign sync_rst_o = sync_rst_2;

endmodule

// Synchronizes an asynchronous clear signal to a target clock domain
module async_clear_synchronizer (
  input  async_clear_i,
  input  sync_clk_i,
  output sync_clear_o
);

  logic sync_clear_1, sync_clear_2;

  always_ff @(posedge sync_clk_i) begin
    sync_clear_1 <= async_clear_i;
    sync_clear_2 <= sync_clear_1;
  end

  assign sync_clear_o = sync_clear_2;

endmodule

// Buffers data between two asynchronous clock domains
module fifo_buffer #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  rst_ni,
  input  clk_i,
  input  clear_i,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  input  dst_clk_i,
  input  dst_rst_ni,
  input  dst_clear_i,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  ready_i
);

  logic [WIDTH-1:0] fifo;
  logic [SYNC_STAGES:0] wr_ptr, rd_ptr;
  logic [SYNC_STAGES:0] wr_ptr_gray, rd_ptr_gray;
  logic [SYNC_STAGES:0] wr_ptr_gray_synced, rd_ptr_gray_synced;
  logic full;

  // Gray code conversion
  function automatic logic [SYNC_STAGES:0] binary_to_gray(logic [SYNC_STAGES:0] bin);
    return bin ^ (bin >> 1);
  endfunction

  // Write pointer logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr <= '0;
    end else if (valid_i && !full) begin
      wr_ptr <= wr_ptr + 1;
    end
  end

  // Read pointer logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      rd_ptr <= '0;
    end else if (ready_i && fifo_valid_o) begin
      rd_ptr <= rd_ptr + 1;
    end
  end

  // Gray code encoding
  assign wr_ptr_gray = binary_to_gray(wr_ptr);
  assign rd_ptr_gray = binary_to_gray(rd_ptr);

  // Synchronize write pointer to read clock domain
  async_fifo_gray_sync #(
    .SYNC_STAGES(SYNC_STAGES)
  ) wr_ptr_gray_sync (
    .async_data_i(wr_ptr_gray),
    .sync_clk_i(dst_clk_i),
    .sync_data_o(wr_ptr_gray_synced)
  );

  // Synchronize read pointer to write clock domain
  async_fifo_gray_sync #(
    .SYNC_STAGES(SYNC_STAGES)
  ) rd_ptr_gray_sync (
    .async_data_i(rd_ptr_gray),
    .sync_clk_i(clk_i),
    .sync_data_o(rd_ptr_gray_synced)
  );

  // Full flag logic
  assign full = (wr_ptr_gray == {~rd_ptr_gray_synced[SYNC_STAGES], rd_ptr_gray_synced[SYNC_STAGES-1:0]});

  // Ready output
  assign ready_o = ~full;

  // Valid output
  assign valid_o = (wr_ptr_gray_synced != rd_ptr_gray);

  // FIFO write logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      fifo <= '0;
    end else if (valid_i && !full) begin
      fifo[wr_ptr[SYNC_STAGES-1:0]] <= data_i;
    end
  end

  // FIFO read logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data_o <= '0;
    end else if (ready_i && fifo_valid_o) begin
      data_o <= fifo[rd_ptr[SYNC_STAGES-1:0]];
    end
  end

  // Clear logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr <= '0;
    end else if (clear_i) begin
      wr_ptr <= '0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      rd_ptr <= '0;
    end else if (dst_clear_i) begin
      rd_ptr <= '0;
    end
  end

endmodule

// Synchronizes a gray-coded pointer between two clock domains
module async_fifo_gray_sync #(
  parameter SYNC_STAGES = 3
)(
  input  [SYNC_STAGES:0] async_data_i,
  input  sync_clk_i,
  output [SYNC_STAGES:0] sync_data_o
);

  logic [SYNC_STAGES:0] sync_data_1;

  always_ff @(posedge sync_clk_i) begin
    sync_data_1 <= async_data_i;
    sync_data_o <= sync_data_1;
  end

endmodule
