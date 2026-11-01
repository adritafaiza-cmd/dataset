module cdc_2phase #(
  parameter WIDTH = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Source domain state
  reg src_valid_reg;
  reg [WIDTH-1:0] src_data_reg;

  // Destination domain state
  reg dst_valid_reg;
  reg [WIDTH-1:0] dst_data_reg;

  // Handshake signals
  // req: source -> destination (asserted when source has data)
  // ack: destination -> source (asserted when destination has accepted data)
  reg req;
  reg ack;

  // Synchronizers for req (2-stage)
  reg req_sync1, req_sync2;
  // Synchronizers for ack (2-stage)
  reg ack_sync1, ack_sync2;

  // Source domain: synchronize ack
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync1 <= 1'b0;
      ack_sync2 <= 1'b0;
    end else begin
      ack_sync1 <= ack;
      ack_sync2 <= ack_sync1;
    end
  end

  // Destination domain: synchronize req
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      req_sync1 <= 1'b0;
      req_sync2 <= 1'b0;
    end else begin
      req_sync1 <= req;
      req_sync2 <= req_sync1;
    end
  end

  // Source domain logic
  // src_ready_o is high when we can accept a new item
  // We can accept a new item if:
  //   - We don't have an outstanding item (src_valid_reg is low), OR
  //   - The destination has acknowledged the previous item (ack_sync2 is high)
  // Actually, let's think about this more carefully.
  //
  // The protocol:
  // - Source asserts req when it has data to send.
  // - Destination sees req (synchronized) and if it's ready, it accepts the data and asserts ack.
  // - Source sees ack (synchronized) and deasserts req, allowing new data.
  //
  // But we need to handle the case where dst_ready_i is low. In that case, the destination
  // should not accept the data, so it should not assert ack.
  //
  // Let's use a simpler approach:
  // - req is asserted by source when it has data and is waiting for ack.
  // - ack is asserted by destination when it has accepted the data (dst_valid_o & dst_ready_i).
  //
  // Source state machine:
  // - IDLE: src_valid_reg = 0, req = 0. If src_valid_i, capture data, set src_valid_reg = 1, req = 1.
  // - WAIT_ACK: src_valid_reg = 1, req = 1. When ack_sync2 = 1, go to IDLE.
  //
  // But we also need to handle the case where the destination is not ready. In that case,
  // the destination should not assert ack, so the source will wait.
  //
  // Destination state machine:
  // - IDLE: dst_valid_reg = 0, ack = 0. If req_sync2 = 1 and dst_ready_i = 1, capture data, set dst_valid_reg = 1, ack = 1.
  // - WAIT_READY: dst_valid_reg = 1, ack = 1. When dst_ready_i = 1, go to IDLE (ack = 0).
  //
  // Wait, there's a problem. The data needs to be transferred from source to destination.
  // The source has the data in src_data_reg. The destination needs to get this data.
  // But the data is in the source domain. We need to synchronize the data as well.
  //
  // Actually, for a 2-phase handshake, the data is typically held stable until the handshake completes.
  // So the source holds the data in src_data_reg, and the destination reads it when it sees req.
  // But the data is multi-bit, so we need to ensure it's stable.
  //
  // One approach: use a FIFO or a register that is written in the source domain and read in the destination domain.
  // But that's complex.
  //
  // Another approach: since we only have one outstanding item, we can use the following:
  // - The source writes the data to a register (src_data_reg) and asserts req.
  // - The destination, when it sees req (synchronized), reads the data from src_data_reg.
  // - But src_data_reg is in the source domain, so reading it in the destination domain is a CDC issue.
  //
  // To handle this, we can use a "data valid" signal that is synchronized, and the data is held stable
  // until the handshake completes. Since the data is held stable (not changing) while req is asserted,
  // the destination can safely read it as long as it's stable.
  //
  // But multi-bit data crossing clock domains is tricky. The standard approach is to use a FIFO or
  // to ensure the data is stable and use a synchronizer for the data as well.
  //
  // For simplicity, let's assume that the data is held stable while req is asserted, and the destination
  // reads it when req is synchronized. This is a common approach for 2-phase handshakes with multi-bit data.
  //
  // However, to be safe, we should synchronize the data as well. But that would require a multi-bit synchronizer,
  // which is complex.
  //
  // Let's use a different approach: use a small FIFO (1-entry) that is written in the source domain and read
  // in the destination domain. But that's also complex.
  //
  // Actually, for a 2-phase handshake, the standard approach is:
  // 1. Source asserts req and holds data stable.
  // 2. Destination synchronizes req.
  // 3. When req is synchronized and dst_ready_i is high, destination captures the data and asserts ack.
  // 4. Source synchronizes ack and deasserts req.
  //
  // The data is held stable by the source while req is asserted, so the destination can safely read it.
  // This is a valid approach for 2-phase handshakes.
  //
  // Let's implement this.

  // Source domain: manage req and data
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg  <= {WIDTH{1'b0}};
      req           <= 1'b0;
    end else begin
      if (src_valid_i && !src_valid_reg) begin
        // Accept new data
        src_valid_reg <= 1'b1;
        src_data_reg  <= src_data_i;
        req           <= 1'b1;
      end else if (src_valid_reg && ack_sync2) begin
        // Acknowledged, clear
        src_valid_reg <= 1'b0;
        req           <= 1'b0;
      end
    end
  end

  // src_ready_o: high when we can accept new data
  assign src_ready_o = !src_valid_reg;

  // Destination domain: manage ack and data
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg  <= {WIDTH{1'b0}};
      ack           <= 1'b0;
    end else begin
      if (!dst_valid_reg && req_sync2 && dst_ready_i) begin
        // Accept data from source
        dst_valid_reg <= 1'b1;
        dst_data_reg  <= src_data_reg; // Read from source domain register (stable while req is high)
        ack           <= 1'b1;
      end else if (dst_valid_reg && dst_ready_i) begin
        // Data accepted, clear
        dst_valid_reg <= 1'b0;
        ack           <= 1'b0;
      end
    end
  end

  // Destination outputs
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o  = dst_data_reg;

endmodule
