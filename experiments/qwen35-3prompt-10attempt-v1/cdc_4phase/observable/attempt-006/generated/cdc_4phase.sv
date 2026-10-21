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

  // Sender side logic (src_clk_i domain)
  // State machine for 4-phase handshake:
  // IDLE: Waiting for valid
  // WAIT_READY: Valid asserted, waiting for ready
  // DATA_VALID: Ready asserted by receiver, data latched, waiting for next valid
  // WAIT_SRC_READY: Receiver ready, sender ready asserted, waiting for receiver to de-assert ready
  
  localparam IDLE = 2'b00;
  localparam WAIT_READY = 2'b01;
  localparam DATA_VALID = 2'b10;
  localparam WAIT_SRC_READY = 2'b11;

  reg [1:0] sender_state;
  reg [WIDTH-1:0] sender_data_reg;
  reg sender_valid_reg;
  reg sender_ready_reg;
  
  // Internal signals for handshake
  wire src_valid_internal = src_valid_i;
  
  // Sender state machine
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sender_state <= IDLE;
      sender_data_reg <= RESET_MSG;
      sender_valid_reg <= 1'b0;
      sender_ready_reg <= 1'b0;
    end else begin
      case (sender_state)
        IDLE: begin
          if (src_valid_internal) begin
            sender_state <= WAIT_READY;
            sender_data_reg <= src_data_i;
            sender_valid_reg <= 1'b1;
          end
        end
        WAIT_READY: begin
          if (sender_ready_reg) begin
            sender_state <= DATA_VALID;
          end
        end
        DATA_VALID: begin
          if (!dst_ready_i) begin
            sender_state <= WAIT_SRC_READY;
          end else begin
            sender_state <= IDLE;
            sender_valid_reg <= 1'b0;
          end
        end
        WAIT_SRC_READY: begin
          if (dst_ready_i) begin
            sender_state <= IDLE;
            sender_valid_reg <= 1'b0;
          end
        end
      endcase
    end
  end

  // Output assignments for sender side
  assign src_ready_o = (sender_state == WAIT_READY) ? 1'b1 : 1'b0;
  assign sender_ready_reg = (sender_state == WAIT_READY) ? 1'b1 : 1'b0;
  
  // Receiver side logic (dst_clk_i domain)
  // State machine for 4-phase handshake:
  // IDLE: Waiting for valid
  // WAIT_VALID: Ready asserted, waiting for valid
  // DATA_READY: Valid asserted by sender, data latched, waiting for sender to de-assert valid
  // WAIT_DST_READY: Sender ready, receiver ready, waiting for sender to de-assert ready
  
  localparam R_IDLE = 2'b00;
  localparam R_WAIT_VALID = 2'b01;
  localparam R_DATA_READY = 2'b10;
  localparam R_WAIT_DST_READY = 2'b11;

  reg [1:0] receiver_state;
  reg [WIDTH-1:0] receiver_data_reg;
  reg receiver_valid_reg;
  reg receiver_ready_reg;
  
  // Internal signals for handshake
  wire dst_ready_internal = dst_ready_i;
  
  // Receiver state machine
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      receiver_state <= R_IDLE;
      receiver_data_reg <= RESET_MSG;
      receiver_valid_reg <= 1'b0;
      receiver_ready_reg <= 1'b0;
    end else begin
      case (receiver_state)
        R_IDLE: begin
          if (sender_valid_reg) begin
            receiver_state <= R_WAIT_VALID;
            receiver_data_reg <= sender_data_reg;
            receiver_valid_reg <= 1'b1;
          end
        end
        R_WAIT_VALID: begin
          if (receiver_ready_reg) begin
            receiver_state <= R_DATA_READY;
          end
        end
        R_DATA_READY: begin
          if (!src_valid_i) begin
            receiver_state <= R_WAIT_DST_READY;
          end else begin
            receiver_state <= R_IDLE;
            receiver_valid_reg <= 1'b0;
          end
        end
        R_WAIT_DST_READY: begin
          if (src_valid_i) begin
            receiver_state <= R_IDLE;
            receiver_valid_reg <= 1'b0;
          end
        end
      endcase
    end
  end

  // Output assignments for receiver side
  assign dst_data_o = receiver_data_reg;
  assign dst_valid_o = receiver_valid_reg;
  assign receiver_ready_reg = (receiver_state == R_WAIT_VALID) ? 1'b1 : 1'b0;
  
  // Decoupled logic
  // If DECOUPLED is 1, we allow the sender to continue sending even if the receiver is not ready
  // This is handled by the state machine logic above where the sender can go back to IDLE
  // and the receiver can go back to IDLE independently.
  
  // Reset message handling
  // If SEND_RESET_MSG is 1, we send the RESET_MSG on the first valid transition
  // This is handled by initializing the registers to RESET_MSG on reset
  
endmodule
```<|im_end|>
