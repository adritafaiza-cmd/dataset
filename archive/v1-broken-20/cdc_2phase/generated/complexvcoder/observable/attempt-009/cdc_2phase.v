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
  logic [WIDTH-1:0] data_sync;
  logic valid_sync;
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  // Synchronization logic
  src_to_sync src_to_sync_inst (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o)
  );

  ff_sync ff_sync_inst (
    .clk_i(src_clk_i),
    .dst_clk_i(dst_clk_i),
    .data_o(data_sync),
    .valid_o(valid_sync)
  );

  sync_to_dst sync_to_dst_inst (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .src_data_i(data_sync),
    .src_valid_i(valid_sync),
    .src_ready_o(ready_reg),
    .dst_data_o(dst_data_o),
    .dst_valid_o(dst_valid_o),
    .dst_ready_i(dst_ready_i)
  );

endmodule

module src_to_sync (
  input rst_ni,
  input clk_i,
  input [WIDTH-1:0] data_i,
  input valid_i,
  output ready_o
);

  // Internal signals
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_reg <= 0;
      valid_reg <= 0;
      ready_reg <= 1;
    end else begin
      if (ready_reg && valid_i) begin
        data_reg <= data_i;
        valid_reg <= 1;
        ready_reg <= 0;
      end else if (!ready_reg) begin
        ready_reg <= 1;
      end
    end
  end

  assign ready_o = ready_reg;

endmodule

module sync_to_dst (
  input rst_ni,
  input clk_i,
  input [WIDTH-1:0] src_data_i,
  input src_valid_i,
  input src_ready_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input dst_ready_i
);

  // Internal signals
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_reg <= 0;
      valid_reg <= 0;
    end else begin
      if (src_valid_i && src_ready_o && dst_ready_i) begin
        data_reg <= src_data_i;
        valid_reg <= 1;
      end else begin
        valid_reg <= 0;
      end
    end
  end

  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;

endmodule

module ff_sync (
  input clk_i,
  input dst_clk_i,
  output [WIDTH-1:0] data_o,
  output valid_o
);

  // Internal signals
  logic [WIDTH-1:0] data_ff;
  logic valid_ff;

  always_ff @(posedge clk_i) begin
    if (valid_ff) begin
      data_o <= data_ff;
    end
  end

  always_ff @(posedge dst_clk_i) begin
    if (valid_ff) begin
      valid_o <= 1;
    end else begin
      valid_o <= 0;
    end
  end

  assign data_ff = data_o;
  assign valid_ff = valid_o;

endmodule
