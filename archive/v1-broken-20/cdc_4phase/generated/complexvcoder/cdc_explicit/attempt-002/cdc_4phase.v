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
  logic [WIDTH-1:0] src_data;
  logic src_valid;
  logic src_ready;
  logic [WIDTH-1:0] dst_data;
  logic dst_valid;
  logic dst_ready;
  logic [WIDTH-1:0] synced_data;
  logic sync_clk_i;
  logic sync_clk_o;

  // Source state machine
  src_state_machine #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED)
  ) src_sm (
    .src_valid_i(src_valid_i),
    .src_ready_o(src_ready_o),
    .src_data_i(src_data_i),
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_valid(src_valid),
    .src_ready(src_ready),
    .src_data(src_data)
  );

  // Destination state machine
  dst_state_machine #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED)
  ) dst_sm (
    .dst_valid_o(dst_valid_o),
    .dst_ready_i(dst_ready_i),
    .dst_data_o(dst_data_o),
    .dst_rst_ni(dst_rst_ni),
    .dst_clk_i(dst_clk_i),
    .dst_valid(dst_valid),
    .dst_ready(dst_ready),
    .dst_data(dst_data)
  );

  // Sync register
  sync_register #(
    .WIDTH(WIDTH)
  ) data_sync (
    .src_data(src_data),
    .dst_data_o(dst_data_o),
    .src_clk_i(src_clk_i),
    .dst_clk_i(dst_clk_i),
    .synced_data(synced_data)
  );

  // Connections
  assign src_sm.src_valid = src_valid;
  assign src_sm.src_ready = src_ready;
  assign src_sm.src_data = src_data;
  assign dst_sm.dst_valid = dst_valid;
  assign dst_sm.dst_ready = dst_ready;
  assign dst_sm.dst_data = dst_data;
  assign src_data_o = synced_data;

endmodule

// Source state machine
module src_state_machine #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1
)(
  input  src_valid_i,
  input  src_ready_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_rst_ni,
  input  src_clk_i,
  output src_valid,
  output src_ready,
  output [WIDTH-1:0] src_data
);

  // Internal signals
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
      end else if (DECOUPLED && src_valid_i) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
      end else if (src_ready_o) begin
        src_valid_reg <= 1'b0;
      end
      src_ready_reg <= src_ready_o;
    end
  end

  assign src_data = src_data_reg;
  assign src_valid = src_valid_reg;
  assign src_ready = src_ready_reg;

endmodule

// Destination state machine
module dst_state_machine #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1
)(
  input  dst_valid_o,
  input  dst_ready_i,
  output [WIDTH-1:0] dst_data_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output dst_valid,
  output dst_ready,
  output [WIDTH-1:0] dst_data
);

  // Internal signals
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
    end else begin
      if (dst_valid_o && dst_ready_i) begin
        dst_data_reg <= dst_data_o;
        dst_valid_reg <= 1'b1;
      end else if (DECOUPLED && dst_valid_o) begin
        dst_data_reg <= dst_data_o;
        dst_valid_reg <= 1'b1;
      end else if (dst_ready_i) begin
        dst_valid_reg <= 1'b0;
      end
      dst_ready_reg <= dst_ready_i;
    end
  end

  assign dst_data = dst_data_reg;
  assign dst_valid = dst_valid_reg;
  assign dst_ready = dst_ready_reg;

endmodule

// Sync register
module sync_register #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] src_data,
  output [WIDTH-1:0] dst_data_o,
  input  src_clk_i,
  input  dst_clk_i,
  output [WIDTH-1:0] synced_data
);

  // Internal signals
  logic [WIDTH-1:0] synced_data_reg;

  always_ff @(posedge src_clk_i) begin
    synced_data_reg <= src_data;
  end

  always_ff @(posedge dst_clk_i) begin
    dst_data_o <= synced_data_reg;
  end

endmodule
