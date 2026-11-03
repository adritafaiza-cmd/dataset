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
  // Destination side: generate acknowledge, synchronize request

  // Source side state
  reg src_valid_reg;
  reg [WIDTH-1:0] src_data_reg;
  reg src_clear_pending_reg;
  reg src_ack_sync [SYNC_STAGES-1:0];
  reg src_req_reg;

  // Destination side state
  reg dst_valid_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_clear_pending_reg;
  reg dst_req_sync [SYNC_STAGES-1:0];
  reg dst_ack_reg;

  // Source clock domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_clear_pending_reg <= 1'b0;
      src_req_reg <= 1'b0;
      src_ack_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      // Synchronize acknowledge from destination
      src_ack_sync[0] <= dst_ack;
      for (int i = 1; i < SYNC_STAGES; i = i + 1)
        src_ack_sync[i] <= src_ack_sync[i-1];

      // Clear handling
      if (src_clear_i) begin
        src_clear_pending_reg <= 1'b1;
      end else if (src_clear_pending_reg && src_ack_sync[SYNC_STAGES-1]) begin
        // Clear acknowledged by destination, return to idle
        src_clear_pending_reg <= 1'b0;
        src_valid_reg <= 1'b0;
        src_req_reg <= 1'b0;
      end

      // Normal operation
      if (!src_clear_pending_reg) begin
        if (src_valid_i && !src_valid_reg) begin
          // New data available, capture it
          src_valid_reg <= 1'b1;
          src_data_reg <= src_data_i;
          src_req_reg <= 1'b1;
        end else if (src_valid_reg && src_ack_sync[SYNC_STAGES-1]) begin
          // Data accepted by destination
          src_valid_reg <= 1'b0;
          src_req_reg <= 1'b0;
        end
      end else begin
        // During clear pending, hold request high until acknowledged
        if (src_valid_reg)
          src_req_reg <= 1'b1;
        else
          src_req_reg <= 1'b0;
      end
    end
  end

  assign src_ready_o = !src_valid_reg && !src_clear_pending_reg;
  assign src_clear_pending_o = src_clear_pending_reg;
  assign src_req = src_req_reg;

  // Destination clock domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_clear_pending_reg <= 1'b0;
      dst_ack_reg <= 1'b0;
      dst_req_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      // Synchronize request from source
      dst_req_sync[0] <= src_req;
      for (int i = 1; i < SYNC_STAGES; i = i + 1)
        dst_req_sync[i] <= dst_req_sync[i-1];

      // Clear handling
      if (dst_clear_i) begin
        dst_clear_pending_reg <= 1'b1;
      end else if (dst_clear_pending_reg && !dst_req_sync[SYNC_STAGES-1]) begin
        // Clear acknowledged by source (request dropped), return to idle
        dst_clear_pending_reg <= 1'b0;
        dst_valid_reg <= 1'b0;
        dst_ack_reg <= 1'b0;
      end

      // Normal operation
      if (!dst_clear_pending_reg) begin
        if (dst_req_sync[SYNC_STAGES-1] && !dst_valid_reg) begin
          // New request from source, capture data
          dst_valid_reg <= 1'b1;
          dst_data_reg <= src_data_reg;
          dst_ack_reg <= 1'b1;
        end else if (dst_valid_reg && dst_ready_i) begin
          // Data accepted by receiver
          dst_valid_reg <= 1'b0;
          dst_ack_reg <= 1'b0;
        end
      end else begin
        // During clear pending, hold acknowledge high until request drops
        if (dst_valid_reg)
          dst_ack_reg <= 1'b1;
        else
          dst_ack_reg <= 1'b0;
      end
    end
  end

  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;
  assign dst_ack = dst_ack_reg;

endmodule
