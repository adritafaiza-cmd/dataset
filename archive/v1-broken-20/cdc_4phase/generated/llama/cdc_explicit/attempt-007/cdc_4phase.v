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

  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready_sync;
  logic [WIDTH-1:0] dst_data_sync;
  logic dst_valid_sync;
  logic dst_ready_sync;

  logic src_handshake;
  logic dst_handshake;

  logic src_rst_sync;
  logic dst_rst_sync;

  // Source clock domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_sync <= '0;
      src_valid_sync <= 1'b0;
      src_ready_sync <= 1'b0;
      src_handshake <= 1'b0;
      src_rst_sync <= 1'b0;
    end else begin
      src_rst_sync <= 1'b1;
      if (src_valid_i && src_ready_sync) begin
        src_data_sync <= src_data_i;
        src_valid_sync <= 1'b1;
        src_handshake <= 1'b1;
      end else if (src_handshake && !src_valid_i) begin
        src_valid_sync <= 1'b0;
        src_handshake <= 1'b0;
      end
      if (src_handshake && dst_handshake) begin
        src_ready_sync <= 1'b1;
      end else begin
        src_ready_sync <= 1'b0;
      end
    end
  end

  // Destination clock domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_sync <= '0;
      dst_valid_sync <= 1'b0;
      dst_ready_sync <= 1'b0;
      dst_handshake <= 1'b0;
      dst_rst_sync <= 1'b0;
    end else begin
      dst_rst_sync <= 1'b1;
      if (dst_valid_sync && dst_ready_i) begin
        dst_valid_sync <= 1'b0;
        dst_handshake <= 1'b0;
      end else if (src_handshake && !dst_handshake) begin
        dst_data_sync <= src_data_sync;
        dst_valid_sync <= 1'b1;
        dst_handshake <= 1'b1;
      end
      if (dst_handshake && src_handshake) begin
        dst_ready_sync <= 1'b1;
      end else begin
        dst_ready_sync <= 1'b0;
      end
    end
  end

  // Reset message
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      if (SEND_RESET_MSG) begin
        src_data_sync <= RESET_MSG;
        src_valid_sync <= 1'b1;
      end else begin
        src_data_sync <= '0;
        src_valid_sync <= 1'b0;
      end
    end
  end

  // Decoupled mode
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
    end else if (DECOUPLED) begin
      src_ready_o <= 1'b1;
    end else begin
      src_ready_o <= src_ready_sync;
    end
  end

  // Output assignments
  assign dst_data_o = dst_data_sync;
  assign dst_valid_o = dst_valid_sync;

endmodule
