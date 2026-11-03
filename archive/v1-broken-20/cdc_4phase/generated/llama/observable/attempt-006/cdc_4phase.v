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

  reg [WIDTH-1:0] src_data;
  reg src_valid;
  reg [WIDTH-1:0] dst_data;
  reg dst_valid;

  reg src_ready;
  reg dst_ready;

  reg [WIDTH-1:0] src_data_pipe;
  reg src_valid_pipe;
  reg [WIDTH-1:0] dst_data_pipe;
  reg dst_valid_pipe;

  reg [WIDTH-1:0] src_data_pipe2;
  reg src_valid_pipe2;
  reg [WIDTH-1:0] dst_data_pipe2;
  reg dst_valid_pipe2;

  reg [WIDTH-1:0] src_data_pipe3;
  reg src_valid_pipe3;
  reg [WIDTH-1:0] dst_data_pipe3;
  reg dst_valid_pipe3;

  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      src_data <= '0;
      src_valid <= 1'b0;
      src_ready <= 1'b0;
      src_data_pipe <= '0;
      src_valid_pipe <= 1'b0;
      src_data_pipe2 <= '0;
      src_valid_pipe2 <= 1'b0;
      src_data_pipe3 <= '0;
      src_valid_pipe3 <= 1'b0;
    end else begin
      if (src_valid_i && src_ready) begin
        src_data <= src_data_i;
        src_valid <= 1'b1;
      end
      if (src_valid && src_ready) begin
        src_valid <= 1'b0;
      end
      if (src_valid && src_ready) begin
        src_data_pipe <= src_data;
        src_valid_pipe <= 1'b1;
      end
      if (src_valid_pipe && src_ready) begin
        src_valid_pipe <= 1'b0;
      end
      if (src_valid_pipe && src_ready) begin
        src_data_pipe2 <= src_data_pipe;
        src_valid_pipe2 <= 1'b1;
      end
      if (src_valid_pipe2 && src_ready) begin
        src_valid_pipe2 <= 1'b0;
      end
      if (src_valid_pipe2 && src_ready) begin
        src_data_pipe3 <= src_data_pipe2;
        src_valid_pipe3 <= 1'b1;
      end
      if (src_valid_pipe3 && src_ready) begin
        src_valid_pipe3 <= 1'b0;
      end
      src_ready <= src_valid_i? src_ready : 1'b1;
    end
  end

  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      dst_data <= '0;
      dst_valid <= 1'b0;
      dst_ready <= 1'b0;
      dst_data_pipe <= '0;
      dst_valid_pipe <= 1'b0;
      dst_data_pipe2 <= '0;
      dst_valid_pipe2 <= 1'b0;
      dst_data_pipe3 <= '0;
      dst_valid_pipe3 <= 1'b0;
    end else begin
      if (dst_valid && dst_ready) begin
        dst_valid <= 1'b0;
      end
      if (dst_valid && dst_ready) begin
        dst_data_pipe <= dst_data;
        dst_valid_pipe <= 1'b1;
      end
      if (dst_valid_pipe && dst_ready) begin
        dst_valid_pipe <= 1'b0;
      end
      if (dst_valid_pipe && dst_ready) begin
        dst_data_pipe2 <= dst_data_pipe;
        dst_valid_pipe2 <= 1'b1;
      end
      if (dst_valid_pipe2 && dst_ready) begin
        dst_valid_pipe2 <= 1'b0;
      end
      if (dst_valid_pipe2 && dst_ready) begin
        dst_data_pipe3 <= dst_data_pipe2;
        dst_valid_pipe3 <= 1'b1;
      end
      if (dst_valid_pipe3 && dst_ready) begin
        dst_valid_pipe3 <= 1'b0;
      end
      dst_ready <= dst_valid? dst_ready : 1'b1;
    end
  end

  assign src_ready_o = src_ready;
  assign dst_data_o = dst_data;
  assign dst_valid_o = dst_valid;

  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      src_data <= SEND_RESET_MSG? RESET_MSG : '0;
      src_valid <= SEND_RESET_MSG? 1'b1 : 1'b0;
    end else begin
      src_data <= src_data_i;
      src_valid <= src_valid_i;
    end
  end

  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      dst_data <= SEND_RESET_MSG? RESET_MSG : '0;
      dst_valid <= SEND_RESET_MSG? 1'b1 : 1'b0;
    end else begin
      dst_data <= dst_data_pipe3;
      dst_valid <= dst_valid_pipe3;
    end
  end

endmodule
