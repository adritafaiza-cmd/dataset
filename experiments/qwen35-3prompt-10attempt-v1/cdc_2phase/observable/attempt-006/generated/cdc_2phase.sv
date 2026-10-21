```systemverilog
module cdc_2phase #(
  parameter WIDTH = 1
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

  // Source side: Capture valid/ready handshake and data
  logic src_valid_reg;
  logic src_ready_reg;
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_prev;

  // Destination side: Capture valid/ready handshake and data
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_prev;

  // Two-phase handshake state machine for source
  // Phase 1: Wait for valid, capture data
  // Phase 2: Wait for ready, release valid
  logic src_phase; // 0: Idle/Waiting for valid, 1: Waiting for ready

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_data_reg  <= 1'b0;
      src_phase     <= 1'b0;
      src_valid_prev <= 1'b0;
    end else begin
      src_valid_prev <= src_valid_reg;
      
      if (src_valid_reg && !src_valid_prev) begin
        // Transition to Phase 1: Data captured, waiting for ready
        src_phase <= 1'b1;
        src_data_reg <= src_data_i;
      end else if (src_phase && src_ready_reg) begin
        // Transition back to Idle: Ready received, release valid
        src_phase <= 1'b0;
        src_valid_reg <= 1'b0;
      end else if (src_phase && !src_ready_reg) begin
        // Stay in Phase 1: Waiting for ready
        src_phase <= 1'b1;
      end else begin
        // Idle state
        src_phase <= 1'b0;
      end
    end
  end

  // Two-phase handshake state machine for destination
  // Phase 1: Wait for valid, capture data
  // Phase 2: Wait for ready, release valid
  logic dst_phase; // 0: Idle/Waiting for valid, 1: Waiting for ready

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
      dst_data_reg  <= 1'b0;
      dst_phase     <= 1'b0;
      dst_valid_prev <= 1'b0;
    end else begin
      dst_valid_prev <= dst_valid_reg;
      
      if (dst_valid_reg && !dst_valid_prev) begin
        // Transition to Phase 1: Data captured, waiting for ready
        dst_phase <= 1'b1;
        dst_data_reg <= src_data_reg; // Capture data from source
      end else if (dst_phase && dst_ready_reg) begin
        // Transition back to Idle: Ready received, release valid
        dst_phase <= 1'b0;
        dst_valid_reg <= 1'b0;
      end else if (dst_phase && !dst_ready_reg) begin
        // Stay in Phase 1: Waiting for ready
        dst_phase <= 1'b1;
      end else begin
        // Idle state
        dst_phase <= 1'b0;
      end
    end
  end

  // Output assignments
  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
```<|im_end|>
