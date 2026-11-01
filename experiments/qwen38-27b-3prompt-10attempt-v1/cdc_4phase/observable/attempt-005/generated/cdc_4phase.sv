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

  // Source side: generate req and handle src_ready
  // Destination side: generate ack and handle dst_valid/dst_ready

  // Source side logic
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_reg;
  reg req_reg;
  reg ack_reg; // synchronized ack from dst

  // Destination side logic
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg ack_reg_dst;
  reg req_reg_dst; // synchronized req from src

  // Synchronizers for req (src -> dst)
  reg [1:0] req_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      req_sync <= 2'b00;
    else
      req_sync <= {req_sync[0], req};
  end
  assign req_reg_dst = req_sync[1];

  // Synchronizers for ack (dst -> src)
  reg [1:0] ack_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      ack_sync <= 2'b00;
    else
      ack_sync <= {ack_sync[0], ack};
  end
  assign ack_reg = ack_sync[1];

  // Source side state machine
  // States: IDLE, WAIT_ACK
  // In IDLE: if src_valid_i and not in transfer, capture data, assert req
  // In WAIT_ACK: wait for ack, then deassert req, go to IDLE

  reg src_state;
  localparam SRC_IDLE = 1'b0;
  localparam SRC_WAIT_ACK = 1'b1;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= SRC_IDLE;
      req_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end else begin
      case (src_state)
        SRC_IDLE: begin
          req_reg <= 1'b0;
          if (src_valid_i) begin
            src_data_reg <= src_data_i;
            src_valid_reg <= 1'b1;
            req_reg <= 1'b1;
            src_state <= SRC_WAIT_ACK;
            src_ready_reg <= 1'b0;
          end else begin
            src_ready_reg <= 1'b1;
          end
        end
        SRC_WAIT_ACK: begin
          if (ack_reg) begin
            // Ack received, complete handshake
            req_reg <= 1'b0;
            src_valid_reg <= 1'b0;
            src_state <= SRC_IDLE;
            src_ready_reg <= 1'b1;
          end else begin
            src_ready_reg <= 1'b0;
          end
        end
        default: begin
          src_state <= SRC_IDLE;
          req_reg <= 1'b0;
          src_ready_reg <= 1'b0;
        end
      endcase
    end
  end

  assign src_ready_o = src_ready_reg;
  assign req = req_reg;

  // Destination side state machine
  // States: IDLE, WAIT_REQ (waiting for req to deassert after ack)
  // When req_reg_dst rises, capture data, assert ack
  // When req_reg_dst falls, deassert ack, go to IDLE

  reg dst_state;
  localparam DST_IDLE = 1'b0;
  localparam DST_WAIT_REQ_FALL = 1'b1;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= DST_IDLE;
      ack_reg_dst <= 1'b0;
      dst_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else begin
      case (dst_state)
        DST_IDLE: begin
          ack_reg_dst <= 1'b0;
          if (req_reg_dst) begin
            dst_data_reg <= req_reg_dst ? src_data_reg : dst_data_reg; // This is wrong, need to capture from src side
            // Actually, we need to capture the data when req rises. But src_data_reg is in src domain.
            // We need to synchronize the data as well, or use a different approach.
            // Let me reconsider the design.
            dst_valid_reg <= 1'b1;
            ack_reg_dst <= 1'b1;
            dst_state <= DST_WAIT_REQ_FALL;
          end else begin
            dst_valid_reg <= 1'b0;
          end
        end
        DST_WAIT_REQ_FALL: begin
          if (!req_reg_dst) begin
            ack_reg_dst <= 1'b0;
            dst_state <= DST_IDLE;
            dst_valid_reg <= 1'b0;
          end else begin
            dst_valid_reg <= 1'b1;
          end
        end
        default: begin
          dst_state <= DST_IDLE;
          ack_reg_dst <= 1'b0;
          dst_valid_reg <= 1'b0;
        end
      endcase
    end
  end

  assign ack = ack_reg_dst;
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

endmodule

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
  wire req;
  wire ack;

  // Source side
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_reg;
  reg req_reg;
  reg ack_sync_reg;

  // Destination side
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg ack_reg;
  reg req_sync_reg;

  // Synchronizer for req (src -> dst)
  reg [1:0] req_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      req_sync <= 2'b00;
    else
      req_sync <= {req_sync[0], req};
  end
  assign req_sync_reg = req_sync[1];

  // Synchronizer for ack (dst -> src)
  reg [1:0] ack_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      ack_sync <= 2'b00;
    else
      ack_sync <= {ack_sync[0], ack};
  end
  assign ack_sync_reg = ack_sync[1];

  // Source side state machine
  reg src_state;
  localparam SRC_IDLE = 1'b0;
  localparam SRC_WAIT_ACK = 1'b1;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= SRC_IDLE;
      req_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end else begin
      case (src_state)
        SRC_IDLE: begin
          req_reg <= 1'b0;
          if (src_valid_i) begin
            src_data_reg <= src_data_i;
            src_valid_reg <= 1'b1;
            req_reg <= 1'b1;
            src_state <= SRC_WAIT_ACK;
            src_ready_reg <= 1'b0;
          end else begin
            src_ready_reg <= 1'b1;
          end
        end
        SRC_WAIT_ACK: begin
          if (ack_sync_reg) begin
            req_reg <= 1'b0;
            src_valid_reg <= 1'b0;
            src_state <= SRC_IDLE;
            src_ready_reg <= 1'b1;
          end else begin
            src_ready_reg <= 1'b0;
          end
        end
        default: begin
          src_state <= SRC_IDLE;
          req_reg <= 1'b0;
          src_ready_reg <= 1'b0;
        end
      endcase
    end
  end

  assign src_ready_o = src_ready_reg;
  assign req = req_reg;

  // Destination side state machine
  reg dst_state;
  localparam DST_IDLE = 1'b0;
  localparam DST_WAIT_REQ_FALL = 1'b1;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= DST_IDLE;
      ack_reg <= 1'b0;
      dst_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else begin
      case (dst_state)
        DST_IDLE: begin
          ack_reg <= 1'b0;
          if (req_sync_reg) begin
            dst_data_reg <= src_data_reg; // This is still wrong - cross-domain read
            dst_valid_reg <= 1'b1;
            ack_reg <= 1'b1;
            dst_state <= DST_WAIT_REQ_FALL;
          end else begin
            dst_valid_reg <= 1'b0;
          end
        end
        DST_WAIT_REQ_FALL: begin
          if (!req_sync_reg) begin
            ack_reg <= 1'b0;
            dst_state <= DST_IDLE;
            dst_valid_reg <= 1'b0;
          end else begin
            dst_valid_reg <= 1'b1;
          end
        end
        default: begin
          dst_state <= DST_IDLE;
          ack_reg <= 1'b0;
          dst_valid_reg <= 1'b0;
        end
      endcase
    end
  end

  assign ack = ack_reg;
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

endmodule

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
  wire req;
  wire ack;

  // Source side
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_reg;
  reg req_reg;
  reg ack_sync_reg;

  // Destination side
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg ack_reg;
  reg req_sync_reg;

  // Synchronizer for req (src -> dst)
  reg [1:0] req_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      req_sync <= 2'b00;
    else
      req_sync <= {req_sync[0], req};
  end
  assign req_sync_reg = req_sync[1];

  // Synchronizer for ack (dst -> src)
  reg [1:0] ack_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      ack_sync <= 2'b00;
    else
      ack_sync <= {ack_sync[0], ack};
  end
  assign ack_sync_reg = ack_sync[1];

  // Data synchronizer (src -> dst) - only valid when req is high
  reg [WIDTH-1:0] data_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      data_sync <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
    else if (req_sync_reg)
      data_sync <= src_data_reg;
  end

  // Source side state machine
  reg src_state;
  localparam SRC_IDLE = 1'b0;
  localparam SRC_WAIT_ACK = 1'b1;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= SRC_IDLE;
      req_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end else begin
      case (src_state)
        SRC_IDLE: begin
          req_reg <= 1'b0;
          if (src_valid_i) begin
            src_data_reg <= src_data_i;
            src_valid_reg <= 1'b1;
            req_reg <= 1'b1;
            src_state <= SRC_WAIT_ACK;
            src_ready_reg <= 1'b0;
          end else begin
            src_ready_reg <= 1'b1;
          end
        end
        SRC_WAIT_ACK: begin
          if (ack_sync_reg) begin
            req_reg <= 1'b0;
            src_valid_reg <= 1'b0;
            src_state <= SRC_IDLE;
            src_ready_reg <= 1'b1;
          end else begin
            src_ready_reg <= 1'b0;
          end
        end
        default: begin
          src_state <= SRC_IDLE;
          req_reg <= 1'b0;
          src_ready_reg <= 1'b0;
        end
      endcase
    end
  end

  assign src_ready_o = src_ready_reg;
  assign req = req_reg;

  // Destination side state machine
  reg dst_state;
  localparam DST_IDLE = 1'b0;
  localparam DST_WAIT_REQ_FALL = 1'b1;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= DST_IDLE;
      ack_reg <= 1'b0;
      dst_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else begin
      case (dst_state)
        DST_IDLE: begin
          ack_reg <= 1'b0;
          if (req_sync_reg) begin
            dst_data_reg <= data_sync;
            dst_valid_reg <= 1'b1;
            ack_reg <= 1'b1;
            dst_state <= DST_WAIT_REQ_FALL;
          end else begin
            dst_valid_reg <= 1'b0;
          end
        end
        DST_WAIT_REQ_FALL: begin
          if (!req_sync_reg) begin
            ack_reg <= 1'b0;
            dst_state <= DST_IDLE;
            dst_valid_reg <= 1'b0;
          end else begin
            dst_valid_reg <= 1'b1;
          end
        end
        default: begin
          dst_state <= DST_IDLE;
          ack_reg <= 1'b0;
          dst_valid_reg <= 1'b0;
        end
      endcase
    end
  end

  assign ack = ack_reg;
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

endmodule
