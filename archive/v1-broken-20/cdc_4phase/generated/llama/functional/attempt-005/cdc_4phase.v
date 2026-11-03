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
  logic dst_valid_reg;
  logic dst_data_reg_valid;
  logic [WIDTH-1:0] dst_data_reg;

  logic src_rst_sync;
  logic dst_rst_sync;

  logic src_handshake;
  logic dst_handshake;

  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_ready_reg <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_reg) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
      end else if (src_handshake) begin
        src_valid_reg <= 1'b0;
      end
      if (src_handshake || (DECOUPLED && src_valid_i)) begin
        src_ready_reg <= 1'b1;
      end else if (!src_valid_i) begin
        src_ready_reg <= 1'b0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_data_reg_valid <= 1'b0;
      if (SEND_RESET_MSG) begin
        dst_data_reg <= RESET_MSG;
        dst_data_reg_valid <= 1'b1;
      end
    end else begin
      if (dst_handshake) begin
        dst_data_reg_valid <= 1'b0;
      end
      if (src_handshake &&!dst_valid_reg) begin
        dst_data_reg <= src_data_reg;
        dst_data_reg_valid <= 1'b1;
      end
      if (dst_data_reg_valid && dst_ready_i) begin
        dst_valid_reg <= 1'b1;
      end else if (dst_handshake) begin
        dst_valid_reg <= 1'b0;
      end
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_rst_sync <= 1'b0;
    end else begin
      src_rst_sync <=!dst_rst_ni;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_rst_sync <= 1'b0;
    end else begin
      dst_rst_sync <=!src_rst_ni;
    end
  end

  assign src_handshake = src_valid_reg &&!src_rst_sync &&!dst_rst_sync;
  assign dst_handshake = dst_valid_reg && dst_ready_i &&!src_rst_sync &&!dst_rst_sync;

endmodule
