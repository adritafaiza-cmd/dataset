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
  logic dst_valid;
  logic [WIDTH-1:0] dst_data;

  // Synchronization registers for clear signals
  logic [SYNC_STAGES-1:0] src_clear_sync_reg;
  logic [SYNC_STAGES-1:0] dst_clear_sync_reg;

  // Synchronization for valid signals
  logic [SYNC_STAGES-1:0] src_valid_sync_reg;
  logic [SYNC_STAGES-1:0] dst_valid_sync_reg;

  // Source domain logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_sync_reg <= '0;
      src_valid_sync_reg <= '0;
    end else begin
      src_clear_sync_reg <= {src_clear_sync_reg[SYNC_STAGES-2:0], src_clear_i};
      src_valid_sync_reg <= {src_valid_sync_reg[SYNC_STAGES-2:0], src_valid_i};
    end
  end

  assign src_valid_sync = src_valid_sync_reg[SYNC_STAGES-1];
  assign src_clear_sync = src_clear_sync_reg[SYNC_STAGES-1];

  // Clear request and acknowledgment
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_req <= 0;
      src_clear_ack <= 0;
      src_clear_done <= 0;
      src_clear_pending <= 0;
    end else begin
      if (src_clear_i && !src_clear_pending) begin
        src_clear_req <= 1;
        src_clear_pending <= 1;
      end else if (src_clear_ack) begin
        src_clear_req <= 0;
        src_clear_done <= 1;
      end else if (src_clear_done && !dst_clear_ack) begin
        src_clear_done <= 0;
        src_clear_pending <= 0;
      end
    end
  end

  assign src_clear_pending_o = src_clear_pending;

  // Ready signal
  assign src_ready = !src_clear_pending && (!dst_valid_sync || dst_ready_i);
  assign src_ready_o = src_ready;

  // Destination domain logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_sync_reg <= '0;
      dst_valid_sync_reg <= '0;
    end else begin
      dst_clear_sync_reg <= {dst_clear_sync_reg[SYNC_STAGES-2:0], dst_clear_i};
      dst_valid_sync_reg <= {dst_valid_sync_reg[SYNC_STAGES-2:0], src_valid_sync};
    end
  end

  assign dst_valid_sync = dst_valid_sync_reg[SYNC_STAGES-1];
  assign dst_clear_sync = dst_clear_sync_reg[SYNC_STAGES-1];

  // Clear request and acknowledgment
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_req <= 0;
      dst_clear_ack <= 0;
      dst_clear_done <= 0;
      dst_clear_pending <= 0;
    end else begin
      if (dst_clear_i && !dst_clear_pending) begin
        dst_clear_req <= 1;
        dst_clear_pending <= 1;
      end else if (dst_clear_ack) begin
        dst_clear_req <= 0;
        dst_clear_done <= 1;
      end else if (dst_clear_done && !src_clear_ack) begin
        dst_clear_done <= 0;
        dst_clear_pending <= 0;
      end
    end
  end

  assign dst_clear_pending_o = dst_clear_pending;

  // Valid and data signals
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid <= 0;
      dst_data <= '0;
    end else begin
      if (src_valid_sync && !dst_valid && !dst_clear_pending) begin
        dst_valid <= 1;
        dst_data <= src_data_i;
      end else if (dst_ready_i && dst_valid) begin
        dst_valid <= 0;
      end
    end
  end

  assign dst_valid_o = dst_valid;
  assign dst_data_o = dst_data;

  // Clear handshake
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_ack <= 0;
    end else begin
      if (dst_clear_req && !src_clear_ack) begin
        src_clear_ack <= 1;
      end else if (src_clear_done) begin
        src_clear_ack <= 0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_ack <= 0;
    end else begin
      if (src_clear_req && !dst_clear_ack) begin
        dst_clear_ack <= 1;
      end else if (dst_clear_done) begin
        dst_clear_ack <= 0;
      end
    end
  end

  // Asynchronous reset handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      if (CLEAR_ON_ASYNC_RESET) begin
        src_clear_req <= 0;
        src_clear_ack <= 0;
        src_clear_done <= 0;
        src_clear_pending <= 0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      if (CLEAR_ON_ASYNC_RESET) begin
        dst_clear_req <= 0;
        dst_clear_ack <= 0;
        dst_clear_done <= 0;
        dst_clear_pending <= 0;
      end
    end
  end

endmodule
