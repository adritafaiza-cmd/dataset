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

  logic [WIDTH-1:0] async_fifo_mem [3:0];
  logic [1:0] src_gray, src_bin, dst_gray, dst_bin;
  logic src_wren, src_empty, dst_rden, dst_full;

  // Gray code counters for source and destination
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_gray <= 2'b00;
    else if (src_wren && !src_empty)
      src_gray <= src_gray + 1;
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_gray <= 2'b00;
    else if (dst_rden && !dst_full)
      dst_gray <= dst_gray + 1;
  end

  // Binary conversion
  assign src_bin = {src_gray[1] ^ src_gray[0], src_gray[0]};
  assign dst_bin = {dst_gray[1] ^ dst_gray[0], dst_gray[0]};

  // FIFO control signals
  assign src_wren = src_valid_i && src_ready_o;
  assign dst_rden = dst_valid_o && dst_ready_i;

  // FIFO empty and full conditions
  assign src_empty = (src_gray == dst_gray);
  assign dst_full = (src_gray == {dst_gray[1], ~dst_gray[0]});

  // FIFO memory write
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      async_fifo_mem[src_bin] <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
    else if (src_wren && !src_empty)
      async_fifo_mem[src_bin] <= src_data_i;
  end

  // FIFO memory read
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_data_o <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
    else if (dst_rden && !dst_full)
      dst_data_o <= async_fifo_mem[dst_bin];
  end

  // Source ready output
  assign src_ready_o = DECOUPLED ? ~src_empty : ~src_full;

  // Destination valid output
  assign dst_valid_o = ~dst_empty;

endmodule
