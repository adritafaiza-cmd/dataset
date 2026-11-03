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
  wire dst_ack;
  wire dst_req;
  wire src_ack;

  // Source side: generate request
  reg src_req_reg;
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_clear_pending_reg;

  // Destination side: generate acknowledge
  reg dst_ack_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg dst_clear_pending_reg;

  // Destination side: generate request (for clear propagation)
  reg dst_req_reg;

  // Source side: generate acknowledge (for clear propagation)
  reg src_ack_reg;

  // Synchronizers
  wire [SYNC_STAGES-1:0] src_req_sync;
  wire [SYNC_STAGES-1:0] dst_ack_sync;
  wire [SYNC_STAGES-1:0] dst_req_sync;
  wire [SYNC_STAGES-1:0] src_ack_sync;

  // Synchronize src_req to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_req_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_req_sync <= {src_req_sync[SYNC_STAGES-2:0], src_req};
    end
  end

  // Synchronize dst_ack to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ack_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_ack_sync <= {dst_ack_sync[SYNC_STAGES-2:0], dst_ack};
    end
  end

  // Synchronize dst_req to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_req_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_req_sync <= {dst_req_sync[SYNC_STAGES-2:0], dst_req};
    end
  end

  // Synchronize src_ack to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ack_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_ack_sync <= {src_ack_sync[SYNC_STAGES-2:0], src_ack};
    end
  end

  // Source domain logic
  // src_req is high when we have data to send and haven't been acknowledged yet
  // src_ack is high when we've acknowledged a clear from destination

  // Clear pending: set when clear is requested, cleared when both sides have acknowledged
  // The clear protocol: 
  // 1. Source sees src_clear_i, sets src_clear_pending, drops src_req
  // 2. Destination sees src_req drop (via sync), sets dst_clear_pending, drops dst_ack
  // 3. Source sees dst_ack drop (via sync), clears src_clear_pending
  // 4. Destination sees src_req stable low, clears dst_clear_pending

  // Actually, let's think about this more carefully.
  // The clear request isolates both ends, then drops the one outstanding beat.
  // "Each clear step reaches the other clock one handshake later."

  // Let me redesign:
  // Normal operation:
  // - src_valid_i && src_ready_o -> transfer, src_req goes high
  // - dst_ack goes high when dst receives and is ready
  // - src_req goes low when dst_ack is seen

  // Clear operation:
  // - src_clear_i: source drops src_req, sets src_clear_pending
  // - dst sees src_req drop: sets dst_clear_pending, drops dst_ack
  // - src sees dst_ack drop: clears src_clear_pending
  // - dst sees src_req stable: clears dst_clear_pending

  // Let's implement this step by step.

  // Source: src_req management
  // src_req is set when valid data is accepted, cleared when dst_ack is seen
  // During clear, src_req is forced low

  wire src_clear_active = src_clear_i || src_clear_pending_reg;
  wire dst_ack_synced = dst_ack_sync[SYNC_STAGES-1];
  wire src_req_synced = src_req_sync[SYNC_STAGES-1];
  wire dst_req_synced = dst_req_sync[SYNC_STAGES-1];
  wire src_ack_synced = src_ack_sync[SYNC_STAGES-1];

  // Source request generation
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
      src_ack_reg <= 1'b0;
    end else begin
      // Handle clear
      if (src_clear_i) begin
        src_clear_pending_reg <= 1'b1;
        src_req_reg <= 1'b0;
        src_valid_reg <= 1'b0;
      end else if (src_clear_pending_reg) begin
        // Wait for dst_ack to drop
        if (!dst_ack_synced) begin
          src_clear_pending_reg <= 1'b0;
        end
      end

      // Normal operation
      if (!src_clear_active) begin
        if (src_valid_i && src_ready_o) begin
          src_req_reg <= 1'b1;
          src_data_reg <= src_data_i;
          src_valid_reg <= 1'b1;
        end else if (dst_ack_synced) begin
          src_req_reg <= 1'b0;
          src_valid_reg <= 1'b0;
        end
      end

      // src_ack: acknowledge clear from destination
      // When dst_req is high (destination is requesting clear), we acknowledge
      if (dst_req_synced) begin
        src_ack_reg <= 1'b1;
      end else begin
        src_ack_reg <= 1'b0;
      end
    end
  end

  assign src_req = src_req_reg;
  assign src_ack = src_ack_reg;
  assign src_clear_pending_o = src_clear_pending_reg;

  // Source ready: ready when not in clear and not already have outstanding request
  assign src_ready_o = !src_clear_active && !src_req_reg;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
      dst_req_reg <= 1'b0;
    end else begin
      // Handle clear
      if (dst_clear_i) begin
        dst_clear_pending_reg <= 1'b1;
        dst_ack_reg <= 1'b0;
        dst_valid_reg <= 1'b0;
      end else if (dst_clear_pending_reg) begin
        // Wait for src_ack to be seen
        if (src_ack_synced) begin
          dst_clear_pending_reg <= 1'b0;
        end
      end

      // Normal operation
      if (!dst_clear_pending_reg) begin
        if (src_req_synced) begin
          dst_ack_reg <= 1'b1;
          dst_data_reg <= src_req_synced ? dst_data_reg : dst_data_reg; // Data is already in src_data_reg, but we need to capture it
          dst_valid_reg <= 1'b1;
        end else if (dst_valid_reg && dst_ready_i) begin
          dst_ack_reg <= 1'b0;
          dst_valid_reg <= 1'b0;
        end
      end

      // dst_req: request clear from source
      if (dst_clear_i || dst_clear_pending_reg) begin
        dst_req_reg <= 1'b1;
      end else begin
        dst_req_reg <= 1'b0;
      end
    end
  end

  assign dst_ack = dst_ack_reg;
  assign dst_req = dst_req_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

endmodule
