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

  // Internal signals
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic valid_sync;
  logic ready_sync;

  // Source to destination synchronization module
  src_to_dst_sync #(.WIDTH(WIDTH)) src_to_dst_sync_inst (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_i(dst_ready_i),
    .data_o(dst_data_o),
    .valid_o(dst_valid_o),
    .ready_o(src_ready_o)
  );

endmodule

// Submodule for synchronization
module src_to_dst_sync #(
  parameter WIDTH = 1
)(
  input  clk_i,
  input  rst_ni,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  input  ready_i,
  output [WIDTH-1:0] data_o,
  output valid_o,
  output ready_o
);

  // Internal signals
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  // Synchronize valid signal
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_reg <= 1'b0;
    end else begin
      valid_reg <= valid_i;
    end
  end

  // Synchronize data signal
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_reg <= 0;
    end else if (valid_i && ready_i) begin
      data_reg <= data_i;
    end
  end

  // Synchronize ready signal
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ready_reg <= 1'b0;
    end else begin
      ready_reg <= ready_i;
    end
  end

  // Assign outputs
  assign data_o = data_reg;
  assign valid_o = valid_reg;
  assign ready_o = ready_reg;

endmodule
