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
  logic src_valid_sync;
  logic dst_ready_sync;
  logic src_clear_req;
  logic dst_clear_req;
  logic src_clear_ack;
  logic dst_clear_ack;
  logic [WIDTH-1:0] data_sync;
  logic data_valid;

  // Synchronizers
  logic [SYNC_STAGES-1:0] src_valid_sync_reg;
  logic [SYNC_STAGES-1:0] dst_ready_sync_reg;

  // Source-side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_req <= 0;
      src_clear_ack <= 0;
      src_ready_o <= 0;
    end else begin
      // Handle clear request
      if (src_clear_i) begin
        src_clear_req <= 1;
      end else if (dst_clear_ack) begin
        src_clear_req <= 0;
        src_clear_ack <= 0;
      end

      // Handle valid/ready handshake
      if (src_valid_i && !data_valid && !src_clear_req) begin
        src_ready_o <= 1;
      end else if (dst_ready_sync && data_valid) begin
        src_ready_o <= 0;
      end
    end
  end

  // Destination-side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_req <= 0;
      dst_clear_ack <= 0;
      dst_valid_o <= 0;
      dst_data_o <= 0;
    end else begin
      // Handle clear request
      if (dst_clear_i) begin
        dst_clear_req <= 1;
      end else if (src_clear_ack) begin
        dst_clear_req <= 0;
        dst_clear_ack <= 0;
      end

      // Handle valid/ready handshake
      if (src_valid_sync && !data_valid && !dst_clear_req) begin
        data_valid <= 1;
        dst_data_o <= data_sync;
        dst_valid_o <= 1;
      end else if (dst_ready_i && data_valid) begin
        data_valid <= 0;
        dst_valid_o <= 0;
      end
    end
  end

  // Synchronize src_valid_i to dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync_reg <= 0;
    end else begin
      src_valid_sync_reg <= {src_valid_sync_reg[SYNC_STAGES-2:0], src_valid_i};
    end
  end
  assign src_valid_sync = src_valid_sync_reg[SYNC_STAGES-1];

  // Synchronize dst_ready_i to src_clk_i
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync_reg <= 0;
    end else begin
      dst_ready_sync_reg <= {dst_ready_sync_reg[SYNC_STAGES-2:0], dst_ready_i};
    end
  end
  assign dst_ready_sync = dst_ready_sync_reg[SYNC_STAGES-1];

  // Synchronize src_data_i to dst_clk_i with a pipeline stage
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data_sync <= 0;
    end else if (src_valid_i && !data_valid && !src_clear_req) begin
      data_sync <= src_data_i;
    end
  end

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_req || src_clear_ack;
  assign dst_clear_pending_o = dst_clear_req || dst_clear_ack;

  // Clear acknowledgment
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

endmodule
