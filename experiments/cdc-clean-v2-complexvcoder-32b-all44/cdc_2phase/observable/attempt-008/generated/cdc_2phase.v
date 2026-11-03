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

  async_fifo #(
    .WIDTH(WIDTH)
  ) fifo_inst (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o),
    .rst_no(dst_rst_ni),
    .clk_o(dst_clk_i),
    .data_o(dst_data_o),
    .valid_o(dst_valid_o),
    .ready_i(dst_ready_i)
  );

endmodule

module async_fifo #(
  parameter WIDTH = 1
)(
  input  rst_ni,
  input  clk_i,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  input  rst_no,
  input  clk_o,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  ready_i
);

  reg [WIDTH-1:0] fifo [0:1];
  reg [1:0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray, rd_ptr_gray_sync;
  reg fifo_full, fifo_empty;

  // Gray code conversion
  assign wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;
  assign rd_ptr_gray_sync = rd_ptr_gray_sync_reg;

  // FIFO full and empty flags
  assign fifo_full = (wr_ptr_gray == rd_ptr_gray_sync);
  assign fifo_empty = (wr_ptr_gray == rd_ptr_gray);

  // Write enable
  assign ready_o = ~fifo_full;

  // Read enable
  assign valid_o = ~fifo_empty;

  // Write data
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      fifo[0] <= 0;
      fifo[1] <= 0;
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end else if (valid_i && !fifo_full) begin
      fifo[wr_ptr[0]] <= data_i;
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= wr_ptr_gray + 1;
    end
  end

  // Read data
  always @(posedge clk_o or negedge rst_no) begin
    if (!rst_no) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
      rd_ptr_gray_sync_reg <= 0;
      data_o <= 0;
    end else if (ready_i && !fifo_empty) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= rd_ptr_gray + 1;
      data_o <= fifo[rd_ptr[0]];
    end
  end

  // Synchronize read pointer gray code to source clock domain
  reg [1:0] rd_ptr_gray_sync_reg;
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_ptr_gray_sync_reg <= 0;
    end else begin
      rd_ptr_gray_sync_reg <= rd_ptr_gray_sync;
    end
  end

endmodule
