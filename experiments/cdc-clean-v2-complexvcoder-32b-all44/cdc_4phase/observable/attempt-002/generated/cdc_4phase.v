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

  // Internal signals for the FIFO
  logic [WIDTH-1:0] fifo_data;
  logic fifo_valid;
  logic fifo_ready;

  // Synchronizer flip-flops for valid and ready signals
  logic sync_src_valid;
  logic sync_src_ready;
  logic sync_dst_valid;
  logic sync_dst_ready;

  // Synchronize src_valid_i to dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_src_valid <= 1'b0;
    end else begin
      sync_src_valid <= src_valid_i;
    end
  end

  // Synchronize dst_ready_i to src_clk_i
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_dst_ready <= 1'b0;
    end else begin
      sync_dst_ready <= dst_ready_i;
    end
  end

  // Synchronize sync_src_valid to src_clk_i
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_src_ready <= 1'b0;
    end else begin
      sync_src_ready <= sync_src_valid;
    end
  end

  // Synchronize sync_dst_ready to dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_dst_valid <= 1'b0;
    end else begin
      sync_dst_valid <= sync_dst_ready;
    end
  end

  // FIFO logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      fifo_data <= RESET_MSG;
      fifo_valid <= 1'b0;
    end else if (src_valid_i && sync_dst_ready && !fifo_valid) begin
      fifo_data <= src_data_i;
      fifo_valid <= 1'b1;
    end else if (sync_dst_valid && fifo_valid) begin
      fifo_valid <= 1'b0;
    end
  end

  // FIFO ready signal
  assign fifo_ready = !fifo_valid || (sync_dst_ready && !fifo_valid);

  // Source side handshake
  assign src_ready_o = fifo_ready;

  // Destination side handshake
  assign dst_data_o = fifo_data;
  assign dst_valid_o = fifo_valid;

endmodule
