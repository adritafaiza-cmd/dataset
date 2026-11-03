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

  // Internal signals for connecting stages
  wire stage1_ready;
  wire [WIDTH-1:0] stage1_data;
  wire stage1_valid;
  wire stage2_ready;
  wire [WIDTH-1:0] stage2_data;
  wire stage2_valid;
  wire stage3_ready;
  wire [WIDTH-1:0] stage3_data;
  wire stage3_valid;
  wire stage4_ready;
  wire [WIDTH-1:0] stage4_data;
  wire stage4_valid;

  // First stage of the CDC pipeline
  cdc_4phase_stage #(
    .WIDTH(WIDTH)
  ) stage1 (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(stage1_ready),
    .data_o(stage1_data),
    .valid_o(stage1_valid)
  );

  // Second stage of the CDC pipeline
  cdc_4phase_stage #(
    .WIDTH(WIDTH)
  ) stage2 (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .data_i(stage1_data),
    .valid_i(stage1_valid),
    .ready_o(stage2_ready),
    .data_o(stage2_data),
    .valid_o(stage2_valid)
  );

  // Third stage of the CDC pipeline
  cdc_4phase_stage #(
    .WIDTH(WIDTH)
  ) stage3 (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .data_i(stage2_data),
    .valid_i(stage2_valid),
    .ready_o(stage3_ready),
    .data_o(stage3_data),
    .valid_o(stage3_valid)
  );

  // Fourth stage of the CDC pipeline
  cdc_4phase_stage #(
    .WIDTH(WIDTH)
  ) stage4 (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .data_i(stage3_data),
    .valid_i(stage3_valid),
    .ready_o(stage4_ready),
    .data_o(stage4_data),
    .valid_o(stage4_valid)
  );

  // Connect internal signals to module ports
  assign src_ready_o = stage1_ready;
  assign dst_data_o = stage4_data;
  assign dst_valid_o = stage4_valid;
  assign stage4_ready = dst_ready_i;

endmodule

module cdc_4phase_stage #(
  parameter WIDTH = 1
)(
  input  rst_ni,
  input  clk_i,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  output [WIDTH-1:0] data_o,
  output valid_o
);

  reg [WIDTH-1:0] data_reg;
  reg valid_reg;

  // Synchronize data and valid signals across clock domains
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_reg <= {WIDTH{1'b0}};
      valid_reg <= 1'b0;
    end else begin
      data_reg <= data_i;
      valid_reg <= valid_i;
    end
  end

  // Assign outputs
  assign data_o = data_reg;
  assign valid_o = valid_reg;
  assign ready_o = 1'b1;

endmodule
