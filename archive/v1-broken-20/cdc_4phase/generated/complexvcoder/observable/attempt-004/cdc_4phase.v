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
  logic [WIDTH-1:0] src_sync_data_o;
  logic src_sync_valid_o;
  logic src_sync_ready_o;
  logic [WIDTH-1:0] dst_sync_data_o;
  logic dst_sync_valid_o;
  logic dst_sync_ready_o;
  logic src_handshake_valid;
  logic src_handshake_ready;
  logic dst_handshake_valid;
  logic dst_handshake_ready;

  // Synchronization modules
  sync_module #(.WIDTH(WIDTH)) src_sync (
    .sync_data_o(src_sync_data_o),
    .sync_valid_o(src_sync_valid_o),
    .sync_ready_o(src_sync_ready_o),
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .clk_dst(dst_clk_i),
    .rst_ni_dst(dst_rst_ni)
  );

  sync_module #(.WIDTH(WIDTH)) dst_sync (
    .sync_data_o(dst_sync_data_o),
    .sync_valid_o(dst_sync_valid_o),
    .sync_ready_o(dst_sync_ready_o),
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .clk_dst(src_clk_i),
    .rst_ni_dst(src_rst_ni)
  );

  // Handshake modules
  handshake_module src_handshake (
    .valid(src_valid_i),
    .ready(src_ready_o),
    .clk(src_clk_i),
    .rst_ni(src_rst_ni)
  );

  handshake_module dst_handshake (
    .valid(dst_valid_o),
    .ready(dst_ready_i),
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni)
  );

  // Data transfer logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
    end else begin
      src_ready_o <= dst_sync_ready_o & src_handshake_ready;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
    end else begin
      dst_valid_o <= src_sync_valid_o & dst_handshake_ready;
    end
  end

  assign dst_data_o = src_sync_data_o;

endmodule

module sync_module #(
  parameter WIDTH = 1
)(
  output [WIDTH-1:0] sync_data_o,
  output sync_valid_o,
  input sync_ready_o,
  input [WIDTH-1:0] sync_data_i,
  input sync_valid_i,
  output sync_ready_i,
  input clk,
  input rst_ni,
  input clk_dst,
  input rst_ni_dst
);

  // Internal signals
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  // Synchronization logic
  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      data_reg <= {WIDTH{1'b0}};
      valid_reg <= 1'b0;
    end else begin
      if (sync_valid_i && sync_ready_o) begin
        data_reg <= sync_data_i;
        valid_reg <= sync_valid_i;
      end
    end
  end

  always_ff @(posedge clk_dst or negedge rst_ni_dst) begin
    if (!rst_ni_dst) begin
      ready_reg <= 1'b0;
    end else begin
      ready_reg <= sync_valid_o;
    end
  end

  assign sync_data_o = data_reg;
  assign sync_valid_o = valid_reg;
  assign sync_ready_i = ready_reg;

endmodule

module handshake_module (
  input valid,
  output ready,
  input clk,
  input rst_ni
);

  // Internal signals
  logic handshake_valid;

  // Handshake logic
  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      handshake_valid <= 1'b0;
    end else begin
      if (valid && handshake_valid) begin
        handshake_valid <= 1'b0;
      end else if (valid) begin
        handshake_valid <= 1'b1;
      end
    end
  end

  assign ready = handshake_valid;

endmodule
