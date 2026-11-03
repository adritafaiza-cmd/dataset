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
  logic [WIDTH-1:0] src_data_sync;
  logic [WIDTH-1:0] dst_data_sync;
  logic src_valid_sync;
  logic dst_ready_sync;

  // Source domain state machine
  fsm_src #(.WIDTH(WIDTH)) fsm_src_inst (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_valid_i(src_valid_i),
    .src_ready_o(src_ready_o),
    .src_data_i(src_data_i),
    .src_data_o(src_data_sync),
    .src_valid_o(src_valid_sync)
  );

  // Destination domain state machine
  fsm_dst #(.WIDTH(WIDTH)) fsm_dst_inst (
    .dst_rst_ni(dst_rst_ni),
    .dst_clk_i(dst_clk_i),
    .dst_ready_i(dst_ready_i),
    .dst_valid_o(dst_valid_o),
    .dst_data_o(dst_data_o),
    .dst_data_i(dst_data_sync),
    .dst_valid_i(src_valid_sync)
  );

  // Synchronization register
  sync_reg #(.WIDTH(WIDTH)) sync_reg_inst (
    .sync_in(src_data_sync),
    .sync_out(dst_data_sync)
  );

endmodule

// Source domain state machine
module fsm_src #(
  parameter WIDTH = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_valid_i,
  output src_ready_o,
  input  [WIDTH-1:0] src_data_i,
  output [WIDTH-1:0] src_data_o,
  output src_valid_o
);

  // Internal signals
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_reg <= {WIDTH{1'b0}};
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
    end else begin
      if (src_valid_i && ready_reg) begin
        data_reg <= src_data_i;
        valid_reg <= 1'b1;
        ready_reg <= 1'b0;
      end else if (dst_ready_sync) begin
        valid_reg <= 1'b0;
        ready_reg <= 1'b1;
      end
    end
  end

  assign src_data_o = data_reg;
  assign src_valid_o = valid_reg;
  assign src_ready_o = ready_reg;

endmodule

// Destination domain state machine
module fsm_dst #(
  parameter WIDTH = 1
)(
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_ready_i,
  output dst_valid_o,
  output [WIDTH-1:0] dst_data_o,
  input  [WIDTH-1:0] dst_data_i,
  input  dst_valid_i
);

  // Internal signals
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data_reg <= {WIDTH{1'b0}};
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
    end else begin
      if (dst_valid_i && !ready_reg) begin
        data_reg <= dst_data_i;
        valid_reg <= 1'b1;
        ready_reg <= 1'b1;
      end else if (dst_ready_i) begin
        valid_reg <= 1'b0;
        ready_reg <= 1'b0;
      end
    end
  end

  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;

endmodule

// Synchronization register
module sync_reg #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] sync_in,
  output [WIDTH-1:0] sync_out
);

  logic [WIDTH-1:0] data_reg;

  always_ff @(posedge dst_clk_i) begin
    data_reg <= sync_in;
  end

  assign sync_out = data_reg;

endmodule
