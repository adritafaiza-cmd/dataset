module async_bidir_fifo #(
  parameter DSIZE = 8,
  parameter ASIZE = 4,
  parameter FALLTHROUGH = "TRUE"
) (
  // A side
  input a_clk,
  input a_rst_n,
  input a_winc,
  input [DSIZE-1:0] a_wdata,
  input a_rinc,
  output [DSIZE-1:0] a_rdata,
  output a_full,
  output a_afull,
  output a_empty,
  output a_aempty,
  input a_dir,
  // B side
  input b_clk,
  input b_rst_n,
  input b_winc,
  input [DSIZE-1:0] b_wdata,
  input b_rinc,
  output [DSIZE-1:0] b_rdata,
  output b_full,
  output b_afull,
  output b_empty,
  output b_aempty,
  input b_dir
);

  // FIFO from A to B
  async_fifo #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_ab (
    .wr_clk(a_clk),
    .wr_rst_n(a_rst_n),
    .wr_en(a_winc & a_dir),
    .wr_data(a_wdata),
    .full(a_full),
    .afull(a_afull),
    .rd_clk(b_clk),
    .rd_rst_n(b_rst_n),
    .rd_en(b_rinc & ~b_dir),
    .empty(b_aempty),
    .aempty(b_aempty),
    .data(b_rdata)
  );

  // FIFO from B to A
  async_fifo #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_ba (
    .wr_clk(b_clk),
    .wr_rst_n(b_rst_n),
    .wr_en(b_winc & b_dir),
    .wr_data(b_wdata),
    .full(b_full),
    .afull(b_afull),
    .rd_clk(a_clk),
    .rd_rst_n(a_rst_n),
    .rd_en(a_rinc & ~a_dir),
    .empty(a_aempty),
    .aempty(a_aempty),
    .data(a_rdata)
  );

endmodule

module async_fifo #(
  parameter DSIZE = 8,
  parameter ASIZE = 4,
  parameter FALLTHROUGH = "TRUE"
) (
  input wr_clk,
  input wr_rst_n,
  input wr_en,
  input [DSIZE-1:0] wr_data,
  output full,
  output afull,
  input rd_clk,
  input rd_rst_n,
  input rd_en,
  output [DSIZE-1:0] rd_data,
  output empty,
  output aempty,
  output afull
);

  reg [DSIZE-1:0] mem [0:(1 << ASIZE)-1];
  reg [ASIZE:0] wr_ptr, rd_ptr;

  function [ASIZE:0] gray;
    input [ASIZE:0] bin;
    begin
      gray = bin ^ (bin >> 1);
    end
  endfunction

  reg [ASIZE:0] wr_ptr_gray, rd_ptr_gray;
  reg [ASIZE:0] wr_ptr_gray_rd, wr_ptr_gray_rd2;
  reg [ASIZE:0] rd_ptr_gray_wr, rd_ptr_gray_wr2;

  assign full = (wr_ptr[ASIZE] != rd_ptr_gray_rd2[ASIZE]) &&
                (wr_ptr[ASIZE-1:0] == rd_ptr_gray_rd2[ASIZE-1:0]);

  assign empty = (rd_ptr == wr_ptr_gray_rd2);

  always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) wr_ptr <= 0;
    else if (wr_en && !full) wr_ptr <= wr_ptr + 1;
  end

  always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) rd_ptr <= 0;
    else if (rd_en && !empty) rd_ptr <= rd_ptr + 1;
  end

  always @(*) begin
    wr_ptr_gray = gray(wr_ptr);
    rd_ptr_gray = gray(rd_ptr);
  end

  always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) {wr_ptr_gray_rd, wr_ptr_gray_rd2} <= 0;
    else {wr_ptr_gray_rd, wr_ptr_gray_rd2} <= {wr_ptr_gray, wr_ptr_gray_rd};
  end

  always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) {rd_ptr_gray_wr, rd_ptr_gray_wr2} <= 0;
    else {rd_ptr_gray_wr, rd_ptr_gray_wr2} <= {rd_ptr_gray, rd_ptr_gray_wr};
  end

  always @(posedge wr_clk) begin
    if (wr_en && !full) mem[wr_ptr[ASIZE-1:0]] <= wr_data;
  end

  assign rd_data = mem[rd_ptr[ASIZE-1:0]];

  assign aempty = FALLTHROUGH == "TRUE" ? empty : !empty;
  assign afull = FALLTHROUGH == "TRUE" ? full : !full;
  assign bempty = FALLTHROUGH == "TRUE" ? empty : !empty;
  assign bfull = FALLTHROUGH == "TRUE" ? full : !full;

endmodule
