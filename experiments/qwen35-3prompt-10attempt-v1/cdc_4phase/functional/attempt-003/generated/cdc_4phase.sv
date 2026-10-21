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

  // Source domain signals
  logic src_state;
  logic src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic src_valid_next;
  logic src_ready_next;
  logic src_valid_prev;
  logic src_ready_prev;

  // Destination domain signals
  logic dst_state;
  logic dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic dst_valid_next;
  logic dst_ready_next;
  logic dst_valid_prev;
  logic dst_ready_prev;

  // Internal state machine for source side
  // States: IDLE, WAIT_READY, WAIT_VALID
  // Simplified logic:
  // - If reset, go to IDLE
  // - If IDLE and valid, go to WAIT_READY
  // - If WAIT_READY and ready, go to WAIT_VALID
  // - If WAIT_VALID and valid, go to IDLE (loop)
  
  // Internal state machine for destination side
  // States: IDLE, WAIT_VALID, WAIT_READY
  // - If reset, go to IDLE
  // - If IDLE and valid, go to WAIT_READY
  // - If WAIT_READY and ready, go to WAIT_VALID
  // - If WAIT_VALID and valid, go to IDLE (loop)

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= 1'b0; // IDLE
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
    end else begin
      src_state <= src_state_next;
      src_data_reg <= src_data_reg_next;
      src_valid_reg <= src_valid_reg_next;
      src_ready_reg <= src_ready_reg_next;
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= 1'b0; // IDLE
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
    end else begin
      dst_state <= dst_state_next;
      dst_data_reg <= dst_data_reg_next;
      dst_valid_reg <= dst_valid_reg_next;
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  // Source state machine logic
  always_comb begin
    src_state_next = src_state;
    src_data_reg_next = src_data_reg;
    src_valid_reg_next = src_valid_reg;
    src_ready_reg_next = src_ready_reg;

    case (src_state)
      1'b0: begin // IDLE
        if (src_valid_i) begin
          src_state_next = 1'b1; // WAIT_READY
          src_data_reg_next = src_data_i;
          src_valid_reg_next = 1'b1;
          src_ready_reg_next = 1'b1;
        end else begin
          src_state_next = 1'b0;
          src_data_reg_next = '0;
          src_valid_reg_next = 1'b0;
          src_ready_reg_next = 1'b1;
        end
      end
      1'b1: begin // WAIT_READY
        if (src_ready_i) begin
          src_state_next = 1'b0; // Back to IDLE
          src_data_reg_next = src_data_reg;
          src_valid_reg_next = 1'b0;
          src_ready_reg_next = 1'b1;
        end else begin
          src_state_next = 1'b1;
          src_data_reg_next = src_data_reg;
          src_valid_reg_next = 1'b1;
          src_ready_reg_next = 1'b0;
        end
      end
      default: begin
        src_state_next = 1'b0;
        src_data_reg_next = '0;
        src_valid_reg_next = 1'b0;
        src_ready_reg_next = 1'b1;
      end
    endcase
  end

  // Destination state machine logic
  always_comb begin
    dst_state_next = dst_state;
    dst_data_reg_next = dst_data_reg;
    dst_valid_reg_next = dst_valid_reg;
    dst_ready_reg_next = dst_ready_reg;

    case (dst_state)
      1'b0: begin // IDLE
        if (dst_valid_i) begin
          dst_state_next = 1'b1; // WAIT_READY
          dst_data_reg_next = dst_data_i;
          dst_valid_reg_next = 1'b1;
          dst_ready_reg_next = 1'b1;
        end else begin
          dst_state_next = 1'b0;
          dst_data_reg_next = '0;
          dst_valid_reg_next = 1'b0;
          dst_ready_reg_next = 1'b1;
        end
      end
      1'b1: begin // WAIT_READY
        if (dst_ready_i) begin
          dst_state_next = 1'b0; // Back to IDLE
          dst_data_reg_next = dst_data_reg;
          dst_valid_reg_next = 1'b0;
          dst_ready_reg_next = 1'b1;
        end else begin
          dst_state_next = 1'b1;
          dst_data_reg_next = dst_data_reg;
          dst_valid_reg_next = 1'b1;
          dst_ready_reg_next = 1'b0;
        end
      end
      default: begin
        dst_state_next = 1'b0;
        dst_data_reg_next = '0;
        dst_valid_reg_next = 1'b0;
        dst_ready_reg_next = 1'b1;
      end
    endcase
  end

  // Output assignments
  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
```<|im_end|>
