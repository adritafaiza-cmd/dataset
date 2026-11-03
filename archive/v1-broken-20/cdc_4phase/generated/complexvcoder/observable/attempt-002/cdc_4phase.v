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

  // Internal signals for handshake and data transfer
  logic [WIDTH-1:0] src_data_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic src_valid_out, src_ready_in;
  logic dst_valid_in, dst_ready_out;

  // Handshake generators for source and destination
  handshake_generator src_handshake (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .valid_in(src_valid_i),
    .ready_out(src_ready_o),
    .valid_out(src_valid_out),
    .ready_in(src_ready_in)
  );

  handshake_generator dst_handshake (
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .valid_in(dst_valid_out),
    .ready_out(dst_ready_o),
    .valid_out(dst_valid_out),
    .ready_in(dst_ready_in)
  );

  // Register to hold the source data
  register_ff src_data_ff (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .d(src_data_i),
    .q(src_data_reg)
  );

  // Register to hold the destination data
  register_ff dst_data_ff (
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .d(src_data_reg),
    .q(dst_data_reg)
  );

  // Assign data to the output when handshake is valid
  assign dst_data_o = dst_data_reg;

  // Assign handshake signals
  assign src_ready_in = src_handshake.ready_in;
  assign dst_valid_in = dst_handshake.valid_out;

endmodule

// Handshake generator module
module handshake_generator (
  input  clk,
  input  rst_n,
  input  valid_in,
  output ready_out,
  output valid_out,
  input  ready_in
);

  // Internal registers for handshake signals
  logic valid_reg, ready_reg;

  // Register the handshake signals
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
    end else begin
      valid_reg <= valid_in;
      ready_reg <= ready_in;
    end
  end

  // Generate valid_out and ready_out
  assign valid_out = valid_reg & ready_in;
  assign ready_out = valid_in & ready_reg;

endmodule

// Register flip-flop module
module register_ff (
  input  clk,
  input  rst_n,
  input  [WIDTH-1:0] d,
  output [WIDTH-1:0] q
);

  // Internal register
  logic [WIDTH-1:0] q_reg;

  // Register the input signal
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      q_reg <= {WIDTH{1'b0}};
    end else begin
      q_reg <= d;
    end
  end

  // Assign the output
  assign q = q_reg;

endmodule
