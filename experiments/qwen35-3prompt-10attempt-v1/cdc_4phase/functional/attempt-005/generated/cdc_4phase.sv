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
  // States: IDLE, GRAB, WAIT_DST_READY, WAIT_DST_VALID
  localparam [1:0] IDLE = 2'b00;
  localparam [1:0] GRAB = 2'b01;
  localparam [1:0] WAIT_DST_READY = 2'b10;
  localparam [1:0] WAIT_DST_VALID = 2'b11;

  logic [1:0] src_state;
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_valid_next;
  logic src_ready_next;
  logic src_valid_in;
  logic src_valid_out;

  // Destination Domain State Machine
  // States: IDLE, GRAB, WAIT_SRC_READY, WAIT_SRC_VALID
  localparam [1:0] dst_idl = 2'b00;
  localparam [1:0] dst_grab = 2'b01;
  localparam [1:0] dst_wait_src_ready = 2'b10;
  localparam [1:0] dst_wait_src_valid = 2'b11;

  logic [1:0] dst_state;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_valid_next;
  logic dst_ready_next;
  logic dst_valid_in;
  logic dst_valid_out;

  // Source Domain Logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= IDLE;
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_valid_out <= 1'b0;
    end else begin
      src_state <= src_state_next;
      src_data_reg <= src_data_reg_next;
      src_valid_reg <= src_valid_reg_next;
      src_valid_out <= src_valid_reg;
    end
  end

  assign src_ready_o = src_ready_next;

  // Source State Next Logic
  always_comb begin
    src_state_next = src_state;
    src_data_reg_next = src_data_reg;
    src_valid_reg_next = 1'b0;
    src_ready_next = 1'b0;

    case (src_state)
      IDLE: begin
        if (src_valid_i) begin
          src_state_next = GRAB;
          src_data_reg_next = src_data_i;
          src_valid_reg_next = 1'b1;
          src_ready_next = 1'b1;
        end else begin
          src_ready_next = 1'b1;
        end
      end

      GRAB: begin
        if (dst_ready_i) begin
          src_state_next = WAIT_DST_READY;
          src_valid_reg_next = 1'b0; // Deassert valid to allow new data if decoupled
          src_ready_next = 1'b1;
        end else begin
          src_ready_next = 1'b0;
        end
      end

      WAIT_DST_READY: begin
        if (dst_ready_i) begin
          src_state_next = WAIT_DST_VALID;
          src_valid_reg_next = 1'b1;
          src_ready_next = 1'b1;
        end else begin
          src_ready_next = 1'b1;
        end
      end

      WAIT_DST_VALID: begin
        if (dst_valid_i) begin
          src_state_next = IDLE;
          src_valid_reg_next = 1'b0;
          src_ready_next = 1'b1;
        end else begin
          src_ready_next = 1'b1;
        end
      end
    endcase
  end

  // Destination Domain Logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= dst_idl;
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
      dst_valid_out <= 1'b0;
    end else begin
      dst_state <= dst_state_next;
      dst_data_reg <= dst_data_reg_next;
      dst_valid_reg <= dst_valid_reg_next;
      dst_valid_out <= dst_valid_reg;
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_out;

  // Destination State Next Logic
  always_comb begin
    dst_state_next = dst_state;
    dst_data_reg_next = dst_data_reg;
    dst_valid_reg_next = 1'b0;
    dst_ready_next = 1'b0;

    case (dst_state)
      dst_idl: begin
        if (src_valid_i) begin
          dst_state_next = dst_grab;
          dst_data_reg_next = src_data_i;
          dst_valid_reg_next = 1'b1;
          dst_ready_next = 1'b1;
        end else begin
          dst_ready_next = 1'b1;
        end
      end

      dst_grab: begin
        if (src_ready_i) begin
          dst_state_next = dst_wait_src_ready;
          dst_valid_reg_next = 1'b0;
          dst_ready_next = 1'b1;
        end else begin
          dst_ready_next = 1'b0;
        end
      end

      dst_wait_src_ready: begin
        if (src_ready_i) begin
          dst_state_next = dst_wait_src_valid;
          dst_valid_reg_next = 1'b1;
          dst_ready_next = 1'b1;
        end else begin
          dst_ready_next = 1'b1;
        end
      end

      dst_wait_src_valid: begin
        if (src_valid_i) begin
          dst_state_next = dst_idl;
          dst_valid_reg_next = 1'b0;
          dst_ready_next = 1'b1;
        end else begin
          dst_ready_next = 1'b1;
        end
      end
    endcase
  end

endmodule
```<|im_end|>
