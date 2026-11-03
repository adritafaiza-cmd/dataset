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

  reg src_ready;
  reg dst_valid;
  reg dst_ready;
  reg [WIDTH-1:0] data_buffer;
  reg valid_buffer;
  reg ready_buffer;
  reg reset_flag;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 0;
      data_buffer <= {WIDTH{1'b0}};
      valid_buffer <= 0;
      ready_buffer <= 0;
      reset_flag <= SEND_RESET_MSG;
    end else begin
      if (src_valid_i && src_ready_o) begin
        data_buffer <= src_data_i;
        valid_buffer <= 1;
        src_ready <= DECOUPLED ? 1 : 0;
      end else if (DECOUPLED) begin
        src_ready <= 1;
      end
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid <= 0;
      valid_buffer <= 0;
      ready_buffer <= 0;
      reset_flag <= SEND_RESET_MSG;
    end else begin
      if (dst_ready_i && valid_buffer) begin
        dst_data_o <= data_buffer;
        dst_valid <= 1;
        valid_buffer <= 0;
      end
      if (!dst_ready_i) begin
        dst_data_o <= data_buffer;
      end
    end
  end

  assign src_ready_o = src_ready;
  assign dst_valid_o = dst_valid;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      reset_flag <= SEND_RESET_MSG;
    end else if (reset_flag) begin
      dst_valid_o <= 0;
      src_ready <= 0;
      reset_flag <= 0;
    end
  end

endmodule
