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

  async_fifo #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) async_fifo_inst (
    .rst_ni(src_rst_ni),
    .clk_wr(src_clk_i),
    .data_wr(src_data_i),
    .valid_wr(src_valid_i),
    .ready_wr(src_ready_o),
    .clk_rd(dst_clk_i),
    .data_rd(dst_data_o),
    .valid_rd(dst_valid_o),
    .ready_rd(dst_ready_i)
  );

endmodule

module async_fifo #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
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

  localparam DEPTH = 4; // Depth of the FIFO
  localparam ADDR_WIDTH = $clog2(DEPTH);

  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [ADDR_WIDTH:0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray, rd_ptr_gray_sync;
  reg [WIDTH-1:0] data_reg;
  reg valid_reg;

  // Gray code conversion
  function [ADDR_WIDTH:0] bin_to_gray;
    input [ADDR_WIDTH:0] bin;
    bin_to_gray = (bin >> 1) ^ bin;
  endfunction

  // Write pointer logic
  always @(posedge clk_wr or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end else if (valid_wr && ready_wr) begin
      mem[wr_ptr[ADDR_WIDTH-1:0]] <= data_wr;
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= bin_to_gray(wr_ptr + 1);
    end
  end

  // Read pointer logic
  always @(posedge clk_rd or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end else if (valid_rd && ready_rd) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= bin_to_gray(rd_ptr + 1);
    end
  end

  // Gray code synchronization
  always @(posedge clk_wr or negedge rst_ni) begin
    if (!rst_ni)
      rd_ptr_gray_sync <= 0;
    else
      rd_ptr_gray_sync <= rd_ptr_gray;
  end

  // FIFO status
  wire full = (wr_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1] != rd_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1]) &&
             (wr_ptr_gray[ADDR_WIDTH-2:0] == rd_ptr_gray_sync[ADDR_WIDTH-2:0]);
  wire empty = (wr_ptr_gray == rd_ptr_gray);

  // Read data and valid
  always @(posedge clk_rd or negedge rst_ni) begin
    if (!rst_ni) begin
      data_reg <= RESET_MSG;
      valid_reg <= SEND_RESET_MSG;
    end else if (valid_rd && ready_rd) begin
      data_reg <= mem[rd_ptr[ADDR_WIDTH-1:0]];
      valid_reg <= 1;
    end else if (!valid_reg) begin
      valid_reg <= 0;
    end
  end

  assign data_rd = data_reg;
  assign valid_rd = valid_reg;
  assign ready_wr = !full;

endmodule
