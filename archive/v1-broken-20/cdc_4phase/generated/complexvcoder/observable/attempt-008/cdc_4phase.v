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

  // Internal signals
  logic [WIDTH-1:0] src_to_dst_data;
  logic src_to_dst_valid;
  logic src_to_dst_ready;
  logic [WIDTH-1:0] dst_to_src_data;
  logic dst_to_src_valid;
  logic dst_to_src_ready;

  // Instantiate the four-phase handshake modules
  src_to_dst src_to_dst_inst (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o),
    .dst_ready_i(dst_ready_i)
  );

  dst_to_src dst_to_src_inst (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .data_i(dst_data_o),
    .valid_i(dst_valid_o),
    .ready_o(dst_ready_i)
  );

endmodule

// Helper module for four-phase handshake from src_clk_i to dst_clk_i
module src_to_dst (
  input  rst_ni,
  input  clk_i,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  input  dst_ready_i
);

  // Internal signals
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  // Synchronize inputs to dst_clk_i domain
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_reg <= {WIDTH{1'b0}};
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
    end else begin
      if (valid_i && dst_ready_i && ready_reg) begin
        data_reg <= data_i;
        valid_reg <= valid_i;
        ready_reg <= 0;
      end else begin
        ready_reg <= 1;
      end
    end
  end

  // Output to dst_clk_i domain
  assign data_o = data_reg;
  assign valid_o = valid_reg;
  assign ready_o = ready_reg;

endmodule

// Helper module for four-phase handshake from dst_clk_i to src_clk_i
module dst_to_src (
  input  rst_ni,
  input  clk_i,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  input  src_ready_o
);

  // Internal signals
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  // Synchronize inputs to src_clk_i domain
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_reg <= {WIDTH{1'b0}};
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
    end else begin
      if (valid_i && src_ready_o && ready_reg) begin
        data_reg <= data_i;
        valid_reg <= valid_i;
        ready_reg <= 0;
      end else begin
        ready_reg <= 1;
      end
    end
  end

  // Output to src_clk_i domain
  assign data_o = data_reg;
  assign valid_o = valid_reg;
  assign ready_o = ready_reg;

endmodule
