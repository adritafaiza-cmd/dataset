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
  logic [WIDTH-1:0] src_reg_data;
  logic src_reg_valid;
  logic dst_reg_valid;
  logic src_to_dst_valid;
  logic src_to_dst_ready;
  logic reset_handler_valid;
  logic reset_handler_ready;
  logic [WIDTH-1:0] reset_handler_data;

  // Source register
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_reg_data <= {WIDTH{1'b0}};
      src_reg_valid <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_reg_data <= src_data_i;
        src_reg_valid <= 1'b1;
      end else begin
        src_reg_valid <= 1'b0;
      end
    end
  end

  // Destination register
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_reg_valid <= 1'b0;
    end else begin
      dst_reg_valid <= src_to_dst_valid && dst_ready_i;
    end
  end

  // Source to Destination transfer
  assign src_to_dst_valid = src_reg_valid && dst_ready_i;
  assign src_to_dst_ready = dst_reg_valid && src_to_dst_valid;
  assign dst_data_o = src_to_dst_valid ? src_reg_data : RESET_MSG;

  // Reset handler
  always_ff @(posedge src_clk_i or negedge src_rst_ni or posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!src_rst_ni || !dst_rst_ni) begin
      reset_handler_valid <= 1'b0;
    end else begin
      reset_handler_valid <= 1'b1;
    end
  end

  assign reset_handler_ready = src_to_dst_ready && dst_reg_valid;
  assign reset_handler_data = RESET_MSG;

  // Output ports
  assign src_ready_o = src_to_dst_ready;

endmodule
