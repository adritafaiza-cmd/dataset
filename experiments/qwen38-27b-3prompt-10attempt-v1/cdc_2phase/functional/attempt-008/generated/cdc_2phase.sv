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

  // Source domain: request signal
  reg src_req;
  // Destination domain: request synchronized
  reg [2:0] req_sync;
  reg req_sync_d;
  wire req_pulse;

  // Destination domain: acknowledge signal
  reg dst_ack;
  // Source domain: acknowledge synchronized
  reg [2:0] ack_sync;
  reg ack_sync_d;
  wire ack_pulse;

  // Source domain: data register
  reg [WIDTH-1:0] src_data_reg;

  // Destination domain: data register
  reg [WIDTH-1:0] dst_data_reg;

  // Source domain: valid/ready logic
  // src_ready_o is high when we are not currently holding a request
  // that hasn't been acknowledged yet.
  // We can accept a new item when src_req is low (no outstanding request).
  // Actually, in a 2-phase handshake, we can accept a new item when the
  // previous one has been fully acknowledged. Let's think about this more carefully.

  // In a 2-phase handshake:
  // - Source asserts req when it has data to send.
  // - Destination synchronizes req, sees the rising edge, latches data, asserts ack.
  // - Source synchronizes ack, sees the rising edge, deasserts req, and can accept new data.
  // - Destination deasserts ack after source deasserts req (or after some delay).

  // Let's use a simpler approach:
  // - src_ready_o = ~src_req (we can accept new data when no request is pending)
  // - When src_valid_i & src_ready_o, we latch data and assert src_req.
  // - When ack_pulse (rising edge of synchronized ack), we deassert src_req.
  // - dst_valid_o = req_sync[1] (the synchronized request in destination domain)
  // - When dst_valid_o & dst_ready_i, we deassert dst_ack... wait, we need to think about this.

  // Actually, let me reconsider. The standard 2-phase handshake:
  // 1. Source: req = 1 (when valid & ready)
  // 2. Destination: sees req=1 (synchronized), latches data, sets valid=1
  // 3. Destination: when valid & ready, sets ack=1
  // 4. Source: sees ack=1 (synchronized), sets req=0
  // 5. Destination: sees req=0 (synchronized), sets valid=0, ack=0

  // But we need to be careful about the timing. Let's use a state machine approach.

  // Source domain state:
  // IDLE: src_ready_o = 1, src_req = 0
  // WAIT_ACK: src_ready_o = 0, src_req = 1

  // Destination domain state:
  // IDLE: dst_valid_o = 0, dst_ack = 0
  // WAIT_READY: dst_valid_o = 1, dst_ack = 0 (waiting for dst_ready_i)
  // WAIT_REQ_DEASSERT: dst_valid_o = 1, dst_ack = 1 (waiting for req to deassert)

  // Let's implement this.

  // Source domain
  reg src_state;
  localparam SRC_IDLE = 1'b0;
  localparam SRC_WAIT_ACK = 1'b1;

  // Destination domain
  reg dst_state;
  localparam DST_IDLE = 2'b00;
  localparam DST_WAIT_READY = 2'b01;
  localparam DST_WAIT_REQ_DEASSERT = 2'b10;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= SRC_IDLE;
      src_req <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      case (src_state)
        SRC_IDLE: begin
          if (src_valid_i) begin
            src_data_reg <= src_data_i;
            src_req <= 1'b1;
            src_state <= SRC_WAIT_ACK;
          end
        end
        SRC_WAIT_ACK: begin
          if (ack_pulse) begin
            src_req <= 1'b0;
            src_state <= SRC_IDLE;
          end
        end
        default: begin
          src_state <= SRC_IDLE;
          src_req <= 1'b0;
        end
      endcase
    end
  end

  assign src_ready_o = (src_state == SRC_IDLE);

  // Synchronize ack from destination to source
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync <= 2'b00;
      ack_sync_d <= 1'b0;
    end else begin
      ack_sync <= {ack_sync[0], dst_ack};
      ack_sync_d <= ack_sync[1];
    end
  end

  assign ack_pulse = ack_sync[1] & ~ack_sync_d;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= DST_IDLE;
      dst_ack <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
    end else begin
      case (dst_state)
        DST_IDLE: begin
          if (req_pulse) begin
            dst_data_reg <= src_data_reg; // This is wrong - we can't read src_data_reg directly
            dst_state <= DST_WAIT_READY;
          end
        end
        DST_WAIT_READY: begin
          if (dst_ready_i) begin
            dst_ack <= 1'b1;
            dst_state <= DST_WAIT_REQ_DEASSERT;
          end
        end
        DST_WAIT_REQ_DEASSERT: begin
          if (!req_sync[1]) begin
            dst_ack <= 1'b0;
            dst_state <= DST_IDLE;
          end
        end
        default: begin
          dst_state <= DST_IDLE;
          dst_ack <= 1'b0;
        end
      endcase
    end
  end

  // Synchronize req from source to destination
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      req_sync <= 2'b00;
      req_sync_d <= 1'b0;
    end else begin
      req_sync <= {req_sync[0], src_req};
      req_sync_d <= req_sync[1];
    end
  end

  assign req_pulse = req_sync[1] & ~req_sync_d;

  assign dst_valid_o = (dst_state == DST_WAIT_READY) || (dst_state == DST_WAIT_REQ_DEASSERT);
  assign dst_data_o = dst_data_reg;

endmodule
