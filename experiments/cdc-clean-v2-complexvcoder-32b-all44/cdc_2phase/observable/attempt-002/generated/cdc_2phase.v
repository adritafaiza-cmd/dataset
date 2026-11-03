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

  // Internal signals for async_fifo
  logic wr_rdy_o;
  logic rd_rdy_o;
  logic [WIDTH-1:0] rd_data_o_int;

  // Instantiate the async_fifo module
  async_fifo #(
    .WIDTH(WIDTH)
  ) async_fifo_inst (
    .rst_ni(src_rst_ni),  // Common reset
    .wr_clk_i(src_clk_i),
    .wr_data_i(src_data_i),
    .wr_en_i(src_valid_i),
    .wr_rdy_o(wr_rdy_o),
    .rd_clk_i(dst_clk_i),
    .rd_data_o(rd_data_o_int),
    .rd_en_o(dst_valid_o),
    .rd_rdy_o(rd_rdy_o)
  );

  // Connect output signals
  assign src_ready_o = wr_rdy_o;
  assign dst_data_o = rd_data_o_int;

endmodule

module async_fifo #(
  parameter WIDTH = 1
)(
  input  rst_ni,
  input  wr_clk_i,
  input  [WIDTH-1:0] wr_data_i,
  input  wr_en_i,
  output wr_rdy_o,
  input  rd_clk_i,
  output [WIDTH-1:0] rd_data_o,
  input  rd_en_o,
  output rd_rdy_o
);

  // FIFO depth and signals
  localparam DEPTH = 4; // Power of 2 for simplicity
  localparam ADDR_WIDTH = $clog2(DEPTH);

  logic [WIDTH-1:0] mem [DEPTH-1:0];
  logic [ADDR_WIDTH:0] wr_ptr, wr_ptr_gray;
  logic [ADDR_WIDTH:0] rd_ptr, rd_ptr_gray;
  logic [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

  // Gray code conversion functions
  function [ADDR_WIDTH:0] bin_to_gray;
    input [ADDR_WIDTH:0] bin;
    bin_to_gray = (bin >> 1) ^ bin;
  endfunction

  function [ADDR_WIDTH:0] gray_to_bin;
    input [ADDR_WIDTH:0] gray;
    integer i;
    logic [ADDR_WIDTH:0] bin;
    bin = gray;
    for (i = ADDR_WIDTH-1; i > 0; i = i - 1) begin
      bin[i-1] = bin[i] ^ bin[i-1];
    end
    gray_to_bin = bin;
  endfunction

  // Write pointer logic
  always_ff @(posedge wr_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr <= 0;
    end else if (wr_rdy_o && wr_en_i) begin
      wr_ptr <= wr_ptr + 1;
    end
  end

  // Write pointer to gray code conversion
  always_ff @(posedge wr_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr_gray <= 0;
    end else begin
      wr_ptr_gray <= bin_to_gray(wr_ptr);
    end
  end

  // Synchronize write pointer gray code to read clock domain
  always_ff @(posedge rd_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr_gray_sync <= 0;
    end else begin
      wr_ptr_gray_sync <= wr_ptr_gray;
    end
  end

  // Read pointer logic
  always_ff @(posedge rd_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_ptr <= 0;
    end else if (rd_rdy_o && rd_en_o) begin
      rd_ptr <= rd_ptr + 1;
    end
  end

  // Read pointer to gray code conversion
  always_ff @(posedge rd_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_ptr_gray <= 0;
    end else begin
      rd_ptr_gray <= bin_to_gray(rd_ptr);
    end
  end

  // Synchronize read pointer gray code to write clock domain
  always_ff @(posedge wr_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_ptr_gray_sync <= 0;
    end else begin
      rd_ptr_gray_sync <= rd_ptr_gray;
    end
  end

  // Write enable and FIFO full condition
  assign wr_rdy_o = ~(wr_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1] ^ wr_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1]) && (wr_ptr_gray[ADDR_WIDTH-2:0] != rd_ptr_gray_sync[ADDR_WIDTH-2:0]);

  // Read enable and FIFO empty condition
  assign rd_rdy_o = ~(rd_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1] ^ rd_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1]) && (rd_ptr_gray[ADDR_WIDTH-2:0] != wr_ptr_gray_sync[ADDR_WIDTH-2:0]);

  // Write data to FIFO memory
  always_ff @(posedge wr_clk_i) begin
    if (wr_rdy_o && wr_en_i) begin
      mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data_i;
    end
  end

  // Read data from FIFO memory
  always_ff @(posedge rd_clk_i) begin
    if (rd_rdy_o && rd_en_o) begin
      rd_data_o <= mem[rd_ptr[ADDR_WIDTH-1:0]];
    end
  end

endmodule
