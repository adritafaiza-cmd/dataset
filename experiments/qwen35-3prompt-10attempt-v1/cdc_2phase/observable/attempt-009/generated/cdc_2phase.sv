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
  // Phase 2: Source deasserts valid when ready is asserted by destination
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_data_reg  <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_next;
      src_ready_reg <= src_ready_next;
      src_data_reg  <= src_data_next;
    end
  end

  // Two-phase handshake logic for destination side
  // Phase 1: Destination captures data and asserts valid when ready
  // Phase 2: Destination deasserts valid when ready is asserted by source
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
      dst_data_reg  <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_next;
      dst_ready_reg <= dst_ready_next;
      dst_data_reg  <= dst_data_next;
    end
  end

  // Source side combinational logic
  // When src_valid is high and src_ready is high, we transfer data
  // When src_valid is high and src_ready is low, we hold data
  // When src_valid is low, we wait for src_ready to go high
  always_comb begin
    src_valid_next = src_valid_reg;
    src_ready_next = src_ready_reg;
    src_data_next  = src_data_reg;

    if (!src_valid_reg) begin
      // If not valid, wait for ready
      src_ready_next = dst_ready_reg;
      src_data_next  = src_data_reg;
    end else begin
      // If valid, check if destination is ready
      if (dst_ready_reg) begin
        // Transfer data and deassert valid
        src_valid_next = 1'b0;
        src_data_next  = src_data_reg;
      end else begin
        // Hold data and keep valid
        src_valid_next = 1'b1;
        src_data_next  = src_data_reg;
      end
    end
  end

  // Destination side combinational logic
  // When dst_valid is high and dst_ready is high, we transfer data
  // When dst_valid is high and dst_ready is low, we hold data
  // When dst_valid is low, we wait for valid to go high
  always_comb begin
    dst_valid_next = dst_valid_reg;
    dst_ready_next = dst_ready_reg;
    dst_data_next  = dst_data_reg;

    if (!dst_valid_reg) begin
      // If not valid, wait for valid
      dst_ready_next = src_ready_reg;
      dst_data_next  = dst_data_reg;
    end else begin
      // If valid, check if source is ready
      if (src_ready_reg) begin
        // Transfer data and deassert valid
        dst_valid_next = 1'b0;
        dst_data_next  = dst_data_reg;
      end else begin
        // Hold data and keep valid
        dst_valid_next = 1'b1;
        dst_data_next  = dst_data_reg;
      end
    end
  end

  // Assign outputs
  assign src_ready_o = src_ready_reg;
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
```<|im_end|>
