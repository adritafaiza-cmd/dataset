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
    .WIDTH(WIDTH),
    .DEPTH(8)
  ) async_fifo_inst (
    .rst_ni    (src_rst_ni & dst_rst_ni), // Active-low reset
    .write_clk_i(src_clk_i),
    .data_i    (src_data_i),
    .write_en_i(src_valid_i),
    .full_o    (src_ready_o),
    .read_clk_i(dst_clk_i),
    .data_o    (dst_data_o),
    .valid_o   (dst_valid_o),
    .read_en_i (dst_ready_i)
  );

endmodule

module async_fifo #(
  parameter WIDTH = 1,
  parameter DEPTH = 8
)(
  input  rst_ni,
  input  write_clk_i,
  input  [WIDTH-1:0] data_i,
  input  write_en_i,
  output full_o,
  input  read_clk_i,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  read_en_i
);

  localparam ADDR_WIDTH = $clog2(DEPTH);

  reg [ADDR_WIDTH:0] write_ptr, read_ptr, write_ptr_gray, read_ptr_gray;
  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [ADDR_WIDTH:0] write_ptr_gray_synced, read_ptr_gray_synced;

  // Gray code conversion functions
  function [ADDR_WIDTH:0] bin_to_gray;
    input [ADDR_WIDTH:0] bin;
    bin_to_gray = (bin >> 1) ^ bin;
  endfunction

  function [ADDR_WIDTH:0] gray_to_bin;
    input [ADDR_WIDTH:0] gray;
    integer i;
    reg [ADDR_WIDTH:0] bin;
    bin = gray;
    for (i = ADDR_WIDTH-1; i > 0; i = i - 1)
      bin[i-1] = bin[i] ^ gray[i-1];
    return bin;
  endfunction

  // Write pointer logic
  always @(posedge write_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      write_ptr <= 0;
    end else if (write_en_i && !full_o) begin
      write_ptr <= write_ptr + 1;
    end
  end

  // Read pointer logic
  always @(posedge read_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      read_ptr <= 0;
    end else if (read_en_i && valid_o) begin
      read_ptr <= read_ptr + 1;
    end
  end

  // Convert write pointer to Gray code and synchronize to read clock domain
  always @(posedge write_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      write_ptr_gray <= 0;
    end else begin
      write_ptr_gray <= bin_to_gray(write_ptr);
    end
  end

  // Synchronize write pointer Gray code to read clock domain
  always @(posedge read_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      write_ptr_gray_synced <= 0;
    end else begin
      write_ptr_gray_synced <= write_ptr_gray;
    end
  end

  // Convert read pointer to Gray code and synchronize to write clock domain
  always @(posedge read_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      read_ptr_gray <= 0;
    end else begin
      read_ptr_gray <= bin_to_gray(read_ptr);
    end
  end

  // Synchronize read pointer Gray code to write clock domain
  always @(posedge write_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      read_ptr_gray_synced <= 0;
    end else begin
      read_ptr_gray_synced <= read_ptr_gray;
    end
  end

  // Write data to memory
  always @(posedge write_clk_i or negedge rst_ni) begin
    if (!rst_ni && write_en_i && !full_o) begin
      mem[write_ptr[ADDR_WIDTH-1:0]] <= data_i;
    end
  end

  // Read data from memory
  assign data_o = mem[read_ptr[ADDR_WIDTH-1:0]];

  // Calculate full and valid signals
  assign full_o = (write_ptr_gray_synced[ADDR_WIDTH] != read_ptr_gray[ADDR_WIDTH]) &&
                  (write_ptr_gray_synced[ADDR_WIDTH-1:0] == read_ptr_gray[ADDR_WIDTH-1:0]);

  assign valid_o = (write_ptr_gray[ADDR_WIDTH] != read_ptr_gray_synced[ADDR_WIDTH]) ||
                   (write_ptr_gray[ADDR_WIDTH-1:0] != read_ptr_gray_synced[ADDR_WIDTH-1:0]);

endmodule
