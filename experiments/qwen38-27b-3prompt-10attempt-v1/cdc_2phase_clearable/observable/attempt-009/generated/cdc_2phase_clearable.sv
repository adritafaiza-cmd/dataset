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

  // Source side: generate request, synchronize acknowledge
  reg src_req_reg;
  wire [SYNC_STAGES-1:0] src_ack_sync;

  // Destination side: generate acknowledge, synchronize request
  reg dst_ack_reg;
  wire [SYNC_STAGES-1:0] dst_req_sync;

  // Data path: source holds data, destination captures on request edge
  reg [WIDTH-1:0] src_data_reg;
  reg [WIDTH-1:0] dst_data_reg;

  // Clear pending tracking
  reg src_clear_pending_reg;
  reg dst_clear_pending_reg;

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_clear_pending_reg <= 1'b0;
    end else begin
      // Handle clear
      if (src_clear_i) begin
        src_req_reg <= 1'b0;
        src_clear_pending_reg <= 1'b1;
      end else if (src_clear_pending_reg) begin
        // Wait for acknowledge to clear
        if (src_ack_sync[SYNC_STAGES-1] == 1'b0) begin
          src_clear_pending_reg <= 1'b0;
        end
      end else begin
        // Normal operation
        if (src_valid_i && !src_req_reg) begin
          src_req_reg <= 1'b1;
          src_data_reg <= src_data_i;
        end else if (src_req_reg && src_ack_sync[SYNC_STAGES-1]) begin
          src_req_reg <= 1'b0;
        end
      end
    end
  end

  // Source ready: can accept new data when not in request and not clearing
  assign src_ready_o = !src_req_reg && !src_clear_pending_reg;

  // Source clear pending output
  assign src_clear_pending_o = src_clear_pending_reg;

  // Synchronize source acknowledge to destination clock domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ack_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_ack_sync <= {src_ack_sync[SYNC_STAGES-2:0], src_ack_reg};
    end
  end

  // Destination side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_clear_pending_reg <= 1'b0;
    end else begin
      // Handle clear
      if (dst_clear_i) begin
        dst_ack_reg <= 1'b0;
        dst_clear_pending_reg <= 1'b1;
      end else if (dst_clear_pending_reg) begin
        // Wait for request to clear
        if (dst_req_sync[SYNC_STAGES-1] == 1'b0) begin
          dst_clear_pending_reg <= 1'b0;
        end
      end else begin
        // Normal operation
        if (dst_req_sync[SYNC_STAGES-1] && !dst_ack_reg) begin
          dst_ack_reg <= 1'b1;
          dst_data_reg <= dst_req_sync[SYNC_STAGES-1] ? dst_data_reg : dst_data_reg;
        end else if (!dst_req_sync[SYNC_STAGES-1] && dst_ack_reg) begin
          dst_ack_reg <= 1'b0;
        end
      end
    end
  end

  // Destination valid: data is valid when request is high and acknowledge is low
  assign dst_valid_o = dst_req_sync[SYNC_STAGES-1] && !dst_ack_reg;

  // Destination data output
  assign dst_data_o = dst_data_reg;

  // Destination clear pending output
  assign dst_clear_pending_o = dst_clear_pending_reg;

  // Synchronize destination request to source clock domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_req_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_req_sync <= {dst_req_sync[SYNC_STAGES-2:0], dst_req};
    end
  end

  // Destination request: generated when acknowledge is high
  assign dst_req = dst_ack_reg;

  // Source acknowledge: generated when request is high
  assign src_ack = src_req_reg;

endmodule
