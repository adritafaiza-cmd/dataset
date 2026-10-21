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

  // Source Domain: Capture valid/ready handshake and latch data
  logic src_valid_reg;
  logic src_ready_reg;
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_next;
  logic src_ready_next;

  // Destination Domain: Capture valid/ready handshake and latch data
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_next;
  logic dst_ready_next;

  // ------------------------------------------------------------------
  // Source Domain Logic
  // ------------------------------------------------------------------
  // Capture incoming signals synchronously
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg  <= 1'b0;
      src_ready_reg  <= 1'b0;
      src_data_reg   <= {WIDTH{1'b0}};
    end else begin
      src_valid_reg  <= src_valid_i;
      src_ready_reg  <= src_ready_o;
      src_data_reg   <= src_data_i;
    end
  end

  // Handshake logic: Accept data only when valid and ready are both high
  // This ensures one outstanding item is transferred safely across the clock domain
  always_comb begin
    src_ready_next = src_valid_reg && dst_ready_reg;
    src_valid_next = src_valid_reg && !dst_ready_reg;
  end

  // Drive output ready signal
  assign src_ready_o = src_ready_next;

  // ------------------------------------------------------------------
  // Destination Domain Logic
  // ------------------------------------------------------------------
  // Capture incoming signals synchronously
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg  <= 1'b0;
      dst_ready_reg  <= 1'b0;
      dst_data_reg   <= {WIDTH{1'b0}};
    end else begin
      dst_valid_reg  <= dst_valid_o;
      dst_ready_reg  <= dst_ready_i;
      dst_data_reg   <= dst_data_o;
    end
  end

  // Handshake logic: Assert valid when we have data and destination is ready
  // This ensures the data is transferred safely across the clock domain
  always_comb begin
    dst_valid_next = src_valid_reg && dst_ready_reg;
    dst_ready_next = 1'b0; // Ready is driven by the source domain logic
  end

  // Drive output valid signal
  assign dst_valid_o = dst_valid_next;

  // Drive output data signal
  assign dst_data_o = src_data_reg;

endmodule<|im_end|>
