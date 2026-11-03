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

  // Internal signals for synchronization
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;

  // Synchronization flip-flops for src_clk_i domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= RESET_MSG;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
    end else begin
      src_data_reg <= src_data_i;
      src_valid_reg <= src_valid_i;
      src_ready_reg <= dst_ready_i;
    end
  end

  // Synchronization flip-flops for dst_clk_i domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= RESET_MSG;
      dst_valid_o <= 1'b0;
    end else begin
      dst_data_o <= src_data_reg;
      dst_valid_o <= src_valid_reg;
    end
  end

  // Handshake logic for src_clk_i domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b1;
    end else begin
      if (src_valid_i && dst_ready_i) begin
        src_ready_reg <= 1'b0;
      end else begin
        src_ready_reg <= 1'b1;
      end
    end
  end

endmodule
