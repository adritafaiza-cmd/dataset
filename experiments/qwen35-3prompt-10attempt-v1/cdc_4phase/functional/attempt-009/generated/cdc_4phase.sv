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

  // Source domain state machine
  localparam IDLE = 0;
  localparam GRAB = 1;
  localparam WAIT_DST = 2;
  localparam DONE = 3;

  reg [1:0] src_state;
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_reg;
  reg [1:0] src_next_state;

  // Destination domain state machine
  localparam IDLE_D = 0;
  localparam GRAB_D = 1;
  localparam WAIT_SRC = 2;
  localparam DONE_D = 3;

  reg [1:0] dst_state;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg dst_ready_reg;
  reg [1:0] dst_next_state;

  // Internal signals for handshake coordination
  wire src_valid_next;
  wire dst_valid_next;

  // ---------------------------------------------------------
  // Source Domain Logic
  // ---------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= IDLE;
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
    end else begin
      src_state <= src_next_state;
      src_data_reg <= src_data_reg;
      src_valid_reg <= src_valid_reg;
      src_ready_reg <= src_ready_reg;
    end
  end

  always_comb begin
    src_ready_o = 1'b0;
    src_valid_next = 1'b0;
    src_next_state = src_state;

    case (src_state)
      IDLE: begin
        src_ready_o = 1'b1;
        if (src_valid_i) begin
          src_data_reg = src_data_i;
          src_valid_next = 1'b1;
          src_next_state = GRAB;
        end
      end

      GRAB: begin
        src_ready_o = 1'b0;
        if (dst_ready_i) begin
          src_valid_next = 1'b0;
          src_next_state = DONE;
        end
      end

      WAIT_DST: begin
        src_ready_o = 1'b0;
        if (dst_ready_i) begin
          src_valid_next = 1'b0;
          src_next_state = DONE;
        end
      end

      DONE: begin
        src_ready_o = 1'b1;
        if (src_valid_i && DECOUPLED) begin
          src_data_reg = src_data_i;
          src_valid_next = 1'b1;
          src_next_state = GRAB;
        end else begin
          src_next_state = IDLE;
        end
      end
    endcase
  end

  // ---------------------------------------------------------
  // Destination Domain Logic
  // ---------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= IDLE_D;
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
    end else begin
      dst_state <= dst_next_state;
      dst_data_reg <= dst_data_reg;
      dst_valid_reg <= dst_valid_reg;
      dst_ready_reg <= dst_ready_reg;
    end
  end

  always_comb begin
    dst_ready_o = 1'b0;
    dst_valid_next = 1'b0;
    dst_next_state = dst_state;

    case (dst_state)
      IDLE_D: begin
        dst_ready_o = 1'b1;
        if (src_valid_reg) begin
          dst_data_reg = src_data_reg;
          dst_valid_next = 1'b1;
          dst_next_state = GRAB_D;
        end
      end

      GRAB_D: begin
        dst_ready_o = 1'b0;
        if (src_ready_o) begin
          dst_valid_next = 1'b0;
          dst_next_state = DONE_D;
        end
      end

      WAIT_SRC: begin
        dst_ready_o = 1'b0;
        if (src_ready_o) begin
          dst_valid_next = 1'b0;
          dst_next_state = DONE_D;
        end
      end

      DONE_D: begin
        dst_ready_o = 1'b1;
        if (src_valid_reg && DECOUPLED) begin
          dst_data_reg = src_data_reg;
          dst_valid_next = 1'b1;
          dst_next_state = GRAB_D;
        end else begin
          dst_next_state = IDLE_D;
        end
      end
    endcase
  end

  // ---------------------------------------------------------
  // Output Assignments
  // ---------------------------------------------------------
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Reset message handling logic
  // This logic ensures that if SEND_RESET_MSG is set, the first valid beat
  // after reset carries the RESET_MSG payload instead of waiting for source data.
  // We implement this by checking if we are in the first cycle after reset in the
  // destination domain and if SEND_RESET_MSG is enabled.
  
  reg [WIDTH-1:0] dst_data_override;
  reg reset_active;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      reset_active <= 1'b1;
    end else begin
      reset_active <= 1'b0;
    end
  end

  always_comb begin
    dst_data_override = dst_data_reg;
    if (SEND_RESET_MSG && reset_active && dst_state == GRAB_D) begin
      dst_data_override = RESET_MSG;
    end
  end

  assign dst_data_o = dst_data_override;

endmodule
```<|im_end|>
