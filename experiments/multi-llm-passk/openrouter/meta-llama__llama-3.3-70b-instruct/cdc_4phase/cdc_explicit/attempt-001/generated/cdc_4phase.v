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
  logic src_handshake;

  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic dst_handshake;

  logic src_rst_sync;
  logic dst_rst_sync;

  logic src_rst_sync_n;
  logic dst_rst_sync_n;

  logic src_send_reset_msg;
  logic dst_send_reset_msg;

  // Synchronize source reset to destination clock domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_rst_sync_n <= 1'b1;
      dst_rst_sync <= 1'b0;
    end else begin
      dst_rst_sync_n <= 1'b0;
      dst_rst_sync <= src_rst_ni;
    end
  end

  // Synchronize destination reset to source clock domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_rst_sync_n <= 1'b1;
      src_rst_sync <= 1'b0;
    end else begin
      src_rst_sync_n <= 1'b0;
      src_rst_sync <= dst_rst_ni;
    end
  end

  // Source handshake logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_handshake <= 1'b0;
      src_send_reset_msg <= SEND_RESET_MSG;
    end else begin
      if (src_valid_i && src_ready_reg) begin
        src_valid_reg <= 1'b1;
        src_data_reg <= src_data_i;
        src_handshake <= 1'b1;
      end
      if (src_handshake && src_rst_sync) begin
        src_valid_reg <= 1'b0;
        src_handshake <= 1'b0;
      end
      if (src_send_reset_msg && src_rst_sync) begin
        src_valid_reg <= 1'b1;
        src_data_reg <= RESET_MSG;
        src_send_reset_msg <= 1'b0;
      end
      src_ready_reg <= src_rst_sync;
    end
  end

  // Destination handshake logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_handshake <= 1'b0;
      dst_send_reset_msg <= SEND_RESET_MSG;
    end else begin
      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 1'b0;
        dst_handshake <= 1'b0;
      end
      if (src_handshake && src_rst_sync_n) begin
        dst_valid_reg <= 1'b1;
        dst_data_reg <= src_data_reg;
        dst_handshake <= 1'b1;
      end
      if (dst_send_reset_msg && src_rst_sync_n) begin
        dst_valid_reg <= 1'b1;
        dst_data_reg <= RESET_MSG;
        dst_send_reset_msg <= 1'b0;
      end
      dst_ready_reg <= dst_rst_sync_n;
    end
  end

  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
