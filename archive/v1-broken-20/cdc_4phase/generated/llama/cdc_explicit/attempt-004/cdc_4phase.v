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

  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic [1:0] src_handshake_reg;

  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [1:0] dst_handshake_reg;

  logic src_rst_sync;
  logic dst_rst_sync;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_handshake_reg <= '0;
      src_rst_sync <= 1'b0;
    end else begin
      src_rst_sync <= 1'b1;
      if (src_handshake_reg == 2'b01) begin
        src_handshake_reg <= 2'b10;
      end else if (src_valid_i && src_ready_reg) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
        src_handshake_reg <= 2'b01;
      end
      if (src_handshake_reg == 2'b10 && ~dst_valid_reg) begin
        src_ready_reg <= 1'b1;
      end else if (src_handshake_reg == 2'b10 && dst_valid_reg && dst_ready_i) begin
        src_ready_reg <= 1'b0;
        src_handshake_reg <= '0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
      dst_handshake_reg <= '0;
      dst_rst_sync <= 1'b0;
    end else begin
      dst_rst_sync <= 1'b1;
      if (dst_handshake_reg == 2'b01) begin
        dst_handshake_reg <= 2'b10;
      end else if (src_valid_reg && ~dst_valid_reg) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
        dst_handshake_reg <= 2'b01;
      end
      if (dst_handshake_reg == 2'b10&& dst_ready_i) begin
        dst_valid_reg <= 1'b0;
        dst_handshake_reg <= '0;
      end
    end
  end

  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Reset message handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      if (SEND_RESET_MSG) begin
        src_data_reg <= RESET_MSG;
        src_valid_reg <= 1'b1;
      end else begin
        src_data_reg <= '0;
        src_valid_reg <= 1'b0;
      end
    end
  end

  // CDC synchronization
  logic src_valid_sync;
  logic src_data_sync [WIDTH-1:0];

  always_ff @(posedge dst_clk_i) begin
    src_valid_sync <= src_valid_reg;
    src_data_sync <= src_data_reg;
  end

  assign dst_data_reg = src_data_sync;
  assign dst_valid_reg = src_valid_sync;

endmodule
