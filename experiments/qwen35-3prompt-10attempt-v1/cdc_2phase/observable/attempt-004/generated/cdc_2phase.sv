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
  logic src_valid_next;
  logic src_ready_next;

  // Destination side: Capture valid/ready handshake and data
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_next;
  logic dst_ready_next;

  // Two-phase handshake logic for source side
  // Phase 1: Source drives data and asserts valid when ready
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_data_reg  <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_next;
      src_ready_reg <= src_ready_next;
      src_data_reg  <= src_data_next;
    end
  end

  // Two-phase handshake logic for destination side
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
      dst_data_reg  <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_next;
      dst_ready_reg <= dst_ready_next;
      dst_data_reg  <= dst_data_next;
    end
  end

  // Source side combinational logic
  always_comb begin
    src_valid_next = src_valid_reg;
    src_ready_next = dst_ready_reg;
    src_data_next  = src_data_reg;

    if (src_valid_reg && dst_ready_reg) begin
      src_valid_next = 1'b0;
      src_data_next  = src_data_i;
    end
  end

  // Destination side combinational logic
  always_comb begin
    dst_valid_next = src_valid_reg;
    dst_ready_next = dst_ready_i;
    dst_data_next  = src_data_reg;

    if (src_valid_reg && dst_ready_i) begin
      dst_valid_next = 1'b0;
    end
  end

  // Output assignments
  assign src_ready_o = src_ready_reg;
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o  = dst_data_reg;

endmodule
```<|im_end|>
