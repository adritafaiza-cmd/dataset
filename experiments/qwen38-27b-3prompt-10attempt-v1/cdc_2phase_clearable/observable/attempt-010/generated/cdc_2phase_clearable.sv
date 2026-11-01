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
  reg src_req_reg;
  reg [WIDTH-1:0] src_data_reg;
  reg src_data_valid_reg;

  // Destination side state
  reg dst_ack_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_data_valid_reg;

  // Synchronization stages for src_ack (dst -> src)
  reg [SYNC_STAGES-1:0] src_ack_sync;

  // Synchronization stages for dst_req (src -> dst)
  reg [SYNC_STAGES-1:0] dst_req_sync;

  // Synchronization stages for src_clear (src -> dst)
  reg [SYNC_STAGES-1:0] src_clear_sync;

  // Synchronization stages for dst_clear (dst -> src)
  reg [SYNC_STAGES-1:0] dst_clear_sync;

  // Clear pending tracking
  reg src_clear_pending_reg;
  reg dst_clear_pending_reg;

  // Source clock domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_data_valid_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
      src_ack_sync <= {SYNC_STAGES{1'b0}};
      dst_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      // Synchronize dst_ack
      src_ack_sync <= {src_ack_sync[SYNC_STAGES-2:0], dst_ack_reg};

      // Synchronize dst_clear
      dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};

      // Clear handling
      if (src_clear_i) begin
        src_clear_pending_reg <= 1'b1;
        src_req_reg <= 1'b0;
        src_data_valid_reg <= 1'b0;
      end else if (src_clear_pending_reg) begin
        // Wait for dst_clear to propagate back
        if (dst_clear_sync[SYNC_STAGES-1]) begin
          src_clear_pending_reg <= 1'b0;
        end
      end

      // Handshake logic
      if (!src_clear_pending_reg) begin
        if (src_valid_i && src_ready_o) begin
          src_data_reg <= src_data_i;
          src_data_valid_reg <= 1'b1;
          src_req_reg <= 1'b1;
        end else if (src_req_reg && src_ack_sync[SYNC_STAGES-1]) begin
          src_req_reg <= 1'b0;
          src_data_valid_reg <= 1'b0;
        end
      end
    end
  end

  assign src_ready_o = !src_clear_pending_reg && (!src_req_reg || src_ack_sync[SYNC_STAGES-1]);
  assign src_clear_pending_o = src_clear_pending_reg;
  assign src_req = src_req_reg;

  // Destination clock domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_data_valid_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
      dst_req_sync <= {SYNC_STAGES{1'b0}};
      src_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      // Synchronize src_req
      dst_req_sync <= {dst_req_sync[SYNC_STAGES-2:0], src_req_reg};

      // Synchronize src_clear
      src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};

      // Clear handling
      if (dst_clear_i) begin
        dst_clear_pending_reg <= 1'b1;
        dst_ack_reg <= 1'b0;
        dst_data_valid_reg <= 1'b0;
      end else if (dst_clear_pending_reg) begin
        // Wait for src_clear to propagate back
        if (src_clear_sync[SYNC_STAGES-1]) begin
          dst_clear_pending_reg <= 1'b0;
        end
      end

      // Handshake logic
      if (!dst_clear_pending_reg) begin
        if (dst_req_sync[SYNC_STAGES-1] && !dst_ack_reg) begin
          dst_data_reg <= dst_req_sync[SYNC_STAGES-1] ? src_data_reg : dst_data_reg;
          dst_data_valid_reg <= 1'b1;
          dst_ack_reg <= 1'b1;
        end else if (dst_ack_reg && dst_ready_i) begin
          dst_ack_reg <= 1'b0;
          dst_data_valid_reg <= 1'b0;
        end
      end
    end
  end

  assign dst_valid_o = dst_data_valid_reg && !dst_clear_pending_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;
  assign dst_ack = dst_ack_reg;

endmodule
