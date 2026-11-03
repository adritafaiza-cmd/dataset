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

logic [WIDTH-1:0] src_data;
logic src_valid;
logic src_ready;
logic [WIDTH-1:0] dst_data;
logic dst_valid;
logic dst_ready;

logic src_valid_sync;
logic src_ready_sync;
logic dst_valid_sync;
logic dst_ready_sync;

logic src_valid_pulse;
logic src_ready_pulse;
logic dst_valid_pulse;
logic dst_ready_pulse;

logic src_valid_handshake;
logic src_ready_handshake;
logic dst_valid_handshake;
logic dst_ready_handshake;

logic src_valid_handshake_sync;
logic src_ready_handshake_sync;
logic dst_valid_handshake_sync;
logic dst_ready_handshake_sync;

logic src_valid_handshake_pulse;
logic src_ready_handshake_pulse;
logic dst_valid_handshake_pulse;
logic dst_ready_handshake_pulse;

always_ff @(posedge src_clk_i) begin
  if (~src_rst_ni) begin
    src_valid_sync <= 1'b0;
    src_ready_sync <= 1'b0;
  end else begin
    src_valid_sync <= src_valid_i;
    src_ready_sync <= src_ready_o;
  end
end

always_ff @(posedge src_clk_i) begin
  if (~src_rst_ni) begin
    src_valid_pulse <= 1'b0;
    src_ready_pulse <= 1'b0;
  end else begin
    src_valid_pulse <= src_valid_sync;
    src_ready_pulse <= src_ready_sync;
  end
end

always_ff @(posedge src_clk_i) begin
  if (~src_rst_ni) begin
    src_valid_handshake <= 1'b0;
    src_ready_handshake <= 1'b0;
  end else begin
    src_valid_handshake <= src_valid_pulse;
    src_ready_handshake <= src_ready_pulse;
  end
end

always_ff @(posedge src_clk_i) begin
  if (~src_rst_ni) begin
    src_valid_handshake_sync <= 1'b0;
    src_ready_handshake_sync <= 1'b0;
  end else begin
    src_valid_handshake_sync <= src_valid_handshake;
    src_ready_handshake_sync <= src_ready_handshake;
  end
end

always_ff @(posedge src_clk_i) begin
  if (~src_rst_ni) begin
    src_valid_handshake_pulse <= 1'b0;
    src_ready_handshake_pulse <= 1'b0;
  end else begin
    src_valid_handshake_pulse <= src_valid_handshake_sync;
    src_ready_handshake_pulse <= src_ready_handshake_sync;
  end
end

always_ff @(posedge dst_clk_i) begin
  if (~dst_rst_ni) begin
    dst_valid_sync <= 1'b0;
    dst_ready_sync <= 1'b0;
  end else begin
    dst_valid_sync <= src_valid_handshake_pulse;
    dst_ready_sync <= src_ready_handshake_pulse;
  end
end

always_ff @(posedge dst_clk_i) begin
  if (~dst_rst_ni) begin
    dst_valid_pulse <= 1'b0;
    dst_ready_pulse <= 1'b0;
  end else begin
    dst_valid_pulse <= dst_valid_sync;
    dst_ready_pulse <= dst_ready_sync;
  end
end

always_ff @(posedge dst_clk_i) begin
  if (~dst_rst_ni) begin
    dst_valid_handshake <= 1'b0;
    dst_ready_handshake <= 1'b0;
  end else begin
    dst_valid_handshake <= dst_valid_pulse;
    dst_ready_handshake <= dst_ready_pulse;
  end
end

always_ff @(posedge dst_clk_i) begin
  if (~dst_rst_ni) begin
    dst_valid_handshake_sync <= 1'b0;
    dst_ready_handshake_sync <= 1'b0;
  end else begin
    dst_valid_handshake_sync <= dst_valid_handshake;
    dst_ready_handshake_sync <= dst_ready_handshake;
  end
end

always_ff @(posedge dst_clk_i) begin
  if (~dst_rst_ni) begin
    dst_valid_handshake_pulse <= 1'b0;
    dst_ready_handshake_pulse <= 1'b0;
  end else begin
    dst_valid_handshake_pulse <= dst_valid_handshake_sync;
    dst_ready_handshake_pulse <= dst_ready_handshake_sync;
  end
end

always_ff @(posedge src_clk_i) begin
  if (~src_rst_ni) begin
    src_data <= {WIDTH{1'b0}};
  end else if (src_valid_i && src_ready_o) begin
    src_data <= src_data_i;
  end
end

always_ff @(posedge dst_clk_i) begin
  if (~dst_rst_ni) begin
    dst_data <= {WIDTH{1'b0}};
  end else if (dst_valid_o && dst_ready_i) begin
    dst_data <= dst_data_o;
  end
end

always_comb begin
  src_ready_o = src_ready_handshake_pulse;
  dst_valid_o = dst_valid_handshake_pulse;
  dst_data_o = dst_valid_handshake_pulse? (SEND_RESET_MSG? RESET_MSG : src_data) : {WIDTH{1'b0}};
  dst_valid_o = dst_valid_handshake_pulse;
end

endmodule
