module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
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

  // Internal signals for the four-phase handshake
  // req: source requests transfer (goes high when valid & ready)
  // ack: destination acknowledges (goes high when it has received data)
  // Four-phase: req goes high, ack goes high, req goes low, ack goes low

  wire req;
  wire ack;

  // Source side: generate req
  // req is high when src_valid_i is high and src_ready_o is high (handshake completes)
  // But in four-phase, req stays high until ack comes back
  // Let's use a state machine approach

  // Source state: IDLE, WAIT_ACK
  // In IDLE: if src_valid_i, assert req, go to WAIT_ACK
  // In WAIT_ACK: wait for ack to go high, then deassert req, go to IDLE

  reg src_state;
  localparam SRC_IDLE = 1'b0;
  localparam SRC_WAIT_ACK = 1'b1;

  assign src_ready_o = (src_state == SRC_IDLE);

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= SRC_IDLE;
    end else begin
      case (src_state)
        SRC_IDLE: begin
          if (src_valid_i) begin
            src_state <= SRC_WAIT_ACK;
          end
        end
        SRC_WAIT_ACK: begin
          if (ack) begin
            src_state <= SRC_IDLE;
          end
        end
        default: src_state <= SRC_IDLE;
      endcase
    end
  end

  assign req = (src_state == SRC_WAIT_ACK);

  // Destination side: generate ack
  // When req goes high, latch data, assert ack
  // When req goes low, deassert ack
  // Also handle dst_valid_o and dst_ready_i for the output side

  // The destination receives data when req transitions from low to high
  // It latches the data and asserts ack
  // It deasserts ack when req goes low

  reg dst_ack_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;

  // Synchronize req into dst clock domain
  reg req_sync1, req_sync2;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      req_sync1 <= 1'b0;
      req_sync2 <= 1'b0;
    end else begin
      req_sync1 <= req;
      req_sync2 <= req_sync1;
    end
  end

  // Synchronize ack into src clock domain
  reg ack_sync1, ack_sync2;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync1 <= 1'b0;
      ack_sync2 <= 1'b0;
    end else begin
      ack_sync1 <= ack;
      ack_sync2 <= ack_sync1;
    end
  end

  assign ack = ack_sync2;

  // Destination logic
  // When req_sync2 rises, latch data and assert ack
  // When req_sync2 falls, deassert ack
  // The output valid is asserted when data is latched and not yet consumed

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
      dst_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else begin
      if (req_sync2 && !dst_ack_reg) begin
        // Rising edge of req: latch data, assert ack
        dst_data_reg <= src_data_i;
        dst_ack_reg <= 1'b1;
        dst_valid_reg <= 1'b1;
      end else if (!req_sync2 && dst_ack_reg) begin
        // Falling edge of req: deassert ack
        dst_ack_reg <= 1'b0;
      end

      // Deassert valid when consumed
      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 1'b0;
      end
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
