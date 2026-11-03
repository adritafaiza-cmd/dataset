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
  logic src_clear_sync;
  logic src_clear_req;
  logic src_clear_ack;
  logic src_clear_pending;
  logic src_valid_sync;
  logic src_valid_req;
  logic src_valid_ack;
  logic [WIDTH-1:0] src_data_sync;

  // Destination domain signals
  logic dst_clear_sync;
  logic dst_clear_req;
  logic dst_clear_ack;
  logic dst_clear_pending;
  logic dst_valid_sync;
  logic dst_valid_req;
  logic dst_valid_ack;
  logic [WIDTH-1:0] dst_data_sync;

  // Synchronization stages for clear signal
  logic [SYNC_STAGES-1:0] src_clear_sync_stages;
  logic [SYNC_STAGES-1:0] dst_clear_sync_stages;

  // Synchronization stages for valid signal
  logic [SYNC_STAGES-1:0] src_valid_sync_stages;
  logic [SYNC_STAGES-1:0] dst_valid_sync_stages;

  // Source domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_sync_stages <= '0;
      src_clear_req <= 0;
      src_clear_ack <= 0;
      src_clear_pending <= 0;
      src_valid_sync_stages <= '0;
      src_valid_req <= 0;
      src_valid_ack <= 0;
      src_data_sync <= '0;
    end else begin
      // Synchronize clear signal
      src_clear_sync_stages <= {src_clear_sync_stages[SYNC_STAGES-2:0], src_clear_i};
      src_clear_sync <= src_clear_sync_stages[SYNC_STAGES-1];

      // Handle clear request and acknowledgment
      if (src_clear_sync && !src_clear_ack) begin
        src_clear_req <= 1;
        src_clear_pending <= 1;
      end else if (src_clear_ack) begin
        src_clear_req <= 0;
        src_clear_pending <= 0;
      end

      // Synchronize valid signal
      src_valid_sync_stages <= {src_valid_sync_stages[SYNC_STAGES-2:0], src_valid_i};
      src_valid_sync <= src_valid_sync_stages[SYNC_STAGES-1];

      // Handle valid request and acknowledgment
      if (src_valid_sync && !src_valid_ack && !src_clear_sync) begin
        src_valid_req <= 1;
        src_data_sync <= src_data_i;
      end else if (src_valid_ack) begin
        src_valid_req <= 0;
      end
    end
  end

  // Destination domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_sync_stages <= '0;
      dst_clear_req <= 0;
      dst_clear_ack <= 0;
      dst_clear_pending <= 0;
      dst_valid_sync_stages <= '0;
      dst_valid_req <= 0;
      dst_valid_ack <= 0;
      dst_data_o <= '0;
      dst_valid_o <= 0;
    end else begin
      // Synchronize clear signal
      dst_clear_sync_stages <= {dst_clear_sync_stages[SYNC_STAGES-2:0], dst_clear_i};
      dst_clear_sync <= dst_clear_sync_stages[SYNC_STAGES-1];

      // Handle clear request and acknowledgment
      if (dst_clear_sync && !dst_clear_ack) begin
        dst_clear_req <= 1;
        dst_clear_pending <= 1;
      end else if (dst_clear_ack) begin
        dst_clear_req <= 0;
        dst_clear_pending <= 0;
      end

      // Synchronize valid signal
      dst_valid_sync_stages <= {dst_valid_sync_stages[SYNC_STAGES-2:0], dst_valid_req};
      dst_valid_sync <= dst_valid_sync_stages[SYNC_STAGES-1];

      // Handle valid request and acknowledgment
      if (dst_valid_sync && !dst_valid_ack && !dst_clear_sync) begin
        dst_valid_o <= 1;
        dst_data_o <= dst_data_sync;
      end else if (dst_ready_i) begin
        dst_valid_o <= 0;
        dst_valid_ack <= 1;
      end else begin
        dst_valid_ack <= 0;
      end
    end
  end

  // Clear handshake
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_ack <= 0;
    end else begin
      if (dst_clear_req) begin
        src_clear_ack <= 1;
      end else if (src_clear_ack) begin
        src_clear_ack <= 0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_ack <= 0;
    end else begin
      if (src_clear_req) begin
        dst_clear_ack <= 1;
      end else if (dst_clear_ack) begin
        dst_clear_ack <= 0;
      end
    end
  end

  // Valid handshake
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_ack <= 0;
    end else begin
      if (dst_valid_ack) begin
        src_valid_ack <= 1;
      end else if (src_valid_ack) begin
        src_valid_ack <= 0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_req <= 0;
      dst_data_sync <= '0;
    end else begin
      if (src_valid_req && !dst_valid_req) begin
        dst_valid_req <= 1;
        dst_data_sync <= src_data_sync;
      end else if (dst_valid_ack) begin
        dst_valid_req <= 0;
      end
    end
  end

  // Outputs
  assign src_clear_pending_o = src_clear_pending;
  assign src_ready_o = !src_valid_req && !src_clear_sync;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule
