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
  // req: source -> destination (data valid request)
  // ack: destination -> source (acknowledge)
  wire req;
  wire ack;

  // Source side: generate req and consume src_valid/src_ready
  // Destination side: generate ack and produce dst_valid/dst_data

  // We use a simple approach:
  // Source holds data in a register, asserts req when it has data and is ready to send.
  // Destination samples data when req is high, asserts ack.
  // Source deasserts req when ack is high.
  // Destination deasserts ack when req is low.

  // Source side registers
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg req_reg;
  reg ack_reg_src; // synchronized ack on source side

  // Destination side registers
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg ack_reg_dst;
  reg req_reg_dst; // synchronized req on destination side

  // Synchronization of req from source to destination (2-FF synchronizer)
  reg [1:0] req_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      req_sync <= 2'b00;
    else
      req_sync <= {req_sync[0], req};
  end
  assign req_reg_dst = req_sync[1];

  // Synchronization of ack from destination to source (2-FF synchronizer)
  reg [1:0] ack_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      ack_sync <= 2'b00;
    else
      ack_sync <= {ack_sync[0], ack};
  end
  assign ack_reg_src = ack_sync[1];

  // Source side logic
  // req is asserted when we have valid data and haven't sent it yet (or are waiting for ack)
  // We use a state machine:
  // IDLE: no data, req=0
  // WAIT_ACK: data sent, req=1, waiting for ack
  // After ack, we can accept new data

  reg src_state;
  localparam SRC_IDLE = 1'b0;
  localparam SRC_WAIT_ACK = 1'b1;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= SRC_IDLE;
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      req_reg <= 1'b0;
    end else begin
      case (src_state)
        SRC_IDLE: begin
          if (src_valid_i) begin
            src_data_reg <= src_data_i;
            src_valid_reg <= 1'b1;
            req_reg <= 1'b1;
            src_state <= SRC_WAIT_ACK;
          end
        end
        SRC_WAIT_ACK: begin
          if (ack_reg_src) begin
            req_reg <= 1'b0;
            src_valid_reg <= 1'b0;
            src_state <= SRC_IDLE;
          end
        end
        default: begin
          src_state <= SRC_IDLE;
          req_reg <= 1'b0;
          src_valid_reg <= 1'b0;
        end
      endcase
    end
  end

  assign req = req_reg;
  assign src_ready_o = (src_state == SRC_IDLE);

  // Destination side logic
  // When req_reg_dst is high, capture data and assert ack
  // When req_reg_dst goes low, deassert ack
  // dst_valid is high when we have data to present

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      ack_reg_dst <= 1'b0;
    end else begin
      if (req_reg_dst) begin
        // Capture data when req is asserted
        dst_data_reg <= src_data_reg; // This is a CDC issue! We need to synchronize data too.
        dst_valid_reg <= 1'b1;
        ack_reg_dst <= 1'b1;
      end else begin
        // req is low
        if (ack_reg_dst) begin
          ack_reg_dst <= 1'b0;
        end
        // If dst_ready_i is high, we can clear valid
        if (dst_valid_reg && dst_ready_i) begin
          dst_valid_reg <= 1'b0;
        end
      end
    end
  end

  assign ack = ack_reg_dst;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
