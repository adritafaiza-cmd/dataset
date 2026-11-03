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
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready_sync;
  logic dst_valid_sync;
  logic dst_ready_sync;

  // Sync registers for src to dst
  sync_reg #(.WIDTH(WIDTH)) src_to_dst_sync (
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .rst_ni(src_rst_ni),
    .clk_i(dst_clk_i),
    .data_o(src_data_sync),
    .valid_o(src_valid_sync)
  );

  // Sync registers for dst to src
  sync_reg #(.WIDTH(WIDTH)) dst_to_src_sync (
    .data_i(dst_data_o),
    .valid_i(dst_valid_o),
    .rst_ni(dst_rst_ni),
    .clk_i(src_clk_i),
    .data_o(dst_data_o),
    .valid_o(dst_valid_o)
  );

  // Handshake logic for src to dst
  handshake src_to_dst_handshake (
    .valid_i(src_valid_sync),
    .ready_o(src_ready_sync)
  );

  // Handshake logic for dst to src
  handshake dst_to_src_handshake (
    .valid_i(dst_valid_sync),
    .ready_o(dst_ready_sync)
  );

  // Output logic
  assign src_ready_o = src_ready_sync;
  assign dst_valid_o = dst_valid_sync;

endmodule

module sync_reg #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  input  rst_ni,
  input  clk_i,
  output [WIDTH-1:0] data_o,
  output valid_o
);

  // Internal signals
  logic [WIDTH-1:0] reg_data;
  logic reg_valid;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      reg_data <= {WIDTH{1'b0}};
      reg_valid <= 1'b0;
    end else begin
      if (valid_i) begin
        reg_data <= data_i;
        reg_valid <= 1'b1;
      end else if (reg_valid && dst_ready_i) begin
        reg_valid <= 1'b0;
      end
    end
  end

  assign data_o = reg_data;
  assign valid_o = reg_valid;

endmodule

module handshake (
  input  valid_i,
  output ready_o
);

  // Internal signals
  logic valid_reg;
  logic ready_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
    end else begin
      valid_reg <= valid_i;
      ready_reg <= dst_ready_i;
    end
  end

  assign ready_o = ready_reg;

endmodule
