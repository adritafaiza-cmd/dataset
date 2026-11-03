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

  // Internal signals for reset synchronization
  wire sync_src_rst_no;
  wire sync_dst_rst_no;

  // Instantiate the reset synchronizers
  async_reset_sync src_reset_sync (
    .async_rst_ni(src_rst_ni),
    .sync_rst_no(sync_src_rst_no),
    .clk_i(dst_clk_i)
  );

  async_reset_sync dst_reset_sync (
    .async_rst_ni(dst_rst_ni),
    .sync_rst_no(sync_dst_rst_no),
    .clk_i(src_clk_i)
  );

  // Instantiate the asynchronous handshake module
  async_handshake handshake (
    .src_clk_i(src_clk_i),
    .src_rst_ni(sync_src_rst_no),
    .src_clear_i(src_clear_i),
    .src_valid_i(src_valid_i),
    .src_ready_o(src_ready_o),
    .dst_clk_i(dst_clk_i),
    .dst_rst_ni(sync_dst_rst_no),
    .dst_clear_i(dst_clear_i),
    .dst_valid_o(dst_valid_o),
    .dst_ready_i(dst_ready_i),
    .data_i(src_data_i),
    .data_o(dst_data_o),
    .src_clear_pending_o(src_clear_pending_o),
    .dst_clear_pending_o(dst_clear_pending_o)
  );

endmodule

module async_reset_sync (
  input  async_rst_ni,
  output sync_rst_no,
  input  clk_i
);

  reg [SYNC_STAGES-1:0] sync_rst_n;

  always @(posedge clk_i) begin
    sync_rst_n <= {sync_rst_n[SYNC_STAGES-2:0], async_rst_ni};
  end

  assign sync_rst_no = sync_rst_n[SYNC_STAGES-1];

endmodule

module async_handshake #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_clk_i,
  input  src_rst_ni,
  input  src_clear_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_clk_i,
  input  dst_rst_ni,
  input  dst_clear_i,
  output dst_valid_o,
  input  dst_ready_i,
  input  [WIDTH-1:0] data_i,
  output [WIDTH-1:0] data_o,
  output src_clear_pending_o,
  output dst_clear_pending_o
);

  // Instantiate the async FIFO
  async_fifo fifo (
    .src_clk_i(src_clk_i),
    .src_rst_ni(src_rst_ni),
    .src_clear_i(src_clear_i),
    .src_valid_i(src_valid_i),
    .src_ready_o(src_ready_o),
    .dst_clk_i(dst_clk_i),
    .dst_rst_ni(dst_rst_ni),
    .dst_clear_i(dst_clear_i),
    .dst_valid_o(dst_valid_o),
    .dst_ready_i(dst_ready_i),
    .data_i(data_i),
    .data_o(data_o),
    .src_clear_pending_o(src_clear_pending_o),
    .dst_clear_pending_o(dst_clear_pending_o)
  );

endmodule

module async_fifo #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_clk_i,
  input  src_rst_ni,
  input  src_clear_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_clk_i,
  input  dst_rst_ni,
  input  dst_clear_i,
  output dst_valid_o,
  input  dst_ready_i,
  input  [WIDTH-1:0] data_i,
  output [WIDTH-1:0] data_o,
  output src_clear_pending_o,
  output dst_clear_pending_o
);

  // FIFO signals
  reg [WIDTH-1:0] fifo_data;
  reg fifo_full;
  reg fifo_empty;
  reg fifo_wr_en;
  reg fifo_rd_en;
  reg src_clear_req;
  reg dst_clear_req;
  reg src_clear_pending;
  reg dst_clear_pending;

  // FIFO write enable
  assign fifo_wr_en = src_valid_i & src_ready_o;

  // FIFO read enable
  assign fifo_rd_en = dst_valid_o & dst_ready_i;

  // FIFO flags
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      fifo_full <= 0;
      fifo_empty <= 1;
    end else begin
      fifo_full <= (fifo_wr_en & !fifo_rd_en & fifo_full) | (fifo_wr_en & !fifo_empty);
      fifo_empty <= (!fifo_wr_en & fifo_rd_en & fifo_empty) | (!fifo_wr_en & fifo_full);
    end
  end

  // FIFO data
  always @(posedge src_clk_i) begin
    if (fifo_wr_en)
      fifo_data <= data_i;
  end

  // Output data
  assign data_o = fifo_data;

  // Ready and valid signals
  assign src_ready_o = !fifo_full;
  assign dst_valid_o = !fifo_empty;

  // Clear requests and pending signals
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_req <= 0;
      src_clear_pending <= 0;
    end else begin
      src_clear_req <= src_clear_i;
      if (src_clear_req)
        src_clear_pending <= 1;
      else if (fifo_empty)
        src_clear_pending <= 0;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_req <= 0;
      dst_clear_pending <= 0;
    end else begin
      dst_clear_req <= dst_clear_i;
      if (dst_clear_req)
        dst_clear_pending <= 1;
      else if (fifo_empty)
        dst_clear_pending <= 0;
    end
  end

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule
