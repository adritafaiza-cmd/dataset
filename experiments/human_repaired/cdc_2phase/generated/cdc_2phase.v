// Functionally correct 2-phase handshake with intentional CDC unsafety:
// req/ack/data cross clocks with no synchronizer and no reset sync.
module cdc_2phase #(
  parameter WIDTH = 1
)(
  input                  src_rst_ni,
  input                  src_clk_i,
  input      [WIDTH-1:0] src_data_i,
  input                  src_valid_i,
  output                 src_ready_o,

  input                  dst_rst_ni,
  input                  dst_clk_i,
  output     [WIDTH-1:0] dst_data_o,
  output                 dst_valid_o,
  input                  dst_ready_i
);

  reg [WIDTH-1:0] data_reg;
  reg             src_req;
  reg             dst_ack;

  assign src_ready_o = src_rst_ni && (src_req == dst_ack);
  assign dst_valid_o = dst_rst_ni && (src_req != dst_ack);
  assign dst_data_o  = data_reg;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req  <= 1'b0;
      data_reg <= {WIDTH{1'b0}};
    end else if (src_valid_i && src_ready_o) begin
      data_reg <= src_data_i;
      src_req  <= ~src_req;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_ack <= 1'b0;
    else if (dst_valid_o && dst_ready_i)
      dst_ack <= ~dst_ack;
  end

endmodule
