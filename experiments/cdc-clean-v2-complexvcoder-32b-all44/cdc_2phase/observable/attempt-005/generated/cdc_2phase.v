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

  // Instantiate the asynchronous FIFO
  fifo #(
    .WIDTH(WIDTH),
    .DEPTH(4)
  ) async_fifo (
    .rst_ni(src_rst_ni),
    .wr_clk_i(src_clk_i),
    .wr_data_i(src_data_i),
    .wr_valid_i(src_valid_i),
    .wr_ready_o(src_ready_o),
    .rd_clk_i(dst_clk_i),
    .rd_rst_ni(dst_rst_ni),
    .rd_data_o(dst_data_o),
    .rd_valid_o(dst_valid_o),
    .rd_ready_i(dst_ready_i)
  );

endmodule

module fifo #(
  parameter WIDTH = 1,
  parameter DEPTH = 4
)(
  input  rst_ni,
  input  wr_clk_i,
  input  [WIDTH-1:0] wr_data_i,
  input  wr_valid_i,
  output wr_ready_o,
  input  rd_clk_i,
  input  rd_rst_ni,
  output [WIDTH-1:0] rd_data_o,
  output rd_valid_o,
  input  rd_ready_i
);

  localparam ADDR_WIDTH = $clog2(DEPTH);

  // FIFO memory
  reg [WIDTH-1:0] fifo_mem [0:DEPTH-1];

  // Write and read pointers
  reg [ADDR_WIDTH-1:0] wr_ptr;
  reg [ADDR_WIDTH-1:0] rd_ptr;

  // Gray-coded pointers
  reg [ADDR_WIDTH-1:0] wr_ptr_gray;
  reg [ADDR_WIDTH-1:0] rd_ptr_gray;

  // Synchronized gray-coded pointers
  reg [ADDR_WIDTH-1:0] wr_ptr_gray_sync;
  reg [ADDR_WIDTH-1:0] rd_ptr_gray_sync;

  // FIFO status
  wire fifo_full;
  wire fifo_empty;

  // Write pointer logic
  always @(posedge wr_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end else if (wr_valid_i && !fifo_full) begin
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= wr_ptr_gray + 1;
      fifo_mem[wr_ptr] <= wr_data_i;
    end
  end

  // Read pointer logic
  always @(posedge rd_clk_i or negedge rd_rst_ni) begin
    if (!rd_rst_ni) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end else if (rd_valid_o && rd_ready_i) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= rd_ptr_gray + 1;
    end
  end

  // Synchronize write pointer gray code to read clock domain
  always @(posedge rd_clk_i or negedge rd_rst_ni) begin
    if (!rd_rst_ni) begin
      wr_ptr_gray_sync <= 0;
    end else begin
      wr_ptr_gray_sync <= wr_ptr_gray;
    end
  end

  // Synchronize read pointer gray code to write clock domain
  always @(posedge wr_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_ptr_gray_sync <= 0;
    end else begin
      rd_ptr_gray_sync <= rd_ptr_gray;
    end
  end

  // FIFO status logic
  assign fifo_full = (wr_ptr_gray_sync ^ wr_ptr_gray) == {ADDR_WIDTH{1'b1}};
  assign fifo_empty = (rd_ptr_gray_sync ^ rd_ptr_gray) == {ADDR_WIDTH{1'b0}};

  // Ready and valid signals
  assign wr_ready_o = !fifo_full;
  assign rd_valid_o = !fifo_empty;

  // Data output
  assign rd_data_o = fifo_mem[rd_ptr];

endmodule
