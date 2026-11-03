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

  // Instantiate the async_fifo module
  async_fifo #(
    .WIDTH(WIDTH)
  ) async_fifo_inst (
    .rst_ni(src_rst_ni),  // Active-low reset, common for both sides
    .clk_wr(src_clk_i),    // Write clock domain
    .data_wr(src_data_i),  // Data to be written
    .valid_wr(src_valid_i),// Data is valid
    .ready_wr(src_ready_o),// Ready to accept data
    .clk_rd(dst_clk_i),    // Read clock domain
    .data_rd(dst_data_o),  // Data read out
    .valid_rd(dst_valid_o),// Data is valid
    .ready_rd(dst_ready_i) // Ready to accept data
  );

endmodule

module async_fifo #(
  parameter WIDTH = 1
)(
  input  rst_ni,
  input  clk_wr,
  input  [WIDTH-1:0] data_wr,
  input  valid_wr,
  output ready_wr,
  input  clk_rd,
  output [WIDTH-1:0] data_rd,
  output valid_rd,
  input  ready_rd
);

  // FIFO depth and pointers
  localparam DEPTH = 4;
  localparam ADDR_WIDTH = $clog2(DEPTH);

  // FIFO memory
  reg [WIDTH-1:0] fifo_memory [0:DEPTH-1];

  // Write and read pointers
  reg [ADDR_WIDTH:0] wr_ptr;
  reg [ADDR_WIDTH:0] rd_ptr;

  // FIFO flags
  reg [ADDR_WIDTH:0] wr_ptr_gray;
  reg [ADDR_WIDTH:0] rd_ptr_gray;

  // FIFO control signals
  wire full;
  wire empty;

  // Gray code conversion functions
  function [ADDR_WIDTH:0] bin2gray;
    input [ADDR_WIDTH:0] bin;
    bin2gray = (bin >> 1) ^ bin;
  endfunction

  // Write pointer logic
  always @(posedge clk_wr or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end else if (!full && valid_wr) begin
      fifo_memory[wr_ptr[ADDR_WIDTH-1:0]] <= data_wr;
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= bin2gray(wr_ptr + 1);
    end
  end

  // Read pointer logic
  always @(posedge clk_rd or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end else if (!empty && ready_rd) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= bin2gray(rd_ptr + 1);
    end
  end

  // Full and empty flags
  assign full = (wr_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1] != rd_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1]) && (wr_ptr_gray[ADDR_WIDTH-2:0] == rd_ptr_gray[ADDR_WIDTH-2:0]);
  assign empty = (wr_ptr_gray == rd_ptr_gray);

  // Read data and valid signal
  assign data_rd = fifo_memory[rd_ptr[ADDR_WIDTH-1:0]];
  assign valid_rd = !empty;

  // Ready signal for writer
  assign ready_wr = !full;

endmodule
