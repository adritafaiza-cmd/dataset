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

  wire dst_src_rst_ni;
  wire src_dst_rst_ni;
  wire dst_src_clear_i;
  wire src_dst_clear_i;

  wire [WIDTH-1:0] fifo_data_o;
  wire fifo_valid_o;
  wire fifo_ready_i;
  wire ack_data_i;
  wire ack_valid_i;
  wire ack_ready_o;
  wire ack_fifo_data_o;
  wire ack_fifo_valid_o;
  wire ack_fifo_ready_i;

  // Synchronize source reset to destination clock domain
  async_reset_synchronizer src_rst_sync (
    .rst_ni(src_rst_ni),
    .clk_i(dst_clk_i),
    .rst_no(dst_src_rst_ni)
  );

  // Synchronize destination reset to source clock domain
  async_reset_synchronizer dst_rst_sync (
    .rst_ni(dst_rst_ni),
    .clk_i(src_clk_i),
    .rst_no(src_dst_rst_ni)
  );

  // Synchronize source clear request to destination clock domain
  async_clear_synchronizer src_clear_sync (
    .clear_i(src_clear_i),
    .clk_i(dst_clk_i),
    .clear_o(dst_src_clear_i)
  );

  // Synchronize destination clear request to source clock domain
  async_clear_synchronizer dst_clear_sync (
    .clear_i(dst_clear_i),
    .clk_i(src_clk_i),
    .clear_o(src_dst_clear_i)
  );

  // FIFO for data transfer between asynchronous clock domains
  fifo #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) async_fifo (
    .rst_ni(src_dst_rst_ni),
    .clk_i(src_clk_i),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o),
    .data_o(fifo_data_o),
    .valid_o(fifo_valid_o),
    .ready_i(fifo_ready_i)
  );

  // FIFO for acknowledge signal transfer between asynchronous clock domains
  fifo #(
    .WIDTH(1),
    .SYNC_STAGES(SYNC_STAGES)
  ) ack_fifo (
    .rst_ni(dst_src_rst_ni),
    .clk_i(dst_clk_i),
    .data_i(ack_data_i),
    .valid_i(ack_valid_i),
    .ready_o(ack_ready_o),
    .data_o(ack_fifo_data_o),
    .valid_o(ack_fifo_valid_o),
    .ready_i(ack_fifo_ready_i)
  );

  // Connections
  assign fifo_ready_i = ack_fifo_valid_o;
  assign ack_data_i = fifo_valid_o;
  assign ack_valid_i = fifo_ready_i;
  assign dst_data_o = fifo_data_o;
  assign dst_valid_o = fifo_valid_o;
  assign fifo_ready_i = dst_ready_i;
  assign src_clear_pending_o = src_dst_clear_i;
  assign dst_clear_pending_o = dst_src_clear_i;

endmodule

module async_reset_synchronizer (
  input  rst_ni,
  input  clk_i,
  output rst_no
);

  reg [SYNC_STAGES-1:0] sync_reg;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_reg <= {(SYNC_STAGES){1'b1}};
    end else begin
      sync_reg <= {sync_reg[SYNC_STAGES-2:0], 1'b0};
    end
  end

  assign rst_no = sync_reg[SYNC_STAGES-1];

endmodule

module async_clear_synchronizer (
  input  clear_i,
  input  clk_i,
  output clear_o
);

  reg [SYNC_STAGES-1:0] sync_reg;

  always @(posedge clk_i) begin
    sync_reg <= {sync_reg[SYNC_STAGES-2:0], clear_i};
  end

  assign clear_o = sync_reg[SYNC_STAGES-1];

endmodule

module fifo #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  rst_ni,
  input  clk_i,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  ready_i
);

  reg [WIDTH-1:0] mem [0:2**SYNC_STAGES-2];
  reg [$clog2(2**SYNC_STAGES)-1:0] wr_ptr, rd_ptr;
  reg full, empty;

  // Write Pointer Logic
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr <= 0;
      full <= 0;
    end else if (valid_i && !full) begin
      mem[wr_ptr] <= data_i;
      wr_ptr <= wr_ptr + 1;
      if (wr_ptr == rd_ptr - 1) full <= 1;
    end else if (rd_ptr == wr_ptr + 1) full <= 0;
  end

  // Read Pointer Logic
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_ptr <= 0;
      empty <= 1;
    end else if (ready_i && !empty) begin
      rd_ptr <= rd_ptr + 1;
      if (rd_ptr == wr_ptr) empty <= 1;
    end else if (wr_ptr != rd_ptr) empty <= 0;
  end

  // Output Logic
  assign data_o = mem[rd_ptr];
  assign valid_o = !empty;
  assign ready_o = !full;

endmodule
