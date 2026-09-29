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
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_clear_req;
  reg src_clear_pending;

  // Synchronization of valid to destination
  reg [SYNC_STAGES-1:0] dst_valid_sync;

  // Synchronization of dst_ready to source
  reg [SYNC_STAGES-1:0] src_ready_sync;

  // Destination domain signals
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg dst_clear_req_sync1, dst_clear_req_sync2;
  reg dst_clear_ack;
  reg src_clear_req_sync1, src_clear_req_sync2;
  reg dst_clear_pending;

  // Assign outputs
  assign src_ready_o = !src_valid_reg || src_ready_sync[SYNC_STAGES-1];
  assign src_clear_pending_o = src_clear_pending;
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_clear_pending_o = dst_clear_pending;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      src_data_reg <= 0;
      src_clear_req <= 0;
      src_clear_pending <= 0;
      src_ready_sync <= 0;
    end else begin
      // Clear handling
      if (src_clear_i && !src_clear_pending) begin
        src_clear_req <= 1;
        src_clear_pending <= 1;
      end else if (src_clear_req && dst_clear_ack) begin
        src_clear_req <= 0;
        src_clear_pending <= 0;
      end

      // Data path
      if (src_clear_pending) begin
        src_valid_reg <= 0;
        src_data_reg <= 0;
      end else if (src_ready_o && src_valid_i) begin
        src_valid_reg <= 1;
        src_data_reg <= src_data_i;
      end else if (dst_valid_sync[SYNC_STAGES-1]) begin
        src_valid_reg <= 0;
      end

      // Synchronize dst_ready to source
      src_ready_sync <= {src_ready_sync[SYNC_STAGES-2:0], dst_ready_i};
    end
  end

  // Synchronize src_valid to destination
  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 0;
    end else begin
      dst_valid_sync <= {dst_valid_sync[SYNC_STAGES-2:0], src_valid_reg};
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
      dst_data_reg <= 0;
      dst_clear_req_sync1 <= 0;
      dst_clear_req_sync2 <= 0;
      dst_clear_ack <= 0;
      dst_clear_pending <= 0;
      src_clear_req_sync1 <= 0;
      src_clear_req_sync2 <= 0;
    end else begin
      // Synchronize clear request from source
      dst_clear_req_sync1 <= src_clear_req;
      dst_clear_req_sync2 <= dst_clear_req_sync1;

      // Clear handling
      if (dst_clear_req_sync2 && !dst_clear_pending) begin
        dst_clear_pending <= 1;
        dst_clear_ack <= 0;
      end else if (src_clear_req_sync2 && dst_clear_ack) begin
        dst_clear_pending <= 0;
        dst_clear_ack <= 1;
      end

      // Data path
      if (dst_clear_pending) begin
        dst_valid_reg <= 0;
        dst_data_reg <= 0;
      end else if (dst_valid_sync[SYNC_STAGES-1] && dst_ready_i) begin
        dst_valid_reg <= 1;
        dst_data_reg <= src_data_reg;
        dst_clear_ack <= 1;
      end else if (dst_clear_ack) begin
        dst_valid_reg <= 0;
        dst_clear_ack <= 0;
      end

      // Synchronize clear ack to source
      src_clear_req_sync1 <= dst_clear_ack;
      src_clear_req_sync2 <= src_clear_req_sync1;

      // Destination clear
      if (dst_clear_i && !dst_clear_pending) begin
        dst_clear_pending <= 1;
        dst_clear_ack <= 0;
      end else if (src_clear_req_sync2 && dst_clear_ack) begin
        dst_clear_pending <= 0;
        dst_clear_ack <= 1;
      end
    end
  end

endmodule
