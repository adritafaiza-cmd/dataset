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
  logic src_clear_synced;
  logic src_clear_req;
  logic src_clear_ack;
  logic src_clear_pending;
  logic src_valid_synced;
  logic src_valid_req;
  logic src_valid_ack;
  logic [WIDTH-1:0] src_data_synced;

  // Destination domain signals
  logic dst_clear_synced;
  logic dst_clear_req;
  logic dst_clear_ack;
  logic dst_clear_pending;
  logic dst_valid_synced;
  logic dst_valid_req;
  logic dst_valid_ack;
  logic [WIDTH-1:0] dst_data_synced;

  // Synchronization FIFO
  logic [WIDTH-1:0] sync_fifo [0:SYNC_STAGES-1];
  logic [SYNC_STAGES-1:0] sync_fifo_valid;

  // Source domain clear handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_synced <= 0;
      src_clear_req <= 0;
      src_clear_ack <= 0;
      src_clear_pending <= 0;
    end else begin
      src_clear_synced <= src_clear_i;
      if (src_clear_i) begin
        src_clear_req <= 1;
        src_clear_pending <= 1;
      end else if (src_clear_ack) begin
        src_clear_req <= 0;
        src_clear_pending <= 0;
      end
    end
  end

  // Destination domain clear handling
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_synced <= 0;
      dst_clear_req <= 0;
      dst_clear_ack <= 0;
      dst_clear_pending <= 0;
    end else begin
      dst_clear_synced <= dst_clear_i;
      if (dst_clear_i) begin
        dst_clear_req <= 1;
        dst_clear_pending <= 1;
      end else if (dst_clear_ack) begin
        dst_clear_req <= 0;
        dst_clear_pending <= 0;
      end
    end
  end

  // Source domain valid handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_synced <= 0;
      src_valid_req <= 0;
      src_valid_ack <= 0;
    end else begin
      src_valid_synced <= src_valid_i;
      if (src_valid_i && !src_clear_i) begin
        src_valid_req <= 1;
      end else if (src_valid_ack) begin
        src_valid_req <= 0;
      end
    end
  end

  // Synchronization FIFO handling
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_fifo_valid <= 0;
      sync_fifo <= '{default:0};
    end else begin
      if (src_valid_req && !src_clear_i) begin
        sync_fifo[0] <= src_data_i;
        sync_fifo_valid[0] <= 1;
      end
      for (int i = 0; i < SYNC_STAGES-1; i++) begin
        sync_fifo[i+1] <= sync_fifo[i];
        sync_fifo_valid[i+1] <= sync_fifo_valid[i];
      end
    end
  end

  // Destination domain valid handling
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_synced <= 0;
      dst_valid_req <= 0;
      dst_valid_ack <= 0;
    end else begin
      dst_valid_synced <= sync_fifo_valid[SYNC_STAGES-1];
      if (sync_fifo_valid[SYNC_STAGES-1] && !dst_clear_i) begin
        dst_valid_req <= 1;
      end else if (dst_valid_ack) begin
        dst_valid_req <= 0;
      end
    end
  end

  // Source domain ready and clear pending output
  assign src_ready_o = !src_valid_synced || src_clear_i;
  assign src_clear_pending_o = src_clear_pending;

  // Destination domain data and valid output
  assign dst_data_o = sync_fifo[SYNC_STAGES-1];
  assign dst_valid_o = dst_valid_synced && !dst_clear_i;
  assign dst_clear_pending_o = dst_clear_pending;

  // Clear handshake
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_ack <= 0;
    end else begin
      src_clear_ack <= dst_clear_req;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_ack <= 0;
    end else begin
      dst_clear_ack <= src_clear_req;
    end
  end

  // Valid handshake
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_ack <= 0;
    end else begin
      dst_valid_ack <= dst_ready_i && dst_valid_req;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_ack <= 0;
    end else begin
      src_valid_ack <= dst_valid_ack;
    end
  end

endmodule
