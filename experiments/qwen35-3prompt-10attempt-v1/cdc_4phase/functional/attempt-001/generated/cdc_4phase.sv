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

  // Source Domain State Machine
  // States: IDLE, WAIT_DST_READY, WAIT_SRC_VALID
  localparam [1:0] STATE_IDLE = 2'b00;
  localparam [1:0] STATE_WAIT_DST_READY = 2'b01;
  localparam [1:0] STATE_WAIT_SRC_VALID = 2'b10;

  reg [1:0] src_state;
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_reg;
  reg [1:0] src_next_state;

  // Destination Domain State Machine
  // States: IDLE, WAIT_SRC_VALID, WAIT_SRC_READY
  localparam [1:0] DST_STATE_IDLE = 2'b00;
  localparam [1:0] DST_STATE_WAIT_SRC_VALID = 2'b01;
  localparam [1:0] DST_STATE_WAIT_SRC_READY = 2'b10;

  reg [1:0] dst_state;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg dst_valid_reg_next;
  reg [1:0] dst_next_state;

  // Reset Logic
  reg src_rst_ni_reg;
  reg dst_rst_ni_reg;
  reg reset_msg_flag;

  // Source Domain Logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= STATE_IDLE;
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      reset_msg_flag <= 1'b0;
    end else begin
      src_state <= src_next_state;
      src_data_reg <= src_data_reg;
      src_valid_reg <= src_valid_reg;
      src_ready_reg <= src_ready_reg;
      reset_msg_flag <= reset_msg_flag;
    end
  end

  always_comb begin
    src_ready_reg = 1'b0;
    src_next_state = src_state;

    case (src_state)
      STATE_IDLE: begin
        if (src_valid_i) begin
          src_data_reg = src_data_i;
          src_valid_reg = 1'b1;
          src_next_state = STATE_WAIT_DST_READY;
        end
      end

      STATE_WAIT_DST_READY: begin
        if (dst_ready_i) begin
          src_valid_reg = 1'b0;
          src_next_state = (DECOUPLED) ? STATE_IDLE : STATE_WAIT_SRC_VALID;
        end
      end

      STATE_WAIT_SRC_VALID: begin
        if (src_valid_i) begin
          src_data_reg = src_data_i;
          src_valid_reg = 1'b1;
          src_next_state = STATE_WAIT_DST_READY;
        end
      end

      default: begin
        src_next_state = STATE_IDLE;
      end
    endcase
  end

  // Destination Domain Logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= DST_STATE_IDLE;
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
      reset_msg_flag <= 1'b0;
    end else begin
      dst_state <= dst_next_state;
      dst_data_reg <= dst_data_reg;
      dst_valid_reg <= dst_valid_reg_next;
      reset_msg_flag <= reset_msg_flag;
    end
  end

  always_comb begin
    dst_valid_reg_next = 1'b0;
    dst_next_state = dst_state;

    case (dst_state)
      DST_STATE_IDLE: begin
        if (reset_msg_flag) begin
          dst_data_reg = RESET_MSG;
          dst_valid_reg_next = 1'b1;
          dst_next_state = DST_STATE_WAIT_SRC_READY;
          reset_msg_flag = 1'b0;
        end else if (src_valid_reg && src_ready_reg) begin
          dst_data_reg = src_data_reg;
          dst_valid_reg_next = 1'b1;
          dst_next_state = DST_STATE_WAIT_SRC_READY;
        end
      end

      DST_STATE_WAIT_SRC_READY: begin
        if (dst_ready_i) begin
          dst_valid_reg_next = 1'b0;
          dst_next_state = (DECOUPLED) ? DST_STATE_IDLE : DST_STATE_WAIT_SRC_VALID;
        end
      end

      DST_STATE_WAIT_SRC_VALID: begin
        if (src_valid_reg && src_ready_reg) begin
          dst_data_reg = src_data_reg;
          dst_valid_reg_next = 1'b1;
          dst_next_state = DST_STATE_WAIT_SRC_READY;
        end
      end

      default: begin
        dst_next_state = DST_STATE_IDLE;
      end
    endcase
  end

  // Output Assignments
  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
```<|im_end|>
