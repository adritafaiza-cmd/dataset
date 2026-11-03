module cdc_2phase #(
  parameter WIDTH = 1
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

  logic src_valid_sync;
  logic src_valid_sync2;
  logic src_valid_sync3;
  logic src_valid_sync4;
  logic [WIDTH-1:0] src_data_sync;
  logic [WIDTH-1:0] src_data_sync2;
  logic [WIDTH-1:0] src_data_sync3;
  logic [WIDTH-1:0] src_data_sync4;

  logic dst_valid;
  logic dst_valid2;
  logic dst_valid3;
  logic [WIDTH-1:0] dst_data;
  logic [WIDTH-1:0] dst_data2;
  logic [WIDTH-1:0] dst_data3;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_valid_sync2 <= 1'b0;
      src_valid_sync3 <= 1'b0;
      src_valid_sync4 <= 1'b0;
      src_data_sync <= '0;
      src_data_sync2 <= '0;
      src_data_sync3 <= '0;
      src_data_sync4 <= '0;
    end else begin
      src_valid_sync <= src_valid_i;
      src_valid_sync2 <= src_valid_sync;
      src_valid_sync3 <= src_valid_sync2;
      src_valid_sync4 <= src_valid_sync3;
      src_data_sync <= src_data_i;
      src_data_sync2 <= src_data_sync;
      src_data_sync3 <= src_data_sync2;
      src_data_sync4 <= src_data_sync3;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid <= 1'b0;
      dst_valid2 <= 1'b0;
      dst_valid3 <= 1'b0;
      dst_data <= '0;
      dst_data2 <= '0;
      dst_data3 <= '0;
    end else begin
      dst_valid <= src_valid_sync4;
      dst_valid2 <= dst_valid;
      dst_valid3 <= dst_valid2;
      dst_data <= src_data_sync4;
      dst_data2 <= dst_data;
      dst_data3 <= dst_data2;
    end
  end

  assign dst_valid_o = dst_valid3;
  assign dst_data_o = dst_data3;

  assign src_ready_o = !src_valid_sync3 || dst_valid;

endmodule
