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

  // Synchronize source reset
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_rst_sync <= 1'b1;
    end else begin
      src_rst_sync <= 1'b0;
    end
  end

  // Synchronize destination reset
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_rst_sync <= 1'b1;
    end else begin
      dst_rst_sync <= 1'b0;
    end
  end

  // Source handshake
  always_ff @(posedge src_clk_i) begin
    if (src_rst_sync) begin
      src_handshake <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_handshake <= 1'b1;
    end else if (src_handshake && !src_valid_i) begin
      src_handshake <= 1'b0;
    end
  end

  // Destination handshake
  always_ff @(posedge dst_clk_i) begin
    if (dst_rst_sync) begin
      dst_handshake <= 1'b0;
    end else if (dst_valid_o && dst_ready_i) begin
      dst_handshake <= 1'b1;
    end else if (dst_handshake && !dst_valid_o) begin
      dst_handshake <= 1'b0;
    end
  end

  // Source data synchronization
  always_ff @(posedge src_clk_i) begin
    if (src_rst_sync) begin
      src_data_sync <= RESET_MSG;
    end else if (src_valid_i && src_ready_o) begin
      src_data_sync <= src_data_i;
    end
  end

  // Source valid synchronization
  always_ff @(posedge src_clk_i) begin
    if (src_rst_sync) begin
      src_valid_sync <= SEND_RESET_MSG;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_sync <= 1'b1;
    end else if (src_handshake && !src_valid_i) begin
      src_valid_sync <= 1'b0;
    end
  end

  // Source ready generation
  always_ff @(posedge src_clk_i) begin
    if (src_rst_sync) begin
      src_ready_o <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_ready_o <= 1'b0;
    end else if (src_handshake && !src_valid_i) begin
      src_ready_o <= 1'b1;
    end else if (DECOUPLED && !src_valid_sync) begin
      src_ready_o <= 1'b1;
    end
  end

  // Destination data synchronization
  always_ff @(posedge dst_clk_i) begin
    if (dst_rst_sync) begin
      dst_data_sync <= RESET_MSG;
    end else if (dst_valid_o && dst_ready_i) begin
      dst_data_sync <= dst_data_o;
    end
  end

  // Destination valid synchronization
  always_ff @(posedge dst_clk_i) begin
    if (dst_rst_sync) begin
      dst_valid_sync <= SEND_RESET_MSG;
    end else if (dst_valid_o && dst_ready_i) begin
      dst_valid_sync <= 1'b1;
    end else if (dst_handshake && !dst_valid_o) begin
      dst_valid_sync <= 1'b0;
    end
  end

  // Destination valid generation
  always_ff @(posedge dst_clk_i) begin
    if (dst_rst_sync) begin
      dst_valid_o <= 1'b0;
    end else if (dst_valid_sync && !dst_ready_i) begin
      dst_valid_o <= 1'b1;
    end else if (dst_handshake && dst_ready_i) begin
      dst_valid_o <= 1'b0;
    end
  end

  // Destination data generation
  always_ff @(posedge dst_clk_i) begin
    if (dst_rst_sync) begin
      dst_data_o <= RESET_MSG;
    end else if (dst_valid_sync && !dst_ready_i) begin
      dst_data_o <= src_data_sync;
    end
  end

  // Destination ready synchronization
  always_ff @(posedge dst_clk_i) begin
    if (dst_rst_sync) begin
      dst_ready_sync <= 1'b0;
    end else if (dst_ready_i) begin
      dst_ready_sync <= 1'b1;
    end else if (!dst_ready_i) begin
      dst_ready_sync <= 1'b0;
    end
  end

endmodule
