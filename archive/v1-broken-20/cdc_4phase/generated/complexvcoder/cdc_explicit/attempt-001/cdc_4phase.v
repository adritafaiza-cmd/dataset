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
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [1:0] phase_reg;

  // Synchronization modules
  sync_module #(.WIDTH(WIDTH)) src_sync (
    .sync_rst_ni(src_rst_ni),
    .sync_clk_i(src_clk_i),
    .sync_data_i(src_data_i),
    .sync_valid_i(src_valid_i),
    .sync_ready_o(src_ready_reg)
  );

  sync_module #(.WIDTH(WIDTH)) dst_sync (
    .sync_rst_ni(dst_rst_ni),
    .sync_clk_i(dst_clk_i),
    .sync_data_i(dst_data_reg),
    .sync_valid_i(dst_valid_reg),
    .sync_ready_o(dst_ready_reg)
  );

  // Four-phase channel
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      phase_reg <= 2'b00;
    end else begin
      if (src_valid_i && src_ready_reg) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
        phase_reg <= 2'b00;
      end else if (phase_reg < 2'b11) begin
        phase_reg <= phase_reg + 1'b1;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      phase_reg <= 2'b00;
    end else begin
      if (dst_ready_i && dst_valid_reg) begin
        dst_valid_reg <= 1'b0;
        phase_reg <= 2'b00;
      end else if (phase_reg < 2'b11) begin
        phase_reg <= phase_reg + 1'b1;
      end
    end
  end

  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule

module sync_module #(
  parameter WIDTH = 1
)(
  input  sync_rst_ni,
  input  sync_clk_i,
  input  [WIDTH-1:0] sync_data_i,
  input  sync_valid_i,
  output sync_ready_o
);

  // Internal signals
  logic [WIDTH-1:0] sync_data_reg;
  logic sync_valid_reg;
  logic sync_ready_reg;

  always_ff @(posedge sync_clk_i or negedge sync_rst_ni) begin
    if (!sync_rst_ni) begin
      sync_data_reg <= {WIDTH{1'b0}};
      sync_valid_reg <= 1'b0;
      sync_ready_reg <= 1'b1;
    end else begin
      sync_data_reg <= sync_data_i;
      sync_valid_reg <= sync_valid_i;
      sync_ready_reg <= sync_valid_i ? 1'b0 : sync_ready_reg;
    end
  end

  assign sync_ready_o = sync_ready_reg;

endmodule
