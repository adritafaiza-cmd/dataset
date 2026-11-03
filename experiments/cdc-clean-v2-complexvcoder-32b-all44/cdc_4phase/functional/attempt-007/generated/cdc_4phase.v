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
  logic src_ready;
  logic dst_valid;
  logic [WIDTH-1:0] data_buffer;
  logic [WIDTH-1:0] src_data_sync;
  logic [WIDTH-1:0] dst_data_sync;
  logic reset_msg_sent;

  // Source-side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 1'b0;
      data_buffer <= RESET_MSG;
      reset_msg_sent <= 1'b0;
    end else begin
      if (src_valid_i && src_ready) begin
        data_buffer <= src_data_i;
      end

      if (SEND_RESET_MSG && !reset_msg_sent) begin
        data_buffer <= RESET_MSG;
        reset_msg_sent <= 1'b1;
      end

      src_ready <= DECOUPLED || !dst_valid;
    end
  end

  // Synchronize data to destination domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= RESET_MSG;
    end else begin
      src_data_sync <= data_buffer;
    end
  end

  // Destination-side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid <= 1'b0;
      dst_data_sync <= RESET_MSG;
    end else begin
      if (src_valid_i && src_ready) begin
        dst_valid <= 1'b1;
        dst_data_sync <= src_data_sync;
      end else if (dst_valid && dst_ready_i) begin
        dst_valid <= 1'b0;
      end
    end
  end

  // Output assignments
  assign src_ready_o = src_ready;
  assign dst_data_o = dst_data_sync;
  assign dst_valid_o = dst_valid;

endmodule
