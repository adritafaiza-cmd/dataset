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

  // Destination side: generate request
  reg dst_req_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;

  // Clear pending signals
  reg src_clear_pending_reg;
  reg dst_clear_pending_reg;

  // Synchronizers for request/ack signals
  // src_req -> dst domain
  reg [SYNC_STAGES-1:0] src_req_sync;
  // dst_ack -> src domain
  reg [SYNC_STAGES-1:0] dst_ack_sync;
  // dst_req -> src domain
  reg [SYNC_STAGES-1:0] dst_req_sync;
  // src_ack -> dst domain
  reg [SYNC_STAGES-1:0] src_ack_sync;

  // Clear signals need synchronization too
  // src_clear -> dst domain
  reg [SYNC_STAGES-1:0] src_clear_sync;
  // dst_clear -> src domain
  reg [SYNC_STAGES-1:0] dst_clear_sync;

  // Synchronizer for src_req to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_req_sync <= {SYNC_STAGES{1'b0}};
    else
      src_req_sync <= {src_req_sync[SYNC_STAGES-2:0], src_req};
  end

  // Synchronizer for dst_ack to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_ack_sync <= {SYNC_STAGES{1'b0}};
    else
      dst_ack_sync <= {dst_ack_sync[SYNC_STAGES-2:0], dst_ack};
  end

  // Synchronizer for dst_req to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_req_sync <= {SYNC_STAGES{1'b0}};
    else
      dst_req_sync <= {dst_req_sync[SYNC_STAGES-2:0], dst_req};
  end

  // Synchronizer for src_ack to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_ack_sync <= {SYNC_STAGES{1'b0}};
    else
      src_ack_sync <= {src_ack_sync[SYNC_STAGES-2:0], src_ack};
  end

  // Synchronizer for src_clear to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_clear_sync <= {SYNC_STAGES{1'b0}};
    else
      src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
  end

  // Synchronizer for dst_clear to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_clear_sync <= {SYNC_STAGES{1'b0}};
    else
      dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
  end

  // Synchronized versions
  wire src_req_synced = src_req_sync[SYNC_STAGES-1];
  wire dst_ack_synced = dst_ack_sync[SYNC_STAGES-1];
  wire dst_req_synced = dst_req_sync[SYNC_STAGES-1];
  wire src_ack_synced = src_ack_sync[SYNC_STAGES-1];
  wire src_clear_synced = src_clear_sync[SYNC_STAGES-1];
  wire dst_clear_synced = dst_clear_sync[SYNC_STAGES-1];

  // Source side logic
  // src_ready is high when we can accept new data
  // We can accept when: not in clear pending, and (no outstanding request or request was acknowledged)
  // In a 2-phase handshake, we toggle req. But let's use a simpler approach:
  // src_req is asserted when we have data to send and dst_ack is low (or we're starting)
  
  // Let's use a state machine approach for clarity
  // States: IDLE, WAIT_ACK
  // In IDLE: if src_valid_i and not clear, capture data, assert src_req, go to WAIT_ACK
  // In WAIT_ACK: if dst_ack_synced, deassert src_req, go to IDLE
  
  // But we also need to handle clear. Clear should flush the channel.
  
  // Let me reconsider. The problem says "two-phase valid/ready channel". This is a standard CDC handshake.
  // Let's use the standard 2-phase handshake where req and ack are toggled.
  
  // Actually, let's use a simpler approach with explicit states.
  
  // Source state: 0 = IDLE, 1 = WAIT_ACK
  reg src_state;
  
  // Destination state: 0 = IDLE, 1 = WAIT_ACK  
  reg dst_state;

  // Source side
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_state <= 1'b0;
      src_clear_pending_reg <= 1'b0;
    end else begin
      if (src_clear_i) begin
        // Clear: deassert request, clear pending
        src_req_reg <= 1'b0;
        src_valid_reg <= 1'b0;
        src_state <= 1'b0;
        src_clear_pending_reg <= 1'b1;
      end else if (src_clear_pending_reg) begin
        // Wait for clear to propagate to other side
        // Clear is done when dst_ack_synced goes low (or we detect the clear has been acknowledged)
        // Actually, clear should complete when the other side has also cleared
        // Let's say clear pending clears when dst_ack_synced is 0 and we've deasserted req
        if (!dst_ack_synced) begin
          src_clear_pending_reg <= 1'b0;
        end
      end else begin
        case (src_state)
          1'b0: begin
            // IDLE
            if (src_valid_i) begin
              src_data_reg <= src_data_i;
              src_valid_reg <= 1'b1;
              src_req_reg <= 1'b1;
              src_state <= 1'b1;
            end
          end
          1'b1: begin
            // WAIT_ACK
            if (dst_ack_synced) begin
              src_req_reg <= 1'b0;
              src_valid_reg <= 1'b0;
              src_state <= 1'b0;
            end
          end
          default: src_state <= 1'b0;
        endcase
      end
    end
  end

  // Destination side
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_state <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        // Clear: deassert request, clear pending
        dst_req_reg <= 1'b0;
        dst_valid_reg <= 1'b0;
        dst_state <= 1'b0;
        dst_clear_pending_reg <= 1'b1;
      end else if (dst_clear_pending_reg) begin
        // Wait for clear to propagate to other side
        if (!src_ack_synced) begin
          dst_clear_pending_reg <= 1'b0;
        end
      end else begin
        case (dst_state)
          1'b0: begin
            // IDLE
            if (src_req_synced) begin
              dst_data_reg <= src_req_synced ? src_data_reg : dst_data_reg; // This is wrong, we need to get data from source
              dst_valid_reg <= 1'b1;
              dst_req_reg <= 1'b1;
              dst_state <= 1'b1;
            end
          end
          1'b1: begin
            // WAIT_ACK
            if (src_ack_synced) begin
              dst_req_reg <= 1'b0;
              dst_valid_reg <= 1'b0;
              dst_state <= 1'b0;
            end
          end
          default: dst_state <= 1'b0;
        endcase
      end
    end
  end

  // This approach has issues with data transfer. Let me reconsider.
  
  // The data needs to be transferred from source to destination. In a CDC handshake,
  // the data is typically held stable while the handshake is in progress.
  
  // Let me use a different approach:
  // Source holds data in src_data_reg when src_valid_i is high and src_ready_o is high.
  // The data is then synchronized to the destination side.
  
  // Actually, for a 2-phase handshake, the data should be stable when req is asserted.
  // So the source should hold the data until the handshake completes.
  
  // Let me redo this more carefully.
  
  // Source side:
  // - When in IDLE and src_valid_i is high, capture src_data_i into src_data_reg, assert src_req, go to WAIT_ACK
  // - When in WAIT_ACK and dst_ack_synced is high, deassert src_req, go to IDLE
  // - src_ready_o is high when in IDLE and not in clear pending
  
  // Destination side:
  // - When in IDLE and src_req_synced is high, the data is available. We need to get the data.
  //   But the data is in src_data_reg on the source side. We need to synchronize it.
  //   Actually, in a proper CDC handshake, the data is held stable on the source side
  //   while the handshake is in progress, and the destination samples it when it sees req.
  //   But since the data is multi-bit, we need to ensure it's stable.
  //   
  //   One approach: the source holds the data in src_data_reg, and we synchronize the data
  //   to the destination side. But this requires the data to be stable during the handshake.
  //   
  //   Actually, the standard approach is:
  //   - Source asserts req and holds data stable
  //   - Destination sees req (synchronized), samples data (which should be stable), asserts ack
  //   - Source sees ack (synchronized), deasserts req
  //   - Destination sees req deasserted (synchronized), deasserts ack
  //   
  //   But the data sampling on the destination side is tricky because the data is in the source domain.
  //   We need to synchronize the data as well, or use a different approach.
  
  // Let me use a simpler approach where we synchronize the data along with the handshake.
  
  // Actually, I think the cleanest approach is:
  // 1. Source holds data in src_data_reg
  // 2. We synchronize src_data_reg to dst domain using a multi-bit synchronizer (or just use the fact that data is stable)
  // 3. Destination samples the synchronized data when it sees req
  
  // But multi-bit synchronizers are tricky. Let me use a different approach:
  // The data is held stable on the source side while req is asserted. The destination
  // can sample the data when it sees the synchronized req. Since the data is stable,
  // we can just use a simple register to capture the data on the destination side.
  
  // Wait, but the data is in the source clock domain. We can't directly read it in the destination domain.
  // We need to synchronize it.
  
  // Let me use a data synchronizer. Since the data is stable while req is asserted,
  // we can synchronize the data using a simple multi-stage synchronizer, but we need to
  // ensure we only sample when req is stable.
  
  // Actually, the standard approach for CDC with data is:
  // - Use a handshake to ensure the data is stable
  // - Synchronize the data using a multi-bit synchronizer or a gray code approach
  // - Or, use a "data valid" signal to indicate when the data is stable
  
  // For simplicity, let's assume the data is stable while req is asserted, and we synchronize
  // the data using a simple register chain. The destination samples the data when it sees req.
  
  // Let me implement this properly.
  
  // Source side data register
  reg [WIDTH-1:0] src_data_hold;
  
  // Synchronize data to destination
  reg [WIDTH-1:0] dst_data_sync;
  
  // Data synchronizer
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_data_sync <= {WIDTH{1'b0}};
    else
      dst_data_sync <= src_data_hold;
  end

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_data_hold <= {WIDTH{1'b0}};
      src_state <= 1'b0;
      src_clear_pending_reg <= 1'b0;
    end else begin
      if (src_clear_i) begin
        src_req_reg <= 1'b0;
        src_state <= 1'b0;
        src_clear_pending_reg <= 1'b1;
      end else if (src_clear_pending_reg) begin
        if (!dst_ack_synced) begin
          src_clear_pending_reg <= 1'b0;
        end
      end else begin
        case (src_state)
          1'b0: begin
            if (src_valid_i) begin
              src_data_hold <= src_data_i;
              src_req_reg <= 1'b1;
              src_state <= 1'b1;
            end
          end
          1'b1: begin
            if (dst_ack_synced) begin
              src_req_reg <= 1'b0;
              src_state <= 1'b0;
            end
          end
          default: src_state <= 1'b0;
        endcase
      end
    end
  end

  // Destination side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_state <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        dst_req_reg <= 1'b0;
        dst_valid_reg <= 1'b0;
        dst_state <= 1'b0;
        dst_clear_pending_reg <= 1'b1;
      end else if (dst_clear_pending_reg) begin
        if (!src_ack_synced) begin
          dst_clear_pending_reg <= 1'b0;
        end
      end else begin
        case (dst_state)
          1'b0: begin
            if (src_req_synced) begin
              dst_data_reg <= dst_data_sync;
              dst_valid_reg <= 1'b1;
              dst_req_reg <= 1'b1;
              dst_state <= 1'b1;
            end
          end
          1'b1: begin
            if (src_ack_synced) begin
              dst_req_reg <= 1'b0;
              dst_valid_reg <= 1'b0;
              dst_state <= 1'b0;
            end
          end
          default: dst_state <= 1'b0;
        endcase
      end
    end
  end

  // Assign outputs
  assign src_req = src_req_reg;
  assign dst_ack = dst_req_reg;
  assign dst_req = dst_req_reg;
  assign src_ack = src_req_reg;

  // Wait, I'm confusing myself. Let me clarify the handshake signals.
  // In a 2-phase handshake:
  // - Source asserts req to indicate it has data
  // - Destination asserts ack to indicate it has received the data
  // - Source deasserts req when it sees ack
  // - Destination deasserts ack when it sees req deasserted
  
  // So:
  // src_req is the request from source to destination
  // dst_ack is the acknowledge from destination to source
  
  // But I also have dst_req and src_ack for the reverse direction? No, this is a unidirectional channel.
  // The data flows from source to destination. So we only need one handshake:
  // - src_req: source to destination
  // - dst_ack: destination to source
  
  // Let me fix this.

  // Actually, looking at the interface again, there's no reverse data path. So we only need:
  // - src_req: source asserts to indicate data is available
  // - dst_ack: destination asserts to indicate data has been received
  
  // Let me redo the logic with this understanding.

  // Source side
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_data_hold <= {WIDTH{1'b0}};
      src_state <= 1'b0;
      src_clear_pending_reg <= 1'b0;
    end else begin
      if (src_clear_i) begin
        src_req_reg <= 1'b0;
        src_state <= 1'b0;
        src_clear_pending_reg <= 1'b1;
      end else if (src_clear_pending_reg) begin
        if (!dst_ack_synced) begin
          src_clear_pending_reg <= 1'b0;
        end
      end else begin
        case (src_state)
          1'b0: begin
            if (src_valid_i) begin
              src_data_hold <= src_data_i;
              src_req_reg <= 1'b1;
              src_state <= 1'b1;
            end
          end
          1'b1: begin
            if (dst_ack_synced) begin
              src_req_reg <= 1'b0;
              src_state <= 1'b0;
            end
          end
          default: src_state <= 1'b0;
        endcase
      end
    end
  end

  // Destination side
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_state <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        dst_ack_reg <= 1'b0;
        dst_valid_reg <= 1'b0;
        dst_state <= 1'b0;
        dst_clear_pending_reg <= 1'b1;
      end else if (dst_clear_pending_reg) begin
        if (!src_req_synced) begin
          dst_clear_pending_reg <= 1'b0;
        end
      end else begin
        case (dst_state)
          1'b0: begin
            if (src_req_synced) begin
              dst_data_reg <= dst_data_sync;
              dst_valid_reg <= 1'b1;
              dst_ack_reg <= 1'b1;
              dst_state <= 1'b1;
            end
          end
          1'b1: begin
            if (!src_req_synced) begin
              dst_ack_reg <= 1'b0;
              dst_valid_reg <= 1'b0;
              dst_state <= 1'b0;
            end
          end
          default: dst_state <= 1'b0;
        endcase
      end
    end
  end

  // Assign outputs
  assign src_req = src_req_reg;
  assign dst_ack = dst_ack_reg;

  // src_ready_o is high when source can accept new data
  assign src_ready_o = (src_state == 1'b0) && !src_clear_pending_reg && !src_clear_i;

  // dst_valid_o and dst_data_o
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_pending_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

  // Data synchronizer
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_data_sync <= {WIDTH{1'b0}};
    else
      dst_data_sync <= src_data_hold;
  end

endmodule
