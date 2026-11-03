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

  // Instantiate the async_fifo module
  async_fifo #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) async_fifo_inst (
    .rst_ni(src_rst_ni),
    .clk_wr(src_clk_i),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o),
    .clk_rd(dst_clk_i),
    .data_o(dst_data_o),
    .valid_o(dst_valid_o),
    .ready_i(dst_ready_i)
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
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  input  clk_rd,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  ready_i
);

  // Internal signals
  reg [WIDTH-1:0] fifo_mem [3:0];
  reg [1:0] wr_ptr, rd_ptr;
  reg [1:0] wr_ptr_gray, rd_ptr_gray;
  reg [1:0] wr_ptr_gray_sync, rd_ptr_gray_sync;
  reg full, empty;
  reg wr_en, rd_en;

  // Gray code conversion functions
  function [1:0] binary_to_gray;
    input [1:0] bin;
    binary_to_gray = bin ^ (bin >> 1);
  endfunction

  function [1:0] gray_to_binary;
    input [1:0] gray;
    reg [1:0] bin;
    bin[1] = gray[1];
    bin[0] = gray[0] ^ bin[1];
    gray_to_binary = bin;
  endfunction

  // Write pointer logic
  always @(posedge clk_wr or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr <= 2'b00;
    end else if (wr_en) begin
      wr_ptr <= wr_ptr + 1;
    end
  end

  // Read pointer logic
  always @(posedge clk_rd or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_ptr <= 2'b00;
    end else if (rd_en) begin
      rd_ptr <= rd_ptr + 1;
    end
  end

  // Gray code conversion
  assign wr_ptr_gray = binary_to_gray(wr_ptr);
  assign rd_ptr_gray = binary_to_gray(rd_ptr);

  // Synchronize gray pointers
  always @(posedge clk_wr or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_ptr_gray_sync <= 2'b00;
    end else begin
      rd_ptr_gray_sync <= rd_ptr_gray;
    end
  end

  always @(posedge clk_rd or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr_gray_sync <= 2'b00;
    end else begin
      wr_ptr_gray_sync <= wr_ptr_gray;
    end
  end

  // Full and empty flags
  assign full = (wr_ptr_gray_sync == {rd_ptr_gray_sync[0], ~rd_ptr_gray_sync[1]});
  assign empty = (wr_ptr_gray_sync == rd_ptr_gray_sync);

  // Write enable
  assign wr_en = valid_i & ~full;

  // Read enable
  assign rd_en = ready_i & ~empty;

  // FIFO memory write
  always @(posedge clk_wr) begin
    if (wr_en) begin
      fifo_mem[wr_ptr] <= data_i;
    end
  end

  // FIFO memory read
  always @(posedge clk_rd) begin
    if (rd_en) begin
      data_o <= fifo_mem[rd_ptr];
    end else if (SEND_RESET_MSG & ~rst_ni) begin
      data_o <= RESET_MSG;
    end
  end

  // Valid and ready outputs
  assign valid_o = ~empty;
  assign ready_o = ~full;

endmodule
