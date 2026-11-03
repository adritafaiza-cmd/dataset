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

  // Source side signals
  logic src_valid_sync;
  logic src_clear_sync;
  logic src_clear_req;
  logic src_clear_ack;
  logic src_clear_done;
  logic src_clear_pending;
  logic src_ready;
  logic [WIDTH-1:0] src_data_reg;

  // Destination side signals
  logic dst_valid_sync;
  logic dst_clear_sync;
  logic dst_clear_req;
  logic dst_clear_ack;
  logic dst_clear_done;
  logic dst_clear_pending;
  logic dst_valid;
  logic [WIDTH-1:0] dst_data_reg;

  // Synchronization flops for clear signals
  logic [SYNC_STAGES-1:0] src_clear_sync_chain;
  logic [SYNC_STAGES-1:0] dst_clear_sync_chain;

  // Synchronization flops for valid signals
  logic [SYNC_STAGES-1:0] src_valid_sync_chain;
  logic [SYNC_STAGES-1:0] dst_valid_sync_chain;

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync_chain <= '0;
      src_clear_sync_chain <= '0;
      src_clear_req <= 0;
      src_clear_ack <= 0;
      src_clear_done <= 0;
      src_clear_pending <= 0;
      src_ready <= 0;
      src_data_reg <= '0;
    end else begin
      // Synchronize clear signal
      src_clear_sync_chain <= {src_clear_sync_chain[SYNC_STAGES-2:0], src_clear_i};
      src_clear_sync <= src_clear_sync_chain[SYNC_STAGES-1];

      // Synchronize valid signal
      src_valid_sync_chain <= {src_valid_sync_chain[SYNC_STAGES-2:0], src_valid_i};
      src_valid_sync <= src_valid_sync_chain[SYNC_STAGES-1];

      // Clear request and acknowledgment
      if (src_clear_sync && !src_clear_ack) begin
        src_clear_req <= 1;
      end else if (src_clear_ack) begin
        src_clear_req <= 0;
      end

      // Clear done
      if (src_clear_req && src_clear_ack) begin
        src_clear_done <= 1;
      end else if (src_clear_done && dst_clear_done) begin
        src_clear_done <= 0;
      end

      // Clear pending
      src_clear_pending <= src_clear_req || src_clear_ack || src_clear_done;

      // Ready signal
      src_ready <= !src_clear_pending && (!src_valid_sync || (src_valid_sync && dst_ready_i));

      // Data register
      if (src_valid_i && src_ready) begin
        src_data_reg <= src_data_i;
      end
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync_chain <= '0;
      dst_clear_sync_chain <= '0;
      dst_clear_req <= 0;
      dst_clear_ack <= 0;
      dst_clear_done <= 0;
      dst_clear_pending <= 0;
      dst_valid <= 0;
      dst_data_reg <= '0;
    end else begin
      // Synchronize clear signal
      dst_clear_sync_chain <= {dst_clear_sync_chain[SYNC_STAGES-2:0], dst_clear_i};
      dst_clear_sync <= dst_clear_sync_chain[SYNC_STAGES-1];

      // Synchronize valid signal
      dst_valid_sync_chain <= {dst_valid_sync_chain[SYNC_STAGES-2:0], src_valid_sync};
      dst_valid_sync <= dst_valid_sync_chain[SYNC_STAGES-1];

      // Clear request and acknowledgment
      if (dst_clear_sync && !dst_clear_ack) begin
        dst_clear_req <= 1;
      end else if (dst_clear_ack) begin
        dst_clear_req <= 0;
      end

      // Clear done
      if (dst_clear_req && dst_clear_ack) begin
        dst_clear_done <= 1;
      end else if (dst_clear_done && src_clear_done) begin
        dst_clear_done <= 0;
      end

      // Clear pending
      dst_clear_pending <= dst_clear_req || dst_clear_ack || dst_clear_done;

      // Valid signal
      dst_valid <= dst_valid_sync && !dst_clear_pending;

      // Data register
      if (dst_valid_sync && !dst_clear_pending) begin
        dst_data_reg <= src_data_reg;
      end

      // Acknowledge clear request
      if (dst_clear_req && !dst_clear_ack) begin
        dst_clear_ack <= 1;
      end else if (dst_clear_ack && src_clear_ack) begin
        dst_clear_ack <= 0;
      end
    end
  end

  // Output assignments
  assign src_clear_pending_o = src_clear_pending;
  assign src_ready_o = src_ready;
  assign dst_clear_pending_o = dst_clear_pending;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid;

endmodule
