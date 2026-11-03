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
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic src_ready_reg;
  logic src_accept;
  logic dst_accept;
  logic reset_flag;

  // Edge detection for source and destination clocks
  logic src_clk_edge;
  logic dst_clk_edge;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clk_edge <= 1'b0;
    end else begin
      src_clk_edge <= 1'b1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clk_edge <= 1'b0;
    end else begin
      dst_clk_edge <= 1'b1;
    end
  end

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_o <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
      end else begin
        src_valid_reg <= 1'b0;
      end
      if (DECOUPLED) begin
        src_ready_o <= dst_ready_i;
      end else begin
        src_ready_o <= (src_valid_i && src_ready_o) ? dst_ready_i : 1'b0;
      end
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
    end else begin
      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 1'b0;
      end else begin
        dst_valid_reg <= src_valid_reg;
      end
      dst_data_reg <= src_data_reg;
      dst_ready_reg <= dst_ready_i;
    end
  end

  // Reset handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni or posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!src_rst_ni || !dst_rst_ni) begin
      reset_flag <= 1'b1;
    end else begin
      reset_flag <= 1'b0;
    end
  end

  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

  // Send reset message if SEND_RESET_MSG is set
  always_ff @(posedge src_clk_i or posedge dst_clk_i) begin
    if (reset_flag && SEND_RESET_MSG) begin
      dst_data_o <= RESET_MSG;
      dst_valid_o <= 1'b1;
    end
  end

endmodule
