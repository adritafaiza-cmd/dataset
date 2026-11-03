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
  wire src_req;
  wire src_ack;
  wire dst_req;
  wire dst_ack;

  // Source domain: request generation and acknowledge synchronization
  reg src_req_reg;
  reg [SYNC_STAGES-1:0] src_ack_sync;

  // Destination domain: acknowledge generation and request synchronization
  reg dst_ack_reg;
  reg [SYNC_STAGES-1:0] dst_req_sync;

  // Destination domain: data register and valid/ready logic
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;

  // Clear pending signals
  reg src_clear_pending_reg;
  reg dst_clear_pending_reg;

  // Source domain: clear logic
  // When src_clear_i is asserted, we need to:
  // 1. Stop accepting new data (src_ready_o = 0)
  // 2. If there's an outstanding request, wait for ack to complete, then deassert req
  // 3. Set src_clear_pending_o high until clear is complete

  // Destination domain: clear logic
  // When dst_clear_i is asserted, we need to:
  // 1. Stop presenting valid data (dst_valid_o = 0)
  // 2. If there's an outstanding request, wait for ack to complete, then deassert ack
  // 3. Set dst_clear_pending_o high until clear is complete

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_ack_sync <= {SYNC_STAGES{1'b0}};
      src_clear_pending_reg <= 1'b0;
    end else begin
      // Synchronize acknowledge from destination
      src_ack_sync <= {src_ack_sync[SYNC_STAGES-2:0], dst_ack};

      // Clear logic
      if (src_clear_i) begin
        src_clear_pending_reg <= 1'b1;
        // Deassert request to drop in-flight data
        src_req_reg <= 1'b0;
      end else begin
        // Normal operation
        if (src_valid_i && src_ready_o) begin
          // Accept new data, assert request
          src_req_reg <= 1'b1;
        end else if (src_ack_sync[SYNC_STAGES-1]) begin
          // Acknowledge received, deassert request
          src_req_reg <= 1'b0;
        end

        // Clear pending: clear when no outstanding request and not in clear
        if (src_clear_pending_reg && !src_req_reg && !src_clear_i) begin
          src_clear_pending_reg <= 1'b0;
        end
      end
    end
  end

  // Source ready: can accept if no outstanding request and not in clear
  assign src_ready_o = !src_req_reg && !src_clear_pending_reg;

  // Source clear pending output
  assign src_clear_pending_o = src_clear_pending_reg;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
      dst_req_sync <= {SYNC_STAGES{1'b0}};
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
    end else begin
      // Synchronize request from source
      dst_req_sync <= {dst_req_sync[SYNC_STAGES-2:0], src_req};

      // Clear logic
      if (dst_clear_i) begin
        dst_clear_pending_reg <= 1'b1;
        // Deassert acknowledge to drop in-flight data
        dst_ack_reg <= 1'b0;
        // Invalidate data
        dst_valid_reg <= 1'b0;
      end else begin
        // Normal operation
        if (dst_req_sync[SYNC_STAGES-1]) begin
          // Request received, capture data and assert acknowledge
          dst_data_reg <= src_data_i;
          dst_valid_reg <= 1'b1;
          dst_ack_reg <= 1'b1;
        end else if (dst_valid_reg && dst_ready_i) begin
          // Data accepted, deassert valid and acknowledge
          dst_valid_reg <= 1'b0;
          dst_ack_reg <= 1'b0;
        end

        // Clear pending: clear when no outstanding valid and not in clear
        if (dst_clear_pending_reg && !dst_valid_reg && !dst_clear_i) begin
          dst_clear_pending_reg <= 1'b0;
        end
      end
    end
  end

  // Destination valid output
  assign dst_valid_o = dst_valid_reg && !dst_clear_pending_reg;

  // Destination data output
  assign dst_data_o = dst_data_reg;

  // Destination clear pending output
  assign dst_clear_pending_o = dst_clear_pending_reg;

  // Cross-domain signals
  assign src_req = src_req_reg;
  assign src_ack = dst_ack_reg;
  assign dst_req = src_req_reg;
  assign dst_ack = dst_ack_reg;

endmodule
