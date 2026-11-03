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
  wire src_rst_sync_o;
  wire dst_rst_sync_o;
  wire src_clear_req;
  wire src_clear_ack;
  wire dst_clear_req;
  wire dst_clear_ack;

  // Synchronize source reset to destination clock domain
  async_reset_sync src_rst_sync (
    .async_rst_i (src_rst_ni),
    .clk_i       (dst_clk_i),
    .sync_rst_o  (src_rst_sync_o)
  );

  // Synchronize destination reset to source clock domain
  async_reset_sync dst_rst_sync (
    .async_rst_i (dst_rst_ni),
    .clk_i       (src_clk_i),
    .sync_rst_o  (dst_rst_sync_o)
  );

  // FIFO for asynchronous data transfer
  fifo_async #(
    .WIDTH       (WIDTH),
    .SYNC_STAGES (SYNC_STAGES)
  ) async_fifo (
    .wr_clk_i  (src_clk_i),
    .wr_rst_ni (src_rst_sync_o),
    .wr_data_i (src_data_i),
    .wr_en_i   (src_valid_i),
    .full_o    (src_ready_o),
    .rd_clk_i  (dst_clk_i),
    .rd_rst_ni (dst_rst_sync_o),
    .rd_data_o (dst_data_o),
    .empty_o   (dst_valid_o),
    .rd_en_i   (dst_ready_i),
    .clear_req_i (src_clear_req),
    .clear_ack_o (src_clear_ack)
  );

  // Clearable control logic
  clearable_control clearable_ctrl (
    .src_clk_i          (src_clk_i),
    .src_rst_ni         (src_rst_ni),
    .src_clear_i        (src_clear_i),
    .src_clear_pending_o(src_clear_pending_o),
    .dst_clk_i          (dst_clk_i),
    .dst_rst_ni         (dst_rst_ni),
    .dst_clear_i        (dst_clear_i),
    .dst_clear_pending_o(dst_clear_pending_o),
    .src_clear_req      (src_clear_req),
    .src_clear_ack      (src_clear_ack),
    .dst_clear_req      (dst_clear_req),
    .dst_clear_ack      (dst_clear_ack)
  );

endmodule

// Synchronizes an asynchronous reset signal to another clock domain
module async_reset_sync (
  input  async_rst_i,
  input  clk_i,
  output sync_rst_o
);

  logic [SYNC_STAGES:0] sync_chain;

  always_ff @(posedge clk_i or negedge async_rst_i) begin
    if (!async_rst_i) begin
      sync_chain <= '1;
    end else begin
      sync_chain <= {sync_chain[SYNC_STAGES-1:0], 1'b0};
    end
  end

  assign sync_rst_o = sync_chain[SYNC_STAGES];

endmodule

// Provides a FIFO buffer for asynchronous data transfer
module fifo_async #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  wr_clk_i,
  input  wr_rst_ni,
  input  [WIDTH-1:0] wr_data_i,
  input  wr_en_i,
  output full_o,
  input  rd_clk_i,
  input  rd_rst_ni,
  output [WIDTH-1:0] rd_data_o,
  output empty_o,
  input  rd_en_i,
  input  clear_req_i,
  output clear_ack_o
);

  logic [WIDTH-1:0] data_reg;
  logic wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray;
  logic wr_ptr_gray_synced;
  logic [1:0] empty_flags;
  logic clear_req_gray, clear_req_gray_synced, clear_ack_gray;

  // Gray code pointers for full/empty flag generation
  always_ff @(posedge wr_clk_i or negedge wr_rst_ni) begin
    if (!wr_rst_ni) begin
      wr_ptr <= '0;
    end else if (wr_en_i && !full_o) begin
      wr_ptr <= wr_ptr + 1;
      data_reg <= wr_data_i;
    end
  end

  assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);

  // Synchronize write pointer gray code to read clock domain
  async_reset_sync wr_ptr_gray_sync (
    .async_rst_i (wr_ptr_gray),
    .clk_i       (rd_clk_i),
    .sync_rst_o  (wr_ptr_gray_synced)
  );

  // Read pointer logic
  always_ff @(posedge rd_clk_i or negedge rd_rst_ni) begin
    if (!rd_rst_ni) begin
      rd_ptr <= '0;
    end else if (rd_en_i && !empty_o) begin
      rd_ptr <= rd_ptr + 1;
    end
  end

  assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

  // Gray code to binary conversion for full flag
  assign full_o = &wr_ptr_gray_synced ^ wr_ptr_gray_synced[0] ^ wr_ptr_gray[0];

  // Gray code to binary conversion for empty flag
  assign empty_flags[0] = &rd_ptr_gray ^ rd_ptr_gray[0] ^ wr_ptr_gray_synced[0];
  assign empty_flags[1] = &rd_ptr_gray ^ rd_ptr_gray[1] ^ wr_ptr_gray_synced[1];
  assign empty_o = empty_flags[0] & empty_flags[1];

  // Output data register
  always_ff @(posedge rd_clk_i or negedge rd_rst_ni) begin
    if (!rd_rst_ni) begin
      rd_data_o <= '0;
    end else if (rd_en_i && !empty_o) begin
      rd_data_o <= data_reg;
    end
  end

  // Clear request gray code
  always_ff @(posedge wr_clk_i or negedge wr_rst_ni) begin
    if (!wr_rst_ni) begin
      clear_req_gray <= 1'b0;
    end else if (clear_req_i) begin
      clear_req_gray <= ~clear_req_gray;
    end
  end

  // Synchronize clear request gray code to read clock domain
  async_reset_sync clear_req_gray_sync (
    .async_rst_i (clear_req_gray),
    .clk_i       (rd_clk_i),
    .sync_rst_o  (clear_req_gray_synced)
  );

  // Clear acknowledge gray code
  always_ff @(posedge rd_clk_i or negedge rd_rst_ni) begin
    if (!rd_rst_ni) begin
      clear_ack_gray <= 1'b0;
    end else if (clear_req_gray_synced) begin
      clear_ack_gray <= ~clear_ack_gray;
    end
  end

  // Clear acknowledge output
  always_ff @(posedge wr_clk_i or negedge wr_rst_ni) begin
    if (!wr_rst_ni) begin
      clear_ack_o <= 1'b0;
    end else begin
      clear_ack_o <= clear_ack_gray;
    end
  end

endmodule

// Handles clear requests and pending status
module clearable_control (
  input  src_clk_i,
  input  src_rst_ni,
  input  src_clear_i,
  output src_clear_pending_o,
  input  dst_clk_i,
  input  dst_rst_ni,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output src_clear_req,
  input  src_clear_ack,
  output dst_clear_req,
  input  dst_clear_ack
);

  logic src_clear_pending, dst_clear_pending;

  // Source clear control
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 1'b0;
      src_clear_req <= 1'b0;
    end else begin
      if (src_clear_i && !src_clear_pending) begin
        src_clear_pending <= 1'b1;
        src_clear_req <= 1'b1;
      end else if (src_clear_ack) begin
        src_clear_pending <= 1'b0;
        src_clear_req <= 1'b0;
      end
    end
  end

  assign src_clear_pending_o = src_clear_pending;

  // Destination clear control
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 1'b0;
      dst_clear_req <= 1'b0;
    end else begin
      if (dst_clear_i && !dst_clear_pending) begin
        dst_clear_pending <= 1'b1;
        dst_clear_req <= 1'b1;
      end else if (dst_clear_ack) begin
        dst_clear_pending <= 1'b0;
        dst_clear_req <= 1'b0;
      end
    end
  end

  assign dst_clear_pending_o = dst_clear_pending;

endmodule
