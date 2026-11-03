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

  // Internal signals for synchronization
  logic [WIDTH:0] src_sync_reg_1;
  logic [WIDTH:0] src_sync_reg_2;
  logic [WIDTH:0] src_sync_reg_3;
  logic dst_sync_reg_4;
  logic [WIDTH:0] dst_sync_reg_5;
  logic [WIDTH:0] dst_sync_reg_6;
  logic cdc_valid_ready_1;

  // Sync registers for src domain to dst domain
  sync_reg #(.WIDTH(WIDTH+1)) src_sync (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_data_i(src_data_i),
    .src_valid_i(src_valid_i),
    .dst_data_o(src_sync_reg_1),
    .dst_valid_o(src_sync_reg_2)
  );

  sync_reg #(.WIDTH(WIDTH+1)) src_sync_reg2 (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_data_i(src_sync_reg_1),
    .src_valid_i(src_sync_reg_2),
    .dst_data_o(src_sync_reg_3),
    .dst_valid_o(src_sync_reg_3)
  );

  // Sync register for dst domain to src domain
  sync_reg #(.WIDTH(1)) dst_sync (
    .src_rst_ni(dst_rst_ni),
    .src_clk_i(dst_clk_i),
    .src_data_i(dst_ready_i),
    .src_valid_i(dst_ready_i),
    .dst_data_o(dst_sync_reg_4),
    .dst_valid_o(dst_sync_reg_5)
  );

  sync_reg #(.WIDTH(WIDTH+1)) dst_sync_reg2 (
    .src_rst_ni(dst_rst_ni),
    .src_clk_i(dst_clk_i),
    .src_data_i(dst_sync_reg_4),
    .src_valid_i(dst_sync_reg_5),
    .dst_data_o(dst_sync_reg_6),
    .dst_valid_o(dst_sync_reg_6)
  );

  // Two-phase valid/ready logic
  two_phase_valid_ready cdc_valid_ready (
    .src_valid_i(src_sync_reg_3[WIDTH]),
    .src_ready_o(src_ready_o),
    .dst_valid_o(dst_valid_o),
    .dst_ready_i(dst_ready_i)
  );

  // Assign output data
  assign dst_data_o = src_sync_reg_3[WIDTH-1:0];

endmodule

// Sync register module
module sync_reg #(
  parameter WIDTH = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o
);

  logic [WIDTH-1:0] shift_reg;
  logic valid_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      shift_reg <= 0;
      valid_reg <= 0;
    end else begin
      if (src_valid_i) begin
        shift_reg <= src_data_i;
        valid_reg <= 1;
      end else if (valid_reg) begin
        valid_reg <= 0;
      end
    end
  end

  assign dst_data_o = shift_reg;
  assign dst_valid_o = valid_reg;

endmodule

// Two-phase valid/ready logic module
module two_phase_valid_ready (
  input  src_valid_i,
  input  src_ready_o,
  output dst_valid_o,
  output dst_ready_i
);

  logic src_valid_reg;
  logic src_ready_reg;

  always_ff @(posedge src_ready_o or negedge src_valid_i) begin
    if (!src_valid_i) begin
      src_valid_reg <= 0;
    end else begin
      src_valid_reg <= src_valid_i;
    end
  end

  always_ff @(posedge src_ready_o or negedge src_valid_i) begin
    if (!src_valid_i) begin
      src_ready_reg <= 0;
    end else begin
      src_ready_reg <= src_ready_o;
    end
  end

  assign dst_valid_o = src_valid_reg;
  assign dst_ready_i = src_ready_reg;

endmodule
