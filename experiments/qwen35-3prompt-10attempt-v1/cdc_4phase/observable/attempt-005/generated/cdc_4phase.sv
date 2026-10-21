```systemverilog
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

  // Sender side state machine
  // States: IDLE, WAIT_DST_READY, WAIT_SRC_VALID
  localparam IDLE = 2'b00;
  localparam WAIT_DST_READY = 2'b01;
  localparam WAIT_SRC_VALID = 2'b10;

  reg [1:0] sender_state;
  reg [WIDTH-1:0] sender_data_reg;
  reg sender_valid_reg;
  reg sender_ready_reg;

  // Receiver side state machine
  // States: IDLE, WAIT_SRC_VALID, WAIT_DST_READY
  localparam R_IDLE = 2'b00;
  localparam R_WAIT_SRC_VALID = 2'b01;
  localparam R_WAIT_DST_READY = 2'b10;

  reg [1:0] receiver_state;
  reg [WIDTH-1:0] receiver_data_reg;
  reg receiver_valid_reg;
  reg receiver_ready_reg;

  // Reset handling for reset message
  reg [WIDTH-1:0] reset_msg_reg;
  reg reset_msg_sent;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sender_state <= IDLE;
      sender_data_reg <= '0;
      sender_valid_reg <= 1'b0;
      sender_ready_reg <= 1'b1;
      reset_msg_reg <= RESET_MSG;
      reset_msg_sent <= 1'b0;
    end else begin
      case (sender_state)
        IDLE: begin
          sender_ready_reg <= 1'b1;
          if (src_valid_i) begin
            sender_data_reg <= src_data_i;
            sender_valid_reg <= 1'b1;
            sender_state <= WAIT_DST_READY;
          end
        end
        WAIT_DST_READY: begin
          sender_ready_reg <= 1'b0;
          if (sender_valid_reg && dst_ready_i) begin
            sender_valid_reg <= 1'b0;
            sender_state <= IDLE;
          end
        end
        WAIT_SRC_VALID: begin
          sender_ready_reg <= 1'b0;
          if (src_valid_i) begin
            sender_data_reg <= src_data_i;
            sender_valid_reg <= 1'b1;
            sender_state <= WAIT_DST_READY;
          end
        end
      endcase
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      receiver_state <= R_IDLE;
      receiver_data_reg <= '0;
      receiver_valid_reg <= 1'b0;
      receiver_ready_reg <= 1'b1;
      reset_msg_reg <= RESET_MSG;
      reset_msg_sent <= 1'b0;
    end else begin
      case (receiver_state)
        R_IDLE: begin
          receiver_ready_reg <= 1'b1;
          if (src_valid_i) begin
            receiver_data_reg <= src_data_i;
            receiver_valid_reg <= 1'b1;
            receiver_state <= R_WAIT_DST_READY;
          end
        end
        R_WAIT_SRC_VALID: begin
          receiver_ready_reg <= 1'b0;
          if (src_valid_i) begin
            receiver_data_reg <= src_data_i;
            receiver_valid_reg <= 1'b1;
            receiver_state <= R_WAIT_DST_READY;
          end
        end
        R_WAIT_DST_READY: begin
          receiver_ready_reg <= 1'b0;
          if (receiver_valid_reg && dst_ready_i) begin
            receiver_valid_reg <= 1'b0;
            receiver_state <= R_IDLE;
          end
        end
      endcase
    end
  end

  // Output assignments
  assign src_ready_o = sender_ready_reg;
  assign dst_data_o = receiver_data_reg;
  assign dst_valid_o = receiver_valid_reg;

  // Reset message handling
  if (SEND_RESET_MSG) begin
    if (!src_rst_ni) begin
      reset_msg_reg <= RESET_MSG;
      reset_msg_sent <= 1'b0;
    end else if (receiver_state === R_IDLE && !receiver_valid_reg) begin
      // Only send reset message when receiver is idle and not currently valid
      // This ensures the message is sent once per reset cycle
      if (!reset_msg_sent) begin
        reset_msg_reg <= RESET_MSG;
        reset_msg_sent <= 1'b1;
      end
    end
  end

  // Decoupled option handling
  // If DECOUPLED is 0, we force the sender to wait for receiver to be ready
  // before accepting new data, effectively making it synchronous-like behavior
  if (!DECOUPLED) begin
    // In non-decoupled mode, sender must wait for receiver to be ready
    // before it can accept new data
    if (sender_state === IDLE && src_valid_i && !receiver_ready_reg) begin
      // Wait until receiver is ready
      sender_state <= WAIT_SRC_VALID;
    end
  end

endmodule
```<|im_end|>
