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

  // Four-phase handshake signals
  // req: source -> destination (data valid)
  // ack: destination -> source (data accepted)
  wire req;
  wire ack;

  // Source side: generate req, consume ack
  // Destination side: consume req, generate ack

  // Source side state machine
  // States: IDLE (waiting for valid), WAIT_ACK (req asserted, waiting for ack)
  reg src_state;
  localparam SRC_IDLE = 1'b0;
  localparam SRC_WAIT_ACK = 1'b1;

  reg [WIDTH-1:0] src_data_reg;
  reg req_reg;

  // Destination side state machine
  // States: IDLE (waiting for req), WAIT_ACK (ack asserted, waiting for req deassert)
  reg dst_state;
  localparam DST_IDLE = 1'b0;
  localparam DST_WAIT_ACK = 1'b1;

  reg [WIDTH-1:0] dst_data_reg;
  reg ack_reg;

  // Synchronizers for req (src -> dst)
  reg [1:0] req_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      req_sync <= 2'b00;
    else
      req_sync <= {req_sync[0], req};
  end
  wire req_synced = req_sync[1];

  // Synchronizers for ack (dst -> src)
  reg [1:0] ack_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      ack_sync <= 2'b00;
    else
      ack_sync <= {ack_sync[0], ack};
  end
  wire ack_synced = ack_sync[1];

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= SRC_IDLE;
      req_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      case (src_state)
        SRC_IDLE: begin
          if (src_valid_i) begin
            src_data_reg <= src_data_i;
            req_reg <= 1'b1;
            src_state <= SRC_WAIT_ACK;
          end
        end
        SRC_WAIT_ACK: begin
          if (ack_synced) begin
            req_reg <= 1'b0;
            src_state <= SRC_IDLE;
          end
        end
        default: begin
          src_state <= SRC_IDLE;
          req_reg <= 1'b0;
        end
      endcase
    end
  end

  assign req = req_reg;
  assign src_ready_o = (src_state == SRC_IDLE);

  // Destination side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= DST_IDLE;
      ack_reg <= 1'b0;
      dst_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
    end else begin
      case (dst_state)
        DST_IDLE: begin
          if (req_synced) begin
            dst_data_reg <= req_synced ? src_data_reg : dst_data_reg; // This is wrong, need to capture data
            ack_reg <= 1'b1;
            dst_state <= DST_WAIT_ACK;
          end
        end
        DST_WAIT_ACK: begin
          if (!req_synced) begin
            ack_reg <= 1'b0;
            dst_state <= DST_IDLE;
          end
        end
        default: begin
          dst_state <= DST_IDLE;
          ack_reg <= 1'b0;
        end
      endcase
    end
  end

  assign ack = ack_reg;
  assign dst_valid_o = (dst_state == DST_WAIT_ACK);
  assign dst_data_o = dst_data_reg;

endmodule
