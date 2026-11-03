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

  // Source domain signals
  logic src_valid_sync;
  logic src_clear_sync;
  logic src_clear_req;
  logic src_clear_ack;
  logic src_clear_done;
  logic src_clear_pending;
  logic src_ready;

  // Destination domain signals
  logic dst_valid_sync;
  logic dst_clear_sync;
  logic dst_clear_req;
  logic dst_clear_ack;
  logic dst_clear_done;
  logic dst_clear_pending;
  logic dst_ready;

  // Synchronization FIFO
  logic [WIDTH-1:0] fifo_data;
  logic fifo_valid;
  logic fifo_ready;

  // Synchronization stages for clear signals
  logic [SYNC_STAGES-1:0] src_clear_sync_chain;
  logic [SYNC_STAGES-1:0] dst_clear_sync_chain;

  // Source domain logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_sync_chain <= '0;
      src_clear_req <= 0;
      src_clear_ack <= 0;
      src_clear_done <= 0;
      src_clear_pending <= 0;
    end else begin
      src_clear_sync_chain <= {src_clear_sync_chain[SYNC_STAGES-2:0], src_clear_i};
      src_clear_sync <= src_clear_sync_chain[SYNC_STAGES-1];

      if (src_clear_sync && !src_clear_done) begin
        src_clear_req <= 1;
      end

      if (src_clear_ack) begin
        src_clear_req <= 0;
        src_clear_done <= 1;
      end

      if (src_clear_done && !src_clear_sync) begin
        src_clear_done <= 0;
        src_clear_pending <= 0;
      end

      if (src_clear_sync && !src_clear_pending) begin
        src_clear_pending <= 1;
      end
    end
  end

  // Destination domain logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_sync_chain <= '0;
      dst_clear_req <= 0;
      dst_clear_ack <= 0;
      dst_clear_done <= 0;
      dst_clear_pending <= 0;
    end else begin
      dst_clear_sync_chain <= {dst_clear_sync_chain[SYNC_STAGES-2:0], dst_clear_i};
      dst_clear_sync <= dst_clear_sync_chain[SYNC_STAGES-1];

      if (dst_clear_sync && !dst_clear_done) begin
        dst_clear_req <= 1;
      end

      if (dst_clear_ack) begin
        dst_clear_req <= 0;
        dst_clear_done <= 1;
      end

      if (dst_clear_done && !dst_clear_sync) begin
        dst_clear_done <= 0;
        dst_clear_pending <= 0;
      end

      if (dst_clear_sync && !dst_clear_pending) begin
        dst_clear_pending <= 1;
      end
    end
  end

  // Two-phase handshake for clear
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_ack <= 0;
    end else if (dst_clear_req) begin
      src_clear_ack <= 1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_ack <= 0;
    end else if (src_clear_req) begin
      dst_clear_ack <= 1;
    end
  end

  // FIFO for data transfer
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      fifo_data <= '0;
      fifo_valid <= 0;
    end else if (src_valid_i && fifo_ready) begin
      fifo_data <= src_data_i;
      fifo_valid <= 1;
    end else if (fifo_ready) begin
      fifo_valid <= 0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      fifo_ready <= 0;
    end else if (fifo_valid && dst_ready_i) begin
      fifo_ready <= 1;
    end else begin
      fifo_ready <= 0;
    end
  end

  // Ready and valid signals
  assign src_ready = fifo_ready && !src_clear_sync;
  assign dst_valid_o = fifo_valid && !dst_clear_sync;
  assign dst_data_o = fifo_data;

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule
