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
  logic dst_valid_sync;
  logic dst_ready_sync;
  logic [WIDTH-1:0] dst_data_sync;
  logic [1:0] src_handshake;
  logic [1:0] dst_handshake;

  // Source domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_handshake <= 2'b00;
      src_ready_sync <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_sync) begin
        src_handshake <= src_handshake + 1'b1;
      end
      if (src_handshake == 2'b11) begin
        src_handshake <= 2'b00;
      end
      src_ready_sync <= (src_handshake == 2'b00) && (dst_valid_sync == 1'b0);
    end
  end

  // Source domain data and valid
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_sync <= RESET_MSG;
      src_valid_sync <= SEND_RESET_MSG;
    end else if (src_valid_i && src_ready_sync) begin
      src_data_sync <= src_data_i;
      src_valid_sync <= 1'b1;
    end else if (src_handshake == 2'b11) begin
      src_valid_sync <= 1'b0;
    end
  end

  // Destination domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_handshake <= 2'b00;
      dst_valid_sync <= SEND_RESET_MSG;
      dst_data_sync <= RESET_MSG;
    end else begin
      if (dst_valid_sync && dst_ready_i) begin
        dst_handshake <= dst_handshake + 1'b1;
      end
      if (dst_handshake == 2'b11) begin
        dst_handshake <= 2'b00;
      end
      dst_valid_sync <= (dst_handshake == 2'b00) && (src_valid_sync == 1'b1);
    end
  end

  // Destination domain data
  always_ff @(posedge dst_clk_i) begin
    if (dst_valid_sync &&!dst_ready_i) begin
      dst_data_sync <= dst_data_sync;
    end else if (dst_valid_sync) begin
      dst_data_sync <= src_data_sync;
    end
  end

  // Output assignments
  assign src_ready_o = src_ready_sync;
  assign dst_data_o = dst_data_sync;
  assign dst_valid_o = dst_valid_sync;

  // Cross-domain signals
  logic src_valid_sync_ff1;
  logic src_valid_sync_ff2;
  logic src_data_sync_ff1;
  logic src_data_sync_ff2;

  always_ff @(posedge dst_clk_i) begin
    src_valid_sync_ff1 <= src_valid_sync;
    src_valid_sync_ff2 <= src_valid_sync_ff1;
    src_data_sync_ff1 <= src_data_sync;
    src_data_sync_ff2 <= src_data_sync_ff1;
  end

  assign dst_valid_sync = src_valid_sync_ff2;
  assign dst_data_sync <= src_data_sync_ff2;

  logic dst_ready_sync_ff1;
  logic dst_ready_sync_ff2;

  always_ff @(posedge src_clk_i) begin
    dst_ready_sync_ff1 <= dst_ready_i;
    dst_ready_sync_ff2 <= dst_ready_sync_ff1;
  end

  assign src_ready_sync <= (dst_ready_sync_ff2 &&!DECOUPLED) || (dst_valid_sync == 1'b0);

endmodule
